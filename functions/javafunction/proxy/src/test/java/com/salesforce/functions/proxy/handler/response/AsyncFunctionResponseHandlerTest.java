package com.salesforce.functions.proxy.handler.response;

import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.model.SfContext;
import com.salesforce.functions.proxy.model.SfFnContext;
import com.salesforce.functions.proxy.util.Utils;
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
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;

import java.nio.charset.StandardCharsets;

import static com.salesforce.functions.proxy.util.Constants.HEADER_EXTRA_INFO;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class AsyncFunctionResponseHandlerTest {

    @Mock
    private RestTemplate mockRestTemplate;
    @Mock
    private Utils mockUtils;
    private SfFnContext mockSfFnContext;
    private SfContext mockSfContext;
    private SfContext.UserContext mockUserContext;
    private Utils utils = new Utils();
    @InjectMocks
    private AsyncFunctionResponseHandler asyncFunctionResponseHandler = new AsyncFunctionResponseHandler();

    @BeforeEach
    public void init() {
        mockSfFnContext = new SfFnContext();
        mockSfContext = new SfContext();
        mockUserContext = new SfContext.UserContext();
        mockSfContext.setUserContext(mockUserContext);
    }

    @Test
    public void handleError_happyPath() {
        String testName = this.getClass().getName();

        // Mock values
        String orgDomainUrl = "http://localhost";
        String apiVersion = "57.0";
        String apiUri = testName + "__" + "__AsyncFunctionInvocationRequest__c";
        String apiUrl = utils.assembleSalesforceAPIUrl(orgDomainUrl, apiVersion, apiUri);

        // Mocks
        mockSfFnContext.setAccessToken(testName);
        mockSfContext.setApiVersion(apiVersion);
        mockUserContext.setNamespace(testName);
        mockUserContext.setOrgDomainUrl(orgDomainUrl);
        when(mockUtils.assembleSalesforceAPIUrl(anyString(), anyString(), anyString())).thenCallRealMethod();
        when(mockUtils.assembleSalesforceAPIHeaders(any())).thenCallRealMethod();
        when(mockUtils.isBlank(any())).thenCallRealMethod();
        when(mockRestTemplate.postForEntity(eq(apiUrl), any(Object.class), eq(String.class)))
          .thenReturn(new ResponseEntity("", HttpStatus.OK));
        FunctionRequestContext functionRequestContext = new FunctionRequestContext(new HttpHeaders(), HttpMethod.POST);
        functionRequestContext.setRequestId(testName);
        functionRequestContext.setSfFnContext(mockSfFnContext);
        functionRequestContext.setSfContext(mockSfContext);
        HttpHeaders headers = new HttpHeaders();
        headers.add(HEADER_EXTRA_INFO, testName);
        HttpClientErrorException ex = new HttpClientErrorException(HttpStatus.BAD_GATEWAY,
                                                                   testName,
                                                                   headers,
                                                                   "".getBytes(),
                                                                   StandardCharsets.UTF_8);

        // Test
        asyncFunctionResponseHandler.handleError(functionRequestContext, ex);
        asyncFunctionResponseHandler.handleError(functionRequestContext, new Exception());
    }

    @Test
    public void handleResponse_happyPath() {
        String testName = this.getClass().getName();

        // Mock values
        String orgDomainUrl = "http://localhost";
        String apiVersion = "57.0";
        String apiUri = testName + "__" + "__AsyncFunctionInvocationRequest__c";
        String apiUrl = utils.assembleSalesforceAPIUrl(orgDomainUrl, apiVersion, apiUri);

        // Mocks
        mockSfFnContext.setAccessToken(testName);
        mockSfContext.setApiVersion(apiVersion);
        mockUserContext.setNamespace(testName);
        mockUserContext.setOrgDomainUrl(orgDomainUrl);
        when(mockUtils.assembleSalesforceAPIUrl(anyString(), anyString(), anyString())).thenCallRealMethod();
        when(mockUtils.assembleSalesforceAPIHeaders(any())).thenCallRealMethod();
        when(mockUtils.isBlank(any())).thenCallRealMethod();
        when(mockRestTemplate.postForEntity(eq(apiUrl), any(Object.class), eq(String.class)))
                .thenReturn(new ResponseEntity("", HttpStatus.OK));
        FunctionRequestContext functionRequestContext = new FunctionRequestContext(new HttpHeaders(), HttpMethod.POST);
        functionRequestContext.setRequestId(testName);
        functionRequestContext.setSfFnContext(mockSfFnContext);
        functionRequestContext.setSfContext(mockSfContext);
        HttpHeaders headers = new HttpHeaders();
        headers.add(HEADER_EXTRA_INFO, testName);
        ResponseEntity functionResponseEntity = new ResponseEntity(headers, HttpStatus.OK);

        // Test
        asyncFunctionResponseHandler.handleResponse(functionRequestContext, functionResponseEntity);
    }
}
