package com.salesforce.functions.proxy.model;

import org.springframework.http.HttpHeaders;

public class FunctionRequestContext1 {
    private final HttpHeaders headers;
    private String requestId;
    private String requestProvidedAccessToken;
    private SfFnContext sfFnContext;
    private SfContext sfContext;

    public FunctionRequestContext1(HttpHeaders headers) {
            this.headers = headers;
        }
}
