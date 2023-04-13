package com.salesforce.functions.proxy.service;

import com.google.common.collect.Lists;
import com.salesforce.functions.proxy.config.ProxyConfig;
import com.salesforce.functions.proxy.util.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.io.*;
import java.util.List;

/**
 * Start and restart co-located function.
 */
@Component
public class StartFunctionService implements InitializingBean {

    private static final Logger LOGGER = LoggerFactory.getLogger(StartFunctionService.class);

    @Autowired
    private ProxyConfig proxyConfig;

    @Autowired
    private ProcessStartService processStartService;

    @Autowired
    private Utils utils;

    @Override
    public void afterPropertiesSet() throws Exception {
        start();
    }

    public void start() throws Exception {
        List<String> functionStartCmd = assembleFunctionStartCommand();
        LOGGER.info("Starting function w/ args: " + String.join(" ", functionStartCmd));
        ProcessHandle functionProcessHandle = null;
        try {
            ProcessBuilder processBuilder = new ProcessBuilder(functionStartCmd);
            // REVIEWME: Why needed?
            processBuilder.environment().put("JAVA_HOME", proxyConfig.getJavaHome());
            functionProcessHandle = processStartService.start(processBuilder);
        } catch (Exception ex) {
            throw new RuntimeException("Unable to start function: " + ex.getMessage());
        }

        if (!functionProcessHandle.isAlive()) {
            throw new RuntimeException("Function process died");
        }

        LOGGER.info("Started function started on port " + proxyConfig.getFunctionPort() + ", process pid " + functionProcessHandle.pid());
    }

    List<String> assembleFunctionStartCommand() throws IOException {
        List<String> functionStartCmd = Lists.newArrayList();
        String javaFilePath = getJavaCmd().getAbsolutePath();
        functionStartCmd.add(javaFilePath);
        if (!utils.isBlank(proxyConfig.getDebugPort())) {
            functionStartCmd.add("-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=" + proxyConfig.getDebugPort());
        }
        if (!utils.isBlank(proxyConfig.getFunctionJavaToolOptions())) {
            String[] javaToolOptionParts = proxyConfig.getFunctionJavaToolOptions().split(" ");
            functionStartCmd.addAll(Lists.newArrayList(javaToolOptionParts));
        }
        functionStartCmd.add("-jar");
        functionStartCmd.add(proxyConfig.getSfFxRuntimeJarFilePath());
        functionStartCmd.add("serve");
        functionStartCmd.add(proxyConfig.getFunctionDir());
        functionStartCmd.add("-h");
        functionStartCmd.add(proxyConfig.getFunctionHost());
        functionStartCmd.add("-p");
        functionStartCmd.add(String.valueOf(proxyConfig.getFunctionPort()));
        return functionStartCmd;
    }

    public File getJavaCmd() throws IOException {
        String javaHome = proxyConfig.getJavaHome();
        File javaCmd;
        if (System.getProperty("os.name").startsWith("Win")) {
            javaCmd = new File(javaHome, "bin/java.exe");
        } else {
            javaCmd = new File(javaHome, "bin/java");
        }
        if (javaCmd.canExecute()) {
            return javaCmd;
        } else {
            throw new UnsupportedOperationException(javaCmd.getCanonicalPath() + " is not executable");
        }
    }
}
