/**
 * Represents the result of a synchronous or asynchronous function invocation.
 */
public class FunctionInvocationImpl implements FunctionInvocation {
    
    private final String requestId;
    private final String response;
    private final FunctionInvocationStatus status;
    private final FunctionInvocationError error;
    private final String asyncFunctionInvocationRequestId;
    private final String encodedExtraInfoJson;
    private final Map<String,Object> extraInfoMap;

    public FunctionInvocationImpl(String requestId,
                                  String asyncFunctionInvocationRequestId) {
        this(requestId, null, null, 0, asyncFunctionInvocationRequestId, null);
    }

    public FunctionInvocationImpl(String requestId,
                                  String response,
                                  String errorMessage,
                                  Integer statusCode,
                                  String encodedExtraInfoJson) {
        this(requestId, response, errorMessage, statusCode, null, encodedExtraInfoJson);
    }

    public FunctionInvocationImpl(String requestId,
                                  String response,
                                  String errorMessage,
                                  Integer statusCode,
                                  String asyncFunctionInvocationRequestId,
                                  String encodedExtraInfoJson) {
        this.requestId = requestId;
        this.response = response;
        this.status = parseStatus(statusCode);
        this.error = errorMessage == null ? null : new FunctionInvocationErrorImpl(errorMessage, parseErrorType(statusCode));
        this.asyncFunctionInvocationRequestId = asyncFunctionInvocationRequestId;
        this.encodedExtraInfoJson = encodedExtraInfoJson;
        if (!String.isBlank(encodedExtraInfoJson)) {
            try {
                this.extraInfoMap = (Map<String,Object>)JSON.deserializeUntyped(EncodingUtil.urlDecode(encodedExtraInfoJson, 'UTF-8'));
            } catch(Exception ex) {
                System.debug('Unable to decode and parse ExtraInfo: ' + ex.getMessage());
                this.extraInfoMap = new Map<String,Object>();
            }
        } else {
            this.extraInfoMap = new Map<String,Object>();
        }
    }

    public String getInvocationId() {
        return requestId;
    }

    public String getAsyncFunctionInvocationRequestId() {
        return asyncFunctionInvocationRequestId;
    }

    public String getRequestId() {
        return requestId;
    }

    public String getResponse() {
        return response;
    }

    public FunctionInvocationStatus getStatus() {
        return status;
    }

    public FunctionInvocationError getError() {
        return error;
    }

    public String getEncodedExtraInfoJson() {
        return encodedExtraInfoJson;
    }
    
    // Was error in function?
    public Boolean isFunctionError() {
        return extraInfoMap.get('isFunctionError') != null ? Boolean.valueOf(extraInfoMap.get('isFunctionError')) : false;
    }
    
    public Integer getExecTimeMs() {
        return extraInfoMap.get('execTimeMs') != null ? Integer.valueOf(extraInfoMap.get('execTimeMs')) : 0;
    }
    
    public String getStacktrace() {
        return extraInfoMap.get('stack') != null ? String.valueOf(extraInfoMap.get('stack')) : '';
    }

    public Integer getStatusCode() {
        return Integer.valueOf(extraInfoMap.get('statusCode'));
    }

    private FunctionInvocationStatus parseStatus(Integer statusCode) {
        switch on statusCode {
            when 0 {
                return FunctionInvocationStatus.PENDING;
            }
            when 200 {
                return FunctionInvocationStatus.SUCCESS;
            }	
            when 201 {
                return FunctionInvocationStatus.PENDING;
            }
            when else {
                return FunctionInvocationStatus.ERROR;
            }
        }
    }

    private FunctionErrorType parseErrorType(Integer statusCode) {
        if (statusCode == null || statusCode > 500) {
            return FunctionErrorType.UNEXPECTED_FUNCTION_EXCEPTION;
        }
        
        if (statusCode == 500) {
            return FunctionErrorType.FUNCTION_EXCEPTION;
        }
        
        return FunctionErrorType.RUNTIME_EXCEPTION;
    }
}