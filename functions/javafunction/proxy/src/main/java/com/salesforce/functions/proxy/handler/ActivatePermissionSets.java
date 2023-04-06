package com.salesforce.functions.proxy.handler;

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.salesforce.functions.proxy.model.*;
import com.salesforce.functions.proxy.util.InvalidRequestException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

@Order(50)
@Component
public class ActivatePermissionSets extends BaseHandler {

    private static final Logger LOGGER = LoggerFactory.getLogger(ActivatePermissionSets.class);

    @Autowired
    RestTemplate restTemplate;

    /**
     * Activate session-based Permission Sets, if applicable.
     *
     * @param functionRequestContext
     * @throws InvalidRequestException
     */
    @Override
    public void handle(FunctionRequestContext functionRequestContext) throws InvalidRequestException {
        String requestId = functionRequestContext.getRequestId();
        SfFnContext functionContext = functionRequestContext.getSfFnContext();
        SfContext salesforceContext = functionRequestContext.getSfContext();
        SfContext.UserContext userContext = salesforceContext.getUserContext();

        if (utils.isBlank(functionContext.getAccessToken())) {
            throw new InvalidRequestException(requestId,
                    "Unable activate session-based Permission Sets: function's token not provided",
                    401);
        }

        List<String> permissionSets = functionContext.getPermissionSets();
        if (permissionSets == null || permissionSets.isEmpty()) {
            LOGGER.info("[" + requestId + "] Skipping session-based Permission Sets activation");
            return;
        }

        // Assemble action payload
        Map<String,Object> inputs = Maps.newHashMap();
        List<ActivatePermSetRequest> toActivatePermSetRequests = Lists.newArrayList();
        inputs.put("inputs", toActivatePermSetRequests);
        permissionSets.forEach(permissionSet -> {
            toActivatePermSetRequests.add(new ActivatePermSetRequest(permissionSet));
        });

        String url = utils.assembleSalesforceAPIUrl(userContext.getSalesforceBaseUrl(),
                salesforceContext.getApiVersion(),
                "/actions/standard/activateSessionPermSet");

        // Assemble POST action request
        ResponseEntity<ActionResponse[]> responseEntity = null;
        try {
            HttpEntity<String> entity = new HttpEntity<>(utils.toJson(inputs),
                    utils.assembleSalesforceAPIHeaders(functionRequestContext));
            responseEntity = restTemplate.postForEntity(url, entity, ActionResponse[].class);
        } catch (Exception ex) {
            throw new InvalidRequestException(requestId,
                    "Unable activated session-based Permission Set(s): " +
                            String.join(",", permissionSets) + ex.getMessage(),
                    responseEntity != null ? responseEntity.getStatusCode().value() : 401);
        }

        if (responseEntity.getStatusCode() != HttpStatus.OK) {
            throw new InvalidRequestException(requestId,
                    "Unable activated session-based Permission Set(s): " + String.join(",", permissionSets),
                    responseEntity.getStatusCode().value());
        }

        ActionResponse[] actionResponses = responseEntity.getBody();
        if (actionResponses != null
                && actionResponses.length > 0
                && Arrays.stream(actionResponses).filter(ar -> !ar.isSuccess()).findFirst().isPresent()) {
            // TODO: Include all errors
            ActionResponse failedActionResponse = Arrays.stream(actionResponses)
                    .filter(ar -> null != ar.getErrors() && ar.getErrors().size() > 0)
                    .findFirst()
                    .get();
            throw new InvalidRequestException(requestId,
                    "Unable activated session-based Permission Set(s): " +
                            failedActionResponse != null ? utils.toJsonNoThrow(failedActionResponse.getErrors()) : "unknown",
                    responseEntity.getStatusCode().value());
        }

        utils.info(LOGGER, requestId, "Activated session-based Permission Set(s): " +
                String.join(",", permissionSets) + " - yessir");
    }
}
