/**
 * Demonstrates the use of the Asynchronous Function Invocation API.
 */
global class AsyncUnitOfWork {

    global static void invoke() { AsyncUnitOfWork.invoke(new AsyncUnitOfWorkCallback()); }
    
    global static void invoke(FunctionCallback callback) { AsyncUnitOfWork.invoke(Function.get('sfhxhello.unitofworkfunction'), callback); }

    global static void invokeSync(Function unitofworkfunction) {
        FunctionInvocation invocation = unitofworkfunction.invoke('{}');
        System.debug('Did an sync enqueue with ID ' + invocation.getInvocationId());
        System.debug('Got response ' + invocation.getResponse());
        if (invocation.getStatus() == FunctionInvocationStatus.ERROR) {
            System.debug('Error: ' + (invocation.getError() != null ? invocation.getError().getMessage() : 'UNKNOWN'));
            return;
        }
    }
    
    global static void invoke(Function unitofworkfunction, FunctionCallback callback) {
        FunctionInvocation invocation = unitofworkfunction.invoke('{}', callback);
        System.debug('Did an async enqueue with ID ' + invocation.getInvocationId());
    }

    // Handle async function callback
    public class AsyncUnitOfWorkCallback implements FunctionCallback {
        public AsyncUnitOfWorkCallback() {}

        public void handleResponse(FunctionInvocation invocation) {            
            System.debug('Got response ' + invocation.getResponse());
            if (invocation.getStatus() == FunctionInvocationStatus.ERROR) {
                System.debug('Error: ' + (invocation.getError() != null ? invocation.getError().getMessage() : 'UNKNOWN'));
                return;
            }
        }
    }
}