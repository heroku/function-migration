/* Sample function HTTP request

When we Base64-decode the ce-sfcontext header and format it for readability (adding spaces and newlines), we get:
{
  'context': {
    'id': '00Dxx0000006IYJEA2-4Y4W3Lw_LkoskcHdEaZze--MyFunction-2020-09-03T20:56:27.608444Z',
    'apiVersion': '55.0',
    'function': 'MyFunction',
    'resource': 'https://...',
    'source': 'urn:event:from:salesforce/<instance>/<orgId>/<sourceId, eg Apex Class Id>',
    'type': 'com.salesforce.function.invoke.sync'
    'namespace': '',
  },
  'userContext': {
    'orgId': '00Dxx0000006IYJ',
    'userId': '005xx000001X8Uz',
    'username': 'test-zqisnf6ytlqv@example.com',
    'onBehalfOfUserId': '',
    'salesforceBaseUrl': 'http://pistachio-virgo-1063-dev-ed.localhost.internal.salesforce.com:6109',
    'orgDomainUrl': 'http://pistachio-virgo-1063-dev-ed.localhost.internal.salesforce.com:6109'
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
        String namespace;
        String asyncFunctionInvocationRequestCallbackUrl;
        List<String> permissionSets;

        private Context() {}

        public Context(ContextBuilder builder) {
            this.id = builder.id;
            this.apiVersion = builder.apiVersion;
            this.function = builder.function;
            this.resource = builder.resource;
            this.source = builder.source;
            this.type = builder.type;
            this.namespace = builder.namespace;
            this.asyncFunctionInvocationRequestCallbackUrl = asyncFunctionInvocationRequestCallbackUrl;
            this.permissionSets = permissionSets;
        }
    }

    public class ContextBuilder {

        private String id;
        private String apiVersion;
        private String function;
        private String resource;
        private String source;
        private String type;
        private String namespace;
        private String asyncFunctionInvocationRequestCallbackUrl;
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

        public ContextBuilder namespace(String namespace) {
            this.namespace = namespace;
            return this;
        }

        public ContextBuilder asyncFunctionInvocationRequestCallbackUrl(String asyncFunctionInvocationRequestCallbackUrl) {
            this.asyncFunctionInvocationRequestCallbackUrl = asyncFunctionInvocationRequestCallbackUrl;
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
            if (type.endsWith('.async') && String.isBlank(asyncFunctionInvocationRequestCallbackUrl)) {
                throw new IllegalStateException('Callback URL is required');
            }
            return new Context(this);
        }
    }

    public class UserContext {

        String orgId;
        String userId;
        String username;
        String onBehalfOfUserId;
        URL salesforceBaseUrl;
        URL orgDomainUrl;

        private UserContext() {}

        public UserContext(UserContextBuilder builder) {
            this.orgId = builder.orgId;
            this.userId = builder.userId;
            this.username = builder.username;
            this.onBehalfOfUserId = '';
            this.salesforceBaseUrl = builder.salesforceBaseUrl;
            this.orgDomainUrl = builder.orgDomainUrl;
        }
    }

    public class UserContextBuilder {

        private String orgId;
        private String userId;
        private String username;
        private URL salesforceBaseUrl;
        private URL orgDomainUrl;

        public UserContextBuilder orgId(String orgId) {
            this.orgId = orgId;
            return this;
        }

        public UserContextBuilder userId(String userId) {
            this.userId = userId;
            return this;
        }

        public UserContextBuilder username(String username) {
            this.username = username;
            return this;
        }

        public UserContextBuilder salesforceBaseUrl(URL salesforceBaseUrl) {
            this.salesforceBaseUrl = salesforceBaseUrl;
            return this;
        }

        public UserContextBuilder orgDomainUrl(URL orgDomainUrl) {
            this.orgDomainUrl = orgDomainUrl;
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
            if (null == salesforceBaseUrl) {
                throw new IllegalStateException('SalesforceBaseUrl is required');
            }
            if (null == orgDomainUrl) {
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

    public String toEncodedJSON() {
        return EncodingUtil.Base64Encode(Blob.valueOf(JSON.serialize(this)));
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