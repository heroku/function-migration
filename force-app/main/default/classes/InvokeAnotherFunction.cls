public class InvokeAnotherFunction {
    
    public InvokeAnotherFunction(ApexPages.StandardSetController controller) {   }
    
    public InvokeAnotherFunction(ApexPages.StandardController controller) {   }
    
    public InvokeAnotherFunction() {    }
    
    public void invokeFromButton() {
        InvokeAnotherFunction.invoke();
    }
    
    // Invoke function
    public static void invokeAsyncFirstInsertAccount() {
        // INVOKE!
        Function docjava = Function.get('sfhxhello.anotherfunction');
        FunctionInput params = new FunctionInput();
        docjava.invoke(JSON.serialize(params), new List<String>{ 'Functions' }, new ProcessApplicationCallback());
    }

    // Invoke function
    public static void invoke() {
            
        // INVOKE!
        Function docjava = Function.get('sfhxhello.anotherfunction');
        FunctionInput params = new FunctionInput();
        // Sync
        //FunctionInvocation invocation = docjava.invoke(JSON.serialize(params), new List<String>{ 'Functions' });
        //System.debug(invocation.getStatus().name() + ': ' + invocation.getResponse());

        // Async
        FunctionInvocation invocation = docjava.invoke(JSON.serialize(params), 
                                                       new List<String>{ 'Functions' }, 
                                                       new ProcessApplicationCallback());
        System.debug(invocation.getStatus().name() + ': ' + invocation.getResponse());
    }
    
    // Callback
    public class ProcessApplicationCallback implements FunctionCallback {    
        public void handleResponse(FunctionInvocation invocation) {
            System.debug(invocation.getStatus().name() + ': ' + invocation.getResponse());
            if (invocation.getStatus() == FunctionInvocationStatus.ERROR) {        
                throw new CalloutException(invocation.getError() != null ? invocation.getError().getMessage() : 'UNKNOWN');
            }
        }
    }
    
    public class FunctionInput {        
        public String documentId;
        public String mode;
        
        public String getMode() {
            return mode;
        }
    }
}