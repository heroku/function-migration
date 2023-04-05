public class InvokeTypescriptFunction {

    static final String FUNCTION_NAME = 'TypescriptFunction';
    
    public InvokeTypescriptFunction(ApexPages.StandardSetController controller) {   }
    
    public InvokeTypescriptFunction(ApexPages.StandardController controller) {   }
    
    public InvokeTypescriptFunction() {    }
    
    public void invokeSyncFromButton() {
        InvokeTypescriptFunction.invokeSync();
    }

    public void invokeAsyncFromButton() {
        InvokeTypescriptFunction.invokeAsync();
    }
    
    // Invoke function
    public static void invokeAsync() {
        Function typescriptfunction = Function.get('sfhxhello_typescriptfunction');
        Map<String,String> params = new Map<String,String>();
        // Async
        FunctionInvocation invocation = typescriptfunction.invoke(JSON.serialize(params), new Callback(FUNCTION_NAME));
        System.debug(invocation.getStatus().name() + '...');
    }

    // Invoke function
    public static void invokeSync() {
        Function typescriptfunction = Function.get('sfhxhello_typescriptfunction');
        Map<String,String> params = new Map<String,String>();
        // Sync
        FunctionInvocation invocation = typescriptfunction.invoke(JSON.serialize(params));
        
        // Handle response
        String logMe = invocation.getStatus().name() + ': ' + invocation.getResponse();
        System.debug(logMe);
        Account acct = new Account();
        acct.Name = FUNCTION_NAME + '/sync/' + invocation.getStatus().name() + '/' + invocation.getInvocationId();
        acct.Description = logMe;
        insert acct;
    }
    
    // Callback
    public class Callback implements FunctionCallback {
    
        String functionName;

        Callback(String functionName) {
            this.functionName = functionName;
        }  
    
        public void handleResponse(FunctionInvocation invocation) {
            String logMe = invocation.getStatus().name() + ': ' + invocation.getResponse();
            System.debug(logMe);
            Account acct = new Account();
            acct.Name = functionName + '/async/' + invocation.getStatus().name() + '/' + invocation.getInvocationId();
            acct.Description = logMe;
            insert acct;
        }
    }
}