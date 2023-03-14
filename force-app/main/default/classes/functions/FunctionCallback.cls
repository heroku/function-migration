global interface FunctionCallback {
    /**
     * The method that is invoked after the Function invocation completes.
     * In the future, String result will be replaced by a rich result object.
     *
     * @param result the result of the Function invocation
     */
    void handleResponse(FunctionInvocation result);
}