package com.salesforce.functions.proxy.controller;

import com.google.common.collect.Lists;
import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.service.InvokeFunctionService;
import com.salesforce.functions.proxy.service.StartFunctionService;
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

import static com.salesforce.functions.proxy.util.Constants.HEADER_HEALTH_CHECK;

/**
 * This controller returns the health of the function.
 */
@RestController
public class HealthCheckController {

    private static final Logger LOGGER = LoggerFactory.getLogger(HealthCheckController.class);

    @Autowired
    InvokeFunctionService invokeFunctionService;

    @Autowired
    StartFunctionService startFunctionService;

    @Autowired
    Utils utils;

    @RequestMapping("/healthcheck/**")
    public ResponseEntity<String> handleAsyncRequest(@RequestBody(required = false) String body,
                                                     @RequestHeader HttpHeaders headers) {
        String requestId = "healthcheck-" + System.currentTimeMillis();
        utils.info(LOGGER, requestId, "Received /healthcheck request");

        // TODO: Validate caller
        // Pass on check to function
        HttpMethod method = HttpMethod.POST;
        List<String> healthCheckHeaderVal = Lists.newArrayList("true");
        headers.put(HEADER_HEALTH_CHECK, healthCheckHeaderVal);
        FunctionRequestContext functionRequestContext = new FunctionRequestContext(headers, method);
        functionRequestContext.setRequestId(requestId);

        ResponseEntity responseEntity = null;
        try {
            responseEntity = invokeFunctionService.invokeFunction(functionRequestContext, body);
        } catch (Exception ex) {
            utils.warn(LOGGER, requestId, "Received /healthcheck exception: " + ex.getMessage());
            try {
                responseEntity = restartFunction(functionRequestContext, body);
            } catch (Exception restartEx) {
                String msg = "Function restart exception: " + ex.getMessage();
                utils.error(LOGGER, requestId, msg);
                return ResponseEntity
                        .status(503)
                        .body(msg);
            }
        }

        if (responseEntity.getStatusCode() != HttpStatus.OK) {
            utils.warn(LOGGER, requestId, "Received /healthcheck function response [" + responseEntity.getStatusCodeValue() + "]: " + responseEntity.getBody());
            try {
                responseEntity = restartFunction(functionRequestContext, body);
            } catch (Exception ex) {
                String msg = "Function restart exception: " + ex.getMessage();
                utils.error(LOGGER, requestId, msg);
                return ResponseEntity
                        .status(503)
                        .body(msg);
            }
        }

        return responseEntity;
    }

    public ResponseEntity restartFunction(FunctionRequestContext functionRequestContext, String body) throws Exception {
        String requestId = functionRequestContext.getRequestId();
        utils.info(LOGGER, requestId, "Attempting to restart function...");

        try {
            startFunctionService.start();
        } catch (Exception ex) {
            utils.error(LOGGER, requestId, "Unable to restart function: " + ex.getMessage());
            return ResponseEntity
                    .status(503)
                    .body(ex.getMessage());
        }

        // Give function time to restart
        Thread.sleep(3000);
        utils.info(LOGGER, requestId, "Retrying function /healthcheck...");
        return invokeFunctionService.invokeFunction(functionRequestContext, body);
    }
}