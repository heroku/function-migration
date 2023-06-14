@isTest
public class FunctionInvokeTests {

    public class FunctionTestCallback implements FunctionCallback {

        String acctName;

        public FunctionTestCallback(String acctName) {
            this.acctName = acctName; 
        }
    
        public void handleResponse(FunctionInvocation invocation) {
            System.debug('FunctionTestCallback.handleResponse invoked w/ invocation ' + invocation.getInvocationId());
            Account acct = new Account(Name=acctName, Description=JSON.serialize(invocation));
            insert acct;
            System.debug('Inserted Account: ' + acct.Id + ', ' + acct.Name);
        }
    }

    private static String PERM_SET_NAME = 'TestInvokePermissionSet';
    private static String FUNCTION_REF = 'TestInvokeFunction';

    @TestSetup 
    static void setup() {
        // Create function's Permission Set and assign to user
        PermissionSet  permSet = FunctionsTestDataFactory.createPermissionSetRecord(PERM_SET_NAME, true);
        FunctionsTestDataFactory.assignPermissionSetRecord(permSet, UserInfo.getUserId());
    }

    @isTest
    static void testInvoke_sync() {
        FunctionReferenceProvider mockFunctionReferenceProvider = 
            FunctionsTestDataFactory.createFunctionReferenceRecord(FUNCTION_REF, withNamespace(PERM_SET_NAME));

        // Pass on invoke() success
        String responseBody = '{}';
        Test.setMock(HttpCalloutMock.class, FunctionInvocationCalloutMocks.respondSuccess(responseBody));        
        Function testInvokeFunction = Function.get('', FUNCTION_REF, mockFunctionReferenceProvider);

        Test.startTest();

        FunctionInvocation invocation = testInvokeFunction.invoke('{}', new FunctionsTestAuthProviderMocks.FakeAuthProvider());

        Test.stopTest();

        Assert.areEqual(responseBody, invocation.getResponse(), invocation.getResponse());
        Assert.isNotNull(invocation.getError());
        Assert.isTrue(String.isEmpty(invocation.getError().getMessage()), invocation.getError().getMessage());
        Assert.areEqual(FunctionInvocationStatus.SUCCESS.name(), invocation.getStatus().name());                
        Assert.isNotNull(invocation.getInvocationId());
        Assert.isNull(invocation.getAsyncFunctionInvocationRequestId());
        Assert.isFalse(invocation.isFunctionError());
        Assert.areEqual(763, invocation.getExecTimeMs());
        Assert.isNotNull(invocation.getStacktrace());
        Assert.areEqual(200, invocation.getStatusCode());
    }

    @isTest
    static void testInvoke_sync_functionError() {
        FunctionReferenceProvider mockFunctionReferenceProvider = 
            FunctionsTestDataFactory.createFunctionReferenceRecord(FUNCTION_REF, withNamespace(PERM_SET_NAME));

        // Pass on invoke() function error
        String responseBody = '{}';        
        Test.setMock(HttpCalloutMock.class, FunctionInvocationCalloutMocks.respondFunctionError(responseBody));        
        Function testInvokeFunction = Function.get('', FUNCTION_REF, mockFunctionReferenceProvider);

        Test.startTest();
        
        FunctionInvocation invocation = testInvokeFunction.invoke('{}', new FunctionsTestAuthProviderMocks.FakeAuthProvider());

        Test.stopTest();

        Assert.areEqual(responseBody, invocation.getResponse(), invocation.getResponse());
        Assert.isNotNull(invocation.getError());
        Assert.isTrue(String.isEmpty(invocation.getError().getMessage()), invocation.getError().getMessage());
        Assert.areEqual(FunctionInvocationStatus.ERROR.name(), invocation.getStatus().name());                
        Assert.isTrue(invocation.isFunctionError());
        Assert.areEqual(763, invocation.getExecTimeMs());
        Assert.isNotNull(invocation.getStacktrace());
        Assert.areEqual(500, invocation.getStatusCode());
    }

    @isTest
    static void testInvoke_sync_errorOnAccessToken() {
        FunctionReferenceProvider mockFunctionReferenceProvider = 
            FunctionsTestDataFactory.createFunctionReferenceRecord(FUNCTION_REF, withNamespace(PERM_SET_NAME));

        // Fail on invalid access token
        String responseBody = '{}';        
        Test.setMock(HttpCalloutMock.class, FunctionInvocationCalloutMocks.respondSuccess(responseBody));
        Function testInvokeFunction = Function.get('', FUNCTION_REF, mockFunctionReferenceProvider);
        try {
            testInvokeFunction.invoke('{}', new FunctionsTestAuthProviderMocks.NullAuthProvider());
            Assert.fail('Expected Function.InvalidFunctionInvocationException');
        } catch(Function.InvalidFunctionInvocationException ex) {
            Assert.isTrue(ex.getMessage().contains('not provided'), ex.getMessage());
        } catch(Exception ex) {
            Assert.fail('Unexpected exception: ' + ex.getMessage());
        }        
    }

