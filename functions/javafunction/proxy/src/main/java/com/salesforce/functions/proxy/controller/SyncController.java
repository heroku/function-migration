package com.salesforce.functions.proxy.controller;

import com.salesforce.functions.proxy.config.ProxyConfig;
import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.util.InvalidRequestException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;

import java.net.URI;
import java.net.URISyntaxException;

/**
 * This contorller forwards /sync function invocation requests to function.  But first, this controller:
 *   - Validates the request ensure expected payload and that the caller is from the owner org.
 *   - Enriches the function payload minting a org-accessible token for the function and activating
 *     given Permission Sets on the function's token, if applicable
 */
@RestController
public class SyncController extends BaseController {
    @RequestMapping("/sync/**")
    public ResponseEntity<String> handleSyncRequest(@RequestBody(required = false) String body,
                                                    @RequestHeader HttpHeaders headers,
                                                    HttpMethod method) {

        FunctionRequestContext functionRequestContext;
        try {
            functionRequestContext = handleRequest(headers);
        } catch (InvalidRequestException ex) {
            return ResponseEntity
                    .status(ex.getStatusCode())
                    .body(ex.getMessage());
        } catch (Exception ex) {
            return ResponseEntity
                    .status(503)
                    .body(ex.getMessage());
        }

        // Forward request to the function
        HttpEntity<String> entity = new HttpEntity<>(body, functionRequestContext.getHeaders());
        ResponseEntity<String> responseEntity;
        try {
            responseEntity = restTemplate.exchange(proxyConfig.getFunctionUrl(), method, entity, String.class);
        } catch (HttpClientErrorException ex) {
            return ResponseEntity
                    .status(ex.getStatusCode())
                    .headers(ex.getResponseHeaders())
                    .body(ex.getResponseBodyAsString());
        }

        return responseEntity;
    }
}
