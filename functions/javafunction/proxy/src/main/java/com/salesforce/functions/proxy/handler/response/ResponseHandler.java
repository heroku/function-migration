package com.salesforce.functions.proxy.handler.response;

import com.salesforce.functions.proxy.model.FunctionRequestContext;
import org.springframework.http.ResponseEntity;

/**
 * Perform specific tasks on a function response.
 */
public interface ResponseHandler {

    void handleError(FunctionRequestContext functionRequestContext, Exception ex);

    void handleResponse(FunctionRequestContext functionRequestContext, ResponseEntity<String> functionResponseEntity);
}
