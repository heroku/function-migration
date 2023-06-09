package com.salesforce.functions.proxy.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Encapsulates a /activateSessionPermSet API request.
 */
public class ActivatePermSetRequest {

    private String permSetName;
    private String permSetNamespace;

    public ActivatePermSetRequest(String permSetName) {
        if (permSetName.contains("__")) {
            permSetNamespace = permSetName.substring(0, permSetName.indexOf("__"));
            this.permSetName = permSetName.substring(permSetName.indexOf("__") + 2);
        } else {
            this.permSetName = permSetName;
            permSetNamespace = null;
        }
    }

    @JsonProperty("PermSetName")
    public String getPermSetName() {
        return permSetName;
    }

    public void setPermSetName(String permSetName) {
        this.permSetName = permSetName;
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    @JsonProperty("PermSetNamespace")
    public String getPermSetNamespace() {
        return permSetNamespace;
    }

    public void setPermSetNamespace(String permSetNamespace) {
        this.permSetNamespace = permSetNamespace;
    }
}
