package com.salesforce.functions.proxy.handler.request;

import com.salesforce.functions.proxy.config.ProxyConfig;
import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.model.OauthExchangeResponse;
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

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Base64;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class MintTokenHandlerTest {

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
    private MintTokenHandler mintTokenHandler = new MintTokenHandler();

    @BeforeEach
    public void init() {
        mockSfFnContext = new SfFnContext();
        mockSfContext = new SfContext();
        mockUserContext = new SfContext.UserContext();
        mockSfContext.setUserContext(mockUserContext);
    }

    @Test
    public void handle_happyPath() throws InvalidRequestException, IOException {
        String testName = this.getClass().getName();

        // Mock values
        String orgDomainUrl = "http://localhost";
        String apiVersion = "57.0";
        String apiUri = "/" + testName;
        String apiUrl = utils.assembleSalesforceAPIUrl(orgDomainUrl, apiVersion, apiUri);
        OauthExchangeResponse oauthExchangeResponse = new OauthExchangeResponse();
        oauthExchangeResponse.setAccess_token(testName);

        // Mocks
        mockSfFnContext.setAccessToken(testName);
        mockUserContext.setOrgDomainUrl(orgDomainUrl);
        mockUserContext.setUsername(testName);
        mockSfContext.setApiVersion(apiVersion);
        when(mockProxyConfig.getOauth2TokenUri()).thenReturn(apiUri);
        when(mockProxyConfig.getConsumerKey()).thenReturn("3MVG9SemV5D8");
        java.security.Security.addProvider(new org.bouncycastle.jce.provider.BouncyCastleProvider());
        Path path = Paths.get("src/test/resources/fakePrivateKey.key");
        String privateKey = Files.readAllLines(path)
                .stream()
                .collect(Collectors.joining(System.lineSeparator()));
        when(mockProxyConfig.getEncodedPrivateKey()).thenReturn(Base64.getEncoder().encodeToString(privateKey.getBytes(StandardCharsets.UTF_8)));
        when(mockUtils.isBlank(any())).thenCallRealMethod();
        // FIXME: eq(apiUrl)
        when(mockRestTemplate.postForEntity(anyString(), any(), eq(OauthExchangeResponse.class)))
          .thenReturn(new ResponseEntity<OauthExchangeResponse>(oauthExchangeResponse, HttpStatus.OK));
        HttpHeaders headers = new HttpHeaders();
        FunctionRequestContext functionRequestContext = new FunctionRequestContext(headers, HttpMethod.POST);
        functionRequestContext.setRequestId(testName);
        functionRequestContext.setSfFnContext(mockSfFnContext);
        functionRequestContext.setSfContext(mockSfContext);

        // Test
        mintTokenHandler.handle(functionRequestContext);
        assertThat(functionRequestContext.getSfFnContext().getAccessToken()).isNotNull();
        assertThat(functionRequestContext.getSfFnContext().getAccessToken()).isEqualTo(testName);
    }
}
