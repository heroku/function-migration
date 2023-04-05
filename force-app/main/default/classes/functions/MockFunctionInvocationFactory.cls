global class MockFunctionInvocationFactory {
    // creates a FunctionInvocation that has status ERROR and a given FunctionErrorType and a given errMsg
    global static FunctionInvocation createErrorResponse(String invocationId, FunctionErrorType functionsErrorType, String errMsg) {
        return new FunctionInvocationImpl(invocationId, '', FunctionInvocationStatus.ERROR.name(), errMsg, 500, '');
    }
    // creates a Function that has status SUCCESS with a given response string
    global static FunctionInvocation createSuccessResponse(String invocationId, String response) {
        return new FunctionInvocationImpl(invocationId, response, FunctionInvocationStatus.SUCCESS.name(), '', 200, '');
    }
}