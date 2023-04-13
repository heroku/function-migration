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
        // Determine namespace
        ApexClass thisCls = [ SELECT NamespacePrefix FROM ApexClass WHERE Name = 'InvokeTypescriptFunction' ];
        
        // Get reference to function
        Function typescriptFunction = Function.get(thisCls.NamespacePrefix, 'sfhxhello_typescriptfunction');
        Map<String,String> params = new Map<String,String>();
        
        // Async
        FunctionInvocation invocation = typescriptFunction.invoke(JSON.serialize(params), new Callback(FUNCTION_NAME));
        System.debug(invocation.getStatus().name() + '...');
    }

    // Invoke function
    public static void invokeSync() {
        // Determine namespace
        ApexClass thisCls = [ SELECT NamespacePrefix FROM ApexClass WHERE Name = 'InvokeTypescriptFunction' ];
        
        // Get reference to function
        Function typescriptFunction = Function.get(thisCls.NamespacePrefix, 'sfhxhello_typescriptfunction');
        Map<String,String> params = new Map<String,String>();

        // Sync
        FunctionInvocation invocation = typescriptFunction.invoke(JSON.serialize(params));
        
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
            acct.Description = logMe + '\n\n' + invocation.getStacktrace();
            insert acct;
        }
    }
}