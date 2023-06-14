/**
 * Implementations provide an accessToken, delivered with function payloads, that is 
 * used by the proxy to validate function requests.  The token should have API and 
 * refresh_token scopes to call the /userinfo API.
 */
public interface FunctionsAuthProvider {
    
    String generateFunctionAuthenticationToken();

}