package com.salesforce.functions.proxy.service;

import com.salesforce.functions.proxy.config.ProxyConfig;
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
import org.springframework.web.reactive.function.client.WebClient;

import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;

import static com.salesforce.functions.proxy.util.Constants.HEADER_EXTRA_INFO;

@Service
public class InvokeFunctionService {

    private static final Logger LOGGER = LoggerFactory.getLogger(InvokeFunctionService.class);

    @Autowired
    ProxyConfig proxyConfig;

    @Autowired
    RestTemplate restTemplate;

    @Autowired
    Utils utils;

    public ResponseEntity syncInvokeFunction(FunctionRequestContext functionRequestContext, String body) {
        String requestId = functionRequestContext.getRequestId();
        SfFnContext sfFnContext = functionRequestContext.getSfFnContext();
        utils.info(LOGGER, requestId,"Sync invoking function " + sfFnContext.getFunctionName() + "...");

        // Forward request to the function
        HttpEntity<String> entity = new HttpEntity<>(body, functionRequestContext.getHeaders());
        ResponseEntity<String> responseEntity;
        long startMs = System.currentTimeMillis();
        try {
            responseEntity = restTemplate.exchange(proxyConfig.getFunctionUrl(),
                                                   functionRequestContext.getMethod(),
                                                   entity,
                    String.class);
        } catch (HttpClientErrorException ex) {
            return ResponseEntity
                    .status(ex.getStatusCode())
                    .headers(ex.getResponseHeaders())
                    .body(ex.getResponseBodyAsString());
        } finally {
            utils.info(LOGGER, requestId,"Invoke function " + sfFnContext.getFunctionName() + " in " +
                    (System.currentTimeMillis() - startMs) + "ms");
        }

        return responseEntity;
    }

    @Async
    public void asyncInvokeFunction(FunctionRequestContext functionRequestContext, String body) {
        String requestId = functionRequestContext.getRequestId();
        SfFnContext sfFnContext = functionRequestContext.getSfFnContext();
        utils.info(LOGGER, requestId,"Async invoking function " + sfFnContext.getFunctionName() + "...");

        // Forward request to the function
        HttpEntity<String> entity = new HttpEntity<>(body, functionRequestContext.getHeaders());
        CompletableFuture<ResponseEntity<String>> future = null;
        long startMs = System.currentTimeMillis();
        try {
            future = CompletableFuture.completedFuture(
                    restTemplate.exchange(proxyConfig.getFunctionUrl(),
                            HttpMethod.POST,
                            entity,
                            String.class));
        } catch (HttpClientErrorException ex) {
            AsyncFunctionInvocationRequest asyncFunctionInvocationRequest =
                    new AsyncFunctionInvocationRequest(ex.getResponseHeaders().getFirst(HEADER_EXTRA_INFO),
                                                       ex.getResponseBodyAsString(),
                                                       "ERROR",
                                                       ex.getStatusCode().value());
            handleFunctionResponse(functionRequestContext, asyncFunctionInvocationRequest);
        } catch (Exception ex) {
            AsyncFunctionInvocationRequest asyncFunctionInvocationRequest =
                    new AsyncFunctionInvocationRequest("", ex.getMessage(), "ERROR", 503);
            handleFunctionResponse(functionRequestContext, asyncFunctionInvocationRequest);
        }

        CompletableFuture.allOf(future);
        try {
            handleFunctionResponse(functionRequestContext, future.get());
        } catch (Exception ex) {
            utils.error(LOGGER, requestId,"Unable to save async function response: " + ex.getMessage());
        } finally {
            utils.info(LOGGER, requestId,"Invoke function " + sfFnContext.getFunctionName() + " in " +
                    (System.currentTimeMillis() - startMs) + "ms");
        }
    }

    private void handleFunctionResponse(FunctionRequestContext functionRequestContext,
                                        ResponseEntity<String> functionResponseEntity) {
        String requestId = functionRequestContext.getRequestId();

        String extraInfoHeaderVal = functionResponseEntity.getHeaders().getFirst(HEADER_EXTRA_INFO);
        String extraInfo = "";
        try {
            extraInfo = extraInfoHeaderVal != null
                    ? URLDecoder.decode(extraInfoHeaderVal, StandardCharsets.UTF_8.toString()) : "";
        } catch (UnsupportedEncodingException ex) {
            utils.warn(LOGGER, requestId,"Unable to decode " + HEADER_EXTRA_INFO + " header: " + ex.getMessage());
        }
        String status = functionResponseEntity.getStatusCodeValue() < 200 || functionResponseEntity.getStatusCodeValue() > 299
                ? "ERROR" : "SUCCESS";
        AsyncFunctionInvocationRequest asyncFunctionInvocationRequest =
                new AsyncFunctionInvocationRequest(extraInfo,
                        functionResponseEntity.getBody(),
                        status,
                        functionResponseEntity.getStatusCodeValue());

        handleFunctionResponse(functionRequestContext, asyncFunctionInvocationRequest);
    }

    private void handleFunctionResponse(FunctionRequestContext functionRequestContext,
                                        AsyncFunctionInvocationRequest asyncFunctionInvocationRequest) {
        String requestId = functionRequestContext.getRequestId();
        SfFnContext sfFnContext = functionRequestContext.getSfFnContext();
        SfContext sfContext = functionRequestContext.getSfContext();
        SfContext.UserContext userContext = sfContext.getUserContext();

        String url = utils.assembleSalesforceAPIUrl(userContext.getSalesforceBaseUrl(),
                sfContext.getApiVersion(),
                "/sobjects/AsyncFunctionInvocationRequest__c/" + sfFnContext.getFunctionInvocationId());

        // Assemble PATCH sobject update request
        try {
            // RestTemplate (underlying HTTP client) does not natively support PATCH
            WebClient.ResponseSpec response = WebClient.create()
                    .patch()
                    .uri(new URI(url))
                    .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + functionRequestContext.getRequestProvidedAccessToken())
                    .bodyValue(utils.toJson(asyncFunctionInvocationRequest))
                    .retrieve();
            ResponseEntity<Void> fulfilledResponse = response.toBodilessEntity().block();

            if (fulfilledResponse == null || fulfilledResponse.getStatusCode() != HttpStatus.NO_CONTENT) {
                utils.error(LOGGER, requestId, "Unable to save function response to AsyncFunctionInvocationRequest__c [" +
                        sfFnContext.getFunctionInvocationId() + "]: " + (fulfilledResponse != null ? fulfilledResponse.getBody() : ""));
            } else {
                utils.info(LOGGER, requestId, "Updated function response [" + asyncFunctionInvocationRequest.getStatus()
                        + "] to AsyncFunctionInvocationRequest__c [" +
                        sfFnContext.getFunctionInvocationId() + "]");
            }
        } catch (Exception ex) {
            String errMsg = ex.getMessage();
            if (errMsg.contains("The requested resource does not exist")) {
                errMsg += ". Ensure that user " + userContext.getUsername() + " has access to AsyncFunctionInvocationRequest__c.";
            }
            utils.error(LOGGER, requestId,"Unable to save function response to AsyncFunctionInvocationRequest__c [" +
                    sfFnContext.getFunctionInvocationId() + "]: " + errMsg);
        }
    }
}
