public class FunctionInvocationErrorImpl implements FunctionInvocationError {
    private String message;
    private FunctionErrorType type;

    public FunctionInvocationErrorImpl(String message, FunctionErrorType type) {
        this.message = message;
        this.type = type;
    }

    public String getMessage() {
        return message;
    }

    public FunctionErrorType getType() {
        return type;
    }
}