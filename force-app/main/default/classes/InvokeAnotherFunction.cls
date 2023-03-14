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
        Function docjava = Function.get('sfhxhello_unitofworkfunction');
        FunctionInput params = new FunctionInput();
        docjava.invoke(JSON.serialize(params), new List<String>{ 'UnitOfWorkFunction' }, new ProcessApplicationCallback());
    }

    // Invoke function
    public static void invoke() {
            
        // INVOKE!
        Function docjava = Function.get('sfhxhello_unitofworkfunction');
        FunctionInput params = new FunctionInput();
        // Sync
        //FunctionInvocation invocation = docjava.invoke(JSON.serialize(params), new List<String>{ 'UnitOfWorkFunction' });
        //System.debug(invocation.getStatus().name() + ': ' + invocation.getResponse());

        // Async
        FunctionInvocation invocation = docjava.invoke(JSON.serialize(params), 
                                                       new List<String>{ 'UnitOfWorkFunction' }, 
                                                       new ProcessApplicationCallback());
        System.debug(invocation.getStatus().name() + ': ' + invocation.getResponse());
    }
    
    // Callback
    public class ProcessApplicationCallback implements FunctionCallback {    
        public void handleResponse(FunctionInvocation invocation) {
            String logMe = invocation.getStatus().name() + ': ' + invocation.getResponse();
            System.debug(logMe);
            Account acct = new Account();
            acct.Name = invocation.getInvocationId();
            acct.Description = invocation.getInvocationId();
            insert acct;
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