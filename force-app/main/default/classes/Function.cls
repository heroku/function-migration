global class Function {

    // TODO: Dynamic look up
    final static String FUNCTION_URL = 'http://localhost:8080';
    // TODO: Dynamic look up - based on SF version or calling API version?
    final static String API_VERSION = '58.0';

    final String namespace;
    final String projectFunctionRef; // <project>.<function>

    // No public constructor, so that this class has factory semantics.
    // (The developer should think of it as "looking up" a Function rather than creating one.)
    private Function(String namespace, String projectFunctionRef) {
        this.namespace = namespace;
        this.projectFunctionRef = projectFunctionRef;
    }

    /**
     * Get reference to given function in <project>.<function> format, eg 'MyProject.MyFunction'.
     * Parent component's namespace is used.
     * Throws NoDataFoundException when FunctionReference is not found.
     */
    global static Function get(String projectFunctionRef) {
        // null namespace applies component's namespace
        return new Function(null, projectFunctionRef);
    }

    /**
     * Get reference to given function in <project>.<function> format, eg 'MyProject.MyFunction'.
     * Throws NoDataFoundException when FunctionReference is not found.
     *
     * Empty namespace ('') designates applying organization's namespace for FunctionReference lookup.
     * null namespace designates applying parent component's namespace for FunctionReference lookup.
     */
    global static Function get(String namespace, String projectFunctionRef) {
        return new Function(namespace, projectFunctionRef);
    }

    /**
     * Synchronous entry point for developers on the platform.
     * Also used by FunctionCallbackQueueable internally.
     */
    global FunctionInvocation invokeSync(String payload) {
        FunctionInvocationRequest functionRequestHeader = 
            generateContext('uuid', 'sync', FUNCTION_URL, '');
        Http httpConn = new Http();
        HttpRequest functionRequest = new HttpRequest();
        functionRequest.setEndpoint(functionRequestHeader.getContext().resource);
        functionRequest.setMethod('POST');
        functionRequest.setHeader('Content-Type', 'application/json');
        // TODO: getSessionId() is null for AutoProc user
        functionRequest.setHeader('Authorization', 'Bearer ' + System.UserInfo.getSessionId());
        functionRequest.setHeader('X-Request-Id', functionRequestHeader.getContext().id);
        functionRequest.setHeader('X-Context', functionRequestHeader.toEncodedJSON());
        functionRequest.setBody(payload);
        HttpResponse functionResponse = httpConn.send(functionRequest);
        String functionResponseBody = functionResponse.getBody();
        // TODO: Review status and error values/fields
        return new FunctionInvocationImpl(functionRequestHeader.getContext().id, functionResponseBody, FunctionInvocationStatus.SUCCESS.name(), '', functionResponse.getStatusCode());
    }

    /**
     * Asynchronous entry point for developers on the platform.
     */
    global FunctionInvocation invokeAsync(String payload, FunctionCallback callback) {       
        // TODO: Set AFIR fields as required - callback, eg
        AsyncFunctionInvocationRequest__c asyncFIR = new AsyncFunctionInvocationRequest__c(
            Request__c = payload,
            Callback__c = JSON.serialize(callback)
        );
        insert asyncFIR;

        // Generate context
        String requestId = generateRequestId(asyncFIR.Id);
        String functionRequestHeaderJson = 
            generateContext(requestId, 'async', FUNCTION_URL, '/services/data/v' + API_VERSION + '/sobjects/AsyncFunctionInvocationRequest__c/' + asyncFIR.Id).toEncodedJSON();
        asyncFIR.RequestId__c = requestId;
        asyncFIR.Context__c = functionRequestHeaderJson;
        upsert asyncFIR;

        Function.invokeAsyncFuture(requestId, FUNCTION_URL, payload, functionRequestHeaderJson, System.UserInfo.getSessionId());

        return new FunctionInvocationImpl(requestId, '', FunctionInvocationStatus.PENDING.name(), '', 0);
    }

    private String generateRequestId(String uuid) {
        return System.UserInfo.getOrganizationId() + '-' + 
            Request.getCurrent().getRequestId() + '-' + 
            uuid + '-' + 
            this.projectFunctionRef + '-' + 
            DateTime.now().millisecondGMT();
    }

    private FunctionInvocationRequest generateContext(String requestId, 
                                                      String type, 
                                                      String resource,
                                                      String asyncFunctionInvocationRequestCallbackUrl) {
        String functionUrl = FUNCTION_URL;
        return new FunctionInvocationRequest.FunctionInvocationRequestBuilder()
            .context(new FunctionInvocationRequest.ContextBuilder()
                // TODO: Lib to genreate UUID
                .id(requestId)
                // TODO: API version of invoking class or latest API version?
                .apiVersion(API_VERSION)
                .function(projectFunctionRef)
                // TODO: URL of function
                .resource(resource)
                // TODO: Get Id of calling Apex class
                .source(System.UserInfo.getOrganizationId() + '/apex/' + 'IDofInvocationClass')
                .type(type)
                .namespace(this.namespace)
                .asyncFunctionInvocationRequestCallbackUrl(asyncFunctionInvocationRequestCallbackUrl)
                .build())
            .userContext(new FunctionInvocationRequest.UserContextBuilder()
                .orgId(System.UserInfo.getOrganizationId())
                .userId(System.UserInfo.getUserId())
                .userName(System.UserInfo.getUserName())
                .salesforceBaseUrl(System.URL.getSalesforceBaseUrl())
                .orgDomainUrl(System.URL.getOrgDomainUrl())
                .build())
            .build();
    }

    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_annotation_future.htm
    @Future(callout=true)
    private static void invokeAsyncFuture(String requestId, 
                                          String resource, 
                                          String payload,                                           
                                          String functionRequestContextJson, 
                                          String sessionId) {
        Http httpConn = new Http();
        HttpRequest functionRequest = new HttpRequest();
        functionRequest.setEndpoint(resource);
        functionRequest.setMethod('POST');
        functionRequest.setHeader('Content-Type', 'application/json');
        // TODO: getSessionId() is null for AutoProc user
        functionRequest.setHeader('Authorization', 'Bearer ' + sessionId);
        functionRequest.setHeader('X-Request-Id', requestId);
        functionRequest.setHeader('X-Context', functionRequestContextJson);
        functionRequest.setBody(payload);
        HttpResponse functionResponse = httpConn.send(functionRequest);
        String functionResponseBody = functionResponse.getBody();
        System.debug('Function response for request ' + requestId + ': ' + functionResponseBody + ', status ' + functionResponse.getStatusCode());
    }
}