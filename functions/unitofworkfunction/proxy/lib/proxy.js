import { spawn } from 'child_process';
import { existsSync } from 'fs';
import https from 'https'
import jwt from 'jsonwebtoken';
import path from 'path';
import proxy from '@fastify/http-proxy';

const __dirname = path.resolve();

// Customer-provided configuration
const ORG_ID_18_CONFIG_VAR_NAME = 'ORG_ID_18';
const FUNCTION_URL_CONFIG_VAR_NAME = 'FUNCTION_URL';
const FUNCTION_PORT_CONFIG_VAR_NAME = 'FUNCTION_PORT';
const PRIVATE_KEY_CONFIG_VAR_NAME = 'PRIVATE_KEY';
const CONSUMER_KEY_CONFIG_VAR_NAME = 'CONSUMER_KEY';
const DEBUG_PORT_CONFIG_VAR_NAME = 'DEBUG_PORT';
const RUNTIME_CLI_FILEPATH_CONFIG_VAR_NAME = 'RUNTIME_CLI_FILEPATH';
const orgId18 = process.env[ORG_ID_18_CONFIG_VAR_NAME];
const functionPort = process.env[FUNCTION_PORT_CONFIG_VAR_NAME] || 8080;
const functionUrl = `${(process.env[FUNCTION_URL_CONFIG_VAR_NAME] || 'http://localhost')}:${functionPort}`;
const privateKey = process.env[PRIVATE_KEY_CONFIG_VAR_NAME];
const clientId = process.env[CONSUMER_KEY_CONFIG_VAR_NAME];
const runtimeCLIPath = process.env[RUNTIME_CLI_FILEPATH_CONFIG_VAR_NAME] || `${__dirname}/../node_modules/@heroku/sf-fx-runtime-nodejs/bin/cli.js`;

// Headers
const HEADER_REQUEST_ID = 'x-request-id';
const HEADER_FUNCTION_REQUEST_CONTEXT = 'ce-sffncontext';
const HEADER_SALESFORCE_CONTEXT = 'ce-sfcontext';
const HEADER_EXTRA_INFO = 'x-extra-info';

// Other constants
const FUNCTION_INVOCATION_TYPE_SYNC = 'com.salesforce.function.invoke.sync';
const FUNCTION_INVOCATION_TYPE_ASYNC = 'com.salesforce.function.invoke.async';
const SANDBOX_AUDIENCE_URL = 'https://test.salesforce.com';
const PROD_AUDIENCE_URL = 'https://login.salesforce.com';

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

class BaseContext {
    decodeAndParse(encodedContext) {
        const decodedContext = Buffer.from(encodedContext, 'base64').toString('utf8');
        return JSON.parse(decodedContext);
    }
}
/**
 * Header 'ce-sffncontext': function request context.
 *
 *  {
 *     'id': '00Dxx0000006IYJEA2-4Y4W3Lw_LkoskcHdEaZze-uuic-MyFunction-2023-03-23T15:18:53.429-0700',
 *     'function': 'MyFunction',
 *     'resource': 'https://...',
 *     'source': 'urn:event:from:salesforce/<instance>/<orgId>/<platform origin, eg apex>',
 *     'type': 'com.salesforce.function.invoke.sync',
 *     'requestTime': '2023-03-23T15:18:53.429-0700',
 *     'functionInvocationId': '<AsyncFunctionInvocationRequest__c.ID>',
 *     'permissionSets': '[ 'MyPermissionSet' ]'
 *   }
 */
export class FunctionContext extends BaseContext {
    constructor(encodedContext) {
        super();
        this.fnContext =  super.decodeAndParse(encodedContext);
        this.type = this.fnContext.type;
        this.functionName = this.fnContext.functionName;
        this.functionInvocationId = this.fnContext.functionInvocationId;
    }

    validate() {
        if (this.type !== FUNCTION_INVOCATION_TYPE_SYNC || this.type !== FUNCTION_INVOCATION_TYPE_ASYNC) {
            throwError(`Invalid function invocation type ${this.type}`, 400, requestId);
        }

        if (this.type === FUNCTION_INVOCATION_TYPE_ASYNC && !fnContext.functionInvocationId) {
            throwError('AsyncFunctionInvocationRequest__c ID not provided for async invocation', 400, requestId);
        }
    }

    setAccessToken(accessToken) {
        this.fnContext.accessToken = accessToken;
    }

    encode(jsonStr) {
        return Buffer.from(JSON.stringify(jsonStr), 'utf8').toString('base64');
    }

