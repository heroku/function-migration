public class FunctionCallbackQueueable implements Queueable {
    // Customer's callback logic.
    // Used by both PSEUDO ASYNC and TRUE ASYNC.
    private final FunctionCallback callback;

    // Response from the completed Function.
    // Used by both PSEUDO ASYNC and TRUE ASYNC.
    private final FunctionInvocation invocation;

    // The Function to invoke, and the payload to pass it.
    // Used *only* by PSEUDO ASYNC.
    // For True Async, the invocation has already occurred
    // before this queueable even gets involved.
    private final Function function;
    private final String requestPayload;

    /**
     * Constructor to create a queueable for TRUE ASYNC direct invocation.
     *
     * All it needs to know is the logic to invoke on completion,
     * and the response from the Function to pass to the callback,
     * since the Function has already been invoked by the time we're constructing this queueable.
     *
     * @param callback the callback implemented by the customer Apex developer
     * @param invocationStatus Function invocation status to be passed to the callback
     */
    public FunctionCallbackQueueable(FunctionCallback callback, FunctionInvocation invocation) {
        this.callback = callback;
        this.function = null;
        this.requestPayload = null;
        this.invocation = invocation;
    }

    /**
     * Constructor to create a queueable for PSEUDO ASYNC direct invocation.
     *
     * It needs to know how to invoke the Function *and* how to perform the callback,
     * since it is responsible for both steps.

     * @param callback the callback implemented by the customer Apex developer
     * @param function the Function to invoke
     * @param requestPayload payload to be passed to the Function
     */
    public FunctionCallbackQueueable(FunctionCallback callback, Function function, String requestPayload) {
        this.callback = callback;
        this.function = function;
        this.requestPayload = requestPayload;
        this.invocation = null;  // Will be filled out after invocation.
    }

    public void execute(QueueableContext context) {
        // Once the Function invocation completes,
        // we call the customer's callback and pass the response.
        this.callback.handleResponse(this.invocation);
    }
}