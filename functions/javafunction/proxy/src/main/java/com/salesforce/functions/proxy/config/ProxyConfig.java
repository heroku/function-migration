package com.salesforce.functions.proxy.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;
import org.springframework.validation.annotation.Validated;

import javax.validation.constraints.Min;
import javax.validation.constraints.NotBlank;

@Component
@Validated
@ConfigurationProperties(prefix="proxy")
public class ProxyConfig {

    @NotBlank
    private String javaHome;
    private String functionJavaToolOptions;
    @NotBlank
    private String functionHost;
    @NotBlank
    private String functionPort;
    @NotBlank
    private String functionUrl;
    @NotBlank
    private String orgId18;
    @NotBlank
    private String consumerKey;
    @NotBlank
    private String encodedPrivateKey;
    private String audience;
    private String debugPort;
    @NotBlank
    private String sfFxRuntimeJarFilePath;
    @NotBlank
    private String functionDir;
    @NotBlank
    private String userInfoUri;
    @NotBlank
    private String oauth2TokenUri;
    @NotBlank
    private String activateSessionPermSetUri;

    public String getJavaHome() {
        return javaHome != null ? javaHome : System.getProperty("java.home");
    }

    public void setJavaHome(String javaHome) {
        this.javaHome = javaHome;
    }

    public String getFunctionJavaToolOptions() {
        return functionJavaToolOptions;
    }

    public void setFunctionJavaToolOptions(String functionJavaToolOptions) {
        this.functionJavaToolOptions = functionJavaToolOptions;
    }

    @NotBlank
    public String getFunctionHost() {
        return functionHost;
    }

    public void setFunctionHost(String functionHost) {
        this.functionHost = functionHost;
    }

    public String getFunctionPort() {
        return functionPort;
    }

    public void setFunctionPort(String functionPort) {
        this.functionPort = functionPort;
    }

    public String getFunctionUrl() {
        return functionUrl;
    }

    public void setFunctionUrl(String functionUrl) {
        this.functionUrl = functionUrl;
    }

    public String getOrgId18() {
        return orgId18;
    }

    public void setOrgId18(String orgId18) {
        this.orgId18 = orgId18;
    }

    public String getConsumerKey() {
        return consumerKey;
    }

    public void setConsumerKey(String consumerKey) {
        this.consumerKey = consumerKey;
    }

    public String getEncodedPrivateKey() {
        return encodedPrivateKey;
    }

    public void setEncodedPrivateKey(String encodedPrivateKey) {
        this.encodedPrivateKey = encodedPrivateKey;
    }

    public String getAudience() {
        return audience;
    }

    public void setAudience(String audience) {
        this.audience = audience;
    }

    public String getDebugPort() {
        return debugPort;
    }

    public void setDebugPort(String debugPort) {
        this.debugPort = debugPort;
    }

    public String getSfFxRuntimeJarFilePath() {
        return sfFxRuntimeJarFilePath;
    }

    public void setSfFxRuntimeJarFilePath(String sfFxRuntimeJarFilePath) {
        this.sfFxRuntimeJarFilePath = sfFxRuntimeJarFilePath;
    }

    public String getFunctionDir() {
        return functionDir;
    }

    public void setFunctionDir(String functionDir) {
        this.functionDir = functionDir;
    }

    public String getUserInfoUri() {
        return userInfoUri;
    }

    public void setUserInfoUri(String userInfoUri) {
        this.userInfoUri = userInfoUri;
    }

    public String getOauth2TokenUri() {
        return oauth2TokenUri;
    }

    public void setOauth2TokenUri(String oauth2TokenUri) {
        this.oauth2TokenUri = oauth2TokenUri;
    }

    public String getActivateSessionPermSetUri() {
        return activateSessionPermSetUri;
    }

    public void setActivateSessionPermSetUri(String activateSessionPermSetUri) {
        this.activateSessionPermSetUri = activateSessionPermSetUri;
    }
}
