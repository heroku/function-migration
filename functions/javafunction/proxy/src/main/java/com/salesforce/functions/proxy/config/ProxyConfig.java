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

    @Min(1)
    private int functionPort;
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

    public int getFunctionPort() {
        return functionPort;
    }

    public void setFunctionPort(int functionPort) {
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
}
