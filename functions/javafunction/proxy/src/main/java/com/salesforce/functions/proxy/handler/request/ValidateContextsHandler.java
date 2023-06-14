package com.salesforce.functions.proxy.handler.request;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.model.SfContext;
import com.salesforce.functions.proxy.model.SfFnContext;
import com.salesforce.functions.proxy.util.InvalidRequestException;
import com.salesforce.functions.proxy.util.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;

import static com.salesforce.functions.proxy.util.Constants.HEADER_FUNCTION_REQUEST_CONTEXT;
import static com.salesforce.functions.proxy.util.Constants.HEADER_SALESFORCE_CONTEXT;

/**
 * Parses and validates 'ce-sffncontext' and 'ce-sfcontext' headers.  See SfFnContext and SfContext.
 */
@Order(20)
@Component
public class ValidateContextsHandler extends BaseRequestHandler {

    private static final Logger LOGGER = LoggerFactory.getLogger(ValidateContextsHandler.class);

    // For testing
    public ValidateContextsHandler(Utils utils) {
        super();
        this.utils = utils;
    }

    /**
     * Parse and validate 'ce-sffncontext' and 'ce-sfcontext' headers.  See SfFnContext and SfContext.
     *
     * @param functionRequestContext
     */
    @Override
    public void handle(FunctionRequestContext functionRequestContext) throws InvalidRequestException {
        String requestId = functionRequestContext.getRequestId();
        HttpHeaders headers = functionRequestContext.getHeaders();
        SfFnContext sfFnContext =
                parseAndValidateFunctionContext(requestId, headers.getFirst(HEADER_FUNCTION_REQUEST_CONTEXT));
        functionRequestContext.setSfFnContext(sfFnContext);
        SfContext sfContext =
                parseAndValidateSalesforceContext(requestId, headers.getFirst(HEADER_SALESFORCE_CONTEXT));
        functionRequestContext.setSfContext(sfContext);

        utils.info(LOGGER, requestId, "Validated context headers - well done");
    }

    /***
     * Parse and validate 'ce-sffncontext' header.
     *
     * @param requestId
     * @param encodedFunctionContextHeader
     * @return SfFnContext
     * @throws InvalidRequestException
     */
    protected SfFnContext parseAndValidateFunctionContext(String requestId, String encodedFunctionContextHeader)
            throws InvalidRequestException {
        if (utils.isBlank(encodedFunctionContextHeader)) {
            throw new InvalidRequestException(requestId, HEADER_FUNCTION_REQUEST_CONTEXT + " not found", 400);
        }

        SfFnContext sfFnContext;
        try {
            sfFnContext = utils.fromEncodedJson(encodedFunctionContextHeader, SfFnContext.class);
        } catch (JsonProcessingException ex) {
            throw new InvalidRequestException(
                    requestId,
                    "Invalid " + HEADER_FUNCTION_REQUEST_CONTEXT + ": " + ex.getMessage(),
                    400);
        }

        sfFnContext.validate(requestId);

        return sfFnContext;
    }

    /**
     * Parse and validate 'ce-sfcontext' header.
     *
     * @param requestId
     * @param encodedSalesforceContextHeader
     * @return SfContext
     * @throws InvalidRequestException
     */
    protected SfContext parseAndValidateSalesforceContext(String requestId, String encodedSalesforceContextHeader)
            throws InvalidRequestException {
        if (utils.isBlank(encodedSalesforceContextHeader)) {
            throw new InvalidRequestException(requestId, HEADER_SALESFORCE_CONTEXT + " not found", 400);
        }

        SfContext salesforceContext;
        try {
            salesforceContext = utils.fromEncodedJson(encodedSalesforceContextHeader, SfContext.class);
        } catch (JsonProcessingException ex) {
            throw new InvalidRequestException(
                    requestId,
                    "Invalid " + HEADER_SALESFORCE_CONTEXT + ": " + ex.getMessage(),
                    400);
        }

        salesforceContext.validate(requestId);

        return salesforceContext;
    }
}
