package com.salesforce.functions.proxy.handler.request;

import com.salesforce.functions.proxy.config.ProxyConfig;
import com.salesforce.functions.proxy.model.ActionResponse;
import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.model.SfContext;
import com.salesforce.functions.proxy.model.SfFnContext;
import com.salesforce.functions.proxy.util.InvalidRequestException;
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
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.List;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class ActivatePermissionSetsHandlerTest {

    @Mock
    private ProxyConfig mockProxyConfig;
    @Mock
    private RestTemplate mockRestTemplate;
    @Mock
    private Utils mockUtils;
    private SfFnContext mockSfFnContext;
    private SfContext mockSfContext;
    private SfContext.UserContext mockUserContext;
    private Utils utils = new Utils();
    @InjectMocks
    private ActivatePermissionSetsHandler activatePermissionSetsHandler = new ActivatePermissionSetsHandler();

    @BeforeEach
    public void init() {
        mockSfFnContext = new SfFnContext();
        mockSfContext = new SfContext();
        mockUserContext = new SfContext.UserContext();
        mockSfContext.setUserContext(mockUserContext);
    }

    @Test
    public void handle_happyPath() throws InvalidRequestException {
        String testName = this.getClass().getName();

        // Mock values
        String orgDomainUrl = "http://localhost";
        String apiVersion = "57.0";
        String apiUri = "/" + testName;
        String apiUrl = utils.assembleSalesforceAPIUrl(orgDomainUrl, apiVersion, apiUri);
        ActionResponse actionResponse = new ActionResponse();
        actionResponse.setIsSuccess(true);
        ActionResponse[] actionResponses = new ActionResponse[] { actionResponse };

        // Mocks
        mockSfFnContext.setAccessToken(testName);
        mockUserContext.setOrgDomainUrl(orgDomainUrl);
        mockSfContext.setApiVersion(apiVersion);
        List<String> permSets = new ArrayList<>();
        permSets.add("ns__" + testName);
        permSets.add(testName);
        mockSfFnContext.setPermissionSetS(permSets);
        when(mockProxyConfig.getActivateSessionPermSetUri()).thenReturn(apiUri);
        when(mockUtils.assembleSalesforceAPIUrl(anyString(), anyString(), anyString())).thenCallRealMethod();
        when(mockUtils.isBlank(any())).thenCallRealMethod();
        when(mockRestTemplate.postForEntity(eq(apiUrl), any(Object.class), eq(ActionResponse[].class)))
          .thenReturn(new ResponseEntity(actionResponses, HttpStatus.OK));
        HttpHeaders headers = new HttpHeaders();
        FunctionRequestContext functionRequestContext = new FunctionRequestContext(headers, HttpMethod.POST);
        functionRequestContext.setRequestId(testName);
        functionRequestContext.setSfFnContext(mockSfFnContext);
        functionRequestContext.setSfContext(mockSfContext);

        // Test
        activatePermissionSetsHandler.handle(functionRequestContext);
    }
}
