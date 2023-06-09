package com.salesforce.functions.proxy.util;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.salesforce.functions.proxy.model.SfFnContext;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.junit.jupiter.MockitoExtension;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Map;

import static org.assertj.core.api.AssertionsForClassTypes.assertThat;

@ExtendWith(MockitoExtension.class)
public class UtilsTest {
    private Utils utils = new Utils();
    @Test
    public void isBlank_happyPath() {
        assertThat(utils.isBlank("")).isTrue();
        assertThat(utils.isBlank(" ")).isTrue();
        assertThat(utils.isBlank(null)).isTrue();
        assertThat(utils.isBlank("null")).isFalse();
    }
    @Test
    public void fromJson_happyPath() throws JsonProcessingException {
        Map result = utils.fromJson("{ \"key\": \"value\" }", Map.class);
        assertThat(result.get("key")).isEqualTo("value");
    }
    @Test
    public void fromEncodedJson_happyPath() throws JsonProcessingException {
        Map result = utils.fromEncodedJson(
                Base64.getEncoder().encodeToString("{ \"key\": \"value\" }".getBytes(StandardCharsets.UTF_8)),
                Map.class);
        assertThat(result.get("key")).isEqualTo("value");
    }
    @Test
    public void toJson_happyPath() throws JsonProcessingException {
        String expectedStr = "toJson_happyPath";
        SfFnContext sfFnContext = new SfFnContext();
        sfFnContext.setAccessToken(expectedStr);
        String sfFnContextJson = utils.toJson(sfFnContext);
        assertThat(sfFnContextJson).isNotNull();
        assertThat(sfFnContextJson.contains(expectedStr)).isTrue();
    }

    @Test
    public void toEncodedJson_happyPath() throws JsonProcessingException {
        String expectedStr = "toEncodedJson_happyPath";
        SfFnContext sfFnContext = new SfFnContext();
        sfFnContext.setAccessToken(expectedStr);
        String sfFnContextEncodedJson = utils.toEncodedJson(sfFnContext);
        assertThat(sfFnContextEncodedJson).isNotNull();
        assertThat(utils.fromEncodedJson(sfFnContextEncodedJson, SfFnContext.class).getAccessToken()).isEqualTo(expectedStr);
    }
}