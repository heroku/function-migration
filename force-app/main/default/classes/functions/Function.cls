global class Function {

    public class InvalidFunctionException extends Exception { }

    public class InvalidFunctionInvocationException extends Exception { }

    // TODO: Dynamic look up
    final static String FUNCTION_URL = 'http://localhost:3000';
    final static String SYNC_FUNCTION_URL = FUNCTION_URL + '/sync';
    final static String ASYNC_FUNCTION_URL = FUNCTION_URL + '/async';
    
    // TODO: Dynamic look up - based on SF version or calling API version?
    final static String API_VERSION = '58.0';
    final static String SYNC_TYPE = 'com.salesforce.function.invoke.sync';
    final static String ASYNC_TYPE = 'com.salesforce.function.invoke.async';

    final String namespace;
    final String projectFunctionRef; // <project>_<function>
    final FunctionReference__mdt functionReference;

    // No public constructor, so that this class has factory semantics.
    // (The developer should think of it as "looking up" a Function rather than creating one.)
    private Function(String namespace, String projectFunctionRef, FunctionReference__mdt functionReference) {
        this.namespace = namespace;
        this.projectFunctionRef = projectFunctionRef;
        this.functionReference = functionReference;
    }

    public String getFunctionName() {
        return (!String.isBlank(namespace) ? namespace + '.'  : '') + projectFunctionRef;
    }

    /**
     * Get reference to given function in <project>.<function> format, eg 'MyProject.MyFunction'.
     * Parent component's namespace is used.
     * Throws NoDataFoundException when FunctionReference is not found.
     */
    global static Function get(String projectFunctionRef) {
        // TODO: Move to utility method
        FunctionReference__mdt functionReference = null;
        try {
            functionReference = [SELECT MasterLabel, DeveloperName, Endpoint__c FROM FunctionReference__mdt WHERE DeveloperName = :projectFunctionRef];
        } catch (Exception ex) {
            System.debug('Unable to retrieve FunctionReference__mdt for ' + projectFunctionRef + ': ' + ex.getMessage());
        }        
        if (null == functionReference || null == functionReference.Endpoint__c) {
            throw new InvalidFunctionException('Invalid function: ' + projectFunctionRef);
        }

        // null namespace applies component's namespace
        return new Function(null, projectFunctionRef, functionReference);
    }

    /**
     * Get reference to given function in <project>.<function> format, eg 'MyProject.MyFunction'.
     * Throws NoDataFoundException when FunctionReference is not found.
     *
     * Empty namespace ('') designates applying organization's namespace for FunctionReference lookup.
     * null namespace designates applying parent component's namespace for FunctionReference lookup.
     */
    global static Function get(String namespace, String projectFunctionRef) {
        // TODO: Handle namespace
        // TODO: Move to utility method
        FunctionReference__mdt functionReference = null;
        try {
            functionReference = [SELECT MasterLabel, DeveloperName, Endpoint__c FROM FunctionReference__mdt WHERE DeveloperName = :projectFunctionRef];
        } catch (Exception ex) {
            System.debug('Unable to retrieve FunctionReference__mdt for ' + projectFunctionRef + ': ' + ex.getMessage());
        }       
        if (null == functionReference || null == functionReference.Endpoint__c) {
            throw new InvalidFunctionException('Invalid function: ' + projectFunctionRef);
        }

        return new Function(namespace, projectFunctionRef, functionReference);
    }

    /**
     * Synchronously invoke function.     * 
     */
    global FunctionInvocation invoke(String payloadJson) {
        return invoke(payloadJson, new List<String>());
    }

    global FunctionInvocation invoke(String payloadJson, List<String> sessionBasedPermSets) {
        if (!String.isBlank(payloadJson)) {
            // REVIEWME: This may bloat head size; worth checking?
            try {
                JSON.deserializeUntyped(payloadJson);
            } catch(Exception ex) {
                throw new InvalidFunctionInvocationException('Invalid payload format: expected JSON');
            }
        }

        String requestId = generateRequestId('');  // TODO: Fix null
        FunctionInvocationRequest functionRequestHeader = generateContext(requestId, 
                                                                          SYNC_TYPE, 
                                                                          functionReference.Endpoint__c + '/sync', 
                                                                          '',
                                                                          sessionBasedPermSets);

        System.debug('Invoking sync function ' + getFunctionName() + ' [' + requestId + ']');

        Http httpConn = new Http();
        HttpRequest functionRequest = new HttpRequest();
        functionRequest.setEndpoint(functionRequestHeader.getContext().resource);
        functionRequest.setMethod('POST');
        functionRequest.setHeader('Content-Type', 'application/json');
        // TODO: getSessionId() is null for AutoProc user
        // REVIEWME: SID is used to validate the incoming request is from a user in this org
        functionRequest.setHeader('Authorization', 'Bearer ' + System.UserInfo.getSessionId());
        functionRequest.setHeader('request-id', functionRequestHeader.getContext().id); // To be logged by proxy framework
        functionRequest.setHeader('X-Request-Id', functionRequestHeader.getContext().id);
        functionRequest.setHeader('X-Context', functionRequestHeader.toEncodedJSON());
        functionRequest.setTimeout(120000);
        functionRequest.setBody(payloadJson);
        
        FunctionInvocationStatus status = FunctionInvocationStatus.SUCCESS;
        Integer statusCode = 0;
        String body = '';
        String error = '';
        String extraInfo = '';
        Long startTime = DateTime.now().getTime();
        try {
            HttpResponse functionResponse = httpConn.send(functionRequest);
            statusCode = functionResponse.getStatusCode();
            body = functionResponse.getBody();
            extraInfo = functionResponse.getHeader('x-extra-info');
        } catch(Exception ex) {
            body = ex.getMessage();
            error = ex.getMessage(); // REVIEWME
            status = FunctionInvocationStatus.ERROR;
        }

        Long totalTime = DateTime.now().getTime() - startTime;

        System.debug('Invoked sync function ' + getFunctionName() + ' in ' + totalTime + 'ms' + ' [' + requestId + ']');
        System.debug('Extra info: ' + extraInfo + ' [' + requestId + ']');

        if (200 != statusCode) {
            System.debug('FAILURE: Async invocation request for function ' + getFunctionName() + ' [' + statusCode + ']: ' +
                body + ' [' + requestId + ']');
        } else {
            System.debug('Successfully sent async invocation request for function ' + getFunctionName() + ' [' + requestId + ']');
        }

        // TODO: Review status and error values/fields
        return new FunctionInvocationImpl(functionRequestHeader.getContext().id,
                                          body,
                                          status.name(),
                                          error,
                                          statusCode,
                                          null);
    }

    /**
     * Asynchronously invoke function.
     */
    global FunctionInvocation invoke(String payloadjson, FunctionCallback callback) {
        return invoke(payloadjson, new List<String>(), callback);
    }

    global FunctionInvocation invoke(String payloadjson, List<String> sessionBasedPermSets, FunctionCallback callback) {
        if (null == callback) {
            throw new InvalidFunctionInvocationException('FunctionCallback not provided');
        }

        if (!String.isBlank(payloadJson)) {
            // REVIEWME: This may bloat head size; worth checking?
            try {
                JSON.deserializeUntyped(payloadJson);
            } catch(Exception ex) {
                throw new InvalidFunctionInvocationException('Invalid payload format: expected JSON');
            }
        }

        // TODO: Set AFIR fields as required - callback, eg
        // TODO: Handle namespace in Type.forName
        String callbackType = '';
        try {
            // Yuck, but this is what it takes to get inner class names 
            DateTime typeCheck = (DateTime) callback;
        } catch (System.TypeException expectedTypeException) {
            String message = expectedTypeException.getMessage()
                .substringAfter('Invalid conversion from runtime type ');
            callbackType = message.substringBefore(' to Datetime');
        }
        System.debug('Saving CallbackType__c: ' + callbackType);
        AsyncFunctionInvocationRequest__c asyncFIR = new AsyncFunctionInvocationRequest__c(
            Request__c = payloadjson,
            Callback__c = JSON.serialize(callback),
            CallbackType__c = callbackType
        );
        insert asyncFIR;

        // Generate context and save to AFIR
        String resource = functionReference.Endpoint__c + '/async';
        String requestId = generateRequestId(asyncFIR.Id);
        String functionRequestHeaderJson = generateContext(requestId, 
                                                           ASYNC_TYPE, 
                                                           resource, 
                                                           asyncFIR.Id,
                                                           sessionBasedPermSets)
                                                           .toEncodedJSON();
        asyncFIR.RequestId__c = requestId;
        asyncFIR.Context__c = functionRequestHeaderJson;
        upsert asyncFIR;

        Function.invokeAsyncFuture(getFunctionName(), 
                                   requestId, 
                                   resource, 
                                   payloadjson, 
                                   functionRequestHeaderJson, 
                                   System.UserInfo.getSessionId(),
                                   asyncFIR.Id);
        System.debug('Queued async function invocation of function ' + getFunctionName() + ' [' + requestId + ']');

        return new FunctionInvocationImpl(requestId, '', FunctionInvocationStatus.PENDING.name(), '', 0, asyncFIR.Id);
    }

    private String generateRequestId(String uuid) {
        Long requestTime = DateTime.now().getTime();
        if ('' == uuid) {
            uuid = EncodingUtil.base64encode(Crypto.generateDigest('SHA1', Blob.valueOf(getFunctionName() + requestTime)));
        }

        return System.UserInfo.getOrganizationId() + '-' + 
            Request.getCurrent().getRequestId() + '-' + 
            uuid + '-' + 
            getFunctionName() + '-' +
            DateTime.now().getTime();
    }

    private FunctionInvocationRequest generateContext(String requestId,
                                                      String type, 
                                                      String resource,
                                                      String asyncFunctionInvocationRequestId,
                                                      List<String> sessionBasedPermSets) {
        String instanceName = [SELECT InstanceName FROM Organization LIMIT 1].InstanceName;
        // TODO: Get Id of calling Apex class
        String classId = [SELECT Id FROM ApexClass WHERE Name = 'Function'].Id;
        return new FunctionInvocationRequest.FunctionInvocationRequestBuilder()
            .context(new FunctionInvocationRequest.ContextBuilder()
                .id(requestId)
                // TODO: API version of invoking class or latest API version?
                .apiVersion(API_VERSION)
                .function(projectFunctionRef)
                // TODO: URL of function
                .resource(resource)
                .source('urn:event:from:salesforce/' + instanceName + '/' + System.UserInfo.getOrganizationId() + '/apex/' + classId)
                .type(type)
                .namespace(this.namespace)
                .asyncFunctionInvocationRequestId(asyncFunctionInvocationRequestId)
                .permissionSets(sessionBasedPermSets)
                .build())
            .userContext(new FunctionInvocationRequest.UserContextBuilder()
                .orgId(System.UserInfo.getOrganizationId())
                .userId(System.UserInfo.getUserId())
                .userName(System.UserInfo.getUserName())
                .salesforceBaseUrl(System.URL.getSalesforceBaseUrl().toExternalForm())
                .orgDomainUrl(System.URL.getOrgDomainUrl().toExternalForm())
                .build())
            .build();
    }

    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_annotation_future.htm
    /**
     * Use the Future annotation to identify methods that are executed asynchronously. When you specify Future,
     * the method executes when Salesforce has available resources.
     * 
     * Complex type parameters are not permitted.
     */
    @Future(callout=true)
    private static void invokeAsyncFuture(String functionName,
                                          String requestId,
                                          String resource,
                                          String payloadJson,
                                          String functionRequestContextJson,
                                          String sessionId,
                                          String asyncFunctionInvocationRequestId) {

        System.debug('Invoke async function ' + functionName + ' [' + requestId + ']');

        Http httpConn = new Http();
        HttpRequest functionRequest = new HttpRequest();
        functionRequest.setEndpoint(resource);
        functionRequest.setMethod('POST');
        functionRequest.setHeader('Content-Type', 'application/json');
        // TODO: getSessionId() is null for AutoProc user
        functionRequest.setHeader('Authorization', 'Bearer ' + sessionId);
        functionRequest.setHeader('request-id', requestId); // To be logged by proxy framework
        functionRequest.setHeader('X-Request-Id', requestId);
        functionRequest.setHeader('X-Context', functionRequestContextJson);
        functionRequest.setTimeout(120000);
        functionRequest.setBody(payloadJson);
        
        Integer statusCode = 0;
        String body = '';
        String extraInfo = '';
        Long startTime = DateTime.now().getTime();
        try {
            HttpResponse functionResponse = httpConn.send(functionRequest);
            statusCode = functionResponse.getStatusCode();
            body = functionResponse.getBody();
            extraInfo = functionResponse.getHeader('x-extra-info');
            // TODO: Validate request and response requestId

        } catch(Exception ex) {
            body = ex.getMessage();
        }
        
        Long totalTime = DateTime.now().getTime() - startTime;

        System.debug('Sent async invocation request for function ' + functionName + ' in ' + totalTime + 'ms' + ' [' + requestId + ']');

        String status = FunctionInvocationStatus.PENDING.name();
        if (201 != statusCode) {
            System.debug('FAILURE: Unsuccessfully sent async invocation request for function ' + functionName + ' [' + statusCode + ']: ' +
                body + ' [' + requestId + ']');
            status = FunctionInvocationStatus.ERROR.name();
        } else {
            System.debug('Successfully sent async invocation request for function ' + functionName + ' [' + requestId + ']');
        }

        AsyncFunctionInvocationRequest__c afir = [SELECT Id FROM AsyncFunctionInvocationRequest__c WHERE Id = :asyncFunctionInvocationRequestId];
        afir.Status__c = status;
        afir.StatusCode__c = statusCode;
        afir.Response__c = body;
        afir.ExtraInfo__c = extraInfo;
        update afir;

        System.debug('Updated AsyncFunctionInvocationRequest__c[' + asyncFunctionInvocationRequestId + '] for function ' + functionName + ' [' + requestId + ']');
    }
}