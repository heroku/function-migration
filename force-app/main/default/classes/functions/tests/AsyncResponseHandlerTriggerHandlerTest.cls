/**
 * Tests for AsyncResponseHandlerTriggerHandler.
 */
@isTest
public class AsyncResponseHandlerTriggerHandlerTest {

    @isTest
    static void testHandle_noResponseYet() {
        AsyncFunctionInvocationRequest__c afir = new AsyncFunctionInvocationRequest__c(
            StatusCode__c = 201
        );
        List<AsyncFunctionInvocationRequest__c> afirs = new List<AsyncFunctionInvocationRequest__c>();
        afirs.add(afir);
        List<AsyncFunctionInvocationRequest__c> afirCallbacks = AsyncResponseHandlerTriggerHandler.handle(afirs);
        Assert.isTrue(afirCallbacks.isEmpty());
    }

    @isTest
    static void testHandle_invalidCallback() {
        AsyncFunctionInvocationRequest__c afir = new AsyncFunctionInvocationRequest__c(
            StatusCode__c = 200
        );
        List<AsyncFunctionInvocationRequest__c> afirs = new List<AsyncFunctionInvocationRequest__c>();
        afirs.add(afir);
        List<AsyncFunctionInvocationRequest__c> afirCallbacks = AsyncResponseHandlerTriggerHandler.handle(afirs);
        Assert.isTrue(afirCallbacks.isEmpty());
    }

    @isTest
    static void testHandle_invokeCallback() {
        String acctName = 'testHandle_invokeCallback-' + Datetime.now().getTime();
        FunctionInvokeTests.FunctionTestCallback callback = new FunctionInvokeTests.FunctionTestCallback(acctName);
        FunctionReference__mdt funcRef = new FunctionReference__mdt(Endpoint__c = '');
        Function function = new Function('', '', funcRef);
        String callbackType = function.determineClassType(callback);
        Assert.isFalse(String.isEmpty(callbackType));
        AsyncFunctionInvocationRequest__c afir = new AsyncFunctionInvocationRequest__c(
            Id = Id.valueOf(AsyncFunctionInvocationRequest__c.SObjectType.getDescribe().getKeyPrefix() + '000000000000'),
            Callback__c = JSON.serialize(callback),
            CallbackType__c = callbackType,
            RequestId__c = 'RequestId',
            Response__c = 'Response',
            StatusCode__c = 200
        );
        List<AsyncFunctionInvocationRequest__c> afirs = new List<AsyncFunctionInvocationRequest__c>();
        afirs.add(afir);

        Test.startTest();

        List<AsyncFunctionInvocationRequest__c> afirCallbacks = AsyncResponseHandlerTriggerHandler.handle(afirs);
        Assert.isFalse(afirCallbacks.isEmpty());

        Test.stopTest();

        // Validate callback invocation
        Account acct = [SELECT Id, Name, Description FROM Account WHERE Name =:acctName];
        Assert.isNotNull(acct);
        Assert.isNotNull(acct.Description);
        Assert.isTrue(acct.Description.contains(afir.Response__c), acct.Description);
    }
}