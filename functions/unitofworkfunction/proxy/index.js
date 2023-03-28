import { spawn } from 'child_process';
import Fastify from 'fastify'
import { readFileSync } from 'fs';
import https from 'https'
import jwt from 'jsonwebtoken';
import path from 'path';
import proxy from '@fastify/http-proxy';

const fastify = Fastify({
    logger: true
})

// Customer-provided configuration
const ORG_ID_18_CONFIG_VAR_NAME = 'ORG_ID_18';
const FUNCTION_URL_CONFIG_VAR_NAME = 'FUNCTION_URL';
const FUNCTION_PORT_CONFIG_VAR_NAME = 'FUNCTION_PORT';
const PRIVATE_KEY_CONFIG_VAR_NAME = 'PRIVATE_KEY';
const PRIVATE_KEY_FILEPATH_CONFIG_VAR_NAME = 'PRIVATE_KEY_FILEPATH';
const CONSUMER_KEY_CONFIG_VAR_NAME = 'CONSUMER_KEY';
const DEBUG_PORT_CONFIG_VAR_NAME = 'DEBUG_PORT';
const orgId18 = process.env[ORG_ID_18_CONFIG_VAR_NAME];
const functionPort = process.env[FUNCTION_PORT_CONFIG_VAR_NAME] || 8080;
const functionUrl = `${(process.env[FUNCTION_URL_CONFIG_VAR_NAME] || 'http://localhost')}:${functionPort}`;
const privateKey = process.env[PRIVATE_KEY_CONFIG_VAR_NAME] || readFileSync(process.env[PRIVATE_KEY_FILEPATH_CONFIG_VAR_NAME], 'utf8');
const clientId = process.env[CONSUMER_KEY_CONFIG_VAR_NAME];

// Headers
const HEADER_REQUEST_ID = 'x-request-id';
const HEADER_FUNCTION_CONTEXT = 'ce-sfcontext';
const HEADER_REQUEST_CONTEXT = 'ce-sffncontext';
const HEADER_EXTRA_INFO = 'x-extra-info';

// Other constants
const FUNCTION_INVOCATION_TYPE_SYNC = 'com.salesforce.function.invoke.sync';
const FUNCTION_INVOCATION_TYPE_ASYNC = 'com.salesforce.function.invoke.async';
const SANDBOX_AUDIENCE_URL = 'https://test.salesforce.com';
const PROD_AUDIENCE_URL = 'https://login.salesforce.com';

// Globals
let functionProcess;

/**
 * Generic HTTP request, Promisified.
 *
 * @param url
 * @param opts
 * @param body
 * @returns {Promise<unknown>}
 */
function httpRequest(url, opts, body = '') {
    return new Promise((resolve, reject) => {
        const req = https.request(url, opts, res => {
            const chunks = [];
            res.on('data', chunk => chunks.push(chunk));
            res.on('error', reject);
            res.on('end', () => {
                const {statusCode, headers} = res;
                const body = chunks.join('');
                if (statusCode >= 200 && statusCode <= 299) {
                    resolve({statusCode, headers, body});
                } else {
                    const err = new Error(body);
                    err.statusCode = statusCode;
                    reject(err);
                }
            })
        })

        req.on('error', reject);
        req.write(body);
        req.end();
    })
}

/**
 * Assemble Salesforce API URI part.
 *
 * @param baseUrl
 * @param apiVersion
 * @param uriPart
 * @returns {string}
 */
function assembleSalesforceAPIUrl(baseUrl, apiVersion, uriPart) {
    return `${baseUrl}/services/data/v${apiVersion}/${uriPart}`;
}

/**
 * Assemble Salesforce API Headers.
 *
 * @param accessToken
 * @returns {{Authorization: string, "Content-Type": string}}
 */
