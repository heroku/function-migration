/* Sample function HTTP request
{
  Context of the function request.  Set on request as 'ce-sffncontext' header, base64 encoded.
  {
    'id': '00Dxx0000006IYJEA2-4Y4W3Lw_LkoskcHdEaZze-uuid-MyFunction-2023-03-23T15:18:53.429-0700',
    'functionName': 'MyFunction',
    'resource': 'https://...',
    'source': 'urn:event:from:salesforce/<instance>/<orgId>/<platform origin, eg apex>',
    'type': 'com.salesforce.function.invoke.sync',
    'requestTime': '2023-03-23T15:18:53.429-0700',
    'functionInvocationId': '<AsyncFunctionInvocationRequest__c.ID>',
    'permissionSets': '[ 'MyPermissionSet' ]'
  }

  Salesforce context - context of invoking Org. Set on request as 'ce-sfcontext' header, base64 encoded.
  'apiVersion': '57.0',
  'payloadVersion': '0.1',
  'userContext': {
    'orgId': '00Dxx0000006IYJ',
    'userId': '005xx000001X8Uz',
    'username': 'admin@example.com',
    'onBehalfOfUserId': '',
    'salesforceBaseUrl': 'https://na1.salesforce.com',
    'orgDomainUrl': 'https://mycompany.my.salesforce.com',
	'namespace': '',
  }
}
*/
global class FunctionInvocationRequest {

    public class IllegalStateException extends Exception {}

    public class FunctionContext {

        public String id { get { return id; } set { id = value; } }
        String functionName;
        public String resource { get { return resource; } set { resource = value; } }
        String source;
        String type;
        String requestTime;
        String functionInvocationId;
        List<String> permissionSets;

        private FunctionContext() {}

        public FunctionContext(FunctionContextBuilder builder) {
            this.id = builder.id;
            this.functionName = builder.functionName;
            this.resource = builder.resource;
            this.source = builder.source;
            this.type = builder.type;
            this.requestTime = builder.requestTime;            
            this.functionInvocationId = builder.functionInvocationId;
            this.permissionSets = builder.permissionSets;
        }
    }

    public class FunctionContextBuilder {

        private String id;
        private String functionName;
        private String resource;
        private String source;
        private String type;
        private String requestTime;
        private String namespace;
        private String functionInvocationId;
        private List<String> permissionSets;

        public FunctionContextBuilder id(String id) {
            this.id = id;
            return this;
        }

        public FunctionContextBuilder function(String functionName) {
            this.functionName = functionName;
            return this;
        }

        public FunctionContextBuilder resource(String resource) {
            this.resource = resource;
            return this;
        }

        public FunctionContextBuilder source(String source) {
            this.source = source;
            return this;
        }

        public FunctionContextBuilder type(String type) {
            this.type = type;
            return this;
        }
        
        public FunctionContextBuilder requestTime(String requestTime) {
            this.requestTime = requestTime;
            return this;
        }

        public FunctionContextBuilder asyncFunctionInvocationRequestId(String functionInvocationId) {
            this.functionInvocationId = functionInvocationId;
            return this;
        }

        public FunctionContextBuilder permissionSets(List<String> permissionSets) {
            this.permissionSets = permissionSets;
            return this;
        }

        public FunctionContext build() {
            if (String.isBlank(id)) {
                throw new IllegalStateException('Id is required');
            }
            if (String.isBlank(functionName)) {
                throw new IllegalStateException('Function is required');
            }
            if (String.isBlank(resource)) {
                throw new IllegalStateException('Resource is required');
            }
            if (String.isBlank(source)) {
                throw new IllegalStateException('Source is required');
            }
            if (String.isBlank(type)) {
                throw new IllegalStateException('Type is required');
            }
            if (String.isBlank(requestTime)) {
                throw new IllegalStateException('Request Time is required');
            }
            if (type.endsWith('.async') && String.isBlank(functionInvocationId)) {
                throw new IllegalStateException('AsyncFunctionInvocationRequest.Id is required');
            }
            return new FunctionContext(this);
        }
    }

    public class UserContext {

        String orgId;
        String userId;
        String username;
        String onBehalfOfUserId;
        String salesforceBaseUrl;
        String orgDomainUrl;
        String namespace;

        private UserContext() {}

        public UserContext(UserContextBuilder builder) {
            this.orgId = builder.orgId;
            this.userId = builder.userId;
            this.username = builder.username;
            this.onBehalfOfUserId = builder.onBehalfOfUserId;
            this.salesforceBaseUrl = builder.salesforceBaseUrl;
            this.orgDomainUrl = builder.orgDomainUrl;
            this.namespace = builder.namespace;
        }
    }

    public class UserContextBuilder {

        private String orgId;
        private String userId;
        private String username;
        private String onBehalfOfUserId;
        private String salesforceBaseUrl;
        private String orgDomainUrl;
        private String namespace;

        public UserContextBuilder apiVersion(String apiVersion) {
            this.apiVersion = apiVersion;
            return this;
        }

        public UserContextBuilder orgId(String orgId) {
            this.orgId = orgId;
            return this;
        }

        public UserContextBuilder username(String username) {
            this.username = username;
            return this;
        }

        public UserContextBuilder onBehalfOfUserId(String onBehalfOfUserId) {
            this.onBehalfOfUserId = onBehalfOfUserId;
            return this;
        }

        public UserContextBuilder userId(String userId) {
            this.userId = userId;
            return this;
        }

        public UserContextBuilder salesforceBaseUrl(String salesforceBaseUrl) {
            this.salesforceBaseUrl = salesforceBaseUrl;
            return this;
        }

        public UserContextBuilder orgDomainUrl(String orgDomainUrl) {
            this.orgDomainUrl = orgDomainUrl;
            return this;
        }
        
        public UserContextBuilder namespace(String namespace) {
            this.namespace = namespace;
            return this;
        }

        public UserContext build() {
            if (String.isBlank(orgId)) {
                throw new IllegalStateException('OrgId is required');
            }
            if (String.isBlank(userId)) {
                throw new IllegalStateException('UserId is required');
            }
            if (String.isBlank(username)) {
                throw new IllegalStateException('Username is required');
            }
            if (String.isBlank(salesforceBaseUrl)) {
                throw new IllegalStateException('SalesforceBaseUrl is required');
            }
            if (String.isBlank(orgDomainUrl)) {
                throw new IllegalStateException('OrgDomainUrl is required');
            }
            return new UserContext(this);
        }
    }

    class SalesforceContext {
        public String apiVersion;
        public String payloadVersion;
        public UserContext userContext;

        SalesforceContext(String apiVersion, String payloadVersion, UserContext userContext) {
            this.apiVersion = apiVersion;
            this.payloadVersion = payloadVersion;
            this.userContext = userContext;
        }

        String getApiVersion() {
            return apiVersion;
        }

        String getPayloadVersion() {
            return payloadVersion;
        }

        UserContext getUserContext() {
            return this.userContext;
        }
    }

    public SalesforceContext sfContext;
    public FunctionContext functionContext;

    private FunctionInvocationRequest() {}

    public FunctionInvocationRequest(FunctionInvocationRequestBuilder builder) {
        this.functionContext = builder.functionContext;
        this.sfContext = new SalesforceContext(builder.apiVersion, '0.1', builder.userContext);
    }
    
    public void setContextHeaders(HttpRequest functionRequest) {
        functionRequest.setHeader('ce-specversion', '1.0');
        functionRequest.setHeader('ce-id', functionContext.id);
        functionRequest.setHeader('ce-source', functionContext.source);
        functionRequest.setHeader('ce-type', functionContext.type);
        functionRequest.setHeader('ce-time', functionContext.requestTime);
        functionRequest.setHeader('ce-sffncontext', EncodingUtil.Base64Encode(Blob.valueOf(JSON.serialize(functionContext))));
        functionRequest.setHeader('ce-sfcontext', EncodingUtil.Base64Encode(Blob.valueOf(JSON.serialize(sfContext))));
    }

    public String toJSON() {
        return JSON.serialize(this);
    }
    
    public static FunctionInvocationRequest fromJSON(String functionInvocationRequestJson) {
        return (FunctionInvocationRequest)JSON.deserializeStrict(functionInvocationRequestJson, FunctionInvocationRequest.class);
    }

    public class FunctionInvocationRequestBuilder {

        private String apiVersion;
        private Context context;
        private UserContext userContext;

        public FunctionInvocationRequestBuilder apiVersion(String apiVersion) {
            this.apiVersion = apiVersion;
            return this;
        }

        public FunctionInvocationRequestBuilder context(Context context) {
            this.context = context;
            return this;
        }

        public FunctionInvocationRequestBuilder userContext(UserContext userContext) {
            this.userContext = userContext;
            return this;
        }

        public FunctionInvocationRequest build() {
            if (null == apiVersion) {
                throw new IllegalStateException('API Version is required');
            }
            if (null == context) {
                throw new IllegalStateException('Context is required');
            }
            if (null == userContext) {
                throw new IllegalStateException('UserContext is required');
            }
            return new FunctionInvocationRequest(this);
        }
    }
}