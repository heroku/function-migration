import {expect} from 'chai';
import sinon from 'sinon';
import jwt from 'jsonwebtoken';
import {
    AsyncRequestHandler,
    Config,
    FunctionContext,
    ProxyServer,
    SalesforceContext,
    HttpRequestUtil,
    SyncRequestHandler,
    UserContext
} from '../lib/proxy.js';

// Globals
const requestId = '00Dxx0000006IYJEA2-4Y4W3Lw_LkoskcHdEaZze--typescriptfunction-2020-09-03T20:56:27.608444Z';
const log = {
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    debug: () => {
    },
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    info: () => {
    },
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    warn: () => {
    },
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    error: () => {
    }
}
describe('Handle Function Request', () => {

    const sandbox = sinon.createSandbox();

    afterEach(() => {
        sandbox.restore();
    });

    describe('Sync', () => {

        describe('parse headers', function () {
            it('happy path', async function () {
                const requestProvidedAccessToken = 'token-here';
                const request = {
                    headers: {
                        'authorization': `Bearer ${requestProvidedAccessToken}`,
                        'x-request-id': requestId,
                        'ce-specversion': 'ce-specversion-here',
                        'ce-id': 'ce-id-here',
                        'ce-datacontenttype': 'ce-datacontenttype-here',
                        'ce-source': 'ce-source-here',
                        'ce-type': 'ce-type-here'
                    },
                    log
                }
                const handler = new SyncRequestHandler({}, request, {});
                const parseAndValidateHeadersResult = handler.parseAndValidateHeaders();
                expect(parseAndValidateHeadersResult.requestId).to.equal(requestId);
                expect(parseAndValidateHeadersResult.requestProvidedAccessToken).to.equal(requestProvidedAccessToken);
            });
        });

        describe('parse context headers', function () {
            it('happy path', async function () {
                const sfFnContext = {
                    'requestId': requestId,
                    'accessToken': undefined,
                    'functionName': 'myproject.typescriptfunction',
                    'functionInvocationId': undefined,
                    'type': 'com.salesforce.function.invoke.sync',
                    'permissionSets': ['Functions']
                };
                const sfContext = {
                    'requestId': requestId,
                    'apiVersion': '57.0',
                    'userContext': {
                        'requestId': requestId,
                        'namespace': '',
                        'orgId': '00Dxx0000006JX6EAM',
                        'username': 'admin@sf-fx-dh.com',
                        'orgDomainUrl': 'https://sf-fx-dh.my.salesforce.com'
                    }
                };
                const request = {
                    headers: {
                        'x-request-id': requestId,
                        'ce-sffncontext': Buffer.from(JSON.stringify(sfFnContext), 'utf8').toString('base64'),
                        'ce-sfcontext': Buffer.from(JSON.stringify(sfContext), 'utf8').toString('base64')
                    },
                    log
                }
                const handler = new SyncRequestHandler({}, request, {});
                const parseAndValidateContextsResult = handler.parseAndValidateContexts()
                expect(parseAndValidateContextsResult.sfFnContext).to.deep.include(sfFnContext);
                expect(parseAndValidateContextsResult.sfContext).to.deep.include(sfContext);
            });
        });

        describe('validate caller', function () {
            it('happy path', async function () {
                const config = {
                    'orgId18': '00Dxx0000006JX6EAM'
                }
                const request = {
                    headers: {
                        'x-request-id': requestId
                    },
                    log
                }
                const instanceUrl = 'https://sf-fx-dh.my.salesforce.com';
                const requestProvidedAccessToken = 'requestProvidedAccessToken';
                const userInfoResponse = {'organization_id': config.orgId18};
                const requestStub = sandbox.stub(HttpRequestUtil.prototype, 'request')
                    .resolves(userInfoResponse);
                const handler = new SyncRequestHandler(config, request, {});
                await handler.validateCaller(instanceUrl, requestProvidedAccessToken);
                expect(requestStub.calledOnce).to.be.true;
            });
        });

        describe('mint token', function () {
            it('happy path', async function () {
                const config = {
                    'clientId': 'clientId',
                    'audience': 'audience'
                };
                const sfContext = {
                    'requestId': requestId,
                    'apiVersion': '57.0',
                    'userContext': {
                        'username': 'admin@sf-fx-dh.com',
                        'orgDomainUrl': 'https://sf-fx-dh.my.salesforce.com'
                    }
                };
                const request = {
                    headers: {
                        'x-request-id': requestId,
                    },
                    log
                };
                const mintTokenResponse = {
                    'access_token': 'access_token',
                    'instance_url': 'instance_url'
                };
                const signStub = sandbox.stub(jwt, 'sign').returns('signedjwt');
                const requestStub = sandbox.stub(HttpRequestUtil.prototype, 'request')
                    .resolves(mintTokenResponse);
                const handler = new SyncRequestHandler(config, request, {});
                const mintTokenResult = await handler.mintToken({}, sfContext);
                expect(signStub.calledOnce).to.be.true;
                expect(requestStub.calledOnce).to.be.true;
                expect(mintTokenResult).to.deep.include({
                    functionsAccessToken: mintTokenResponse.access_token,
                    instanceUrl: mintTokenResponse.instance_url
                });
            });
        });

        const activateSessionPermSetTest = async (namespace) => {
            const sfFnContext = {
                'requestId': requestId,
                'accessToken': 'accessToken',
                'permissionSets': ['Functions']
            };
            const sfContext = {
                'requestId': requestId,
                'apiVersion': '57.0',
                'userContext': {
                    'requestId': requestId,
                    'namespace': 'namespace',
                    'username': 'admin@sf-fx-dh.com',
                    'orgDomainUrl': 'https://sf-fx-dh.my.salesforce.com'
                }
            };
            const request = {
                headers: {
                    'x-request-id': requestId,
                },
                log
            };
            const activationResponse = [
                {
                    'actionName': 'activateSessionPermSet',
                    'errors': null,
                    'isSuccess': true,
                    'outputValues': {}
                }, {
                    'actionName': 'activateSessionPermSet',
                    'errors': null,
                    'isSuccess': true,
                    'outputValues': {}
                }
            ];
            const requestStub = sandbox.stub(HttpRequestUtil.prototype, 'request')
                .resolves(activationResponse);
            const handler = new SyncRequestHandler({}, request, {});
            await handler.activateSessionPermSet(sfFnContext, sfContext, 'functionsAccessToken');
            expect(requestStub.calledOnce).to.be.true;
        }

        describe('activate session-based Permission Sets w/o namespace', function () {
            it('happy path', async function () {
                await activateSessionPermSetTest(undefined);
            });
        });

        describe('activate session-based Permission Sets w/ namespace', function () {
            it('happy path', async function () {
                await activateSessionPermSetTest('namespace');
            });
        });

        describe('prepare function request', function () {
            it('happy path', async function () {
                const functionsAccessToken = 'functionsAccessToken';
                const toBeEncodedSfFnContext = {
                    'requestId': requestId,
                    'accessToken': undefined,
                    'functionName': 'myproject.typescriptfunction',
                    'functionInvocationId': 'functionInvocationId',
                    'type': 'com.salesforce.function.invoke.sync',
                    'permissionSets': ['Functions']
                };
                const sfFnContext = new FunctionContext('requestId',
                    Buffer.from(JSON.stringify(toBeEncodedSfFnContext), 'utf8').toString('base64'));
                const request = {
                    headers: {
                        'x-request-id': requestId,
                        'ce-sffncontext': Buffer.from(JSON.stringify(sfFnContext), 'utf8').toString('base64'),
                    },
                    log
                };
                const handler = new SyncRequestHandler({}, request, {});
                await handler.prepareFunctionRequest(sfFnContext, functionsAccessToken);
                const updatedSfFnContextStr = Buffer.from(request.headers['ce-sffncontext'], 'base64').toString('utf8');
                const updatedSfFnContext = JSON.parse(updatedSfFnContextStr);
                expect(updatedSfFnContext.accessToken).to.not.be.undefined;
                expect(updatedSfFnContext.accessToken).to.equal(functionsAccessToken);
            });
        });
    });

    describe('Async', () => {

        describe('parse context headers w/ sfFnContext.functionInvocationId', function () {
            it('happy path', async function () {
                const sfFnContext = {
                    'requestId': requestId,
                    'accessToken': undefined,
                    'functionName': 'myproject.typescriptfunction',
                    'functionInvocationId': 'functionInvocationId',
                    'type': 'com.salesforce.function.invoke.sync',
                    'permissionSets': ['Functions']
                };
                const sfContext = {
                    'requestId': requestId,
                    'apiVersion': '57.0',
                    'userContext': {
                        'requestId': requestId,
                        'namespace': 'namespace',
                        'orgId': '00Dxx0000006JX6EAM',
                        'username': 'admin@sf-fx-dh.com',
                        'orgDomainUrl': 'https://sf-fx-dh.my.salesforce.com'
                    }
                };
                const request = {
                    headers: {
                        'x-request-id': requestId,
                        'ce-sffncontext': Buffer.from(JSON.stringify(sfFnContext), 'utf8').toString('base64'),
                        'ce-sfcontext': Buffer.from(JSON.stringify(sfContext), 'utf8').toString('base64')
                    },
                    log
                }
                const handler = new AsyncRequestHandler({}, request, {});
                const parseAndValidateContextsResult = handler.parseAndValidateContexts()
                expect(parseAndValidateContextsResult.sfFnContext).to.deep.include(sfFnContext);
                expect(parseAndValidateContextsResult.sfContext).to.deep.include(sfContext);
            });
        });
    });
});