function assembleSalesforceAPIHeaders(accessToken) {
    return {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`
    };
}

/**
 * Generic error thrower setting status code.
 *
 * @param msg
 * @param statusCode
 * @param requestId
 */
function throwError(msg, statusCode, requestId) {
    if (requestId) {
        msg = `[${requestId}] ${msg}`;
    }
    const err = new Error(msg);
    err.statusCode = statusCode;
    throw err;
}

/**
 * Decode and parse encoded given encoded header.
 *
 * @param requestId
 * @param headerName
 * @param headers
 * @returns {any}
 */
function decodeAndParseEncodedHeader(requestId, headerName, headers) {
    const encodedHeader = headers[headerName];
    if (!encodedHeader) {
        throwError(`Context ${headerName} not found`, 400, requestId);
    }

    let decodedHeader;
    try {
        decodedHeader = Buffer.from(encodedHeader, 'base64').toString('utf8');
    } catch (err) {
        throwError(`[${requestId}] Invalid ${headerName} format - expected base64 encoded header: ${err.message}`, 400, requestId);
    }

    return JSON.parse(decodedHeader);
}

/**
 * Excepted context headers and schema w/ examples:
 *
 *  - ce-sffncontext: context of the function request
 *  {
 *     'id': '00Dxx0000006IYJEA2-4Y4W3Lw_LkoskcHdEaZze-uuic-MyFunction-2023-03-23T15:18:53.429-0700',
 *     'function': 'MyFunction',
 *     'resource': 'https://...',
 *     'source': 'urn:event:from:salesforce/<instance>/<orgId>/<platform origin, eg apex>',
 *     'type': 'com.salesforce.function.invoke.sync',
 *     'requestTime': '2023-03-23T15:18:53.429-0700',
 *     'asyncFunctionInvocationRequestId': '<id>',
 *     'permissionSets': '[ 'MyPermissionSet' ]'
 *   }
 *
 *  - ce-sfcontext: Salesforce context, ie the context of the requesting Org and user
 *  {
 *     'apiVersion': '57.0',
 *     'payloadVersion': '0.1',
 *     'userContext': {
 *       'orgId': '00Dxx0000006IYJ',
 *       'userId': '005xx000001X8Uz',
 *       'username': 'admin@example.com',
 *       'onBehalfOfUserId': '',
 *       'salesforceBaseUrl': 'https://na1.salesforce.com',
 *       'orgDomainUrl': 'https://mycompany.my.salesforce.com',
 * 	     'namespace': ''
 * 	   }
 *   }
 *
 * @param requestId
 * @param headers
 * @returns {{fnContext: *, sfContext: *}}
 */
function parseContexts(requestId, headers) {
    const fnContext = decodeAndParseEncodedHeader(HEADER_FUNCTION_CONTEXT, headers);
    if (!fnContext) {
        throwError(`Invalid ${HEADER_FUNCTION_CONTEXT} - function request context not found`, 400, requestId);
    }

    const sfContext = decodeAndParseEncodedHeader(HEADER_REQUEST_CONTEXT, headers);
    if (!sfContext || sfContext.userContext) {
        throwError(`Invalid ${HEADER_REQUEST_CONTEXT} - Salesforce context not found`, 400, requestId);
    }

    return {
        fnContext,
        sfContext
    };
}

/**
 * Excepted headers:
 *  - x-request-id: request id generated by client that tracks the entire request/response
 *  - ce-specversion: version of CloudEvent schema
 *  - ce-id: see x-request-id
 *  - ce-source: source of request
 *  - ce-type: type of request
 *  - ce-time: origin time of request
 *  - ce-sfcontext: context of function request
 *  - ce-sffncontext: context of invoker, eg user and org context
 *
 * @param headers
 * @returns {{requestId: string, accessToken: string, fnContext: *, sfContext: *}}
 */
function parseAndValidateHeaders(headers) {
    const requestId = headers[HEADER_REQUEST_ID];
    if (!requestId) {
        throwError(`${HEADER_REQUEST_ID} header not found`, 400);
    }

    if (!headers.authorization) { // TODO: Regex validate
        throwError('Authorization not found', 400, requestId);
    }
    const accessToken = headers.authorization.substring(headers.authorization.indexOf(' ') + 1);
    if (!accessToken) {
        throwError('Authorization accessToken not found', 400, requestId);
    }

    // Parse function request and salesforce contexts
    const { fnContext, sfContext } = parseContexts(requestId, headers);

    if (fnContext.type !== FUNCTION_INVOCATION_TYPE_SYNC || fnContext.type !== FUNCTION_INVOCATION_TYPE_ASYNC) {
        throwError(`Invalid function invocation type ${fnContext.type}`, 400, requestId);
    }

    if (fnContext.type === FUNCTION_INVOCATION_TYPE_ASYNC && !fnContext.asyncFunctionInvocationRequestId) {
        throwError('AsyncFunctionInvocationRequest__c ID not provided for async invocation', 400, requestId);
    }

    if (!sfContext.apiVersion) {
        throwError('API Version not provided', 400, requestId);
    }

    if (!sfContext.userContext.orgId) {
        throwError('Org ID not provided', 400, requestId);
    }

    if (!sfContext.userContext.username) {
        throwError('Username not provided', 400, requestId);
    }

    if (!sfContext.userContext.salesforceBaseUrl) {
        throwError(`SalesforceBaseUrl not provided`, 400, requestId);
    }

    return { requestId, accessToken, fnContext, sfContext };
}

/**
 * Validate expected payload and that the function invoker is of the expected org.
 *
 * @param logger
 * @param headers
 * @returns {Promise<{requestId: string, accessToken: string, fnContext: *, sfContext: *}>}
 */
async function validateRequest(logger, headers) {
    // Parse and validate request
    const { requestId, accessToken, fnContext, sfContext } = parseAndValidateHeaders(headers);

    // Validate that the context's orgId matches the accessToken
    await validateCaller(requestId, logger, sfContext.userContext.salesforceBaseUrl, accessToken);

    return { requestId, accessToken, fnContext, sfContext };
}

/**
 * Mint and return function's token for requesting user using configured Connected App.
 *
 * If applicable, activate provided session-based Permission Set(s) to token.
 *
 * TODO: Consider caching tokens for given signature: user, connected app, session-based Permission(s).  If cached,
 *       use /services/oauth2/introspect to determine token validity (eg, timeout).
 *
 * @param requestId
 * @param logger
 * @param fnContext
 * @param sfContext
 * @returns {Promise<String>}
 */
async function mintAndPrepareFunctionToken(requestId, logger, fnContext, sfContext) {
    const oauthUrl = `${sfContext.userContext.salesforceBaseUrl}/services/oauth2/token`;
    let isTest = false;
    if (oauthUrl.includes('.sandbox.') || oauthUrl.includes('c.scratch.vf.force.com')) {
        isTest = true;
    }

    const jwtOpts = {
        issuer: clientId,
        audience: process.env.SF_AUDIENCE || (isTest ? SANDBOX_AUDIENCE_URL : PROD_AUDIENCE_URL),
        algorithm: 'RS256'
    }
    const signedJWT = jwt.sign({ prn: sfContext.userContext.username }, privateKey, jwtOpts);
    const oauthOpts = {
        method: 'POST',
        form: {
            'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion':  signedJWT
        }
    };

    logger.info(`[${requestId}] Minting ${isTest ? 'test ' : ' '}token for user ${sfContext.userContext.username}, audience ${jwtOpts.audience}, uri ${oauthUrl}, issuer ${jwtOpts.issuer.substring(0,5)}...`);
    let response;
    try {
        response = await httpRequest(oauthUrl, oauthOpts);
    } catch (err) {
        let errMsg = err.message;
        if (errMsg.includes('invalid_app_access') || errMsg.includes('user hasn\'t approved this consumer')) {
            errMsg += `. Ensure that the target Connected App is set to "Admin approved users are pre-authorized" and user ${sfContext.userContext.username} is assigned to Connected App via a Permission Set`;
        }
        logger.error(errMsg);
        throwError(errMsg, 403, requestId);
    }

    const accessToken = response.access_token;

    // Activate session-based Permission Sets, if applicable
    await activateSessionPermSet(requestId, logger, fnContext, accessToken, response.instance_url);

    return accessToken;
}

/**
 * Update  async request's associated AsyncFunctionInvocationRequest__c w/ function's response.
 *
 * @param logger
 * @param fnContext
 * @param sfContext
 * @param accessToken
 * @param functionResponse
 * @param statusCode
 * @param extraInfo
 * @returns {Promise<void>}
 */
async function updateAsyncFunctionResponse(logger, fnContext, sfContext, accessToken, functionResponse, statusCode, extraInfo) {
    const apiUrl = assembleSalesforceAPIUrl(sfContext.userContext.salesforceBaseUrl, sfContext.apiVersion, `/sobjects/AsyncFunctionInvocationRequest__c/${fnContext.asyncFunctionInvocationRequestId}`);
    const status = statusCode < 200 || statusCode > 299 ? 'ERROR' : 'SUCCESS';
    const opts = {
        method: 'POST',
        headers: assembleSalesforceAPIHeaders(accessToken)
    };
    const body = {
        ExtraInfo__c: extraInfo,
        Id: fnContext.asyncFunctionInvocationRequestId,
        Response__c: functionResponse,
        Status__c: status,
        StatusCode__c: statusCode
    };

    // Update AsyncFunctionInvocationRequest__c
    let response;
    try {
        response = await httpRequest(apiUrl, opts, JSON.stringify(body));
    } catch (err) {
        let errMsg = err.message;
        if (errMsg.includes('The requested resource does not exist')) {
            errMsg += `. Ensure that user ${sfContext.userContext.username} has access to AsyncFunctionInvocationRequest__c.`;
        }

        // TODO: Retry on certain error status codes

        logger.error(errMsg);
        throw new Error(errMsg);
    }

    if (response && !response.success) {
        logger.error(`Unable to save function response to AsyncFunctionInvocationRequest [${fnContext.asyncFunctionInvocationRequestId}]: ${JSON.stringify(response.errors.join(','))}`);
    } else {
        logger.info(`Save function response [${statusCode}] to AsyncFunctionInvocationRequest [${fnContext.asyncFunctionInvocationRequestId}]`);
    }
}

/**
 * Handle async request invoking function and saving response to associated AsyncFunctionInvocationRequest__c.
 *
 * @param request
 * @param reply
 * @returns {Promise<void>}
 */
async function handleAsyncRequest(request, reply) {
    const logger = request.log;
    const headers = request.headers;
    const { requestId, accessToken, fnContext, sfContext } = parseAndValidateHeaders(headers);
    logger.info(`[${requestId}] Invoking async function ${fnContext.function}...`);

    const opts = {
        method: request.method,
        headers
    };

    let statusCode, response, extraInfo;
    try {
        // Invoke function!
        const functionResponse = await httpRequest(functionUrl, opts, JSON.stringify(request.body));
        statusCode = functionResponse.statusCode;
        response = functionResponse.body;
        extraInfo = functionResponse.headers[HEADER_EXTRA_INFO];
    } catch (err) {
        logger.error(err.message);
        statusCode = 500;
        response = `${err.message} ${err.code}]`;
        if (err.response) {
            statusCode = err.response.statusCode;
            response = err.response.body;
            extraInfo = err.response.headers[HEADER_EXTRA_INFO];
        }
    }

    await updateAsyncFunctionResponse(logger, fnContext, sfContext, accessToken, response, statusCode, extraInfo);
}

/**
 * Validate that requesting org is expected org (orgId18) by using given token to verify org info
 * provided by /userinfo API.
 *
 * @param requestId
 * @param logger
 * @param instanceUrl
 * @param accessToken
 * @returns {Promise<void>}
 */
async function validateCaller(requestId, logger, instanceUrl, accessToken) {
    const url = `${instanceUrl}/services/oauth2/userinfo`;
    const opts = {
        method: 'GET',
        headers: assembleSalesforceAPIHeaders(accessToken)
    };

    // Get Org's info via /userinfo API
    let response;
    try {
        response = httpRequest(url, opts);
    } catch (err) {
        throwError(`[${requestId}] Unable to obtain userinfo for org ${orgId18}: ${err.message}`, err.statusCode);
    }

    if (response && orgId18 !== response.organization_id) {
        logger.warn(`[${requestId}] Unauthorized caller from org ${response.organization_id}, expected ${orgId18}`);
        throwError('Unauthorized request', 401, requestId);
    }
}

/**
 * Activate session-based Permission Sets, if applicable.
 *
 * @param requestId
 * @param logger
 * @param fnContext
 * @param accessToken
 * @param instanceUrl
 * @returns {Promise<void>}
 */
async function activateSessionPermSet(requestId, logger, fnContext, accessToken, instanceUrl) {
    const permissionSets = fnContext.permissionSets;
    if (!permissionSets || permissionSets.length === 0) {
        logger.info(`[${requestId}] Skipping session-based Permission Sets activation`);
        return;
    }

    // Assemble /activateSessionPermSet API body
    const inputs = [];
    permissionSets.forEach(permissionSet => {
        if (permissionSet.includes('__')) {
            inputs.push({
                PermSetName: permissionSet.substring(0, permissionSet.indexOf('__')),
                PermSetNamespace: permissionSet.substring(permissionSet.indexOf('__') + 2)
            });
        } else {
            inputs.push({ PermSetName: permissionSet });
        }
    });
    const body = { inputs: inputs };

    const apiUrl = assembleSalesforceAPIUrl(instanceUrl, sfContext.apiVersion, '/actions/standard/activateSessionPermSet');
    const opts = {
        method: 'POST',
        headers: assembleSalesforceAPIHeaders(accessToken),
        json: { inputs: inputs },
    };

    let response;
    try {
        // Activate!
        response = await httpRequest(apiUrl, opts, JSON.stringify(body));
    } catch (err) {
        let errMsg = err.message;
        try {
            const errResponses = JSON.parse(errMsg);
            if (errResponses && errResponses.length > 0) {
                const errMsgs = [];
                // FIXME: Do array collect or whatever
                errResponses.forEach(errResponse => errResponse.errors.forEach(error => errMsgs.push(`${error.message} [${error.statusCode}]`)));
                errMsg = errMsgs.join('; ')
            }
        } catch (parseErr) {
            // ignore
        }
        logger.error(errMsg);
        throwError(errMsg, err.statusCode || 503, requestId);
    }

    const failedActivations = response.filter(activation => !activation.isSuccess);
    if (response && failedActivations.length > 0) {
        // TODO: Output failed PermissionSet names from response
        throwError(`Unable to activate session-based Permission Set(s) ${permissionSets.join(', ')}: ${JSON.stringify(failedActivations.map(failedActivation => failedActivation.errors))}`, response.statusCode || 503, requestId);
    } else {
        logger.info(`[${requestId}] Successfully activated session-based Permission Set(s): ${permissionSets.join(', ')}`);
    }
}

/**
 * Re-assemble the function's context setting function's accessToken.
 *
 * @param headers
 * @param fnContext
 * @param accessToken
 */
function assembleFunctionRequest(headers, fnContext, accessToken) {
    // Function's org-access token
    fnContext.accessToken = accessToken;
    headers[HEADER_REQUEST_CONTEXT] = Buffer.from(JSON.stringify(fnContext), 'utf8').toString('base64');
}

/**
 * Start function process.
 *
 * @returns {ChildProcessWithoutNullStreams}
 */
function startFunction(logger) {
    const __dirname = path.resolve();
    const args = [
        `${__dirname}/../node_modules/@heroku/sf-fx-runtime-nodejs/bin/cli.js`,
        'serve',
        `${__dirname}/..`,
        '-p',
        functionPort
    ];
    logger.info(`Starting function w/ args: ${args.join(' ')}`);

    if (process.env[DEBUG_PORT_CONFIG_VAR_NAME]) {
        args.push('-d');
        args.push(DEBUG_PORT_CONFIG_VAR_NAME);
    }

    const functionProcess = spawn('node', args,{});
    functionProcess.stdout.on('data', buff => {
        // REVIEWME: Prefix message w/ function name or add/change attribute to include function name?
        const line = buff.toLocaleString();
        logger.info(line);
    });
    functionProcess.stderr.on('data', buff => { // also catch any error output
        // REVIEWME: Prefix message w/ function name or add/change attribute to include function name?
        const line = buff.toLocaleString();
        logger.error(line);
    });
    functionProcess.on('error', err => { // also catch any error output
        // REVIEWME: Prefix message w/ function name or add/change attribute to include function name?
        // TODO: Retry?
        logger.error(err.message);
    });
    functionProcess.on('exit', code => {
        // REVIEWME: Prefix message w/ function name or add/change attribute to include function name?
        logger.info(`Function process exited with code ${code}`);
        // REVIEWME: What to do here?
        process.exit(1);
    });

    return functionProcess;
}

//   F A S T I F Y    C O N F I G U R A T I O N

/**
 * Register 'http-proxy' plugin to handle validating and enriching sync requests.  The request is forwarded to
 * the function.
 */
fastify.register(proxy, {
    upstream: functionUrl,
    prefix: '/sync',
    // Validate and enrich sync requests
    preHandler: async (request, reply) => {
        const logger = request.log,
            headers = request.headers;
        const { requestId, fnContext, sfContext } = await validateRequest(logger, headers);
        logger.info(`[${requestId}] Handling ${fnContext.type} function request ${fnContext.function}`);

        const accessToken = await mintAndPrepareFunctionToken(requestId, logger, fnContext, sfContext);
        assembleFunctionRequest(headers, fnContext, accessToken);
    },
    replyOptions: {
        onError: (reply, error) => {
            if (error.statusCode && 503 === error.statusCode) {
                fastify.log.warn('Function request failed with 503 - implement function health check, restart (if necessary), and retry');
            }
            reply.send(error);
        }
    }
});

/**
 * Route to handle async requests.
 *
 * Requests are validate, a function token is minted and apply to the request, and finally a response is
 * sent to disconnect the original request.  The 'onResponse' handler then makes a separate request to the function.
 */
fastify.post('/async', async function (request, reply) {
    const logger = request.log;
    const headers = request.headers;
    const { requestId, context: fnContext, userContext: sfContext } = await validateRequest(logger, headers);
    logger.info(`[${requestId}] Handling ${fnContext.type} function request ${fnContext.function}`);

    if (FUNCTION_INVOCATION_TYPE_ASYNC !== fnContext.type) {
        throwError('Invalid request type', 400, requestId);
    }

    // Mint token w/ JWT and apply session-based PermSets to accessToken
    const accessToken = await mintAndPrepareFunctionToken(requestId, logger, fnContext, sfContext);
    assembleFunctionRequest(headers, fnContext, accessToken);
    reply.code(201);
});

/**
 * Route to check health of function process.
 */
fastify.register(proxy, {
    upstream: functionUrl,
    prefix: '/healthcheck',
    preHandler: async (request, reply) => {
        const logger = request.log,
            headers = request.headers;
        logger.info('Handling function health check request');
        headers['x-health-check'] = 'true';
    }
});

/**
 * On response, handle async requests.  The original request was validated and enriched in the /async route handler.
 */
fastify.addHook('onResponse', async (request, reply) => {
    if (reply.statusCode !== 201) {
        return;
    }

    const { context } = parseContexts(request.headers[HEADER_REQUEST_ID], request.headers);
    if (context && FUNCTION_INVOCATION_TYPE_ASYNC === fnContext.type) {
        await handleAsyncRequest(request, reply);
    }
});

/**
 * Before proxy listens, validate required configuration and start function server.
 */
fastify.addHook('onReady', async () => {
    const validateRequiredConfig = (name, value) => {
        if (!value) {
            throw Error(`Required config ${name} not found`);
        }
    }

    validateRequiredConfig(ORG_ID_18_CONFIG_VAR_NAME, orgId18);
    validateRequiredConfig(FUNCTION_PORT_CONFIG_VAR_NAME, functionPort);
    validateRequiredConfig(`${PRIVATE_KEY_CONFIG_VAR_NAME} or ${PRIVATE_KEY_FILEPATH_CONFIG_VAR_NAME}`, privateKey);
    validateRequiredConfig(CONSUMER_KEY_CONFIG_VAR_NAME, clientId);

    functionProcess = startFunction(fastify.log);
    fastify.log.info(`Started function started on port ${functionPort}, process pid ${functionProcess.pid}`);
})

/**
 * If close is called, also kill function server.
 */
fastify.addHook('onClose', async (instance) => {
    if (functionProcess) {
        functionProcess.kill();
    }
})

/**
 * Listen on given port.  Startup function service.
 */
fastify.listen({ host: '0.0.0.0', port: process.env.PORT || 3000 }, async (err, address) => {
    if (err) {
        fastify.log.error(err);
        process.exit(1);
    }
});