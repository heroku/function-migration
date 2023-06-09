package com.salesforce.functions.proxy.handler.request;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.google.common.collect.Lists;
import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.util.InvalidRequestException;
import com.salesforce.functions.proxy.util.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;

import java.util.List;

import static com.salesforce.functions.proxy.util.Constants.HEADER_FUNCTION_REQUEST_CONTEXT;

/**
 * Prepares the function requests prior to invoking a function.
 */
@Order(60)
@Component
public class PrepareFunctionRequestHandler extends BaseRequestHandler {

    private static final Logger LOGGER = LoggerFactory.getLogger(PrepareFunctionRequestHandler.class);

    // For testing
    public PrepareFunctionRequestHandler(Utils utils) {
        super();
        this.utils = utils;
    }

    @Override
    public void handle(FunctionRequestContext functionRequestContext) throws InvalidRequestException {
        String requestId = functionRequestContext.getRequestId();

        String sfFnContext;
        try {
            sfFnContext = utils.toEncodedJson(functionRequestContext.getSfFnContext());
        } catch (JsonProcessingException ex) {
            throw new InvalidRequestException(functionRequestContext.getRequestId(),
                    "Unable to set " + HEADER_FUNCTION_REQUEST_CONTEXT + " header: " + ex.getMessage(),
                    401);
        }

        HttpHeaders headers = functionRequestContext.getHeaders();
        headers.remove(HEADER_FUNCTION_REQUEST_CONTEXT);
        List<String> sfFnContextHeaderVal = Lists.newArrayList(sfFnContext);
        headers.put(HEADER_FUNCTION_REQUEST_CONTEXT, sfFnContextHeaderVal);

        utils.info(LOGGER, requestId, "Prepared function request - let's go");
    }
}