    @isTest
    static void testInvoke_async() {
        FunctionReferenceProvider mockFunctionReferenceProvider = 
            FunctionsTestDataFactory.createFunctionReferenceRecord(FUNCTION_REF, withNamespace(PERM_SET_NAME));

        // Pass on invoke() success
        String responseBody = '{}';
        Function testInvokeFunction = Function.get(getNamespace(), FUNCTION_REF, mockFunctionReferenceProvider);
        String acctName = 'testInvoke_async' +  Datetime.now().getTime();
        FunctionTestCallback callback = new FunctionTestCallback(acctName);

        Test.setMock(HttpCalloutMock.class, FunctionInvocationCalloutMocks.asyncRespondSuccess());
        Test.startTest();

        String requestPayload = '{}';
        FunctionInvocation invocation = 
            testInvokeFunction.invoke(requestPayload, callback, new FunctionsTestAuthProviderMocks.FakeAuthProvider());
        Assert.isNotNull(invocation);        
        Assert.isNull(invocation.getResponse());
        Assert.isNull(invocation.getError());
        Assert.areEqual(FunctionInvocationStatus.PENDING.name(), invocation.getStatus().name());
        Assert.isNotNull(invocation.getInvocationId());
        Assert.isNotNull(invocation.getAsyncFunctionInvocationRequestId());

        // Validate AsyncFunctionInvocationRequest__c
        AsyncFunctionInvocationRequest__c afir = [SELECT Id, AsyncInvocationJobId__c, Callback__c, CallbackType__c, 
                                                         Context__c, ExtraInfo__c, Request__c, RequestId__c, 
                                                         Response__c, Status__c, StatusCode__c 
                                                  FROM AsyncFunctionInvocationRequest__c 
                                                  WHERE Id =:invocation.getAsyncFunctionInvocationRequestId()];
        Assert.isNotNull(afir);
        Assert.isNotNull(afir.Id);
        Assert.isNotNull(afir.AsyncInvocationJobId__c);
        Assert.isNotNull(afir.Callback__c);
        Assert.isNotNull(afir.CallbackType__c);
        Assert.isTrue(afir.CallbackType__c.contains('FunctionTestCallback'));
        Assert.isNull(afir.ExtraInfo__c);
        Assert.areEqual(requestPayload, afir.Request__c);
        Assert.isNotNull(afir.RequestId__c);
        Assert.isTrue(afir.RequestId__c.contains(FUNCTION_REF));
        Assert.isNull(afir.Response__c);
        Assert.areEqual(FunctionInvocationStatus.PENDING.name(), afir.Status__c);
        Assert.isNull(afir.StatusCode__c);

        // Simulate function response
        afir.ExtraInfo__c = FunctionInvocationCalloutMocks.EXTRA_INFO_SUCCESS;
        afir.Response__c = responseBody;
        afir.Status__c = FunctionInvocationStatus.SUCCESS.name();
        afir.StatusCode__c = 200;
        Database.SaveResult result = Database.update(afir, false);
        Assert.isTrue(result.isSuccess());
        Assert.isNotNull(result.id, invocation.getAsyncFunctionInvocationRequestId());

        Test.stopTest();

        // Validate callback
        Account acct = [SELECT Id, Name, Description FROM Account WHERE Name =:acctName ORDER BY CreatedDate DESC limit 1];
        Assert.isNotNull(acct);
        Assert.isNotNull(acct.Description);
        Assert.isTrue(acct.Description.contains('200'), acct.Description);
    }

    @isTest
    static void testInvoke_async_errorOnAccessToken() {
        String responseBody = '{}';
        FunctionReferenceProvider mockFunctionReferenceProvider = 
            FunctionsTestDataFactory.createFunctionReferenceRecord(FUNCTION_REF, withNamespace(PERM_SET_NAME));
        Function testInvokeFunction = Function.get(getNamespace(), FUNCTION_REF, mockFunctionReferenceProvider);
        String acctName = 'testInvoke_async_errorOnAccessToken-' + Datetime.now().getTime();
        FunctionTestCallback callback = new FunctionTestCallback(acctName);

        // Fail on invalid access token
        Test.setMock(HttpCalloutMock.class, FunctionInvocationCalloutMocks.respondSuccess(responseBody));
        try {
            testInvokeFunction.invoke('{}', callback, new FunctionsTestAuthProviderMocks.NullAuthProvider());
            Assert.fail('Expected Function.InvalidFunctionInvocationException');
        } catch(Function.InvalidFunctionInvocationException ex) {
            Assert.isTrue(ex.getMessage().contains('not provided'), ex.getMessage());
        } catch(Exception ex) {
            Assert.fail('Unexpected exception: ' + ex.getMessage());
        }   
    }

