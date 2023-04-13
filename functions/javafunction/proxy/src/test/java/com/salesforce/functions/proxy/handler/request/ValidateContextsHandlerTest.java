package com.salesforce.functions.proxy.handler.request;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.model.SfContext;
import com.salesforce.functions.proxy.model.SfFnContext;
import com.salesforce.functions.proxy.util.InvalidRequestException;
import com.salesforce.functions.proxy.util.Utils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;

import static com.salesforce.functions.proxy.util.Constants.*;

@ExtendWith(MockitoExtension.class)
public class ValidateContextsHandlerTest {

    private SfFnContext mockSfFnContext;
    private SfContext mockSfContext;
    private SfContext.UserContext mockUserContext;
    private ValidateContextsHandler validateContextsHandler;
    private Utils utils = new Utils();

    @BeforeEach
    public void init() {
        validateContextsHandler = new ValidateContextsHandler(new Utils());
        mockSfFnContext = new SfFnContext();
        mockSfContext = new SfContext();
        mockUserContext = new SfContext.UserContext();
        mockSfContext.setUserContext(mockUserContext);
    }

    @Test
    public void handle_happyPath() throws InvalidRequestException, JsonProcessingException {
        String testName = this.getClass().getName();

        // Mocks
        mockSfFnContext.setAccessToken(testName);
        HttpHeaders headers = new HttpHeaders();
        mockSfFnContext.setFunctionName(testName);
        mockSfFnContext.setType(FUNCTION_INVOCATION_TYPE_ASYNC);
        mockSfFnContext.setFunctionInvocationId(testName);
        headers.add(HEADER_FUNCTION_REQUEST_CONTEXT, utils.toEncodedJson(mockSfFnContext));
        mockSfContext.setApiVersion("57.0");
        mockUserContext.setOrgId(testName);
        mockUserContext.setUsername(testName);
        mockUserContext.setUsername(testName);
        mockUserContext.setOrgDomainUrl(testName);
        mockUserContext.setSalesforceBaseUrl(testName);
        headers.add(HEADER_SALESFORCE_CONTEXT, utils.toEncodedJson(mockSfContext));
        FunctionRequestContext functionRequestContext = new FunctionRequestContext(headers, HttpMethod.POST);
        functionRequestContext.setRequestId(testName);

        // Test
        validateContextsHandler.handle(functionRequestContext);
    }
}