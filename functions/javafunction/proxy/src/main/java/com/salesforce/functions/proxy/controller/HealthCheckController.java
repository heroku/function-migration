package com.salesforce.functions.proxy.controller;

import com.google.common.collect.Lists;
import com.salesforce.functions.proxy.handler.Handler;
import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.service.InvokeFunctionService;
import com.salesforce.functions.proxy.util.InvalidRequestException;
import com.salesforce.functions.proxy.util.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

import static com.salesforce.functions.proxy.util.Constants.HEADER_FUNCTION_REQUEST_CONTEXT;
import static com.salesforce.functions.proxy.util.Constants.HEADER_HEALTH_CHECK;

/**
 * This controller returns the health of the function.
 */
@RestController
public class HealthCheckController {

    private static final Logger LOGGER = LoggerFactory.getLogger(SyncController.class);

    @Autowired
    InvokeFunctionService invokeFunctionService;

    @RequestMapping("/healthcheck/**")
    public ResponseEntity<String> handleAsyncRequest(@RequestBody(required = false) String body,
                                                     @RequestHeader HttpHeaders headers,
                                                     HttpMethod method) {
        // TODO: Validate caller
        // Pass on check to function
        List<String> healthCheckHeaderVal = Lists.newArrayList("true");
        headers.put(HEADER_HEALTH_CHECK, healthCheckHeaderVal);
        FunctionRequestContext functionRequestContext = new FunctionRequestContext(headers, method);

        return invokeFunctionService.invokeFunction(functionRequestContext, body);
    }
}
