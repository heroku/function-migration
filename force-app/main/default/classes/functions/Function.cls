global class Function {

    public class InvalidFunctionException extends Exception { }

    public class InvalidFunctionInvocationException extends Exception { }
    
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
        System.debug('Endpoint for ' + projectFunctionRef + ' FunctionReference__mdt: ' + functionReference.Endpoint__c);
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
        // null namespace applies component's namespace
        return get(null, projectFunctionRef);
    }

    /**
     * Get reference to given function in <project>.<function> format, eg 'MyProject.MyFunction'.
     * Throws NoDataFoundException when FunctionReference is not found.
     *
     * Empty namespace ('') designates applying organization's namespace for FunctionReference lookup.
     * null namespace designates applying parent component's namespace for FunctionReference lookup.
     */
    global static Function get(String namespace, String projectFunctionRef) {
        FunctionReference__mdt functionReference = null;
        try {
            functionReference = [SELECT Endpoint__c, PermissionSetOrGroup__c FROM FunctionReference__mdt WHERE DeveloperName = :projectFunctionRef AND NamespacePrefix = :namespace];
        } catch (Exception ex) {
            System.debug('Unable to retrieve FunctionReference__mdt for ' + namespace + '__' + projectFunctionRef + ': ' + ex.getMessage());
        }       
        
        // Ensure exists and has endpoint
        if (null == functionReference || null == functionReference.Endpoint__c) {
            throw new InvalidFunctionException('Invalid function: ' + projectFunctionRef);
        }
        
        // If provided, ensure that:
        // (1) PermissionSet or PermissionSetGroup exists, 
        // (2) user is assigned to PermissionSet or PermissionSetGroup, and 
        // (3) PermissionSet or PermissionSetGroup is session-based.
        if (null != functionReference.PermissionSetOrGroup__c) {
            List<PermissionSetAssignment> assignments = null;
            try {
                assignments = 
                	[SELECT PermissionSet.HasActivationRequired FROM PermissionSetAssignment WHERE Assignee.Id = :UserInfo.getUserId() AND PermissionSet.Name = :functionReference.PermissionSetOrGroup__c];
            } catch (Exception ex) {
                throw new InvalidFunctionException('Unable to validate PermissionSetAssignment for user ' + UserInfo.getUserName() + ' and PermissionSetOrGroup \'' + functionReference.PermissionSetOrGroup__c + '\': '+ ex.getMessage());
            }
            
            if (null == assignments || assignments.size() == 0 || assignments.get(1).PermissionSet.HasActivationRequired == false) {
                throw new InvalidFunctionException('PermissionSetOrGroup \'' + functionReference.PermissionSetOrGroup__c + '\' not found or user ' + UserInfo.getUserName() + ' is not assigned or PermissionSetOrGroup is not session-based.');
            }            
        }

        return new Function(namespace, projectFunctionRef, functionReference);
    }

    /**
     * Synchronously invoke function.
     */
    global FunctionInvocation invoke(String payloadJson) {
        return invoke(payloadJson, new List<String>());
    }
    
    /**
     * Synchronously invoke function activating given session-based Permission Sets defining function org access.
     */
    global FunctionInvocation invoke(String payloadJson, List<String> sessionBasedPermSets) {
        return invoke(new FunctionsMetadataAuthProvider(functionReference), payloadJson, sessionBasedPermSets);
    }

    /**
     * Synchronously invoke function generating a token with given FunctionsAuthProvider and activating given 
     * session-based Permission Sets that define function's org access.
     */
    global FunctionInvocation invoke(FunctionsAuthProvider authProvider, String payloadJson, List<String> sessionBasedPermSets) {
        String accessToken = authProvider.generateToken();
        if (null == accessToken) {
            throw new InvalidFunctionInvocationException('AccessToken not provided');
        }
        
        String requestTime = Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        String requestId = generateRequestId(requestTime);
        String resource = functionReference.Endpoint__c + '/sync';
        FunctionInvocationRequest functionRequestContext = generateContext(requestId,
                                                                           functionReference.APIVersion__c,
                                                                           SYNC_TYPE, 
                                                                           resource, 
                                                                           requestTime,
                                                                           '',
                                                                           sessionBasedPermSets);

        HttpRequest functionRequest = Function.generateRequest(requestId,
                                                               resource,
                                                               payloadJson,
                                                               functionRequestContext,
                                                               accessToken);
        functionRequest.setTimeout(120000);
        
        FunctionInvocationStatus status = FunctionInvocationStatus.SUCCESS;
        Integer statusCode = 0;
        String body = '';
        String error = '';
        String extraInfo = '';
        Long startTime = DateTime.now().getTime();
        try {
            System.debug('Invoking sync function ' + getFunctionName() + ' [' + requestId + ']...');
            Http httpConn = new Http();
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

        if (200 != statusCode) {
            System.debug('FAILURE: Sync invocation request for function ' + getFunctionName() + ' [' + statusCode + ']: ' +
                body + ' [' + requestId + ']');
        } else {
            System.debug('Successfully sent async invocation request for function ' + getFunctionName() + ' [' + requestId + ']');
        }

        // TODO: Review status and error values/fields
        return new FunctionInvocationImpl(requestId,
                                          body,
                                          status.name(),
                                          error,
                                          statusCode,
                                          null,
                                          extraInfo);
    }

    /**
     * Asynchronously invoke function.
     */
    global FunctionInvocation invoke(String payloadJson, FunctionCallback callback) {
        return invoke(payloadJson, new List<String>(), callback);
    }
    
    /**
     * Asynchronously invoke function activating given session-based Permission Sets that define function's org access.
     */
    global FunctionInvocation invoke(String payloadjson, 
                                     List<String> sessionBasedPermSets, 
                                     FunctionCallback callback) {
        return invoke(new FunctionsMetadataAuthProvider(functionReference), payloadJson, sessionBasedPermSets, callback);
    }

    /**
     * Asynchronously invoke function generating a token with given FunctionsAuthProvider and activating given 
     * session-based Permission Sets that define function's org access.
     */
    global FunctionInvocation invoke(FunctionsAuthProvider authProvider, 
                                     String payloadJson, 
                                     List<String> sessionBasedPermSets, 
                                     FunctionCallback callback) {
        if (null == authProvider) {
            throw new InvalidFunctionInvocationException('FunctionsAuthProvider not provided');
        }
                                         
        String accessToken = authProvider.generateToken();
        if (null == accessToken) {
            throw new InvalidFunctionInvocationException('AccessToken not provided');
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
        String requestTime = Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        String requestId = generateRequestId(asyncFIR.Id, requestTime);
        FunctionInvocationRequest functionInvocationRequest = generateContext(requestId, 
                                                                              functionReference.APIVersion__c,
                                                                              ASYNC_TYPE, 
                                                                              resource, 
                                                                              requestTime,
                                                                              asyncFIR.Id,
                                                                              sessionBasedPermSets);
		String functionRequestHeaderJson = functionInvocationRequest.toJSON();
        asyncFIR.RequestId__c = requestId;
        asyncFIR.Context__c = functionRequestHeaderJson;
        upsert asyncFIR;

        Function.invokeAsyncFuture(getFunctionName(), 
                                   requestId, 
                                   resource, 
                                   payloadjson, 
                                   functionRequestHeaderJson, 
                                   accessToken,
                                   asyncFIR.Id);
        System.debug('Queued async function invocation of function ' + getFunctionName() + ' [' + requestId + ']');

        return new FunctionInvocationImpl(requestId, '', FunctionInvocationStatus.PENDING.name(), '', 0, asyncFIR.Id);
    }
    

    //   P R I V A T E

    private String generateRequestId(String requestTime) {
        return generateRequestId(null, requestTime);
    }
    
    /**
     * Generate unique request id used to track the function's request.
     * 
     * Format: <OrgId>-<Current Request Id>-<UUID or AsyncFunctionInvocationRequest__c.Id>-<Function Name>-<Datetime>
     * Eg: 00Dxx0000006IYJEA2-4Y4W3Lw_LkoskcHdEaZze-[UUID or AsyncFunctionInvocationRequest__c.Id]-MyFunction-2023-03-23T15:18:53.429-0700
     */
    private String generateRequestId(String uuid, String requestTime) {
        if (null == uuid) {
            uuid = EncodingUtil.base64encode(Crypto.generateDigest('SHA1', Blob.valueOf(getFunctionName() + requestTime)));
        }

        return System.UserInfo.getOrganizationId() + '-' + 
            Request.getCurrent().getRequestId() + '-' + 
            uuid + '-' + 
            getFunctionName() + '-' +
            requestTime;
    }

    private FunctionInvocationRequest generateContext(String requestId,
                                                      String apiVersion,
                                                      String type, 
                                                      String resource,
                                                      String requestTime,
                                                      String asyncFunctionInvocationRequestId,
                                                      List<String> sessionBasedPermSets) {
        String instanceName = [SELECT InstanceName FROM Organization LIMIT 1].InstanceName;
        return new FunctionInvocationRequest.FunctionInvocationRequestBuilder()
            .context(new FunctionInvocationRequest.ContextBuilder()
                .id(requestId)
                .apiVersion(apiVersion)
                .function(projectFunctionRef)
                .resource(resource)
                 // TODO: If desired, include calling class's Id (obtain via new DmlException() r)
                .source('urn:event:from:salesforce/' + instanceName + '/' + System.UserInfo.getOrganizationId() + '/apex')
                .type(type)
                .requestTime(requestTime)                
                .asyncFunctionInvocationRequestId(asyncFunctionInvocationRequestId)
                .permissionSets(sessionBasedPermSets)
                .build())
            .userContext(new FunctionInvocationRequest.UserContextBuilder()
                .orgId(System.UserInfo.getOrganizationId())
                .userId(System.UserInfo.getUserId())
                .userName(System.UserInfo.getUserName())
                .salesforceBaseUrl(System.URL.getSalesforceBaseUrl().toExternalForm())
                .orgDomainUrl(System.URL.getOrgDomainUrl().toExternalForm())
                .namespace(this.namespace)
                .build())
            .build();
    }

    /**
     * Use the Future annotation to identify methods that are executed asynchronously. When you specify Future,
     * the method executes when Salesforce has available resources.
     * 
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_annotation_future.htm
     * 
     * Complex type parameters are not permitted.
     */
    @Future(callout=true)
    private static void invokeAsyncFuture(String functionName,
                                          String requestId,
                                          String resource,
                                          String payloadJson,
                                          String functionRequestContextJson,
                                          String accessToken,
                                          String asyncFunctionInvocationRequestId) {

        System.debug('Invoke async function ' + functionName + ' [' + requestId + ']');
       
        HttpRequest functionRequest = generateRequest(requestId,
                                                      resource,
                                                      payloadJson,
                                                      functionRequestContextJson,
                                                      accessToken);
        
        Integer statusCode = 0;
        String body = '';
        String extraInfo = '';
        Long startTime = DateTime.now().getTime();
        try {
            Http httpConn = new Http();
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
    
    private static HttpRequest generateRequest(String requestId,
                                               String resource,
                                               String payloadJson,
                                               String functionRequestContextJson,
                                               String accessToken) {
		return generateRequest(requestId, resource, payloadJson, FunctionInvocationRequest.fromJSON(functionRequestContextJson), accessToken);
	}
    
    private static HttpRequest generateRequest(String requestId,
                                               String resource,
                                               String payloadJson,
                                               FunctionInvocationRequest functionRequestContext,
                                               String accessToken) {
        HttpRequest functionRequest = new HttpRequest();
        functionRequest.setEndpoint(resource);
        functionRequest.setMethod('POST');
        functionRequest.setHeader('Content-Type', 'application/json');
        functionRequest.setHeader('Authorization', 'Bearer ' + accessToken);
        functionRequest.setHeader('request-id', requestId);   // Logged by proxy framework
        functionRequest.setHeader('X-Request-Id', requestId); // Logged by function
        functionRequestContext.setContextHeaders(functionRequest);
        functionRequest.setTimeout(120000);
        functionRequest.setBody(payloadJson);
        return functionRequest;
    }
    
    
}