trigger InvokeAnotherFunctionAccountTrigger on AsyncFunctionInvocationRequest__c (after update) {
    for (AsyncFunctionInvocationRequest__c afir : Trigger.new) {
        // REVIEWME: Way to know what fields were updated?
        if (afir.Response__c != null && afir.StatusCode__c != null) {
            // TODO: Ensure there's a callback
            FunctionInvocation invocation = new FunctionInvocationImpl(
                afir.Id,
                afir.Response__c,
                FunctionInvocationStatus.SUCCESS.name(),
                '',
                afir.StatusCode__c);
            // REVIEWME: Should we capture the Apex class type for strict deser?
            FunctionCallback callback = (FunctionCallback)JSON.deserializeStrict(afir.Callback__c, FunctionCallback.class)
            FunctionCallbackQueueable callbackQueueable = new FunctionCallbackQueueable(callback, invocation);
            ID jobID = System.enqueueJob(callbackQueueable);
            System.debug('Enqueued function callback for ' + afir.Id);
        }
    }
}