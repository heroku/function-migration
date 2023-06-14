public interface FunctionInvocation {

    /**
     * @return the unique ID of this Function invocation request
     */
    String getInvocationId();

    /**
     * @return for async requests, the unique ID of the associated AsyncFunctionInvocationRequest__c record
     */
    String getAsyncFunctionInvocationRequestId();

    /**
     * @return the response payload, if any, returned by the Function
     */
    String getResponse();

    /**
     * @return the current execution status of this Function invocation
     */
    FunctionInvocationStatus getStatus();

    /**
     * @return the error, if any, that occurred during this Function invocation
     */
    FunctionInvocationError getError();

    /**
     * @return 'x-extra-info' header value
     */
    String getEncodedExtraInfoJson();

    /**
     * @return true if error occurred in the function (from 'x-extra-info' header)
     */
    Boolean isFunctionError();
    
    /**
     * @return function execution time in milliseconds (from 'x-extra-info' header)
     */
    Integer getExecTimeMs();
    
    /**
     * @return stracktrace of error (from 'x-extra-info' header)
     */
    String getStacktrace();

    /**
     * @return statusCode (from 'x-extra-info' header)
     */
    Integer getStatusCode();
}