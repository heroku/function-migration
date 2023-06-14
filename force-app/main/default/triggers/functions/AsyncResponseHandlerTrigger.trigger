/**
 * Handles invoking the FunctionCallback implementations for asynchronous function invocations.
 */
trigger AsyncResponseHandlerTrigger on AsyncFunctionInvocationRequest__c (after update) {
    AsyncResponseHandlerTriggerHandler.handle(Trigger.new);
}