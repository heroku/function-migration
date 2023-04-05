package com.salesforce.functions.proxy.model;

import com.salesforce.functions.proxy.util.InvalidRequestException;

public class SfContext {

    public static final class UserContext {

        private String orgId;
        private String username;
        private String salesforceBaseUrl;

        UserContext() {}

        public String getOrgId() {
            return orgId;
        }

        public String getUsername() {
            return username;
        }

        public String getSalesforceBaseUrl() {
            return salesforceBaseUrl;
        }

        void validate(String requestId) throws InvalidRequestException {
            if (null == this.orgId) {
                throw new InvalidRequestException(requestId, "Org ID not provided", 400);
            }

            if (null == this.username) {
                throw new InvalidRequestException(requestId, "Username not provided", 400);
            }

            if (null == salesforceBaseUrl) {
                throw new InvalidRequestException(requestId, "SalesforceBaseUrl not provided", 400);
            }
        }
    }

    private String apiVersion;
    private UserContext userContext;

    SfContext() {}

    public void validate(String requestId) throws InvalidRequestException {
        if (null == apiVersion) {
            throw new InvalidRequestException(requestId, "API Version not provided", 400);
        }

        if (userContext == null) {
            throw new InvalidRequestException(requestId, "UserContext not provided", 400);
        }

        userContext.validate(requestId);
    }

    public String getApiVersion() {
        return apiVersion;
    }

    public UserContext getUserContext() {
        return userContext;
    }
}
