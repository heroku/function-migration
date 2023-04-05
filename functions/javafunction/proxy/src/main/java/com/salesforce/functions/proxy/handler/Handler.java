package com.salesforce.functions.proxy.handler;

import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.util.InvalidRequestException;

public interface Handler {

    void handle(FunctionRequestContext functionRequestContext) throws InvalidRequestException;
}
