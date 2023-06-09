package com.salesforce.functions.proxy.util;

public class InvalidRequestException extends Exception {

    private final int statusCode;

    public InvalidRequestException(String msg, int statusCode) {
        this(null, msg, statusCode);
    }

    public InvalidRequestException(String requestId, String msg, int statusCode) {
        super((null != requestId ? "[" + requestId + "] " : "") + msg);
        this.statusCode = statusCode;
    }

    public int getStatusCode() {
        return statusCode;
    }
}
