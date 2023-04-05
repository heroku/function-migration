package com.salesforce.functions.proxy.util;

public class Constants {
    // Headers
    public static final String HEADER_REQUEST_ID = "x-request-id";
    public static final String AUTHORIZATION_BEARER_PREFIX = "Bearer ";
    public static final String HEADER_FUNCTION_REQUEST_CONTEXT = "ce-sffncontext";
    public static final String HEADER_SALESFORCE_CONTEXT = "ce-sfcontext";
    public static final String HEADER_EXTRA_INFO = "x-extra-info";
    
    // Function
    public static final String FUNCTION_INVOCATION_TYPE_SYNC = "com.salesforce.function.invoke.sync";
    public static final String FUNCTION_INVOCATION_TYPE_ASYNC = "com.salesforce.function.invoke.async";

    // Oauth
    public static final String SANDBOX_AUDIENCE_URL = "https://test.salesforce.com";
    public static final String PROD_AUDIENCE_URL = "https://login.salesforce.com";
}
