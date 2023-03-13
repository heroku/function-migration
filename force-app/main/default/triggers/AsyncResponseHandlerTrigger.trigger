trigger AsyncResponseHandlerTrigger on AsyncFunctionInvocationRequest__c (after update) {
    for(AsyncFunctionInvocationRequest__c afir : Trigger.new) {
        if (null == afir.StatusCode__c || 201 == afir.StatusCode__c)  {
            // TODO: Check for expected StatusCode__c values
            System.debug('Not handling ' + afir.Id + ': StatusCode__c not set or request is PENDING');
            continue;
        }

        if (String.isBlank(afir.Callback__c) || String.isBlank(afir.CallbackType__c)) {
            System.debug('Unable to invoke callback for request ' + afir.RequestId__c + ': Callback__c and/or CallbackType__c not provided for AsyncFunctionInvocationRequest__c ' + afir.Id);
            continue;
        }    

        System.debug('Processing callback for request ' + afir.RequestId__c + ', AsyncFunctionInvocationRequest__c ' + afir.Id);
        FunctionInvocationImpl invocation = new FunctionInvocationImpl(afir.RequestId__c, 
                                                                       afir.Response__c,
                                                                       afir.Status__c,
                                                                       afir.Status__c.equalsIgnoreCase(FunctionInvocationStatus.ERROR.name()) ? afir.Response__c : '',
                                                                       afir.StatusCode__c.intValue(),
                                                                       afir.Id);

        
        try {
            // Deserialize callback and enqueue callback invocation
            // TODO: Handle namespace
            Type fullyQualifiedNameCallbackTypeClass = Type.forName(afir.CallbackType__c);
            FunctionCallback callback = (FunctionCallback)JSON.deserializeStrict(afir.Callback__c, fullyQualifiedNameCallbackTypeClass);
            FunctionCallbackQueueable callbackQueueable = new FunctionCallbackQueueable(callback, invocation);
            ID callbackQueueableId = System.enqueueJob(callbackQueueable);
            System.debug('Enqueued callback ' + fullyQualifiedNameCallbackTypeClass + ' for request ' + afir.RequestId__c + ', AsyncFunctionInvocationRequest__c ' + afir.Id + ': FunctionCallbackQueueable job Id ' + callbackQueueableId);
        } catch(Exception ex) {
            System.debug('Unable to process callback for request ' + afir.RequestId__c + ', AsyncFunctionInvocationRequest__c ' + afir.Id + ': ' + ex.getMessage());
        }
    }
}