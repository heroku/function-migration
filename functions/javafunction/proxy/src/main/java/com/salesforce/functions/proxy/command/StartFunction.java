package com.salesforce.functions.proxy.command;

import com.google.common.collect.Lists;
import com.salesforce.functions.proxy.config.ProxyConfig;
import com.salesforce.functions.proxy.util.Utils;
import org.apache.logging.log4j.util.Strings;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.io.*;
import java.util.List;
import java.util.concurrent.CompletableFuture;

@Component
public class StartFunction implements InitializingBean {

    private static final Logger LOGGER = LoggerFactory.getLogger(StartFunction.class);

    @Autowired
    private ProxyConfig proxyConfig;

    @Autowired
    Utils utils;

    @Override
    public void afterPropertiesSet() throws Exception {
        List<String> functionStartCmd = Lists.newArrayList();
        String javaFilePath = getJavaCmd().getAbsolutePath();
        functionStartCmd.add(javaFilePath);
        if (!utils.isBlank(proxyConfig.getDebugPort())) {
            functionStartCmd.add("-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=");
            functionStartCmd.add(proxyConfig.getDebugPort());
        }
        functionStartCmd.add("-jar");
        functionStartCmd.add("/tmp/sf-fx-runtime-java-runtime-1.1.3-jar-with-dependencies.jar");
        functionStartCmd.add("serve");
        functionStartCmd.add("/home/cwall/git/function-migration/functions/javafunction");
        functionStartCmd.add("-h");
        functionStartCmd.add("0.0.0.0");
        functionStartCmd.add("-p");
        functionStartCmd.add(String.valueOf(proxyConfig.getFunctionPort()));

        LOGGER.info("Starting function w/ args: " + String.join(" ", functionStartCmd));
        Process functionProcess = null;
        ProcessHandle functionProcessHandle = null;
        try {
            ProcessBuilder processBuilder = new ProcessBuilder(functionStartCmd);
            // REVIEWME: Why needed?
            processBuilder.environment().put("JAVA_HOME", System.getProperty("java.home"));
            functionProcess = processBuilder.inheritIO().start();
            functionProcessHandle = functionProcess.toHandle();
        } catch (Exception ex) {
            throw new RuntimeException("Unable to start function: " + ex.getMessage());
        }

        if (!functionProcessHandle.isAlive()) {
            throw new RuntimeException("Function process died");
        }

        String output = loadStream(functionProcess.getInputStream());
        LOGGER.info(output);
        String error = loadStream(functionProcess.getErrorStream());
        LOGGER.info(error);

        LOGGER.info("Started function started on port " + proxyConfig.getFunctionPort() + ", process pid " + functionProcessHandle.pid());
    }

    private String loadStream(InputStream s) throws Exception {
        BufferedReader br = new BufferedReader(new InputStreamReader(s));
        StringBuilder sb = new StringBuilder();
        String line;
        while ((line = br.readLine()) != null)
            sb.append(line).append("\n");
        return sb.toString();
    }

    public File getJavaCmd() throws IOException {
        String javaHome = System.getProperty("java.home");
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
