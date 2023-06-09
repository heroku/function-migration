package com.salesforce.functions.proxy.service;

import com.salesforce.functions.proxy.config.ProxyConfig;
import com.salesforce.functions.proxy.handler.response.ResponseHandler;
import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.util.Utils;
import org.awaitility.Duration;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.RestTemplate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class InvokeFunctionServiceTest {

    @Mock
    private ProxyConfig mockProxyConfig;
    @Mock
    private RestTemplate mockRestTemplate;
    @Mock
    private Utils mockUtils;
    @InjectMocks
    private InvokeFunctionService invokeFunctionService = new InvokeFunctionService();

    @BeforeEach
    public void init() {
    }

    @Test
    public void invokeFunction_happyPath() {
        String testName = this.getClass().getName();

        // Mock values
        String apiUrl = "http://localhost";

        // Mocks
        when(mockProxyConfig.getFunctionUrl()).thenReturn(apiUrl);
        when(mockRestTemplate.exchange(any(String.class), any(), any(), eq(String.class)))
                .thenReturn(new ResponseEntity("", HttpStatus.OK));
        HttpHeaders headers = new HttpHeaders();
        FunctionRequestContext functionRequestContext = new FunctionRequestContext(headers, HttpMethod.POST);
        functionRequestContext.setRequestId(testName);

        // Test
        ResponseEntity responseEntity = invokeFunctionService.invokeFunction("healthcheck", functionRequestContext, "");
        assertThat(responseEntity).isNotNull();
        assertThat(responseEntity.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    public void syncInvokeFunction_happyPath() {
        String testName = this.getClass().getName();

        // Mock values
        String apiUrl = "http://localhost";

        // Mocks
        when(mockProxyConfig.getFunctionUrl()).thenReturn(apiUrl);
        when(mockRestTemplate.exchange(any(String.class), any(), any(), eq(String.class)))
                .thenReturn(new ResponseEntity("", HttpStatus.OK));
        HttpHeaders headers = new HttpHeaders();
        FunctionRequestContext functionRequestContext = new FunctionRequestContext(headers, HttpMethod.POST);
        functionRequestContext.setRequestId(testName);

        // Test
        ResponseEntity responseEntity = invokeFunctionService.syncInvokeFunction(functionRequestContext, "");
        assertThat(responseEntity).isNotNull();
        assertThat(responseEntity.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    public void asyncInvokeFunction_happyPath() {
        String testName = this.getClass().getName();

        // Mock values
        String apiUrl = "http://localhost";

        // Mocks
        when(mockProxyConfig.getFunctionUrl()).thenReturn(apiUrl);
        when(mockRestTemplate.exchange(any(String.class), any(), any(), eq(String.class)))
                .thenReturn(new ResponseEntity("", HttpStatus.OK));
        HttpHeaders headers = new HttpHeaders();
        FunctionRequestContext functionRequestContext = new FunctionRequestContext(headers, HttpMethod.POST);
        functionRequestContext.setRequestId(testName);
        ResponseHandler mockResponseHandler = mock(ResponseHandler.class);

        // Test
        invokeFunctionService.asyncInvokeFunction(functionRequestContext, "", mockResponseHandler);
        await().atMost(Duration.FIVE_SECONDS).untilAsserted(() ->
                verify(mockResponseHandler, times(1)).handleResponse(any(), any()));
    }
}
