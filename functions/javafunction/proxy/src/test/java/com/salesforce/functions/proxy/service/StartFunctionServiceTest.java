package com.salesforce.functions.proxy.service;

import com.salesforce.functions.proxy.config.ProxyConfig;
import com.salesforce.functions.proxy.util.Utils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class StartFunctionServiceTest {

    @Mock
    private ProxyConfig mockProxyConfig;
    @Mock
    private ProcessHandle mockProcessHandle;
    @Mock
    private ProcessStartService mockProcessStartService;
    @Mock
    private Utils mockUtils;
    @InjectMocks
    private StartFunctionService startFunctionService = new StartFunctionService();

    @BeforeEach
    public void init() {
    }

    @Test
    public void start_happyPath() throws Exception {
        // Mocks
        when(mockUtils.isBlank(any())).thenCallRealMethod();
        when(mockProxyConfig.getJavaHome()).thenCallRealMethod();
        when(mockProcessHandle.isAlive()).thenReturn(true);
        when(mockProcessStartService.start(any())).thenReturn(mockProcessHandle);

        // Test
        startFunctionService.start();
    }

    @Test
    public void assembleFunctionStartCommand_happyPath() throws Exception {
        String testName = this.getClass().getName();

        // Mocks
        when(mockUtils.isBlank(any())).thenCallRealMethod();
        when(mockProxyConfig.getJavaHome()).thenCallRealMethod();
        when(mockProxyConfig.getDebugPort()).thenReturn("8081");
        when(mockProxyConfig.getFunctionJavaToolOptions()).thenReturn(testName + " " + testName);

        // Test
        List<String> cmd = startFunctionService.assembleFunctionStartCommand();
        assertNotNull(cmd);
        assertThat(cmd.size()).isEqualTo(12);
    }
}
