package com.salesforce.functions.proxy.controller;

import com.salesforce.functions.proxy.config.ProxyConfig;
import com.salesforce.functions.proxy.handler.request.RequestHandler;
import com.salesforce.functions.proxy.service.InvokeFunctionService;
import com.salesforce.functions.proxy.service.StartFunctionService;
import com.salesforce.functions.proxy.util.Utils;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.List;

import static com.salesforce.functions.proxy.util.Constants.HEADER_ORG_ID_18;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class HealthCheckControllerTest {

    @Mock
    private ProxyConfig mockProxyConfig;

    @Mock
    private Utils mockUtils;

    @Mock
    StartFunctionService mockStartFunctionService;

    @Mock
    InvokeFunctionService mockInvokeFunctionService;

    @InjectMocks
    HealthCheckController healthCheckController = new HealthCheckController();

    @Test
    public void handleRequest_happyPath() {
        String orgId = "ORGID";
        when(mockProxyConfig.getOrgId18()).thenReturn(orgId);
        when(mockInvokeFunctionService.invokeFunction(eq("healthcheck"), any(), any()))
                .thenReturn(new ResponseEntity("OK", HttpStatus.OK));

        HttpHeaders headers = new HttpHeaders();
        headers.add(HEADER_ORG_ID_18, orgId);
        ResponseEntity<String> responseEntity = healthCheckController.handleRequest("", headers);
        assertThat(responseEntity).isNotNull();
        assertThat(responseEntity.getStatusCode()).isEqualTo(HttpStatus.OK);
    }
}
