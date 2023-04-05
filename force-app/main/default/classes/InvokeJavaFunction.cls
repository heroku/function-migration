public class InvokeJavaFunction {

    static final String FUNCTION_NAME = 'JavaFunction';
    
    public InvokeJavaFunction(ApexPages.StandardSetController controller) {   }
    
    public InvokeJavaFunction(ApexPages.StandardController controller) {   }
    
    public InvokeJavaFunction() {    }
    
    public void invokeSyncFromButton() {
        InvokeJavaFunction.invokeSync();
    }
    
    public void invokeAsyncFromButton() {
        InvokeJavaFunction.invokeAsync();
    }
    
    // Invoke function
    public static void invokeAsync() {
        Function javafunction = Function.get('sfhxhello_javafunction');
        Map<String,String> params = new Map<String,String>();
        // Async
        FunctionInvocation invocation = javafunction.invoke(JSON.serialize(params), new Callback(FUNCTION_NAME));
        System.debug(invocation.getStatus().name() + '...');
    }

    // Invoke sync function
    public static void invokeSync() {
        Function javafunction = Function.get('sfhxhello_javafunction');
        Map<String,String> params = new Map<String,String>();
        // Sync
        FunctionInvocation invocation = javafunction.invoke(JSON.serialize(params));
        
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