    serialize() {
        return JSON.stringify(this.fnContext);
    }
}

/**
 * 'userContext' part of header 'ce-sfcontext'.
 *
 *  {
 *      'orgId': '00Dxx0000006IYJ',
 *      'userId': '005xx000001X8Uz',
 *      'username': 'admin@example.com',
 *      'onBehalfOfUserId': '',
 *      'salesforceBaseUrl': 'https://na1.salesforce.com',
 *      'orgDomainUrl': 'https://mycompany.my.salesforce.com',
 * 	    'namespace': ''
 *   }
 */
export class UserContext {
    constructor(userContext) {
        this.orgId = userContext.apiVersion;
        this.salesforceBaseUrl = userContext.salesforceBaseUrl;
        this.username = userContext.username;
    }

    validate() {
        if (!this.orgId) {
            throwError('Org ID not provided', 400, requestId);
        }

        if (!this.username) {
            throwError('Username not provided', 400, requestId);
        }

        if (!this.userContext.salesforceBaseUrl) {
            throwError(`SalesforceBaseUrl not provided`, 400, requestId);
        }
    }
}

/**
 * Header 'ce-sfcontext': Salesforce context, ie the context of the requesting Org and user.
 *
 *  {
 *     'apiVersion': '57.0',
 *     'payloadVersion': '0.1',
 *     'userContext': ...UserContext...
 *   }
 */
export class SalesforceContext extends BaseContext {
    constructor(encodedContext) {
        super();
        const sfContext =  super.decodeAndParse(encodedContext);
        this.apiVersion = sfContext.apiVersion;
        this.userContext = new UserContext(sfContext.userContext);
    }

    validate() {
        if (!this.apiVersion) {
            throwError('API Version not provided', 400, requestId);
        }

        if (!this.userContext) {
            throwError('UserContext not provided', 400, requestId);
        }

        this.userContext.validate();
    }
}

class BaseRequestHandler {
    constructor(request, reply) {
        this.request = request;
        this.reply = reply;
    }

    /**
     * Parse and validate 'ce-sffncontext' and 'ce-sfcontext' headers.  See FunctionContext and SalesforceContext.
     *
     * @param requestId
     * @param headers
     * @returns {{fnContext: *, sfContext: *}}
     */
    parseAndValidateContexts(requestId, headers) {
        // Function request context
        const encodedFunctionContextHeader = headers[HEADER_FUNCTION_REQUEST_CONTEXT];
        if (!encodedFunctionContextHeader) {
            throwError(`Function context header ${HEADER_FUNCTION_REQUEST_CONTEXT} not found`, 400, requestId);
        }

        let fnContext;
        try {
            fnContext = new FunctionContext(encodedFunctionContextHeader);
        } catch (err) {
            throwError(`[${requestId}] Invalid ${HEADER_FUNCTION_REQUEST_CONTEXT} format - expected base64 encoded header: ${err.message}`, 400, requestId);
        }
        fnContext.validate();

        // Salesforce context
        const encodedSalesforceContextHeader = headers[HEADER_SALESFORCE_CONTEXT];
        if (!encodedSalesforceContextHeader) {
            throwError(`Salesforce context header ${HEADER_SALESFORCE_CONTEXT} not found`, 400, requestId);
        }

        let sfContext;
        try {
            sfContext = new SalesforceContext(encodedSalesforceContextHeader);
        } catch (err) {
            throwError(`[${requestId}] Invalid ${HEADER_SALESFORCE_CONTEXT} format - expected base64 encoded header: ${err.message}`, 400, requestId);
        }
        sfContext.validate();

        return {
            fnContext,
            sfContext
        };
    }

    /**
     * Expected headers:
     *  - x-request-id: request id generated by client that tracks the entire request/response
     *  - ce-specversion: version of CloudEvent schema
     *  - ce-id: see x-request-id
     *  - ce-source: source of request
     *  - ce-type: type of request
     *  - ce-time: origin time of request
     *  - ce-sfcontext: Salesforce context - context of invoking Org
     *  - ce-sffncontext: context of function request
     *
     * @param headers
     * @returns {{requestId: string, accessToken: string, fnContext: *, sfContext: *}}
     */
    parseAndValidateHeaders(headers) {
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

        // Parse and validate function request and salesforce contexts
        const {fnContext, sfContext} = this.parseAndValidateContexts(requestId, headers);

        return {requestId, accessToken, fnContext, sfContext};
    }

