@isTest
public class AsyncUnitOfWorkTest {

    @isTest 
    static void testAsyncFunctionCallSuccess() {
        // Set mock class to respond to function invocations
        Test.setMock(FunctionInvokeMock.class, new FunctionsInvokeMockInner());
        
        Function mockedFunction = Function.get('sfhxhello.unitofworkfunction');
        
        Test.startTest();
        //Asynchronous function invocation with callback
        AsyncUnitOfWork.invoke(mockedFunction, new TestAsyncUnitOfWorkCallbackSuccess());
        Test.stopTest();
        // Include assertions here about the expected callback processing        
    }

    @isTest
    static void testAsyncUnitOfWorkCallbackError() {
        String invocationId = '000000000000000';
        FunctionInvocation errorResponse = MockFunctionInvocationFactory.createErrorResponse(
                        invocationId,
                        FunctionErrorType.FUNCTION_EXCEPTION,
                        '500');
        AsyncUnitOfWork.AsyncUnitOfWorkCallback callback = new AsyncUnitOfWork.AsyncUnitOfWorkCallback();
        callback.handleResponse(errorResponse);
    }
    
    public class TestAsyncUnitOfWorkCallbackSuccess implements FunctionCallback {
        public void handleResponse(FunctionInvocation invokeResult) {
            System.assertEquals(invokeResult.getStatus(), FunctionInvocationStatus.SUCCESS);
            FunctionInvocationError resultError = invokeResult.getError();
            System.assertEquals('000000000000000', invokeResult.getInvocationId());
        }
    }

    public class FunctionsInvokeMockInner implements FunctionInvokeMock {
        public FunctionInvocation respond(String functionName, String payload) {
            // Return mock success response
            String invocationId = '000000000000000';
            String response = '{ "done": true, "totalSize": 1, "records": [ { "type": "Account", "fields": { "id": "001RO000003SwhXYAS", "name": "Acme" } } ] }';
            return MockFunctionInvocationFactory.createSuccessResponse(invocationId, response);       
        }
    }
}