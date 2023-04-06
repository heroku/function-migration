import { spawn } from 'child_process';
import { existsSync, readFileSync } from 'fs';
import got from 'got';
import jwt from 'jsonwebtoken';
import path from 'path';
import proxy from '@fastify/http-proxy';

const __dirname = path.resolve();

// Customer-provided configuration
const ORG_ID_18_CONFIG_VAR_NAME = 'ORG_ID_18';
const FUNCTION_URL_CONFIG_VAR_NAME = 'FUNCTION_URL';
const FUNCTION_PORT_CONFIG_VAR_NAME = 'FUNCTION_PORT';
const ENCODED_PRIVATE_KEY_CONFIG_VAR_NAME = 'ENCODED_PRIVATE_KEY';
const PRIVATE_KEY_FILEPATH_CONFIG_VAR_NAME = 'PRIVATE_KEY_FILEPATH';
const CONSUMER_KEY_CONFIG_VAR_NAME = 'CONSUMER_KEY';
const DEBUG_PORT_CONFIG_VAR_NAME = 'DEBUG_PORT';
const RUNTIME_CLI_FILEPATH_CONFIG_VAR_NAME = 'RUNTIME_CLI_FILEPATH';
const SF_AUDIENCE_CONFIG_VAR_NAME = 'SF_AUDIENCE';

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

class Config {
    constructor(env) {
        this.env = env;
    }

    assemble() {
        this.proxyPort = this.env['PORT'] || 3000;
        this.runtimeCLIPath = this.env[RUNTIME_CLI_FILEPATH_CONFIG_VAR_NAME] || `${__dirname}/../node_modules/@heroku/sf-fx-runtime-nodejs/bin/cli.js`;
        this.functionPort = this.env[FUNCTION_PORT_CONFIG_VAR_NAME] || 8080;
        this.functionDebugPort = this.env[DEBUG_PORT_CONFIG_VAR_NAME];
        this.functionUrl = `${(this.env[FUNCTION_URL_CONFIG_VAR_NAME] || 'http://localhost')}:${this.functionPort}`;
        this.orgId18 = this.env[ORG_ID_18_CONFIG_VAR_NAME];
        const encodedPrivateKey = this.env[ENCODED_PRIVATE_KEY_CONFIG_VAR_NAME];
        if (encodedPrivateKey) {
            this.privateKey = Buffer.from(encodedPrivateKey, 'base64').toString('utf8');
        } else if (this.env[PRIVATE_KEY_FILEPATH_CONFIG_VAR_NAME]) {
            this.privateKey = readFileSync(this.env.PRIVATE_KEY_FILEPATH);
        }
        this.clientId = this.env[CONSUMER_KEY_CONFIG_VAR_NAME];
        this.audience = this.env[SF_AUDIENCE_CONFIG_VAR_NAME];

        return this;
    }

    validate() {
        const validateRequiredConfig = (name, value) => {
            if (!value) {
                throw Error(`Required config ${name} not found`);
            }
        }

        if (!existsSync(this.runtimeCLIPath)) {
            throw Error(`Function start CLI not found ${this.runtimeCLIPath}.  Ensure that function's buildpack ./bin/compile was run.`);
        }

        validateRequiredConfig(ORG_ID_18_CONFIG_VAR_NAME, this.orgId18);
        validateRequiredConfig(FUNCTION_PORT_CONFIG_VAR_NAME, this.functionPort);
        validateRequiredConfig(`${ENCODED_PRIVATE_KEY_CONFIG_VAR_NAME} or ${PRIVATE_KEY_FILEPATH_CONFIG_VAR_NAME}`,
            this.privateKey);
        validateRequiredConfig(CONSUMER_KEY_CONFIG_VAR_NAME, this.clientId);

        return this;
    }
}
const config = new Config(process.env);

class BaseContext {
    constructor(requestId) {
        this.requestId = requestId;
    }

    decodeAndParse(encodedContext) {
        const decodedContext = Buffer.from(encodedContext, 'base64').toString('utf8');
        return JSON.parse(decodedContext);
    }
}
/**
 * Header 'ce-sffncontext': function request context.
 *
 *  {
 *     'id': '00Dxx0000006IYJEA2-4Y4W3Lw_LkoskcHdEaZze-uuid-MyFunction-2023-03-23T15:18:53.429-0700',
 *     'functionName': 'MyFunction',
 *     'resource': 'https://...',
 *     'source': 'urn:event:from:salesforce/<instance>/<orgId>/<platform origin, eg apex>',
 *     'type': 'com.salesforce.function.invoke.sync',
 *     'requestTime': '2023-03-23T15:18:53.429-0700',
 *     'functionInvocationId': '<AsyncFunctionInvocationRequest__c.ID>',
 *     'permissionSets': '[ 'MyPermissionSet' ]'
 *   }
 */
