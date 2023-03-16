public class InvokeUnitOfWorkFunction {
    
    public InvokeUnitOfWorkFunction(ApexPages.StandardSetController controller) {   }
    
    public InvokeUnitOfWorkFunction(ApexPages.StandardController controller) {   }
    
    public InvokeUnitOfWorkFunction() {    }
    
    public void invokeFromButton() {
        InvokeUnitOfWorkFunction.invoke();
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

        // Async
        FunctionInvocation invocation = docjava.invoke(JSON.serialize(params), 
                                                       new List<String>{ 'UnitOfWorkFunction' }, 
                                                       new ProcessApplicationCallback());

        System.debug(invocation.getStatus().name() + ': ' + invocation.getResponse());
    }
    
    // Callback
    public class ProcessApplicationCallback implements FunctionCallback {
    
        final String FUNCTION = 'UnitOfWorkFunction';
    
        public void handleResponse(FunctionInvocation invocation) {
            String logMe = invocation.getStatus().name() + ': ' + invocation.getResponse();
            System.debug(logMe);
            Account acct = new Account();
            acct.Name = FUNCTION + '/' + invocation.getInvocationId();
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