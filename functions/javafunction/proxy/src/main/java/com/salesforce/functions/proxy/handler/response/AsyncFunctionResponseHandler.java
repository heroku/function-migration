package com.salesforce.functions.proxy.handler.response;

import com.salesforce.functions.proxy.model.AsyncFunctionInvocationRequest;
import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.model.SfContext;
import com.salesforce.functions.proxy.model.SfFnContext;
import com.salesforce.functions.proxy.util.InvalidRequestException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;

import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;

import static com.salesforce.functions.proxy.util.Constants.HEADER_EXTRA_INFO;

/**
 * Handle function responses from async requests.  Responses are saved to associated AsyncFunctionInvocationRequest__c.
 */
@Component
public class AsyncFunctionResponseHandler extends BaseResponseHandler {

    private static final Logger LOGGER = LoggerFactory.getLogger(AsyncFunctionResponseHandler.class);

    @Autowired
    RestTemplate restTemplate;

    @Override
    public void handleError(FunctionRequestContext functionRequestContext, Exception ex) {
        SfContext.UserContext userContext = functionRequestContext.getSfContext().getUserContext();

        AsyncFunctionInvocationRequest asyncFunctionInvocationRequest = null;
        if (ex instanceof HttpClientErrorException) {
            HttpClientErrorException httpEx = (HttpClientErrorException)ex;
            asyncFunctionInvocationRequest = new AsyncFunctionInvocationRequest(userContext.getNamespace(),
                                                                                httpEx.getResponseHeaders().getFirst(HEADER_EXTRA_INFO),
                                                                                httpEx.getResponseBodyAsString(),
                                                                            "ERROR",
                                                                                httpEx.getStatusCode().value());
            handleFunctionResponse(functionRequestContext, asyncFunctionInvocationRequest);
        } else {
            asyncFunctionInvocationRequest = new AsyncFunctionInvocationRequest(userContext.getNamespace(),
                                                                        "",
                                                                                ex.getMessage(),
                                                                          "ERROR",
                                                                       503);

        }

        handleFunctionResponse(functionRequestContext, asyncFunctionInvocationRequest);
    }

    @Override
    public void handleResponse(FunctionRequestContext functionRequestContext, ResponseEntity<String> functionResponseEntity) {
        String requestId = functionRequestContext.getRequestId();
        SfContext.UserContext userContext = functionRequestContext.getSfContext().getUserContext();

        String extraInfo = functionResponseEntity.getHeaders().getFirst(HEADER_EXTRA_INFO);
        String status = functionResponseEntity.getStatusCodeValue() < 200 || functionResponseEntity.getStatusCodeValue() > 299
                ? "ERROR" : "SUCCESS";
        AsyncFunctionInvocationRequest asyncFunctionInvocationRequest =
                new AsyncFunctionInvocationRequest(userContext.getNamespace(),
                                                   extraInfo,
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

        String afirObjectName =
                (!utils.isBlank(userContext.getNamespace()) ? userContext.getNamespace() + "__" : "") + "AsyncFunctionInvocationRequest__c";
        String uriPart = "/sobjects/" + afirObjectName + "/" + sfFnContext.getFunctionInvocationId() + "?_HttpMethod=PATCH";
        String url = utils.assembleSalesforceAPIUrl(userContext.getOrgDomainUrl(),
                sfContext.getApiVersion(),
                uriPart);

        if (utils.isBlank(sfFnContext.getAccessToken())) {
            utils.error(LOGGER, requestId, "Unable to save function response to " + afirObjectName +
                    " [" + sfFnContext.getFunctionInvocationId() + "]: function's token not provided");
            return;
        }

        // Assemble POST (PATCH) sobject update request
        try {
            String afirJson = utils.toJson(asyncFunctionInvocationRequest);
            utils.debug(LOGGER, requestId, "POST " + uriPart + ": " + afirJson);

            HttpHeaders httpHeaders = utils.assembleSalesforceAPIHeaders(sfFnContext.getAccessToken());
            HttpEntity<String> entity = new HttpEntity<>(afirJson, httpHeaders);
            ResponseEntity<String> responseEntity = restTemplate.postForEntity(url, entity, String.class);

            if (responseEntity == null || responseEntity.getStatusCode() != HttpStatus.NO_CONTENT) {
                utils.error(LOGGER, requestId, "Unable to save function response to " + afirObjectName + " [" +
                        sfFnContext.getFunctionInvocationId() + "]: " + (responseEntity != null ? responseEntity.getBody() : ""));
            } else {
                utils.info(LOGGER, requestId, "Updated function response [" + asyncFunctionInvocationRequest.getStatus()
                        + "] to AsyncFunctionInvocationRequest__c [" +
                        sfFnContext.getFunctionInvocationId() + "]");
            }
        } catch (Exception ex) {
            String errMsg = ex.getMessage();
            if (errMsg.contains("The requested resource does not exist")) {
                errMsg += ". Ensure that user " + userContext.getUsername() + " has access to " + afirObjectName + ".";
            }
            utils.error(LOGGER, requestId,"Unable to save function response to " + afirObjectName + " [" +
                    sfFnContext.getFunctionInvocationId() + "]: " + errMsg);
        }
    }
}