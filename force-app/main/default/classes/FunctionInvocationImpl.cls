global class FunctionInvocationImpl implements FunctionInvocation {
    private String invocationId;
    private String response;
    private FunctionInvocationStatus status;
    private FunctionInvocationError error;

    public FunctionInvocationImpl(
            String invocationId,
            String response,
            String status,
            String errorMessage,
            Integer statusCode) {
        this.invocationId = invocationId;
        this.response = response;
        this.status = parseStatus(status);
        this.error = errorMessage == null ? null : new FunctionInvocationErrorImpl(errorMessage, parseErrorType(statusCode));
    }

    // Parse in Apex, because it's a lot less cryptic than constructing an Apex enum in Java.
    private FunctionInvocationStatus parseStatus(String val) {
        if (val == 'Success') return FunctionInvocationStatus.SUCCESS;
        if (val == 'Error') return FunctionInvocationStatus.ERROR;
        if (val == 'Pending') return FunctionInvocationStatus.PENDING;
        return null;
    }

    // Parse in Apex, because it's a lot less cryptic than constructing an Apex enum in Java.
    private FunctionErrorType parseErrorType(Integer statusCode) {
        if (statusCode == null || statusCode == 503) return FunctionErrorType.UNEXPECTED_FUNCTION_EXCEPTION;
        if (statusCode == 500) return FunctionErrorType.FUNCTION_EXCEPTION;
        return FunctionErrorType.RUNTIME_EXCEPTION;
    }

    global String getInvocationId() {
        return invocationId;
    }

    global String getResponse() {
        return response;
    }

    global FunctionInvocationStatus getStatus() {
        return status;
    }

    global FunctionInvocationError getError() {
        return error;
    }
}
