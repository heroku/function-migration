package com.salesforce.functions.proxy.handler.request;

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
import static org.assertj.core.api.Assertions.assertThat;

@ExtendWith(MockitoExtension.class)
public class ValidateHeadersHandlerTest {

    private SfFnContext mockSfFnContext;
    private SfContext mockSfContext;
    private SfContext.UserContext mockUserContext;
    private ValidateHeadersHandler validateHeadersHandler;

    @BeforeEach
    public void init() {
        validateHeadersHandler = new ValidateHeadersHandler(new Utils());
        mockSfFnContext = new SfFnContext();
        mockSfContext = new SfContext();
        mockUserContext = new SfContext.UserContext();
        mockSfContext.setUserContext(mockUserContext);
    }

    @Test
    public void handle_happyPath() throws InvalidRequestException {
        String testName = this.getClass().getName();

        // Mocks
        mockSfFnContext.setAccessToken(testName);

        HttpHeaders headers = new HttpHeaders();
        headers.add(HEADER_REQUEST_ID, testName);
        headers.add(HttpHeaders.AUTHORIZATION, AUTHORIZATION_BEARER_PREFIX + " " + testName);
        for (String expectedCloudEventHeader : REQUIRED_CLOUD_EVENT_HEADERS) {
            headers.add(expectedCloudEventHeader, testName);
        }
        FunctionRequestContext functionRequestContext = new FunctionRequestContext(headers, HttpMethod.POST);
        functionRequestContext.setRequestId(testName);
        functionRequestContext.setSfFnContext(mockSfFnContext);

        // Test
        validateHeadersHandler.handle(functionRequestContext);
        assertThat(functionRequestContext.getRequestProvidedAccessToken()).isNotNull();
        assertThat(functionRequestContext.getRequestProvidedAccessToken()).isEqualTo(testName);
    }
}