describe('Handle Async Function Response', () => {

    const sandbox = sinon.createSandbox();

    afterEach(() => {
        sandbox.restore();
    });

    describe('invoke function', function () {
        it('happy path', async function () {
            const sfFnContext = {
                'requestId': requestId,
                'accessToken': 'functionsAccessToken',
                'functionName': 'myproject.typescriptfunction',
                'functionInvocationId': 'functionInvocationId',
                'type': 'com.salesforce.function.invoke.sync',
                'permissionSets': ['Functions']
            };
            const sfContext = {
                'requestId': requestId,
                'apiVersion': '57.0',
                'userContext': {
                    'requestId': requestId,
                    'namespace': '',
                    'orgId': '00Dxx0000006JX6EAM',
                    'username': 'admin@sf-fx-dh.com',
                    'orgDomainUrl': 'https://sf-fx-dh.my.salesforce.com'
                }
            };
            const request = {
                method: 'POST',
                headers: {
                    'authorization': `Bearer requestProvidedAccessToken`,
                    'x-request-id': requestId,
                    'ce-specversion': 'ce-specversion-here',
                    'ce-id': 'ce-id-here',
                    'ce-datacontenttype': 'ce-datacontenttype-here',
                    'ce-source': 'ce-source-here',
                    'ce-type': 'ce-type-here',
                    'ce-sffncontext': Buffer.from(JSON.stringify(sfFnContext), 'utf8').toString('base64'),
                    'ce-sfcontext': Buffer.from(JSON.stringify(sfContext), 'utf8').toString('base64')
                },
                body: '{}',
                log
            }
            const functionResponse = {
                body: 'It Worked!',
                headers: {
                    'x-extra-info': '{"requestId":"00Dxx0000006IYJEA2-4pKLsu1D0B0BL9-qbvxXF--a00B000000Ou3NuIAJ-typescriptfunction-2023-04-12T17:26:12.318-0700","source":"urn:event:from:salesforce/xxx/00DB0000000gJmXMAU/apex","execTimeMs":283.3725370168686,"isFunctionError":false,"stack":"","statusCode":200}'
                },
                statusCode: 200
            };
            const requestStub = sandbox.stub(HttpRequestUtil.prototype, 'request')
                .resolves(functionResponse);
            const handler = new AsyncRequestHandler({}, request, {});
            const parseAndValidateContextsResult = handler.parseAndValidateContexts()
            const invokeFunctionResult = await handler.invokeFunction(parseAndValidateContextsResult.sfFnContext);
            expect(invokeFunctionResult.body).to.equal(functionResponse.body);
            expect(invokeFunctionResult.extraInfo).to.equal(functionResponse.headers['x-extra-info']);
            expect(invokeFunctionResult.statusCode).to.equal(functionResponse.statusCode);
        });
    });

    const updateAsyncFunctionResponseTest = async (namespace) => {
        const sfFnContext = {
            'requestId': requestId,
            'accessToken': 'functionsAccessToken',
            'functionName': 'myproject.typescriptfunction',
            'functionInvocationId': 'functionInvocationId',
            'type': 'com.salesforce.function.invoke.sync',
            'permissionSets': ['Functions']
        };
        const sfContext = {
            'requestId': requestId,
            'apiVersion': '57.0',
            'userContext': {
                'requestId': requestId,
                'namespace': namespace,
                'orgId': '00Dxx0000006JX6EAM',
                'username': 'admin@sf-fx-dh.com',
                'orgDomainUrl': 'https://sf-fx-dh.my.salesforce.com'
            }
        };
        const request = {
            method: 'POST',
            headers: {
                'authorization': `Bearer requestProvidedAccessToken`,
                'x-request-id': requestId,
                'ce-specversion': 'ce-specversion-here',
                'ce-id': 'ce-id-here',
                'ce-datacontenttype': 'ce-datacontenttype-here',
                'ce-source': 'ce-source-here',
                'ce-type': 'ce-type-here',
                'ce-sffncontext': Buffer.from(JSON.stringify(sfFnContext), 'utf8').toString('base64'),
                'ce-sfcontext': Buffer.from(JSON.stringify(sfContext), 'utf8').toString('base64')
            },
            body: '{}',
            log
        }
        const functionResponse = {
            body: 'It Worked!',
            extraInfo: '{"requestId":"00Dxx0000006IYJEA2-4pKLsu1D0B0BL9-qbvxXF--a00B000000Ou3NuIAJ-typescriptfunction-2023-04-12T17:26:12.318-0700","source":"urn:event:from:salesforce/xxx/00DB0000000gJmXMAU/apex","execTimeMs":283.3725370168686,"isFunctionError":false,"stack":"","statusCode":200}',
            statusCode: 200
        };
        const afirUpdateResponse = {
            statusCode: 204
        }
        const requestStub = sandbox.stub(HttpRequestUtil.prototype, 'request')
            .resolves(afirUpdateResponse);
        const handler = new AsyncRequestHandler({}, request, {});
        const updateAsyncFunctionResult = await handler.updateAsyncFunctionResponse(sfFnContext, sfContext,
            functionResponse.body, functionResponse.statusCode, functionResponse.extraInfo);
        expect(requestStub.calledOnce).to.be.true;
    }

    describe('update AsyncFunctionInvocationRequest__c w/o namespace', function () {
        it('happy path', async function () {
            updateAsyncFunctionResponseTest(undefined);
        });
    });

    describe('update AsyncFunctionInvocationRequest__c w/ namespace', function () {
        it('happy path', async function () {
            updateAsyncFunctionResponseTest('namespace');
        });
    });
});