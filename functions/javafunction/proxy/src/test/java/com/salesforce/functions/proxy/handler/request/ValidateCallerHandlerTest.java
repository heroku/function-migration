package com.salesforce.functions.proxy.handler.request;

import com.salesforce.functions.proxy.config.ProxyConfig;
import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.model.SfContext;
import com.salesforce.functions.proxy.model.SfFnContext;
import com.salesforce.functions.proxy.model.UserInfoResponse;
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

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class ValidateCallerHandlerTest {

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
    private ValidateCallerHandler validateCallerHandler = new ValidateCallerHandler();

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
        String orgId = "00D";
        String orgDomainUrl = "http://localhost";
        String apiVersion = "57.0";
        String apiUri = "/" + testName;
        String apiUrl = utils.assembleSalesforceAPIUrl(orgDomainUrl, apiVersion, apiUri);
        UserInfoResponse userInfoResponse = new UserInfoResponse();
        userInfoResponse.setOrganization_id(orgId);

        // Mocks
        mockSfFnContext.setAccessToken(testName);
        mockUserContext.setOrgDomainUrl(orgDomainUrl);
        mockSfContext.setApiVersion(apiVersion);
        when(mockProxyConfig.getUserInfoUri()).thenReturn(apiUri);
        when(mockProxyConfig.getOrgId18()).thenReturn(orgId);
        when(mockUtils.isBlank(any())).thenCallRealMethod();
        when(mockRestTemplate.exchange(any(), any(), any(), eq(UserInfoResponse.class)))
          .thenReturn(new ResponseEntity(userInfoResponse, HttpStatus.OK));
        HttpHeaders headers = new HttpHeaders();
        FunctionRequestContext functionRequestContext = new FunctionRequestContext(headers, HttpMethod.POST);
        functionRequestContext.setRequestId(testName);
        functionRequestContext.setSfFnContext(mockSfFnContext);
        functionRequestContext.setSfContext(mockSfContext);

        // Test
        validateCallerHandler.handle(functionRequestContext);
    }
}
