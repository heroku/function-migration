/* Sample function HTTP request
{
  Set on request as 'ce-sffncontex' header, base64 encoded:
  'context': {
    'id': '00Dxx0000006IYJEA2-4Y4W3Lw_LkoskcHdEaZze--MyFunction-2023-03-23T15:18:53.429-0700',
    'apiVersion': '57.0',
    'function': 'MyFunction',
    'resource': 'https://...',
    'source': 'urn:event:from:salesforce/<instance>/<orgId>/<platform origin, eg apex>',
    'type': 'com.salesforce.function.invoke.sync',
    'requestTime': '2023-03-23T15:18:53.429-0700',
    'asyncFunctionInvocationRequestId': '<id>',
    'permissionSets': '[ 'MyPermissionSet' ]'
  }

  Set on request as 'ce-sfcontext' header, base64 encoded:
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

    public class Context {

        public String id { get { return id; } set { id = value; } }
        String apiVersion;
        String function;
        public String resource { get { return resource; } set { resource = value; } }
        String source;
        String type;
        String requestTime;
        String asyncFunctionInvocationRequestId;
        List<String> permissionSets;

        private Context() {}

        public Context(ContextBuilder builder) {
            this.id = builder.id;
            this.apiVersion = builder.apiVersion;
            this.function = builder.function;
            this.resource = builder.resource;
            this.source = builder.source;
            this.type = builder.type;
            this.requestTime = builder.requestTime;            
            this.asyncFunctionInvocationRequestId = builder.asyncFunctionInvocationRequestId;
            this.permissionSets = builder.permissionSets;
        }
    }

    public class ContextBuilder {

        private String id;
        private String apiVersion;
        private String function;
        private String resource;
        private String source;
        private String type;
        private String requestTime;
        private String namespace;
        private String asyncFunctionInvocationRequestId;
        private List<String> permissionSets;

        public ContextBuilder id(String id) {
            this.id = id;
            return this;
        }

        public ContextBuilder apiVersion(String apiVersion) {
            this.apiVersion = apiVersion;
            return this;
        }

        public ContextBuilder function(String function) {
            this.function = function;
            return this;
        }

        public ContextBuilder resource(String resource) {
            this.resource = resource;
            return this;
        }

        public ContextBuilder source(String source) {
            this.source = source;
            return this;
        }

        public ContextBuilder type(String type) {
            this.type = type;
            return this;
        }
        
        public ContextBuilder requestTime(String requestTime) {
            this.requestTime = requestTime;
            return this;
        }

        public ContextBuilder asyncFunctionInvocationRequestId(String asyncFunctionInvocationRequestId) {
            this.asyncFunctionInvocationRequestId = asyncFunctionInvocationRequestId;
            return this;
        }

        public ContextBuilder permissionSets(List<String> permissionSets) {
            this.permissionSets = permissionSets;
            return this;
        }

        public Context build() {
            if (String.isBlank(id)) {
                throw new IllegalStateException('Id is required');
            }
            if (String.isBlank(apiVersion)) {
                throw new IllegalStateException('API Version is required');
            }
            if (String.isBlank(function)) {
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
            if (type.endsWith('.async') && String.isBlank(asyncFunctionInvocationRequestId)) {
                throw new IllegalStateException('AsyncFunctionInvocationRequest.Id is required');
            }
            return new Context(this);
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

    public Context context;
    public UserContext userContext;

    private FunctionInvocationRequest() {}

    public FunctionInvocationRequest(FunctionInvocationRequestBuilder builder) {
        this.context = builder.context;
        this.userContext = builder.userContext;
    }

    public Context getContext() {
        return this.context;
    }

    public UserContext getUserContext() {
        return this.userContext;
    }
    
    public void setContextHeaders(HttpRequest functionRequest) {
        functionRequest.setHeader('ce-specversion', '1.0');
        functionRequest.setHeader('ce-id', context.id);
        functionRequest.setHeader('ce-source', context.source);
        functionRequest.setHeader('ce-type', context.type);
        functionRequest.setHeader('ce-time', context.requestTime);
        functionRequest.setHeader('ce-sffncontext', EncodingUtil.Base64Encode(Blob.valueOf(JSON.serialize(context))));
        functionRequest.setHeader('ce-sfcontext', EncodingUtil.Base64Encode(Blob.valueOf(JSON.serialize(userContext))));
    }

    public String toJSON() {
        return JSON.serialize(this);
    }
    
    public static FunctionInvocationRequest fromJSON(String functionInvocationRequestJson) {
        return (FunctionInvocationRequest)JSON.deserializeStrict(functionInvocationRequestJson, FunctionInvocationRequest.class);
    }

    public class FunctionInvocationRequestBuilder {

        private Context context;
        private UserContext userContext;

        public FunctionInvocationRequestBuilder context(Context context) {
            this.context = context;
            return this;
        }

        public FunctionInvocationRequestBuilder userContext(UserContext userContext) {
            this.userContext = userContext;
            return this;
        }

        public FunctionInvocationRequest build() {
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