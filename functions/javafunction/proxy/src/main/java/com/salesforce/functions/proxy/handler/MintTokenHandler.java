package com.salesforce.functions.proxy.handler;

import com.salesforce.functions.proxy.model.FunctionRequestContext;
import com.salesforce.functions.proxy.model.OauthExchangeResponse;
import com.salesforce.functions.proxy.model.SfContext;
import com.salesforce.functions.proxy.util.InvalidRequestException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.annotation.Order;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import java.io.UnsupportedEncodingException;
import java.security.KeyFactory;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Base64;
import java.util.Date;

import static com.salesforce.functions.proxy.util.Constants.PROD_AUDIENCE_URL;
import static com.salesforce.functions.proxy.util.Constants.SANDBOX_AUDIENCE_URL;

@Order(40)
@Component
public class MintTokenHandler extends BaseHandler {

    private static final Logger LOGGER = LoggerFactory.getLogger(MintTokenHandler.class);

    @Autowired
    RestTemplate restTemplate;

    /**
     * Mint and return function's token for requesting user using configured Connected App.
     *
     * If applicable, activate provided session-based Permission Set(s) to token.
     *
     * TODO: Consider caching tokens (referesh token) for given signature: user, connected app,
     *  session-based Permission(s).  If cached, use /services/oauth2/introspect to determine
     *  token validity (eg, timeout).
     *
     * @param functionRequestContext
     * @throws InvalidRequestException
     */
    @Override
    public void handle(FunctionRequestContext functionRequestContext) throws InvalidRequestException {
        String requestId = functionRequestContext.getRequestId();
        SfContext.UserContext userContext = functionRequestContext.getSfContext().getUserContext();
        String url = userContext.getSalesforceBaseUrl() + "/services/oauth2/token";
        boolean isTest = url.contains(".sandbox.") || url.contains("c.scratch.vf.force.com");

        String issuer = proxyConfig.getConsumerKey();
        String audience = proxyConfig.getAudience();

        ResponseEntity<OauthExchangeResponse> responseEntity = null;
        try {
            String privateKey = decodePrivateKey(proxyConfig.getEncodedPrivateKey());
            PrivateKey signedKey = generatePrivateKey(privateKey);
            String signedJWT = Jwts.builder()
                    .setIssuer(issuer)
                    .setSubject(userContext.getUsername())
                    .setAudience(audience != null ? audience : (isTest ? SANDBOX_AUDIENCE_URL : PROD_AUDIENCE_URL))
                    .setExpiration(new Date((new Date()).getTime() + 360))
                    .signWith(signedKey, SignatureAlgorithm.RS256)
                    .compact();

            // Assemble payload
            MultiValueMap<String, String> formDataMap = new LinkedMultiValueMap<>();
            formDataMap.add("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer");
            formDataMap.add("assertion", signedJWT);

            // Assemble POST form request
            HttpHeaders headers = new HttpHeaders();
            headers.add(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_FORM_URLENCODED_VALUE);
            headers.add(HttpHeaders.AUTHORIZATION, "Bearer " + functionRequestContext.getRequestProvidedAccessToken());
            HttpEntity<MultiValueMap<String, String>> entity = new HttpEntity<>(formDataMap, headers);
            responseEntity = restTemplate.postForEntity(url, entity, OauthExchangeResponse.class);
        } catch (Exception ex) {;
            throw new InvalidRequestException(requestId,
                    "Unable to mint function token: " + ex.getMessage(),
                    responseEntity != null ? responseEntity.getStatusCode().value() : 401);
        }

        if (responseEntity.getStatusCode() != HttpStatus.OK) {
            throw new InvalidRequestException(requestId,
                    "Unable to mint function token",
                    responseEntity.getStatusCode().value());
        }

        OauthExchangeResponse oauthExchangeResponse = responseEntity.getBody();

        // {"error":"invalid_grant","error_description":"invalid assertion"}
        if (!utils.isBlank(oauthExchangeResponse.getError())) {
            String msg = oauthExchangeResponse.getError() +
                    (!utils.isBlank(oauthExchangeResponse.getError_description())
                            ? " (" + oauthExchangeResponse.getError_description() + ")" : "");
            if (msg.contains("invalid_app_access") || msg.contains("user hasn't approved this consumer")) {
                msg += ". Ensure that the target Connected App is set to \"Admin approved users are pre-authorized\" and user " +
                        userContext.getUsername() + " is assigned to Connected App via a Permission Set";
            }
            throw new InvalidRequestException(requestId,
                    "Unable to mint function token: " + msg,
                    401);
        }

        functionRequestContext.getSfFnContext().setAccessToken(oauthExchangeResponse.getAccess_token());

        utils.info(LOGGER, requestId, "Minted function's token - hooray");
    }

    private String decodePrivateKey(String encodedPrivateKey) throws UnsupportedEncodingException {
        String privateKey = new String(Base64.getDecoder().decode(encodedPrivateKey), "UTF-8");
        privateKey = privateKey.replaceAll("-----(BEGIN|END)[\\w\\s]*-----", "");
        privateKey = privateKey.replaceAll(" ", "");
        privateKey = privateKey.replaceAll("\n", "");
        return privateKey.trim();
    }

    private PrivateKey generatePrivateKey(String privateKeyStr) throws NoSuchAlgorithmException, InvalidKeySpecException {
        PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(Base64.getDecoder().decode(privateKeyStr));
        KeyFactory kf = KeyFactory.getInstance("RSA");
        return kf.generatePrivate(keySpec);
    }
}