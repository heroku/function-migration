package com.salesforce.functions.proxy.controller;

import com.google.common.collect.ImmutableList;
import com.salesforce.functions.proxy.handler.request.RequestHandler;
import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.service.InvokeFunctionService;
import com.salesforce.functions.proxy.util.InvalidRequestException;
import com.salesforce.functions.proxy.util.Utils;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.List;

import static com.salesforce.functions.proxy.util.Constants.HEADER_ORG_ID_18;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class SyncControllerTest {

    @Mock
    private Utils mockUtils;

    @Mock
    InvokeFunctionService mockInvokeFunctionService;

    @InjectMocks
    SyncController syncController = new SyncController();

    @Test
    public void handleRequest_happyPath() {
        when(mockInvokeFunctionService.syncInvokeFunction(any(), any()))
                .thenReturn(new ResponseEntity("OK", HttpStatus.OK));

        syncController.handlers = ImmutableList.<RequestHandler>of(new NoOpRequestHandler());
        HttpHeaders headers = new HttpHeaders();
        ResponseEntity<String> responseEntity = syncController.handleRequest("", headers, HttpMethod.POST);
        assertThat(responseEntity).isNotNull();
        assertThat(responseEntity.getStatusCode()).isEqualTo(HttpStatus.OK);
    }
}
