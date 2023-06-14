package com.salesforce.functions.proxy.handler.request;

import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.util.InvalidRequestException;

/**
 * Perform specific tasks on a function request.
 */
public interface RequestHandler {

    void handle(FunctionRequestContext functionRequestContext) throws InvalidRequestException;
}
