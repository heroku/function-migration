package com.salesforce.functions.proxy.handler.request;

import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.model.SfFnContext;
import com.salesforce.functions.proxy.util.InvalidRequestException;
import com.salesforce.functions.proxy.util.Utils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;

import static com.salesforce.functions.proxy.util.Constants.HEADER_FUNCTION_REQUEST_CONTEXT;
import static org.assertj.core.api.Assertions.assertThat;

@ExtendWith(MockitoExtension.class)
public class PrepareFunctionRequestHandlerTest {

    private SfFnContext mockSfFnContext;
    private PrepareFunctionRequestHandler prepareFunctionRequestHandler;

    @BeforeEach
    public void init() {
        prepareFunctionRequestHandler = new PrepareFunctionRequestHandler(new Utils());
        mockSfFnContext = new SfFnContext();
    }

    @Test
    public void handle_happyPath() throws InvalidRequestException {
        String testName = this.getClass().getName();

        // Mocks
        mockSfFnContext.setAccessToken(testName);
        HttpHeaders headers = new HttpHeaders();
        FunctionRequestContext functionRequestContext = new FunctionRequestContext(headers, HttpMethod.POST);
        functionRequestContext.setRequestId(testName);
        functionRequestContext.setSfFnContext(mockSfFnContext);

        // Test
        prepareFunctionRequestHandler.handle(functionRequestContext);
        assertThat(functionRequestContext.getHeaders().getFirst(HEADER_FUNCTION_REQUEST_CONTEXT)).isNotNull();
    }
}