    @isTest
    static void testInvoke_async_errorOnRequest_retry() {
        FunctionReferenceProvider mockFunctionReferenceProvider = 
            FunctionsTestDataFactory.createFunctionReferenceRecord(FUNCTION_REF, withNamespace(PERM_SET_NAME));
        Function testInvokeFunction = Function.get(getNamespace(), FUNCTION_REF, mockFunctionReferenceProvider);
        String acctName = 'testInvoke_async_errorOnRequest_retry-' + Datetime.now().getTime();
        FunctionTestCallback callback = new FunctionTestCallback(acctName);

        // Pass on invoke() function error
        Test.setMock(HttpCalloutMock.class, FunctionInvocationCalloutMocks.asyncRespondError());        
        Test.startTest();
        
        FunctionInvocation invocation = testInvokeFunction.invoke('{}', callback, 
            new FunctionsTestAuthProviderMocks.FakeAuthProvider());
        Assert.isNotNull(invocation);
        Assert.isNotNull(invocation.getInvocationId());
        Assert.isNotNull(invocation.getAsyncFunctionInvocationRequestId());
        
        Test.stopTest();

        // Validate callback
        Account acct = [SELECT Id, Name, Description FROM Account WHERE Name =:acctName];
        Assert.isNotNull(acct);
        Assert.isNotNull(acct.Description);
        Assert.isTrue(acct.Description.contains('503'), acct.Description);
    }

    @isTest
    static void testInvoke_async_errorOnRequest_noRetry() {
        FunctionReferenceProvider mockFunctionReferenceProvider = 
            FunctionsTestDataFactory.createFunctionReferenceRecord(FUNCTION_REF, withNamespace(PERM_SET_NAME));
        Function testInvokeFunction = Function.get(getNamespace(), FUNCTION_REF, mockFunctionReferenceProvider);
        String acctName = 'testInvoke_async_errorOnRequest_noRetry-' + Datetime.now().getTime();
        FunctionTestCallback callback = new FunctionTestCallback(acctName);

        // Pass on invoke() function error
        Test.setMock(HttpCalloutMock.class, FunctionInvocationCalloutMocks.asyncRespondErrorNoRetry());        
        Test.startTest();
        
        FunctionInvocation invocation = testInvokeFunction.invoke('{}', callback, 
            new FunctionsTestAuthProviderMocks.FakeAuthProvider());
        Assert.isNotNull(invocation);
        Assert.isNotNull(invocation.getInvocationId());
        Assert.isNotNull(invocation.getAsyncFunctionInvocationRequestId());
        
        Test.stopTest();

        // Validate callback
        Account acct = [SELECT Id, Name, Description FROM Account WHERE Name =:acctName];
        Assert.isNotNull(acct);
        Assert.isNotNull(acct.Description);
        Assert.isTrue(acct.Description.contains('599'), acct.Description);
    }

    @isTest
    static void test_validateCallbackType() {
        String acctName = 'test_validateCallbackType-' + Datetime.now().getTime();
        FunctionTestCallback callback = new FunctionTestCallback(acctName);
        FunctionReference__mdt funcRef = new FunctionReference__mdt(Endpoint__c = '');
        Function function = new Function('', '', funcRef);
        String callbackType = function.determineClassType(callback);
        Assert.isNotNull(callbackType);
        Assert.isTrue(callbackType.contains('FunctionTestCallback'));
    }

    public class FakeFinalizerContext implements FinalizerContext {

        String exMsg;

        public FakeFinalizerContext(String exMsg) {
            this.exMsg = exMsg;
        }
        
        public System.ParentJobResult getResult() { 
            return ParentJobResult.UNHANDLED_EXCEPTION;
        }

        public System.Exception getException() {
            return new Function.InvalidFunctionException(exMsg);
        }

        public String getRequestId() { 
            return null; 
        }

        public Id getAsyncApexJobId() { 
            return null; 
        }
    }

    @isTest
    static void testInvoke_async_unhandledExceptionOnInvoke() {
        AsyncFunctionInvocationRequest__c afir = new AsyncFunctionInvocationRequest__c(
            Callback__c = '{}',
            CallbackType__c = 'CallbackType',
            RequestId__c = 'RequestId'
        );
        insert afir;

        AsyncFunctionInvocationQueueable afiq = 
            new AsyncFunctionInvocationQueueable('FunctionName', 'RequestId', 'Resource', 'Payload', 'Context', 'Token', 
                afir.Id);

        String exMsg = 'testInvoke_async_unhandledExceptionOnInvoke-' + Datetime.now().getTime();
        afiq.execute(new FakeFinalizerContext(exMsg));

        afir = [SELECT Id, Status__c, StatusCode__c, Response__c
                FROM AsyncFunctionInvocationRequest__c 
                WHERE Id = :afir.Id];
        Assert.areEqual(FunctionInvocationStatus.ERROR.name(), afir.Status__c);
        Assert.areEqual(400, afir.StatusCode__c);
        Assert.areEqual(exMsg, afir.Response__c);
    }

    private static String getNamespace() {
        ApexClass thisCls = [ SELECT NamespacePrefix FROM ApexClass WHERE Name = 'Function' ];
        return thisCls.NamespacePrefix;
    }

    private static String withDotNamespace(String name) {
        String namespace = getNamespace();
        return String.isNotBlank(namespace) ? namespace + '.' + name : name;
    }

    private static String withNamespace(String name) {
        String namespace = getNamespace();
        return String.isNotBlank(namespace) ? namespace + '__' + name : name;
    }
}