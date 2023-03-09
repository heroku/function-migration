global interface FunctionInvocationError {
    /**
     * @return the error message associated with this error
     */
    String getMessage();

    /**
     * @return the error type associated with this error
     */
    FunctionErrorType getType();
}