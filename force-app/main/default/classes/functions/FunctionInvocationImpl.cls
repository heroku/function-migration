/**
 * Represents the result of a synchronous or asynchronous function invocation.
 */
global class FunctionInvocationImpl implements FunctionInvocation {
    
    private String requestId;
    private String response;
    private FunctionInvocationStatus status;
    private FunctionInvocationError error;
    private String asyncFunctionInvocationRequestId;
    private Map<String,Object> extraInfoMap;

    public FunctionInvocationImpl(
            String requestId,
            String response,
            String status,
            String errorMessage,
            Integer statusCode,
    		String extraInfoJson) {
        this(requestId, response, status, errorMessage, statusCode, null, extraInfoJson);
    }

    public FunctionInvocationImpl(
            String requestId,
            String response,
            String status,
            String errorMessage,
            Integer statusCode,
            String asyncFunctionInvocationRequestId,
            String extraInfoJson) {
        this.requestId = requestId;
        this.response = response;
        this.status = parseStatus(status);
        this.error = errorMessage == null ? null : new FunctionInvocationErrorImpl(errorMessage, parseErrorType(statusCode));
        this.asyncFunctionInvocationRequestId = asyncFunctionInvocationRequestId;
        if (!String.isBlank(extraInfoJson)) {
            try {
                this.extraInfoMap = (Map<String,Object>)JSON.deserializeUntyped(String.valueOf(EncodingUtil.Base64Decode(extraInfoJson)));
            } catch(Exception ex) {
                System.debug('Unable to parse ExtraInfo: ' + ex.getMessage());
                this.extraInfoMap = new Map<String,Object>();
            }
        }
    }

    global String getInvocationId() {
        return requestId;
    }

    global String getRequestId() {
        return requestId;
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
    
    // Was error in function?
    global Boolean isFunctionError() {
        return Boolean.valueOf(extraInfoMap.get('isFunctionError'));
    }
    
    global Integer getExecTimeMs() {
        return Integer.valueOf(extraInfoMap.get('execTimeMs'));
    }
    
    global String getStacktrace() {
        return String.valueOf(extraInfoMap.get('stack'));
    }

    private FunctionInvocationStatus parseStatus(String val) {
        if (val == 'Success') return FunctionInvocationStatus.SUCCESS;
        if (val == 'Error') return FunctionInvocationStatus.ERROR;
        if (val == 'Pending') return FunctionInvocationStatus.PENDING;
        return null;
    }

    private FunctionErrorType parseErrorType(Integer statusCode) {
        if (statusCode == null || statusCode == 503) return FunctionErrorType.UNEXPECTED_FUNCTION_EXCEPTION;
        if (statusCode == 500) return FunctionErrorType.FUNCTION_EXCEPTION;
        return FunctionErrorType.RUNTIME_EXCEPTION;
    }
}