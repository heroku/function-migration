/**
 * Encapsulates enqueuing an async function callback invocation.  
 * Dequeuing invokes the callback. 
 */
public class FunctionCallbackQueueable implements Queueable {

    // Customer's callback logic.
    private final FunctionCallback callback;

    // Response from the completed Function.
    private final FunctionInvocation invocation;

    /**
     * Constructor to create a queueable function invocation.
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
        this.invocation = invocation;
    }

    public void execute(QueueableContext context) {
        // Once the Function invocation completes,
        // we call the callback and pass the response.
        this.callback.handleResponse(this.invocation);
    }
}