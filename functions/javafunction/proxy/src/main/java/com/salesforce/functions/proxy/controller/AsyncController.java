package com.salesforce.functions.proxy.controller;

import com.salesforce.functions.proxy.handler.request.RequestHandler;
import com.salesforce.functions.proxy.handler.response.AsyncFunctionResponseHandler;
import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.service.InvokeFunctionService;
import com.salesforce.functions.proxy.util.InvalidRequestException;
import com.salesforce.functions.proxy.util.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * This controller handles async requests disconnecting from the client before managing function invocation.
 *
 * Before disconnecting from the client, this controller:
 *   - Validates the request ensure expected payload and that the caller is from the owner org.
 *   - Enriches the function payload minting an org-accessible token for the function and activating
 *     given Permission Sets on the function's token, if applicable.
 */
@RestController
public class AsyncController {

    private static final Logger LOGGER = LoggerFactory.getLogger(SyncController.class);

    @Autowired
    Utils utils;

    @Autowired
    List<RequestHandler> handlers;

    @Autowired
    InvokeFunctionService invokeFunctionService;

    @Autowired
    AsyncFunctionResponseHandler asyncFunctionResponseHandler;

    @RequestMapping("/async/**")
    public ResponseEntity<String> handleRequest(@RequestBody(required = false) String body,
                                                @RequestHeader HttpHeaders headers,
                                                HttpMethod method) {
        LOGGER.info("Received /async request");

        FunctionRequestContext functionRequestContext = new FunctionRequestContext(headers, method);
        try {
            for (RequestHandler handler : handlers) {
                String requestId = functionRequestContext.getRequestId();
                String handlerName = handler.getClass().getSimpleName();
                utils.debug(LOGGER, requestId, "Invoking handler " + handlerName + "...");
                long startMs = System.currentTimeMillis();

                handler.handle(functionRequestContext);

                utils.debug(LOGGER,
                            functionRequestContext.getRequestId(),
                            "Invoked handler " + handlerName + " in " + (System.currentTimeMillis() - startMs) + "ms");
            }
        } catch (InvalidRequestException ex) {
            utils.error(LOGGER, functionRequestContext.getRequestId(), ex.getMessage());
            return ResponseEntity
                    .status(ex.getStatusCode())
                    .body(ex.getMessage());
        } catch (Exception ex) {
            utils.error(LOGGER, functionRequestContext.getRequestId(), ex.getMessage());
            return ResponseEntity
                    .status(503)
                    .body(ex.getMessage());
        }

        // TODO: Validate AsyncFunctionInvocationRequest__c access and existence

        // Async'ly invoke function
        invokeFunctionService.asyncInvokeFunction(functionRequestContext, body, asyncFunctionResponseHandler);

        return ResponseEntity.status(HttpStatus.CREATED).build();
    }
}
