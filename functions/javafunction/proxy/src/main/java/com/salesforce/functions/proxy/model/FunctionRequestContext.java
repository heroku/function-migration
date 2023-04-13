package com.salesforce.functions.proxy.model;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;

/**
 * Encapsulates a function request.
 */
public class FunctionRequestContext {

    private final HttpHeaders headers;
    private final HttpMethod method;
    private String requestId;
    private String requestProvidedAccessToken;
    private SfFnContext sfFnContext;
    private SfContext sfContext;

    public FunctionRequestContext(HttpHeaders headers, HttpMethod method) {
        this.headers = headers;
        this.method = method;
    }

    public HttpMethod getMethod() {
        return method;
    }

    public HttpHeaders getHeaders() {
        return headers;
    }

    public String getRequestId() {
        return requestId;
    }

    public void setRequestId(String requestId) {
        this.requestId = requestId;
    }

    public String getRequestProvidedAccessToken() {
        return requestProvidedAccessToken;
    }

    public void setRequestProvidedAccessToken(String requestProvidedAccessToken) {
        this.requestProvidedAccessToken = requestProvidedAccessToken;
    }

    public SfFnContext getSfFnContext() {
        return sfFnContext;
    }

    public void setSfFnContext(SfFnContext sfFnContext) {
        this.sfFnContext = sfFnContext;
    }

    public SfContext getSfContext() {
        return sfContext;
    }

    public void setSfContext(SfContext sfContext) {
        this.sfContext = sfContext;
    }
}
