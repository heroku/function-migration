package com.salesforce.functions.proxy.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public class AsyncFunctionInvocationRequest {
    private String extraInfo;
    private String response;
    private String status;
    private int statusCode;

    public AsyncFunctionInvocationRequest(String extraInfo, String response, String status, int statusCode) {
        this.extraInfo = extraInfo;
        this.response = response;
        this.status = status;
        this.statusCode = statusCode;
    }

    @JsonProperty("ExtraInfo__c")
    public String getExtraInfo() {
        return extraInfo;
    }

    @JsonProperty("Response__c")
    public String getResponse() {
        return response;
    }

    @JsonProperty("Status__c")
    public String getStatus() {
        return status;
    }

    @JsonProperty("StatusCode__c")
    public int getStatusCode() {
        return statusCode;
    }
}
