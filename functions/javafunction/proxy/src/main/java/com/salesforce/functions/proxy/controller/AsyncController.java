package com.salesforce.functions.proxy.controller;

import com.salesforce.functions.proxy.config.ProxyConfig;
import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.model.SfContext;
import com.salesforce.functions.proxy.model.SfFnContext;
import com.salesforce.functions.proxy.service.AsyncInvokeFunctionService;
import com.salesforce.functions.proxy.util.InvalidRequestException;
import com.salesforce.functions.proxy.util.Utils;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.*;
import org.springframework.scheduling.annotation.Async;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;

import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;

import static com.salesforce.functions.proxy.util.Constants.HEADER_EXTRA_INFO;

/**
 * This controller handles async requests disconnecting from the client before managing function invocation.
 * Before disconnecting from the client, this controller:
 *   - Validates the request ensure expected payload and that the caller is from the owner org.
 *   - Enriches the function payload minting an org-accessible token for the function and activating
 *     given Permission Sets on the function's token, if applicable.
 */
@RestController
public class AsyncController extends BaseController {

    private static final Logger LOGGER = LoggerFactory.getLogger(AsyncController.class);

    @Autowired
    ProxyConfig proxyConfig;

    @Autowired
    AsyncInvokeFunctionService asyncInvokeFunctionService;

    @RequestMapping("/async/**")
    public ResponseEntity<String> handleAsyncRequest(@RequestBody String body,
                                                     @RequestHeader HttpHeaders headers) {
        // Validate and enrich request
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

        // Async'ly invoke function
        asyncInvokeFunctionService.invokeFunction(functionRequestContext, body);

        return ResponseEntity.status(HttpStatus.CREATED).build();
    }
}
