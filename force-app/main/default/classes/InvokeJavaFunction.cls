/**
 * Example of invoking a function using Reference Functions Framework.
 */
public class InvokeJavaFunction {

    public static final String FUNCTION_NAME = 'sfhxhello_javafunction';
    
    public InvokeJavaFunction(ApexPages.StandardSetController controller) {   }
    
    public InvokeJavaFunction(ApexPages.StandardController controller) {   }
    
    public InvokeJavaFunction() {    }
    
    public void invokeSyncFromButton() {
        InvokeJavaFunction.invokeSync();
    }

    // Invoke sync function
    public static void invokeSync() {
        // Use the default FunctionsAuthProvider impl
        invokeSyncWork(null);
    }

    public static FunctionInvocation invokeSyncWork(FunctionsAuthProvider authProvider) {
        // Determine namespace
        ApexClass thisCls = [ SELECT NamespacePrefix FROM ApexClass WHERE Name = 'InvokeJavaFunction' ];
        
        // Get reference to function
        Function javafunction = Function.get(thisCls.NamespacePrefix, 'sfhxhello_javafunction');
        Map<String,String> params = new Map<String,String>();

        // Sync
        FunctionInvocation invocation;
        if (authProvider != null) {
            // Test support
            invocation = javafunction.invoke(JSON.serialize(params), authProvider);
        } else {
            invocation = javafunction.invoke(JSON.serialize(params));
        }
        
        // Handle response
        String logMe = invocation.getStatus().name() + ': ' + invocation.getResponse();
        System.debug(logMe);
        Account acct = new Account();
        acct.Name = FUNCTION_NAME + '/sync/' + invocation.getStatus().name() + '/' + invocation.getInvocationId();
        acct.Description = logMe + '\n\nExecTimeMs: ' + invocation.getExecTimeMs() + '\n\nFunctionError?: ' + 
            invocation.isFunctionError() + '\n\nStacktrace: ' + invocation.getStacktrace();
        insert acct;

        return invocation;
    }
    
    public void invokeAsyncFromButton() {
        InvokeJavaFunction.invokeAsync();
    }
    
    // Invoke async function
    public static void invokeAsync() {
        // Use the default FunctionsAuthProvider impl
        invokeAsyncWork(FUNCTION_NAME, null);
    }

    public static FunctionInvocation invokeAsyncWork(String callbackName, FunctionsAuthProvider authProvider) {
        // Determine namespace
        ApexClass thisCls = [ SELECT NamespacePrefix FROM ApexClass WHERE Name = 'InvokeJavaFunction' ];
        
        // Get reference to function
        Function javaFunction = Function.get(thisCls.NamespacePrefix, 'sfhxhello_javafunction');
        Map<String,String> params = new Map<String,String>();

        // Async
        FunctionInvocation invocation;
        if (authProvider != null) {
            // Test support
            invocation = javaFunction.invoke(JSON.serialize(params), new Callback(callbackName), authProvider);
        } else {
            invocation = javaFunction.invoke(JSON.serialize(params), new Callback(callbackName));
        }
        
        System.debug(invocation.getStatus().name() + '...');

        return invocation;
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
            acct.Name = functionName + '/async/' + invocation.getStatus().name() + '/' + invocation.getInvocationId() + 
                '/' +  Datetime.now().getTime();
            acct.Description = logMe + '\n\nExecTimeMs: ' + invocation.getExecTimeMs() + '\n\nFunctionError?: ' + 
                invocation.isFunctionError() + '\n\nStacktrace: ' + invocation.getStacktrace();
            insert acct;

            System.debug('Inserted callback Account: ' + acct.Name);
        }
    }
}