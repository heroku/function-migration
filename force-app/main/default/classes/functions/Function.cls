/**
 * Function API that invokes functions synchronously or asynchronously.
 */
public with sharing class Function {

    public class InvalidFunctionException extends Exception { }

    public class InvalidFunctionInvocationException extends Exception { }
    
    final static String SYNC_TYPE = 'com.salesforce.function.invoke.sync';
    final static String ASYNC_TYPE = 'com.salesforce.function.invoke.async';
    final static String[] FUNCTION_REFERENCE_FIELDS = new String[] { 'APIVersion__c', 'ConsumerKey__c', 
        'Certificate__c', 'Endpoint__c', 'PermissionSetOrGroup__c' };
    final static FunctionReferenceProvider DEFAULT_FUNCTION_REFERENCE_PROVIDER = new FunctionReferenceMetadataProviderImpl();

    final String namespace;
    final String projectFunctionRef; // <project>_<function>
    final FunctionReference__mdt functionReference;

    // No public constructor, so that this class has factory semantics.
    // (The developer should think of it as "looking up" a Function rather than creating one.)
    @TestVisible
    private Function(String namespace, String projectFunctionRef, FunctionReference__mdt functionReference) {
        this.namespace = String.isBlank(namespace) ? '' : namespace;
        this.projectFunctionRef = projectFunctionRef;
        this.functionReference = functionReference;
        System.debug('Endpoint for ' + projectFunctionRef + ' FunctionReference__mdt: ' + functionReference.Endpoint__c);
    }

    public String getFunctionName() {
        return (!String.isBlank(namespace) ? namespace + '.'  : '') + projectFunctionRef;
    }

    /**
     * Get reference to given FunctionReference__mdt.  Organization's namespace is applied.
     */
    public static Function get(String projectFunctionRef) {
        // null namespace applies component's namespace
        return get(null, projectFunctionRef);
    }

    /**
     * Get reference to given FunctionReference__mdt in the following formats:
     *   - <function>
     *   - <project>.<function>, ala Salesforce Functions reference
     *   - <project>_<function>
     *
     * Empty or null namespace ('') designates applying Organization's namespace for FunctionReference__mdt lookup.
     *
     * Throws NoDataFoundException when FunctionReference__mdt is not found.
     */
    public static Function get(String namespace, String projectFunctionRef) {
        return get(namespace, projectFunctionRef, DEFAULT_FUNCTION_REFERENCE_PROVIDER);
    }

    public static Function get(String namespace, 
                               String projectFunctionRef, 
                               FunctionReferenceProvider functionReferenceProvider) {
        if (String.isEmpty(projectFunctionRef)) {
            throw new InvalidFunctionInvocationException('Invalid function reference');
        }

        if (String.isEmpty(namespace)) {
            namespace = [SELECT NamespacePrefix FROM Organization].NamespacePrefix;
        }

        FunctionReference__mdt functionReference = getFunctionReference(namespace, projectFunctionRef, 
            functionReferenceProvider);
        validatePermissionSet(functionReference);
        return new Function(namespace, projectFunctionRef, functionReference);
    }

    /**
     * Synchronously invoke function.
     *
     * Synchronous function invocations are not allowed when there is an uncommitted transaction pending (CalloutException).
     * 
     * @param payloadJson - function payload (JSON)
     */
    public FunctionInvocation invoke(String payloadJson) {
        return invoke(payloadJson, new FunctionsMetadataAuthProviderImpl(functionReference));
    }

    /**
     * Synchronously invoke function generating a token with given FunctionsAuthProvider.
     *
     * Synchronous function invocations are not allowed when there is an uncommitted transaction pending (CalloutException).
     * 
     * @param payloadJson - function payload (JSON)
     * @param authProvider - FunctionsAuthProvider implementation provides accessToken for function request authentication
     */
    public FunctionInvocation invoke(String payloadJson, FunctionsAuthProvider authProvider) {
        String authenticationToken = authProvider.generateFunctionAuthenticationToken();
        if (null == authenticationToken) {
            throw new InvalidFunctionInvocationException('Authentication token not provided');
        }

        // Ensure non-null payload
        payloadJson = sanitizePayload(payloadJson);
        
        String requestTime = Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        String requestId = generateRequestId(requestTime);
        String resource = functionReference.Endpoint__c + '/sync';
        List<String> sessionBasedPermSets = new List<String>();
        if (null != functionReference.PermissionSetOrGroup__c) {
            sessionBasedPermSets.add(functionReference.PermissionSetOrGroup__c);
        }
        FunctionInvocationRequest functionRequestContext = generateContext(requestId,
                                                                           functionReference.APIVersion__c,
                                                                           SYNC_TYPE, 
                                                                           resource, 
                                                                           requestTime,
                                                                           '',
                                                                           sessionBasedPermSets);

        FunctionInvoker invoker = new FunctionInvoker(getFunctionName(),
                                                      requestId,
                                                      resource,
                                                      payloadJson,
                                                      functionRequestContext,
                                                      authenticationToken);
        FunctionInvocation functionInvocation;
        try {
            functionInvocation = invoker.invoke(true);
        } catch(Exception ex) {
            functionInvocation = new FunctionInvocationImpl(requestId, null, ex.getMessage(), 400, null);
        }

        Integer statusCode = functionInvocation.getStatusCode();
        String response = functionInvocation.getResponse();
        if (200 != statusCode) {
            System.debug('FAILURE: Sync invocation request for function ' + getFunctionName() + ' [' + statusCode + ']: ' +
                response + ' [' + requestId + ']');
        } else {
            System.debug('Successfully invoked sync request for function ' + getFunctionName() + ' [' + requestId + ']');
        }

        return functionInvocation;
    }

    /**
     * Asynchronously invoke function.
     * 
     * @param payloadJson - function payload (JSON)
     * @param callback - FunctionCallback implementation that handles async function response
     */
    public FunctionInvocation invoke(String payloadJson, FunctionCallback callback) {
        return invoke(payloadJson, callback, new FunctionsMetadataAuthProviderImpl(functionReference));
    }

    /**
     * Asynchronously invoke function generating a token with given FunctionsAuthProvider.
     * 
     * @param payloadJson - function payload (JSON)
     * @param authProvider - FunctionsAuthProvider implementation provides accessToken for function request authentication
     * @param callback - FunctionCallback implementation that handles async function response
     */
    public FunctionInvocation invoke(String payloadJson,                                      
                                     FunctionCallback callback,
                                     FunctionsAuthProvider authProvider) {
        if (null == callback) {
            throw new InvalidFunctionInvocationException('FunctionCallback not provided');
        }

        if (null == authProvider) {
            throw new InvalidFunctionInvocationException('FunctionsAuthProvider not provided');
        }
                                         
        String authenticationToken = authProvider.generateFunctionAuthenticationToken();
        if (null == authenticationToken) {
            throw new InvalidFunctionInvocationException('Authentication token not provided');
        }

        // Ensure non-null payload
        payloadJson = sanitizePayload(payloadJson);

        // Ensure that the callback class is NOT deleted prior to invocation
        AsyncFunctionInvocationRequest__c afir = new AsyncFunctionInvocationRequest__c(
            Callback__c = JSON.serialize(callback),
            CallbackType__c = determineClassType(callback),
            Request__c = payloadjson
        );
        insert afir;

        // Generate context and save to AFIR
        String resource = functionReference.Endpoint__c + '/async';
        String requestTime = Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        String requestId = generateRequestId(afir.Id, requestTime);
        List<String> sessionBasedPermSets = new List<String>();
        if (null != functionReference.PermissionSetOrGroup__c) {
            sessionBasedPermSets.add(functionReference.PermissionSetOrGroup__c);
        }
        FunctionInvocationRequest functionInvocationRequest = generateContext(requestId, 
                                                                              functionReference.APIVersion__c,
                                                                              ASYNC_TYPE, 
                                                                              resource, 
                                                                              requestTime,
                                                                              afir.Id,
                                                                              sessionBasedPermSets);
		String functionRequestHeaderJson = functionInvocationRequest.toJSON();        

        // Enqueue async invocation job
        AsyncFunctionInvocationQueueable asyncFunctionInvocationQueueable = 
            new AsyncFunctionInvocationQueueable(getFunctionName(), 
                                                 requestId, 
                                                 resource, 
                                                 payloadjson, 
                                                 functionRequestHeaderJson, 
                                                 authenticationToken,
                                                 afir.Id);
        ID asyncInvocationJobId = System.enqueueJob(asyncFunctionInvocationQueueable);
        System.debug('Enqueued job (' + asyncInvocationJobId + ') for async invocation (' + 
            afir.Id + ') of function ' +  getFunctionName() + ' to job ' + asyncInvocationJobId + 
            ' [' + requestId + ']');
       
        // Update AsyncFunctionInvocationRequest__c
        afir.AsyncInvocationJobId__c = asyncInvocationJobId.to15();
        afir.Context__c = functionRequestHeaderJson;
        afir.RequestId__c = requestId;
        afir.Status__c = FunctionInvocationStatus.PENDING.name();
        update afir;

        System.debug('Updated AsyncFunctionInvocationRequest__c [' + afir.Id + '] for function ' + getFunctionName() + 
            ' [' + requestId + ']');

        return new FunctionInvocationImpl(requestId, Id.valueOf(afir.Id, true));
    }


    //   P R I V A T E

    private static FunctionReference__mdt getFunctionReference(String namespace, 
                                                               String projectFunctionRef, 
                                                               FunctionReferenceProvider functionReferenceProvider) {        
        Boolean isNamespaceNotBlank = String.isNotBlank(namespace);
        String fullyQualifiedFunctionNameForDisplay = (isNamespaceNotBlank ? namespace + '.' : '')  +
            projectFunctionRef;
        String projectFunctionRefForQuery = projectFunctionRef.replace('.', '_');
        
        // Query for FunctionReference_mdt record
        // Query statement assembly may be moved to FunctionReferenceMetadataProviderImpl#getFunctionReference
        String functionReferenceCustomMetadataName = (isNamespaceNotBlank ? namespace + '__' : '')  +
            'FunctionReference__mdt';
        List<String> functionReferenceFields = new List<String>(FUNCTION_REFERENCE_FIELDS);
        if (isNamespaceNotBlank) {
            functionReferenceFields.clear();
            for (String functionReferenceField : FUNCTION_REFERENCE_FIELDS) {
                functionReferenceFields.add(namespace + '__' + functionReferenceField);
            }
        }

        String namespaceForSoql = isNamespaceNotBlank ? namespace : 'null';
        String functionReferenceSoql = 'SELECT ' + String.join(functionReferenceFields, ', ' ) + ' FROM ' + 
            functionReferenceCustomMetadataName + ' WHERE DeveloperName = \'' + projectFunctionRefForQuery + 
            '\' AND NamespacePrefix = \'' + namespaceForSoql + '\'';
        System.debug(functionReferenceSoql);

        FunctionReference__mdt functionReference = null;
        try {
            functionReference = functionReferenceProvider.getFunctionReference(functionReferenceSoql);
        } catch (Exception ex) {
            System.debug('Unable to retrieve FunctionReference__mdt for ' + fullyQualifiedFunctionNameForDisplay + 
                ': ' + ex.getMessage());
        }       
        
        // Ensure exists and has endpoint
        if (null == functionReference || null == functionReference.Endpoint__c) {
            throw new InvalidFunctionException('Invalid function: ' + fullyQualifiedFunctionNameForDisplay);
        }

        return functionReference;
    }

    private static void validatePermissionSet(FunctionReference__mdt functionReference) {
        // If provided, ensure that:
        // (1) PermissionSet or PermissionSetGroup exists, 
        // (2) user is assigned to PermissionSet or PermissionSetGroup, and 
        // (3) PermissionSet or PermissionSetGroup is session-based.
        if (null != functionReference.PermissionSetOrGroup__c) {
            String permSetOrGroupName = functionReference.PermissionSetOrGroup__c;
            String namespace = '';
            if (permSetOrGroupName.contains('__')) {
                String[] permSetNameParts = permSetOrGroupName.split('__');
                namespace = permSetNameParts[0];
                permSetOrGroupName = permSetNameParts[1];                
            }
            List<PermissionSetAssignment> assignments = null;
            try {
                assignments = 
                	[SELECT PermissionSet.HasActivationRequired 
                     FROM PermissionSetAssignment 
                     WHERE Assignee.Id = :UserInfo.getUserId() 
                        AND PermissionSet.Name = :permSetOrGroupName 
                        AND PermissionSet.NamespacePrefix = :namespace
                     WITH SECURITY_ENFORCED];
            } catch (Exception ex) {
                throw new InvalidFunctionException('Unable to validate PermissionSetAssignment for user ' + 
                    UserInfo.getUserName() + ' and PermissionSet or PermissionSetGroup \'' + 
                    functionReference.PermissionSetOrGroup__c + '\': '+ ex.getMessage());
            }
            
            if (null == assignments || assignments.size() == 0) {
                throw new InvalidFunctionException('PermissionSet or PermissionSetGroup \'' + 
                    functionReference.PermissionSetOrGroup__c + '\' not found or user ' + UserInfo.getUserName() + 
                    ' is not assigned.');
            }

            if (assignments.get(0).PermissionSet.HasActivationRequired == false) {
                throw new InvalidFunctionException('PermissionSet or PermissionSetGroup \'' + 
                    functionReference.PermissionSetOrGroup__c + 
                    '\' PermissionSet or PermissionSetGroup is not session-based.');
            }
        }
    }

    private String sanitizePayload(String payload) {
        if (String.isEmpty(payload)) {
            payload = '{}';
        }

        return payload;
    }

    private String generateRequestId(String requestTime) {
        return generateRequestId(null, requestTime);
    }
    
    /**
     * Generate unique request id used to track the function's request.
     * 
     * Format: <OrgId>-<Current Request Id>-<UUID or AsyncFunctionInvocationRequest__c.Id>-<Function Name>-<Datetime>
     * Eg: 00Dxx0000006IYJEA2-4Y4W3Lw_LkoskcHdEaZze-[UUID or AsyncFunctionInvocationRequest__c.Id]
     *         -<MyNamespace.MyProject.MyFunction>-2023-03-23T15:18:53.429-0700
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

    @TestVisible
    private String determineClassType(FunctionCallback callback) {
        // Ensure that the callback class is NOT deleted prior to invocation
        String callbackType = '';
        try {
            // Yuck, but this is what it takes to get inner class names 
            DateTime typeCheck = (DateTime) callback;
        } catch (System.TypeException expectedTypeException) {
            String message = expectedTypeException.getMessage()
                .substringAfter('Invalid conversion from runtime type ');
            callbackType = message.substringBefore(' to Datetime');
        }
        System.debug('Determine callback type: ' + callbackType);

        return callbackType;
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
            .apiVersion(apiVersion)
            .context(new FunctionInvocationRequest.FunctionContextBuilder()
                .id(requestId)
                .function(projectFunctionRef)
                .resource(resource)
                 // TODO: If desired, include calling class's Id (obtain via new DmlException(), eg)
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
}