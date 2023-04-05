package com.salesforce.functions.proxy.handler;

import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.model.UserInfoResponse;
import com.salesforce.functions.proxy.util.InvalidRequestException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

@Order(30)
@Component
public class ValidateCaller extends BaseHandler {

    private static final Logger LOGGER = LoggerFactory.getLogger(ValidateCaller.class);

    @Autowired
    RestTemplate restTemplate;

    /**
     * Validate that requesting org is expected org (orgId18) by using given token to verify org info
     * provided by /userinfo API.
     *
     * Alternative approach that is simpler and efficient send a private key encrypted value and is
     * decrypted w/ a public key and validated by the proxy.
     *
     * @param functionRequestContext
     * @throws InvalidRequestException
     */
    @Override
    public void handle(FunctionRequestContext functionRequestContext) throws InvalidRequestException {
        String requestId = functionRequestContext.getRequestId();
        String url = functionRequestContext.getSfContext().getUserContext().getSalesforceBaseUrl() + "/services/oauth2/userinfo";
        ResponseEntity<UserInfoResponse> responseEntity = null;
        try {
            HttpEntity<String> entity = new HttpEntity<>(utils.assembleSalesforceAPIHeaders(functionRequestContext));
            responseEntity = restTemplate.exchange(url, HttpMethod.GET, entity, UserInfoResponse.class);
        } catch (Exception ex) {
            throw new InvalidRequestException(requestId,
                    "Unable to validate request: " + ex.getMessage(),
                    responseEntity != null ? responseEntity.getStatusCode().value() : 400);
        }

        UserInfoResponse userInfo = responseEntity.getBody();
        if (null == userInfo || responseEntity.getStatusCode() != HttpStatus.OK) {
            throw new InvalidRequestException(requestId, "Unauthorized request", 400);
        }

        String expectedOrgId18 = proxyConfig.getOrgId18();
        if (utils.isBlank(userInfo.getOrganization_id()) || !userInfo.getOrganization_id().equals(expectedOrgId18)) {
            LOGGER.warn("[" + requestId + "] Unauthorized caller from org " + userInfo.getOrganization_id() +
                    ", expected " + expectedOrgId18);
            throw new InvalidRequestException(requestId, "Unauthorized request", 401);
        }

        utils.info(LOGGER, requestId, "Validated client - good to go");
    }
}