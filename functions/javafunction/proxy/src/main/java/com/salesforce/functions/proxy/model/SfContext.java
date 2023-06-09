package com.salesforce.functions.proxy.model;

import com.salesforce.functions.proxy.util.InvalidRequestException;
import com.salesforce.functions.proxy.util.Utils;

/**
 * Encapsulates Salesforce function request context.
 */
public class SfContext {

    public static class UserContext {
        private String namespace;
        private String orgId;
        private String username;
        private String orgDomainUrl;
        private String salesforceBaseUrl;

        public UserContext() {}

        public String getNamespace() {
            return namespace;
        }

        public void setNamespace(String namespace) {
            this.namespace = namespace;
        }

        public String getOrgId() {
            return orgId;
        }

        public void setOrgId(String orgId) {
            this.orgId = orgId;
        }

        public String getUsername() {
            return username;
        }

        public void setUsername(String username) {
            this.username = username;
        }

        public String getOrgDomainUrl() {
            return orgDomainUrl;
        }

        public void setOrgDomainUrl(String orgDomainUrl) {
            this.orgDomainUrl = orgDomainUrl;
        }

        public String getSalesforceBaseUrl() {
            return salesforceBaseUrl;
        }

        public void setSalesforceBaseUrl(String salesforceBaseUrl) {
            this.salesforceBaseUrl = salesforceBaseUrl;
        }

        void validate(String requestId) throws InvalidRequestException {
            if (null == this.orgId) {
                throw new InvalidRequestException(requestId, "Org ID not provided", 400);
            }

            if (null == this.username) {
                throw new InvalidRequestException(requestId, "Username not provided", 400);
            }

            if (null == orgDomainUrl) {
                throw new InvalidRequestException(requestId, "OrgDomainUrl not provided", 400);
            }

            if (null == salesforceBaseUrl) {
                throw new InvalidRequestException(requestId, "SalesforceBaseUrl not provided", 400);
            }
        }
    }

    private String apiVersion;
    private UserContext userContext;

    public SfContext() {}

    public String getApiVersion() {
        return apiVersion;
    }

    public void setApiVersion(String apiVersion) {
        this.apiVersion = apiVersion;
    }

    public UserContext getUserContext() {
        return userContext;
    }

    public void setUserContext(UserContext userContext) {
        this.userContext = userContext;
    }

    public void validate(String requestId) throws InvalidRequestException {
        if (null == apiVersion) {
            throw new InvalidRequestException(requestId, "API Version not provided", 400);
        }

        if (userContext == null) {
            throw new InvalidRequestException(requestId, "UserContext not provided", 400);
        }

        userContext.validate(requestId);
    }
}
