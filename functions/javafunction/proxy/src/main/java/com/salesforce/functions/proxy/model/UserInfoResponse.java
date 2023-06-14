package com.salesforce.functions.proxy.model;

/**
 * Encapsulates /userinfo API response.
 */
public class UserInfoResponse {

    private String organization_id;

    public String getOrganization_id() {
        return organization_id;
    }

    public void setOrganization_id(String organization_id) {
        this.organization_id = organization_id;
    }
}