    /**
     * Assemble Salesforce API URI part.
     *
     * @param baseUrl
     * @param apiVersion
     * @param uriPart
     * @returns {string}
     */
    assembleSalesforceAPIUrl(baseUrl, apiVersion, uriPart) {
        return `${baseUrl}/services/data/v${apiVersion}/${uriPart}`;
    }

    /**
     * Assemble Salesforce API Headers.
     *
     * @param accessToken
     * @returns {{Authorization: string, "Content-Type": string}}
     */
    assembleSalesforceAPIHeaders(accessToken) {
        return {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${accessToken}`
        };
    }

    /**
     * Generic HTTP request, Promisified.
     *
     * @param url
     * @param opts
     * @param body
     * @returns {Promise<unknown>}
     */
    async httpRequest(url, opts, body = '') {
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
     * Validate that requesting org is expected org (orgId18) by using given token to verify org info
     * provided by /userinfo API.
     *
     * @param requestId
     * @param logger
     * @param instanceUrl
     * @param accessToken
     * @returns {Promise<void>}
     */
    async validateCaller(requestId, logger, instanceUrl, accessToken) {
        const url = `${instanceUrl}/services/oauth2/userinfo`;
        const opts = {
            method: 'GET',
            headers: this.assembleSalesforceAPIHeaders(accessToken)
        };

        // Get Org's info via /userinfo API
        let response;
        try {
            response = await this.httpRequest(url, opts);
        } catch (err) {
            throwError(`[${requestId}] Unable to obtain userinfo for org ${orgId18}: ${err.message}`, err.statusCode);
        }

        if (response && orgId18 !== response.organization_id) {
            logger.warn(`[${requestId}] Unauthorized caller from org ${response.organization_id}, expected ${orgId18}`);
            throwError('Unauthorized request', 401, requestId);
        }
    }

    /**
     * Validate expected payload and that the function invoker is of the expected org.
     *
     * @returns {Promise<{requestId: string, accessToken: string, fnContext: *, sfContext: *}>}
     */
    async validate() {
        // Parse and validate request
        const {requestId, accessToken, fnContext, sfContext} = this.parseAndValidateHeaders(this.request.headers);

        // Validate that the context's orgId matches the accessToken
        await this.validateCaller(requestId, logger, sfContext.userContext.salesforceBaseUrl, accessToken);

        return {requestId, accessToken, fnContext, sfContext};
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
    async mintToken(requestId, fnContext, sfContext) {
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
        const signedJWT = jwt.sign({prn: sfContext.userContext.username}, privateKey, jwtOpts);
        const oauthOpts = {
            method: 'POST',
            form: {
                'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion': signedJWT
            }
        };

        this.logger.info(`[${requestId}] Minting ${isTest ? 'test ' : ' '}token for user ${sfContext.userContext.username}, audience ${jwtOpts.audience}, uri ${oauthUrl}, issuer ${jwtOpts.issuer.substring(0, 5)}...`);
        let response;
        try {
            response = await this.httpRequest(oauthUrl, oauthOpts);
        } catch (err) {
            let errMsg = err.message;
            if (errMsg.includes('invalid_app_access') || errMsg.includes('user hasn\'t approved this consumer')) {
                errMsg += `. Ensure that the target Connected App is set to "Admin approved users are pre-authorized" and user ${sfContext.userContext.username} is assigned to Connected App via a Permission Set`;
            }
            this.logger.error(errMsg);
            throwError(errMsg, 403, requestId);
        }

        return {
            accessToken: response.access_token,
            instanceUrl: response.instance_url
        };
    }

    /**
     * Activate session-based Permission Sets, if applicable.
     *
     * @param requestId
     * @param fnContext
     * @param accessToken
     * @param instanceUrl
     * @returns {Promise<void>}
     */
    async activateSessionPermSet(requestId, fnContext, accessToken, instanceUrl) {
        const permissionSets = fnContext.permissionSets;
        if (!permissionSets || permissionSets.length === 0) {
            this.logger.info(`[${requestId}] Skipping session-based Permission Sets activation`);
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
                inputs.push({PermSetName: permissionSet});
            }
        });
        const body = {inputs: inputs};

        const apiUrl = this.assembleSalesforceAPIUrl(instanceUrl, sfContext.apiVersion, '/actions/standard/activateSessionPermSet');
        const opts = {
            method: 'POST',
            headers: this.assembleSalesforceAPIHeaders(accessToken),
            json: {inputs: inputs},
        };

        let response;
        try {
            // Activate!
            response = await this.httpRequest(apiUrl, opts, JSON.stringify(body));
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
            this.logger.error(errMsg);
            throwError(errMsg, err.statusCode || 503, requestId);
        }

        const failedActivations = response.filter(activation => !activation.isSuccess);
        if (response && failedActivations.length > 0) {
            // TODO: Output failed PermissionSet names from response
            throwError(`Unable to activate session-based Permission Set(s) ${permissionSets.join(', ')}: ${JSON.stringify(failedActivations.map(failedActivation => failedActivation.errors))}`, response.statusCode || 503, requestId);
        } else {
            this.logger.info(`[${requestId}] Successfully activated session-based Permission Set(s): ${permissionSets.join(', ')}`);
        }
    }

    /**
     * Re-assemble the function's context setting function's accessToken.
     *
     * @param headers
     * @param fnContext
     * @param accessToken
     */

    assembleFunctionRequest(fnContext, accessToken) {
        // Function's org-access token
        fnContext.setAccessToken(accessToken);
        this.request.headers[HEADER_FUNCTION_REQUEST_CONTEXT] = fnContext.encode(fnContext.serialize());
    }

    /**
     * Enrich request with function's accessToken activating session-based Permission Sets, if applicable.
     * @param requestId
     * @param fnContext
     * @param sfContext
     * @returns {Promise<void>}
     */
    async enrich(requestId, fnContext, sfContext) {
        // Mint token with configured Connected App
        const {accessToken, instanceUrl} = await this.mintToken(requestId, fnContext, sfContext);

        // Activate session-based Permission Sets, if applicable
        await this.activateSessionPermSet(requestId, fnContext, accessToken, instanceUrl);

        // Set token on function request context
        this.assembleFunctionRequest(fnContext, accessToken);
    }
}

export class SyncRequestHandler extends BaseRequestHandler {

    constructor(request, reply) {
        super(request, reply);
    }

    /**
     * Handle sync function request.
     *
     * @returns {Promise<void>}
     */
    async handle() {
        const {requestId, fnContext, sfContext} = await this.validate();

        this.logger.info(`[${requestId}] Handling ${fnContext.type} request to function '${fnContext.functionName}'...`);

        await this.enrich(requestId, fnContext, sfContext);

        this.logger.info(`[${requestId}] Sending ${fnContext.type} request to function '${fnContext.functionName}'...`);
    }
}

export class AsyncRequestHandler extends BaseRequestHandler {

    constructor(request, reply) {
        super(request, reply);
    }

    /**
     * Handle async function request.
     *
     * @returns {Promise<void>}
     */
    async handle() {
        const { requestId, fnContext, sfContext } = await this.validate();
        this.logger.info(`[${requestId}] Handling ${fnContext.type} request to function '${fnContext.functionName}'...`);

        if (FUNCTION_INVOCATION_TYPE_ASYNC !== fnContext.type) {
            throwError('Invalid request type', 400, requestId);
        }

        await this.enrich(requestId, fnContext, sfContext);

        this.logger.info(`[${requestId}] Sending ${fnContext.type} request to function '${fnContext.functionName}'...`);
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
    async updateAsyncFunctionResponse(fnContext, sfContext, accessToken, functionResponse, statusCode, extraInfo) {
        const apiUrl = assembleSalesforceAPIUrl(sfContext.userContext.salesforceBaseUrl, sfContext.apiVersion, `/sobjects/AsyncFunctionInvocationRequest__c/${fnContext.asyncFunctionInvocationRequestId}`);
        const status = statusCode < 200 || statusCode > 299 ? 'ERROR' : 'SUCCESS';
        const opts = {
            method: 'POST',
            headers: this.assembleSalesforceAPIHeaders(accessToken)
        };
        const body = {
            ExtraInfo__c: extraInfo,
            Id: fnContext.functionInvocationId,
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
    async invokeFunction() {
        const { requestId, accessToken, fnContext, sfContext } = this.parseAndValidateHeaders(headers);
        logger.info(`[${requestId}] Invoking async function ${fnContext.functionName}...`);

        const opts = {
            method: this.request.method,
            headers: this.request.headers
        };

        let statusCode, response, extraInfo;
        try {
            // Invoke function!
            const functionResponse = await this.httpRequest(functionUrl, opts, JSON.stringify(this.request.body));
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
}

export class ProxyServer {
    constructor(fastify) {
        this.fastify = fastify;
        this.logger = fastify.log;
    }

    /**
     * Validate required configuration and start function server.
     */
    validate() {
        const validateRequiredConfig = (name, value) => {
            if (!value) {
                throw Error(`Required config ${name} not found`);
            }
        }

        if (!existsSync(runtimeCLIPath)) {
            throw Error(`Function start CLI not found ${runtimeCLIPath}.  Ensure that function's buildpack ./bin/compile was run.`);
        }

        validateRequiredConfig(ORG_ID_18_CONFIG_VAR_NAME, orgId18);
        validateRequiredConfig(FUNCTION_PORT_CONFIG_VAR_NAME, functionPort);
        validateRequiredConfig(PRIVATE_KEY_CONFIG_VAR_NAME, privateKey);
        validateRequiredConfig(CONSUMER_KEY_CONFIG_VAR_NAME, clientId);
    }

