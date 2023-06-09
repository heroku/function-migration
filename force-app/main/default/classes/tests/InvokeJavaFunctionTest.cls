/**
 * Tests for InvokeJavaFunction.  Test assumes that FunctionReference_mdt records are deployed.
 */
@isTest
public class InvokeJavaFunctionTest {
    
    @isTest
    static void testInvoke_sync() {
        String responseBody = '{}';
        Test.setMock(HttpCalloutMock.class, FunctionInvocationCalloutMocks.respondSuccess(responseBody));

        Test.startTest();        

        FunctionInvocation invocation = InvokeJavaFunction.invokeSyncWork(new FunctionsTestAuthProviderMocks.FakeAuthProvider());

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
    static void testInvoke_async() {
        String responseBody = '{}';
        Test.setMock(HttpCalloutMock.class, FunctionInvocationCalloutMocks.asyncRespondSuccess());
        
        Test.startTest();

        String callbackName = 'testInvoke_async' + Datetime.now().getTime();
        FunctionInvocation invocation = 
            InvokeJavaFunction.invokeAsyncWork(callbackName, new FunctionsTestAuthProviderMocks.FakeAuthProvider());        
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
        Assert.isTrue(afir.CallbackType__c.contains('Callback'));
        Assert.isNull(afir.ExtraInfo__c);
        Assert.areEqual('{}', afir.Request__c);
        Assert.isNotNull(afir.RequestId__c);
        Assert.isTrue(afir.RequestId__c.contains(InvokeJavaFunction.FUNCTION_NAME));
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
        Assert.isNotNull(result.id);
        Assert.isNotNull(result.id, invocation.getAsyncFunctionInvocationRequestId());

        Test.stopTest();

        // Validate callback
        String whereLike = '%' + callbackName + '%';
        Account acct = [SELECT Id, Name, Description 
                        FROM Account 
                        WHERE Name LIKE :whereLike 
                        ORDER BY CreatedDate DESC limit 1];
        Assert.isNotNull(acct);
        Assert.isNotNull(acct.Name);
        Assert.isTrue(acct.Name.contains(callbackName), acct.Name);
        Assert.isNotNull(acct.Description);
        Assert.isTrue(acct.Description.contains('SUCCESS'), acct.Description);
        Assert.isTrue(acct.Description.contains('ExecTimeMs: 763'), acct.Description);
        Assert.isTrue(acct.Description.contains('FunctionError?: false'), acct.Description);
        Assert.isTrue(acct.Description.contains('Stacktrace: ()'), acct.Description);
    }
}