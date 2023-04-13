/**
 * Generates an accessToken with provided Connected App referenced by 
 * FunctionReference__mdt fields ConsumerKey__c and Certificate__c.
 * 
 * The accessToken is used by the function proxy to validate the caller.
 */
public class FunctionsMetadataAuthProvider implements FunctionsAuthProvider {
    
    private FunctionReference__mdt functionReference;
    
    public FunctionsMetadataAuthProvider(FunctionReference__mdt functionReference) {
        this.functionReference = functionReference;
    }
    
    public String generateFunctionAuthenticationToken() {  
        if (null == functionReference.ConsumerKey__c) {
            throw new Function.InvalidFunctionException('FunctionReference__mdt.ConsumerKey__c not provided');
        }

        if (null == functionReference.Certificate__c) {
            throw new Function.InvalidFunctionException('FunctionReference__mdt.Certificate__c not provided');
        }

        return generateToken(UserInfo.getUserName(), functionReference.ConsumerKey__c, functionReference.Certificate__c);
    }

    private String generateToken(String username, String consumerKey, String certDevName) {  
        if (null == username) {
            throw new Function.InvalidFunctionException('Username not provided');
        }

        if (null == consumerKey) {
            throw new Function.InvalidFunctionException('Consumer Key not provided');
        }

        if (null == certDevName) {
            throw new Function.InvalidFunctionException('Certificate Name not provided');
        }
        
		String tokenEndPoint = URL.getSalesforceBaseURL().toExternalForm() + '/services/oauth2/token';

        String audience = 'https://login.salesforce.com';
        Organization org = [SELECT IsSandbox FROM Organization];
        if (org.IsSandbox) {
            audience = 'https://test.salesforce.com';
        }
        
		Auth.JWT jwt = new Auth.JWT();
		jwt.setSub(username);
		jwt.setAud(audience);
		jwt.setIss(consumerKey);
        jwt.setValidityLength(60);
		Auth.JWS jws = new Auth.JWS(jwt, certDevName);
		Auth.JWTBearerTokenExchange bearer = new Auth.JWTBearerTokenExchange(tokenEndPoint, jws);
		return bearer.getAccessToken();        
    }
}