    /**
     * Configure Fastify routes and hook implementations.
     *
     * @returns {ProxyServer}
     */
    configure() {
        /**
         * Register 'http-proxy' plugin to handle validating and enriching sync requests.  The request is forwarded to
         * the function.
         */
        this.fastify.register(proxy, {
            upstream: functionUrl,
            prefix: '/sync',
            // Validate and enrich sync requests
            preHandler: async (request, reply) => {
                const requestHandler = new SyncRequestHandler(request, reply);
                await requestHandler.handle();
            },
            replyOptions: {
                onError: (reply, error) => {
                    if (error.statusCode && 503 === error.statusCode) {
                        this.logger.warn('Function request failed with 503 - implement function health check, restart (if necessary), and retry');
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
        this.fastify.post('/async', async function (request, reply) {
            const requestHandler = new AsyncRequestHandler(request, reply);
            await requestHandler.handle();
            reply.code(201);
        });

        /**
         * Route to check health of function process.
         */
        this.fastify.register(proxy, {
            upstream: functionUrl,
            prefix: '/healthcheck',
            preHandler: async (request, reply) => {
                request.log.info('Handling function health check request');
                request.headers['x-health-check'] = 'true';
            }
        });

        /**
         * On response, handle async requests.  The original request was validated and enriched in the /async route handler.
         */
        this.fastify.addHook('onResponse', async (request, reply) => {
            if (reply.statusCode !== 201) {
                return;
            }

            const requestHandler = new AsyncRequestHandler(request, reply);
            const { fnContext } = requestHandler.parseAndValidateContexts(request.headers[HEADER_REQUEST_ID], request.headers);
            if (fnContext && FUNCTION_INVOCATION_TYPE_ASYNC === fnContext.type) {
                await requestHandler.invokeFunction(request, reply);
            }
        });

        /**
         * If close is called, also kill function server.
         */
        this.fastify.addHook('onClose', async (instance) => {
            if (this.functionProcess) {
                this.functionProcess.kill();
            }
        });

        return this;
    }

    /**
     * Start function server.
     *
     * @returns {ProxyServer}
     */
    startFunctionServer() {
        const args = [
            runtimeCLIPath,
            'serve',
            `${__dirname}/..`,
            '-p',
            functionPort
        ];
        this.logger.info(`Starting function w/ args: ${args.join(' ')}`);

        if (process.env[DEBUG_PORT_CONFIG_VAR_NAME]) {
            args.push('-d');
            args.push(DEBUG_PORT_CONFIG_VAR_NAME);
        }

        this.functionProcess = spawn('node', args,{});
        this.logger.info(`Started function started on port ${functionPort}, process pid ${this.functionProcess.pid}`);

        this.functionProcess.stdout.on('data', buff => {
            // REVIEWME: Prefix message w/ function name or add/change attribute to include function name?
            const line = buff.toLocaleString();
            this.logger.info(line);
        });
        this.functionProcess.stderr.on('data', buff => { // also catch any error output
            // REVIEWME: Prefix message w/ function name or add/change attribute to include function name?
            const line = buff.toLocaleString();
            this.logger.error(line);
        });
        this.functionProcess.on('error', err => { // also catch any error output
            // REVIEWME: Prefix message w/ function name or add/change attribute to include function name?
            // TODO: Retry?
            this.logger.error(err.message);
        });
        this.functionProcess.on('exit', code => {
            // REVIEWME: Prefix message w/ function name or add/change attribute to include function name?
            this.logger.info(`Function process exited with code ${code}`);
            // REVIEWME: What to do here?
            process.exit(1);
        });

        return this;
    }

    /**
     * Start proxy.
     *
     * @returns {ProxyServer}
     */
    start() {
        this.fastify.listen({ host: '0.0.0.0', port: process.env.PORT || 3000 }, async (err, address) => {
            if (err) {
                this.logger.error(err);
                process.exit(1);
            }
        });

        return this;
    }
}