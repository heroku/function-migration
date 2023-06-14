package com.salesforce.functions.proxy.service;

import com.salesforce.functions.proxy.config.ProxyConfig;
import com.salesforce.functions.proxy.handler.response.ResponseHandler;
import com.salesforce.functions.proxy.model.AsyncFunctionInvocationRequest;
import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.model.SfContext;
import com.salesforce.functions.proxy.model.SfFnContext;
import com.salesforce.functions.proxy.util.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.*;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;

import static com.salesforce.functions.proxy.util.Constants.HEADER_EXTRA_INFO;

/**
 * Service to invoke co-located function.
 */
@Service
public class InvokeFunctionService {

    private static final Logger LOGGER = LoggerFactory.getLogger(InvokeFunctionService.class);

    @Autowired
    ProxyConfig proxyConfig;

    @Autowired
    RestTemplate restTemplate;

    @Autowired
    Utils utils;

    /**
     * Invoke function synchronously.
     *
     * @param functionRequestContext
     * @param body
     * @return
     */
    public ResponseEntity syncInvokeFunction(FunctionRequestContext functionRequestContext, String body) {
        // Forward request to the function
        ResponseEntity<String> responseEntity;
        try {
            responseEntity = invokeFunction("sync", functionRequestContext, body);
        } catch (HttpClientErrorException ex) {
            return ResponseEntity
                    .status(ex.getStatusCode())
                    .headers(ex.getResponseHeaders())
                    .body(ex.getResponseBodyAsString());
        }

        return responseEntity;
    }

    /**
     * Invoke function asynchronously.
     *
     * @param functionRequestContext
     * @param body
     * @param responseHandler
     */
    @Async
    public void asyncInvokeFunction(FunctionRequestContext functionRequestContext,
                                    String body,
                                    ResponseHandler responseHandler) {
        // POST request to the function
        ResponseEntity<String> responseEntity = null;
        try {
            CompletableFuture<ResponseEntity<String>> future = CompletableFuture.completedFuture(
                    invokeFunction("async", functionRequestContext, body));
            // Wait for response to be fulfilled
            CompletableFuture.allOf(future);
            responseEntity = future.get();
        } catch (Exception ex) {
            responseHandler.handleError(functionRequestContext, ex);
            return;
        }

        // Handle function response
        responseHandler.handleResponse(functionRequestContext, responseEntity);
    }

    /**
     * Generic function invocation.
     *
     * @param invocationType
     * @param functionRequestContext
     * @param body
     * @return
     */
    public ResponseEntity invokeFunction(String invocationType,
                                         FunctionRequestContext functionRequestContext,
                                         String body)
            throws HttpClientErrorException {
        String requestId = functionRequestContext.getRequestId();
        utils.info(LOGGER, requestId,"Invoking " + invocationType + " function " + proxyConfig.getFunctionUrl() + "...");
        HttpEntity<String> entity = new HttpEntity<>(body, functionRequestContext.getHeaders());
        ResponseEntity<String> responseEntity;
        long startMs = System.currentTimeMillis();
        try {
            responseEntity = restTemplate.exchange(proxyConfig.getFunctionUrl(),
                                                   functionRequestContext.getMethod(),
                                                   entity,
                                                   String.class);
        } finally {
            utils.info(LOGGER, requestId,"Invoked function " + proxyConfig.getFunctionUrl() + " in " +
                    (System.currentTimeMillis() - startMs) + "ms");
        }

        return responseEntity;
    }
}
