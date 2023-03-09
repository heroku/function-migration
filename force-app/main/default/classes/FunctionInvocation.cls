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
}