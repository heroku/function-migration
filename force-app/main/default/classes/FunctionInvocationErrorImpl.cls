global class FunctionInvocationErrorImpl implements FunctionInvocationError {
    private String message;
    private FunctionErrorType type;

    public FunctionInvocationErrorImpl(String message, FunctionErrorType type) {
        this.message = message;
        this.type = type;
    }

    global String getMessage() {
        return message;
    }

    global FunctionErrorType getType() {
        return type;
    }
}
