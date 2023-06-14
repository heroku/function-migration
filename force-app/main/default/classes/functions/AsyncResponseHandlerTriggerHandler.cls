/**
 * Handle AsyncFunctionInvocationRequest__c updates.  On function response update, invoke callback.
 */
public with sharing class AsyncResponseHandlerTriggerHandler {

    /**
     * Handles invoking the FunctionCallback implementations for asynchronous function invocations.
     * 
     * @return List of AsyncFunctionInvocationRequest__c instances whose callback was invoked
     */
    public static List<AsyncFunctionInvocationRequest__c> handle(List<AsyncFunctionInvocationRequest__c> afirs) {
        // Track which AsyncFunctionInvocationRequest__c instances resulted in callbacks
        List<AsyncFunctionInvocationRequest__c> afirCallbacks = new List<AsyncFunctionInvocationRequest__c>();

        for (AsyncFunctionInvocationRequest__c afir : afirs) {
            if (null == afir.StatusCode__c || 201 == afir.StatusCode__c)  {
                // TODO: Check for expected StatusCode__c values
                System.debug('Not handling ' + afir.Id + ': StatusCode__c not set or request is PENDING');
                continue;
            }
    
            if (String.isBlank(afir.Callback__c) || String.isBlank(afir.CallbackType__c)) {
                System.debug('Unable to invoke callback for request ' + afir.RequestId__c + 
                    ': Callback__c and/or CallbackType__c not provided for AsyncFunctionInvocationRequest__c ' + afir.Id);
                continue;
            }    
    
            Integer statusCode = afir.StatusCode__c.intValue();
            String error = statusCode < 200 || statusCode > 299 ? afir.Response__c : null;
            System.debug('Processing callback for async request ' + afir.RequestId__c + 
                ', AsyncFunctionInvocationRequest__c ' + afir.Id + ', statusCode ' +statusCode);
            FunctionInvocationImpl invocation = new FunctionInvocationImpl(afir.RequestId__c, 
                                                                           afir.Response__c,
                                                                           error,
                                                                           statusCode,
                                                                           Id.valueOf(afir.Id, true),
                                                                           afir.ExtraInfo__c);
    
            
            try {
                // Deserialize callback and enqueue callback invocation
                Type fullyQualifiedNameCallbackTypeClass = Type.forName(afir.CallbackType__c);
                FunctionCallback callback = (FunctionCallback)JSON.deserializeStrict(afir.Callback__c, 
                    fullyQualifiedNameCallbackTypeClass);
                FunctionCallbackQueueable callbackQueueable = new FunctionCallbackQueueable(callback, invocation);
                ID callbackQueueableId = System.enqueueJob(callbackQueueable);
                System.debug('Enqueued callback ' + fullyQualifiedNameCallbackTypeClass + ' for request ' + 
                    afir.RequestId__c + ', AsyncFunctionInvocationRequest__c ' + afir.Id + 
                    ': FunctionCallbackQueueable job Id ' + callbackQueueableId);
                afirCallbacks.add(afir);
            } catch(Exception ex) {
                System.debug('Unable to process callback for request ' + afir.RequestId__c + 
                    ', AsyncFunctionInvocationRequest__c ' + afir.Id + ': ' + ex.getMessage());
            }
        }

        return afirCallbacks;
    }
}