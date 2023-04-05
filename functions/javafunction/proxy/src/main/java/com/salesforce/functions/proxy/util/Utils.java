package com.salesforce.functions.proxy.util;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.salesforce.functions.proxy.model.FunctionRequestContext;
import org.slf4j.Logger;
import org.springframework.context.annotation.Bean;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;

import java.util.Base64;

@Component
public class Utils {
    private final ObjectMapper defaultMapper = new ObjectMapper();

    public Utils() {
        defaultMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
    }

    public boolean isBlank(String str) {
        return null == str || "".equals(str);
    }
    public boolean isValidJson(String maybeJson)  {
        try {
            defaultMapper.readTree(maybeJson);
        } catch (JsonProcessingException ex) {
            return false;
        }

        return true;
    }

    public <T> T fromJson(String json, Class<T> clazz) throws JsonProcessingException {
        return defaultMapper.readValue(json, clazz);
    }

    public <T> T fromJson(String json, TypeReference<T> clazz) throws JsonProcessingException {
        return defaultMapper.readValue(json, clazz);
    }

    public <T> T fromEncodedJson(String encoded, Class<T> clazz) throws JsonProcessingException {
        final byte[] decoded = Base64.getDecoder().decode(encoded);
        return fromJson(new String(decoded), clazz);
    }

    public String toJson(Object obj) throws JsonProcessingException {
        return defaultMapper.writeValueAsString(obj);
    }

    public String toJsonNoThrow(Object obj) {
        try {
            return defaultMapper.writeValueAsString(obj);
        } catch (JsonProcessingException e) {
            return "";
        }
    }

    public String toEncodedJson(Object obj) throws JsonProcessingException {
        String json = toJson(obj);
        return Base64.getEncoder().encodeToString(json.getBytes());
    }

    /**
     * Assemble Salesforce API URI part.
     *
     * @param baseUrl
     * @param apiVersion
     * @param uriPart
     * @return
     */
    public String assembleSalesforceAPIUrl(String baseUrl, String apiVersion, String uriPart) {
        return baseUrl + "/services/data/v" + apiVersion + uriPart;
    }

    /**
     * Assemble Salesforce API Headers.
     *
     * @param functionRequestContext
     * @return
     */
    public HttpHeaders assembleSalesforceAPIHeaders(FunctionRequestContext functionRequestContext) {
        HttpHeaders headers = new HttpHeaders();
        headers.add(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE);
        headers.add(HttpHeaders.AUTHORIZATION, "Bearer " + functionRequestContext.getRequestProvidedAccessToken());
        return headers;
    }

    public void info(Logger logger, String requestId, String msg) {
        logger.info("[" + requestId + "]: " + msg);
    }

    public void warn(Logger logger, String requestId, String msg) {
        logger.warn("[" + requestId + "]: " + msg);
    }

    public void error(Logger logger, String requestId, String msg) {
        logger.info("[" + requestId + "]: " + msg);
    }
}
