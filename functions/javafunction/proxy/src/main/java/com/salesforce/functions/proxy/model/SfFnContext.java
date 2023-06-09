package com.salesforce.functions.proxy.model;

import com.salesforce.functions.proxy.util.InvalidRequestException;
import com.salesforce.functions.proxy.util.Utils;

import java.util.List;

import static com.salesforce.functions.proxy.util.Constants.FUNCTION_INVOCATION_TYPE_ASYNC;
import static com.salesforce.functions.proxy.util.Constants.FUNCTION_INVOCATION_TYPE_SYNC;

/**
 * Encapsulates function request context.
 */
public class SfFnContext {

    private String id;
    private String functionName;
    private String resource;
    private String source;
    private String type;
    private String requestTime;
    private String functionInvocationId;
    private List<String> permissionSets;
    private String accessToken;

    public SfFnContext() {
    }

    public String getFunctionName() {
        return functionName;
    }

    public void setFunctionName(String functionName) {
        this.functionName = functionName;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getFunctionInvocationId() {
        return functionInvocationId;
    }

    public void setFunctionInvocationId(String functionInvocationId) {
        this.functionInvocationId = functionInvocationId;
    }

    public List<String> getPermissionSets() {
        return permissionSets;
    }

    public void setPermissionSetS(List<String> permissionSets) {
        this.permissionSets = permissionSets;
    }

    public String getAccessToken() {
        return accessToken;
    }

    public void setAccessToken(String accessToken) {
        this.accessToken= accessToken;
    }

    public void validate(String requestId) throws InvalidRequestException {
        if (null == getFunctionName()) {
            throw new InvalidRequestException(requestId, "Function name not provided", 400);
        }

        if (!(FUNCTION_INVOCATION_TYPE_SYNC.equals(type) || FUNCTION_INVOCATION_TYPE_ASYNC.equals(type))) {
            throw new InvalidRequestException(requestId, "Invalid function invocation type '" + type + "'", 400);
        }

        if (FUNCTION_INVOCATION_TYPE_ASYNC.equals(type) && null == functionInvocationId) {
            throw new InvalidRequestException(requestId,
                                              "AsyncFunctionInvocationRequest__c ID not provided for async invocation",
                                              400);
        }
    }
}
