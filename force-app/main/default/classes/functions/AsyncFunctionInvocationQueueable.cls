/**
 * Encapsulates queuing an async function invocation request.  
 * Dequeuing will invoke the function.
 */
public class AsyncFunctionInvocationQueueable implements Queueable, Database.AllowsCallouts, Finalizer {

    private final String functionName;
    private final String requestId;
    private final String resource;
    private final String payloadJson;
    private final String functionRequestContextJson;
    private final String authenticationToken;
    private final String asyncFunctionInvocationRequestId;
    
    public AsyncFunctionInvocationQueueable(String functionName,
                                            String requestId,
                                            String resource,
                                            String payloadJson,
                                            String functionRequestContextJson,
                                            String authenticationToken,
                                            String asyncFunctionInvocationRequestId) {
        this.functionName = functionName;
        this.requestId = requestId;
        this.resource = resource;
        this.payloadJson = payloadJson;
        this.functionRequestContextJson = functionRequestContextJson;
        this.authenticationToken = authenticationToken;
        this.asyncFunctionInvocationRequestId = asyncFunctionInvocationRequestId;
    }

    /**
     * Dequeue to async invoke function.
     */
    public void execute(QueueableContext queueableCtx) {
        // Attach finalizer to job execution to handle unexpected exception
        System.attachFinalizer(this);

        // Invoke!
        FunctionInvoker invoker = new FunctionInvoker(functionName,
                                                      requestId,
                                                      resource,
                                                      payloadJson,
                                                      FunctionInvocationRequest.fromJSON(functionRequestContextJson),
                                                      authenticationToken);
        FunctionInvocationImpl functionInvocation = invoker.invoke(true);

        // Evaluate and handle response
        Integer statusCode = functionInvocation.getStatusCode();
        String status = FunctionInvocationStatus.PENDING.name();
        String response = functionInvocation.getResponse();
        if (201 != statusCode) {
            System.debug('FAILURE: Unsuccessfully sent async invocation request for function ' + functionName + 
                ' [' + statusCode + ']: ' + response + ' [' + requestId + ']');
            status = FunctionInvocationStatus.ERROR.name();
        } else {
            System.debug('Successfully sent async invocation request for function ' + functionName + 
                ' [' + requestId + ']');
        }

        // Update AFIR to trigger callback
        AsyncFunctionInvocationRequest__c afir = [SELECT Id 
                                                  FROM AsyncFunctionInvocationRequest__c 
                                                  WHERE Id = :asyncFunctionInvocationRequestId
                                                  WITH SECURITY_ENFORCED];
        afir.Status__c = status;
        afir.StatusCode__c = statusCode;
        afir.Response__c = response;
        afir.ExtraInfo__c = functionInvocation.getEncodedExtraInfoJson();
        update afir;

        System.debug('Updated AsyncFunctionInvocationRequest__c [' + asyncFunctionInvocationRequestId + 
            '] for function ' + functionName + ' [' + requestId + ']');
    }

    /**
     * Finalizer implementation captures failed function invocation jobs on unexpected execptions, eg limit errors.
     * 
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_transaction_finalizers.htm
     */
    public void execute(FinalizerContext finalizerCtx) {        
        if (finalizerCtx.getResult() == ParentJobResult.UNHANDLED_EXCEPTION) {
            System.debug('FAILURE: Unsuccessful invocation job [' + finalizerCtx.getAsyncApexJobId() + '] for function ' + 
                functionName + ' [' + requestId + ']: ' + finalizerCtx.getException().getMessage());

            // TODO: Evaluate failure and consider retrying function invocation here.

            AsyncFunctionInvocationRequest__c afir = [SELECT Id, Status__c, StatusCode__c, Response__c
                                                      FROM AsyncFunctionInvocationRequest__c 
                                                      WHERE Id = :asyncFunctionInvocationRequestId
                                                      WITH SECURITY_ENFORCED];
            afir.Status__c = FunctionInvocationStatus.ERROR.name();
            afir.StatusCode__c = 400;
            afir.Response__c = finalizerCtx.getException().getMessage();
            update afir;
        }
    }
}