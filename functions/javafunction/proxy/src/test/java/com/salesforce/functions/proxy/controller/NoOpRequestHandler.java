package com.salesforce.functions.proxy.controller;

import com.salesforce.functions.proxy.handler.request.RequestHandler;
import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.util.InvalidRequestException;

public class NoOpRequestHandler implements RequestHandler {
    @Override
    public void handle(FunctionRequestContext functionRequestContext) throws InvalidRequestException {
    }
}