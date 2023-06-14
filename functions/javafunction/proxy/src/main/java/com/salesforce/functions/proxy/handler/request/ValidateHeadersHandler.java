package com.salesforce.functions.proxy.handler.request;

import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.util.InvalidRequestException;
import com.salesforce.functions.proxy.util.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;

import static com.salesforce.functions.proxy.util.Constants.*;

/**
 * Parses and validates expected function request headers.
 */
@Order(10)
@Component
public class ValidateHeadersHandler extends BaseRequestHandler {

    private static final Logger LOGGER = LoggerFactory.getLogger(ValidateHeadersHandler.class);

    // For testing
    public ValidateHeadersHandler(Utils utils) {
        super();
        this.utils = utils;
    }

    @Override
    /**
     * Expected headers:
     *  - x-request-id: request id generated by client that tracks the entire request/response
     *  - ce-specversion: version of CloudEvent schema
     *  - ce-id: see x-request-id
     *  - ce-datacontenttype: content type of request
     *  - ce-source: source of request
     *  - ce-type: type of request
     *  - ce-time: origin time of request
     *  - ce-sfcontext: Salesforce context - context of invoking Org
     *  - ce-sffncontext: context of function request
     *
     * @throws InvalidRequestException
     */
    public void handle(FunctionRequestContext functionRequestContext) throws InvalidRequestException {
        HttpHeaders headers = functionRequestContext.getHeaders();
        String requestId = headers.getFirst(HEADER_REQUEST_ID);
        if (utils.isBlank(requestId)) {
            throw new InvalidRequestException(HEADER_REQUEST_ID + " not found", 400);
        }
        functionRequestContext.setRequestId(requestId);

        String auth = headers.getFirst(HttpHeaders.AUTHORIZATION);
        if (utils.isBlank(auth)) {
            throw new InvalidRequestException(requestId, HttpHeaders.AUTHORIZATION + " not found", 400);
        }

        if (!auth.startsWith(AUTHORIZATION_BEARER_PREFIX)) {
            throw new InvalidRequestException(requestId, "Invalid " + HttpHeaders.AUTHORIZATION, 400);
        }

        String requestProvidedAccessToken = auth.substring(AUTHORIZATION_BEARER_PREFIX.length());
        if (utils.isBlank(requestProvidedAccessToken)) {
            throw new InvalidRequestException(requestId, HttpHeaders.AUTHORIZATION + " accessToken not found", 400);
        }

        for (String expectedCloudEventHeader : REQUIRED_CLOUD_EVENT_HEADERS) {
            if (utils.isBlank(headers.getFirst(expectedCloudEventHeader))) {
                throw new InvalidRequestException(requestId, expectedCloudEventHeader + " not found", 400);
            }
        }

        functionRequestContext.setRequestProvidedAccessToken(requestProvidedAccessToken.trim());

        utils.info(LOGGER, requestId, "Validated request headers - looks good");
    }
}