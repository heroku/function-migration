global interface FunctionInvocation {
    /**
     * @return the unique ID of this Function invocation
     */
    String getInvocationId();

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
     * @return true if error occurred in the function
     */
    Boolean isFunctionError();
    
    /**
     * @return function execution time in milliseconds
     */
    Integer getExecTimeMs();
    
    /**
     * @return stracktrace of error
     */
    String getStacktrace();
}