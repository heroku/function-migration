package com.salesforce.functions.proxy.model;

/**
 * Encapsulates Salesforce API error response.
 */
public class APIError {
    public String errorCode;
    public String message;
    public String [] fields;
}