export class FunctionContext extends BaseContext {
    constructor(requestId, encodedContext) {
        super(requestId);
        this.sfFnContext =  super.decodeAndParse(encodedContext);
        this.type = this.sfFnContext.type;
        this.functionName = this.sfFnContext.functionName;
        this.functionInvocationId = this.sfFnContext.functionInvocationId;
        this.permissionSets = this.sfFnContext.permissionSets;
    }

    validate() {
        if (!(this.type === FUNCTION_INVOCATION_TYPE_SYNC || this.type === FUNCTION_INVOCATION_TYPE_ASYNC)) {
            throwError(`Invalid function invocation type ${this.type}`, 400, this.requestId);
        }

        if (this.type === FUNCTION_INVOCATION_TYPE_ASYNC && !this.functionInvocationId) {
            throwError('AsyncFunctionInvocationRequest__c ID not provided for async invocation', 400, this.requestId);
        }

        if (this.permissionSets && !Array.isArray(this.permissionSets)) {
            throwError('Expected array of Permission Sets', 400, this.requestId);
        }
    }

    setAccessToken(accessToken) {
        this.accessToken = accessToken;
    }

    toJsonEncoded() {
        return Buffer.from(JSON.stringify(this), 'utf8').toString('base64');
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
export class UserContext extends BaseContext {
    constructor(requestId, userContext) {
        super(requestId);
        this.orgId = userContext.orgId;
        this.salesforceBaseUrl = userContext.salesforceBaseUrl;
        this.username = userContext.username;
    }

    validate() {
        if (!this.orgId) {
            throwError('Org ID not provided', 400, this.requestId);
        }

        if (!this.username) {
            throwError('Username not provided', 400, this.requestId);
        }

        if (!this.salesforceBaseUrl) {
            throwError(`SalesforceBaseUrl not provided`, 400, this.requestId);
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
    constructor(requestId, encodedContext) {
        super(requestId);
        const sfContext =  super.decodeAndParse(encodedContext);
        this.apiVersion = sfContext.apiVersion;
        this.userContext = new UserContext(requestId, sfContext.userContext);
    }

    validate() {
        if (!this.apiVersion) {
            throwError('API Version not provided', 400, this.requestId);
        }

        if (!this.userContext) {
            throwError('UserContext not provided', 400, this.requestId);
        }

        this.userContext.validate();
    }
}

class BaseRequestHandler {
    constructor(request, reply) {
        this.request = request;
        this.reply = reply;
        this.logger = this.request.log;
    }

    /**
     * Parse and validate 'ce-sffncontext' and 'ce-sfcontext' headers.  See FunctionContext and SalesforceContext.
     *
     * @param requestId
     * @param headers
     * @returns {{sfFnContext: *, sfContext: *}}
     */
    parseAndValidateContexts(requestId, headers) {
        // Function request context
        const encodedFunctionContextHeader = headers[HEADER_FUNCTION_REQUEST_CONTEXT];
        if (!encodedFunctionContextHeader) {
            throwError(`Function context header ${HEADER_FUNCTION_REQUEST_CONTEXT} not found`, 400, requestId);
        }

        let sfFnContext;
        try {
            sfFnContext = new FunctionContext(requestId, encodedFunctionContextHeader);
        } catch (err) {
            throwError(`Invalid ${HEADER_FUNCTION_REQUEST_CONTEXT} format - expected base64 encoded header: ${err.message}`, 400, requestId);
        }
        sfFnContext.validate();

        // Salesforce context
        const encodedSalesforceContextHeader = headers[HEADER_SALESFORCE_CONTEXT];
        if (!encodedSalesforceContextHeader) {
            throwError(`Salesforce context header ${HEADER_SALESFORCE_CONTEXT} not found`, 400, requestId);
        }

        let sfContext;
        try {
            sfContext = new SalesforceContext(requestId, encodedSalesforceContextHeader);
        } catch (err) {
            throwError(`Invalid ${HEADER_SALESFORCE_CONTEXT} format - expected base64 encoded header: ${err.message}`, 400, requestId);
        }
        sfContext.validate();

        return {
            sfFnContext,
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
     * @returns {{requestId: string, requestProvidedAccessToken: string, sfFnContext: *, sfContext: *}}
     */
    parseAndValidateHeaders(headers) {
        const requestId = headers[HEADER_REQUEST_ID];
        if (!requestId) {
            throwError(`${HEADER_REQUEST_ID} not found`, 400);
        }

        if (!headers.authorization) { // TODO: Regex validate
            throwError('Authorization not found', 400, requestId);
        }
        if (!headers.authorization.startsWith('Bearer ')) {
            throwError('Invalid Authorization', 400, requestId);
        }

        const requestProvidedAccessToken = headers.authorization.substring(headers.authorization.indexOf(' ') + 1);
        if (!requestProvidedAccessToken) {
            throwError('Authorization accessToken not found', 400, requestId);
        }

        // Parse and validate function request and salesforce contexts
        const {sfFnContext, sfContext} = this.parseAndValidateContexts(requestId, headers);

        return {requestId, requestProvidedAccessToken, sfFnContext, sfContext};
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
        return `${baseUrl}/services/data/v${apiVersion}${uriPart}`;
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
     * Validate that requesting org is expected org (orgId18) by using given token to verify org info
     * provided by /userinfo API.
     *
     * Alternative approach that is simpler and efficient, but may not be as secure is to validate a
     * key sent by the client.
     *
     * @param requestId
     * @param instanceUrl
     * @param requestProvidedAccessToken
     * @returns {Promise<void>}
     */
    async validateCaller(requestId, instanceUrl, requestProvidedAccessToken) {
        const url = `${instanceUrl}/services/oauth2/userinfo`;
        const opts = {
            method: 'GET',
            headers: this.assembleSalesforceAPIHeaders(requestProvidedAccessToken),
            retry: {
                limit: 1
            }
        };

        // Get Org's info via /userinfo API
        let userInfo;
        try {
            userInfo = await this.request(url, opts);
        } catch (err) {
            throwError(`Unable to validate request (/userinfo): ${err.message}`, requestId);
        }

        if (!userInfo || config.orgId18 !== userInfo.organization_id) {
            this.logger.warn(`Unauthorized caller from org ${response.organization_id}, expected ${orgId18}`);
            throwError('Unauthorized request', 401, requestId);
        }
    }

    /**
     * Validate expected payload and that the function invoker is of the expected org.
     *
     * @returns {Promise<{requestId: string, requestProvidedAccessToken: string, sfFnContext: *, sfContext: *}>}
     */
    async validate() {
        // Parse and validate request
        const {requestId, requestProvidedAccessToken, sfFnContext, sfContext} = this.parseAndValidateHeaders(this.request.headers);

        // Validate that the context's orgId matches the accessToken
        await this.validateCaller(requestId, sfContext.userContext.salesforceBaseUrl, requestProvidedAccessToken);

        return {requestId, requestProvidedAccessToken, sfFnContext, sfContext};
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
     * @param sfFnContext
     * @param sfContext
     * @returns {Promise<String>}
     */
    async mintToken(requestId, sfFnContext, sfContext) {
        const url = `${sfContext.userContext.salesforceBaseUrl}/services/oauth2/token`;
        const isTest = (url.includes('.sandbox.') || url.includes('.scratch.'));

        const jwtOpts = {
            issuer: config.clientId,
            audience: config.audience || (isTest ? SANDBOX_AUDIENCE_URL : PROD_AUDIENCE_URL),
            algorithm: 'RS256',
            expiresIn: 360,
        }

        const signedJWT = jwt.sign({prn: sfContext.userContext.username}, config.privateKey, jwtOpts);
        const oauthOpts = {
            method: 'POST',
            headers: {
                'content-type': 'application/x-www-form-urlencoded'
                // content-length set by request API
            },
            form: {
                'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion': signedJWT
            },
            retry: {
                limit: 1
            }
        };

        // Mint!
        this.logger.info(`[${requestId}] Minting function ${isTest ? 'test ' : ' '}token for user ${sfContext.userContext.username}, audience ${jwtOpts.audience}, url ${url}, issuer ${jwtOpts.issuer.substring(0, 5)}...`);
        let body;
        try {
            body = await await this.request(url, opts);
        } catch (err) {
            const errResponse = JSON.parse(err.response.body);
            let errMsg = `Unable to mint function token: ${errResponse.error} (${errResponse.error_description})`;
            if (errMsg.includes('invalid_app_access') || errMsg.includes('user hasn\'t approved this consumer')) {
                errMsg += `. Ensure that the target Connected App is set to "Admin approved users are pre-authorized" and user ${sfContext.userContext.username} is assigned to Connected App via a Permission Set`;
            }
            this.logger.error(errMsg);
            throwError(errMsg, 403, requestId);
        }

        return {
            functionsAccessToken: body.access_token,
            instanceUrl: body.instance_url
        };
    }

    /**
     * Activate session-based Permission Sets, if applicable.
     *
     * @param requestId
     * @param sfFnContext
     * @param functionsAccessToken
     * @param instanceUrl
     * @returns {Promise<void>}
     */
    async activateSessionPermSet(requestId, sfFnContext, sfContext, functionsAccessToken) {
        const permissionSets = sfFnContext.permissionSets;
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

        const url = this.assembleSalesforceAPIUrl(sfContext.userContext.salesforceBaseUrl,
                                                     sfContext.apiVersion,
                                              '/actions/standard/activateSessionPermSet');
        const opts = {
            method: 'POST',
            headers: this.assembleSalesforceAPIHeaders(functionsAccessToken),
            json: {inputs: inputs},
            retry: {
                limit: 1
            }
        };

        // Activate!
        let activations;
        try {
            activations = await this.request(url, opts);
        } catch (err) {
            let errMsg = err.response.body;
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

        const failedActivations = activations.filter(activation => !activation.isSuccess);
        if (failedActivations && failedActivations.length > 0) {
            // TODO: Output failed PermissionSet names from response
            throwError(`Unable to activate session-based Permission Set(s) ${permissionSets.join(', ')}: ${JSON.stringify(failedActivations.map(failedActivation => failedActivation.errors))}`, 503, requestId);
        } else {
            this.logger.info(`[${requestId}] Successfully activated session-based Permission Set(s): ${permissionSets.join(', ')}`);
        }
    }

    /**
     * Re-assemble the function's context setting function's accessToken.
     *
     * REVIEWME: This should use the token provided in the request that uses an Admin-controlled Connected App?
     *
     * @param headers
     * @param sfFnContext
     * @param functionsAccessToken
     */

    assembleFunctionRequest(sfFnContext, functionsAccessToken) {
        // Function's org-access token
        sfFnContext.setAccessToken(functionsAccessToken);
        this.request.headers[HEADER_FUNCTION_REQUEST_CONTEXT] = sfFnContext.toJsonEncoded();
    }

    /**
     * Enrich request with function's accessToken activating session-based Permission Sets, if applicable.
     * @param requestId
     * @param sfFnContext
     * @param sfContext
     * @returns {Promise<void>}
     */
    async enrich(requestId, sfFnContext, sfContext) {
        // Mint token with configured Connected App
        const {functionsAccessToken} = await this.mintToken(requestId, sfFnContext, sfContext);

        // Activate session-based Permission Sets, if applicable
        await this.activateSessionPermSet(requestId, sfFnContext, sfContext, functionsAccessToken);

        // Set token on function request context
        this.assembleFunctionRequest(sfFnContext, functionsAccessToken);
    }

    async request(url, opts, json = true) {
        const response = await got(url, opts);
        return json ? response.json() : response;
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
        const {requestId, sfFnContext, sfContext} = await this.validate();

        this.logger.info(`[${requestId}] Handling ${sfFnContext.type} request to function '${sfFnContext.functionName}'...`);

        await this.enrich(requestId, sfFnContext, sfContext);

        this.logger.info(`[${requestId}] Sending ${sfFnContext.type} request to function '${sfFnContext.functionName}'...`);
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
        const { requestId, sfFnContext, sfContext } = await this.validate();
        this.logger.info(`[${requestId}] Handling ${sfFnContext.type} request to function '${sfFnContext.functionName}'...`);

        if (FUNCTION_INVOCATION_TYPE_ASYNC !== sfFnContext.type) {
            throwError('Invalid request type', 400, requestId);
        }

        await this.enrich(requestId, sfFnContext, sfContext);

        this.logger.info(`[${requestId}] Sending ${sfFnContext.type} request to function '${sfFnContext.functionName}'...`);
    }

    /**
     * Update  async request's associated AsyncFunctionInvocationRequest__c w/ function's response.
     *
     * @param sfFnContext
     * @param sfContext
     * @param accessToken
     * @param functionResponse
     * @param statusCode
     * @param extraInfo
     * @returns {Promise<void>}
     */
    async updateAsyncFunctionResponse(sfFnContext, sfContext, accessToken, functionResponse, statusCode, extraInfo) {
        const functionInvocationId = sfFnContext.functionInvocationId;
        const url = this.assembleSalesforceAPIUrl(sfContext.userContext.salesforceBaseUrl,
                                                     sfContext.apiVersion,
                                                    `/sobjects/AsyncFunctionInvocationRequest__c/${functionInvocationId}`);
        const status = statusCode < 200 || statusCode > 299 ? 'ERROR' : 'SUCCESS';
        const opts = {
            method: 'PATCH',
            headers: this.assembleSalesforceAPIHeaders(accessToken),
            json: {
                ExtraInfo__c: extraInfo ? decodeURI(extraInfo) : extraInfo,
                Response__c: functionResponse,
                Status__c: status,
                StatusCode__c: statusCode
            },
            retry: {
                limit: 1
            }
        };

        // Update AsyncFunctionInvocationRequest__c
        let response;
        try {
            response = await this.request(url, opts, false);
        } catch (err) {
            let errMsg = err.response ? err.response.body : err.message;
            if (errMsg.includes('The requested resource does not exist')) {
                errMsg += `. Ensure that user ${sfContext.userContext.username} has access to AsyncFunctionInvocationRequest__c.`;
            }

            this.logger.error(errMsg);
            throw new Error(errMsg);
        }

        if (!response || response.statusCode !== 204) {
            this.logger.error(`Unable to save function response to AsyncFunctionInvocationRequest__c [${functionInvocationId}]: ${JSON.stringify(response.errors.join(','))}`);
        } else {
            this.logger.info(`Updated function response [${statusCode}] to AsyncFunctionInvocationRequest__c [${functionInvocationId}]`);
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
        const { requestId, requestProvidedAccessToken, sfFnContext, sfContext } = this.parseAndValidateHeaders(this.request.headers);
        this.logger.info(`[${requestId}] Invoking async function ${sfFnContext.functionName}...`);

        const opts = {
            method: this.request.method,
            headers: this.request.headers,
            body: JSON.stringify(this.request.body)
        };

        let statusCode, body, extraInfo;
        try {
            // Invoke function!
            const functionResponse = await this.request(config.functionUrl, opts, false);
            statusCode = functionResponse.statusCode;
            body = functionResponse.body;
            extraInfo = functionResponse.headers[HEADER_EXTRA_INFO];
        } catch (err) {
            const response = err.response
            this.logger.error(response);
            statusCode = response.statusCode;
            body = response.body;
            extraInfo = response.headers[HEADER_EXTRA_INFO];
        }

        await this.updateAsyncFunctionResponse(sfFnContext, sfContext, requestProvidedAccessToken, body, statusCode, extraInfo);
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
        config.assemble().validate();
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
            upstream: config.functionUrl,
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
            upstream: config.functionUrl,
            prefix: '/healthcheck',
            preHandler: async (request, reply) => {
                // TODO: Validate caller
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
            const { sfFnContext } = requestHandler.parseAndValidateContexts(request.headers[HEADER_REQUEST_ID], request.headers);
            if (sfFnContext && FUNCTION_INVOCATION_TYPE_ASYNC === sfFnContext.type) {
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
            config.runtimeCLIPath,
            'serve',
            `${__dirname}/..`,
            '-p',
            config.functionPort
        ];
        this.logger.info(`Starting function w/ args: ${args.join(' ')}`);

        if (config.functionDebugPort) {
            args.push('-d');
            args.push(config.functionDebugPort);
        }

        this.functionProcess = spawn('node', args,{});
        this.logger.info(`Started function started on port ${config.functionPort}, process pid ${this.functionProcess.pid}`);

        this.functionProcess.stdout.on('data', buff => {
            // REVIEWME: Prefix message w/ function name or add/change attribute to include function name?
            const line = buff.toLocaleString();
            this.logger.info(`[fn] ${line}`);
        });
        this.functionProcess.stderr.on('data', buff => { // also catch any error output
            // REVIEWME: Prefix message w/ function name or add/change attribute to include function name?
            const line = buff.toLocaleString();
            this.logger.info(`[fn] ${line}`);
        });
        this.functionProcess.on('error', err => { // also catch any error output
            // REVIEWME: Prefix message w/ function name or add/change attribute to include function name?
            // TODO: Retry?
            this.logger.error(`[fn] ${line}`);
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
        this.fastify.listen({ host: '0.0.0.0', port: config.proxyPort }, async (err, address) => {
            if (err) {
                this.logger.error(err);
                process.exit(1);
            }
        });

        return this;
    }
}