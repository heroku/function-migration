/**
 * Generates an accessToken with given Connected App ConsumerId and Certificate.
 * The accessToken is used by the function proxy to validate the caller.
 */
public class FunctionsMetadataAuthProvider implements FunctionsAuthProvider {
    
    private FunctionReference__mdt functionReference;
    
    public FunctionsMetadataAuthProvider(FunctionReference__mdt functionReference) {
        this.functionReference = functionReference;
    }
    
    public String generateToken() {  
        if (null == functionReference.ConsumerId__c) {
            throw new Function.InvalidFunctionException('FunctionReference__mdt.ConsumerId__c not provided');
        }

        if (null == functionReference.Certificate__c) {
            throw new Function.InvalidFunctionException('FunctionReference__mdt.Certificate__c not provided');
        }

        return generateToken(UserInfo.getUserName(), functionReference.ConsumerId__c, functionReference.Certificate__c);
    }

    public String generateToken(String username, String consumerId, String certDevName) {  
        if (null == username) {
            throw new Function.InvalidFunctionException('Username Id not provided');
        }

        if (null == consumerId) {
            throw new Function.InvalidFunctionException('Consumer Id not provided');
        }

        if (null == certDevName) {
            throw new Function.InvalidFunctionException('Certificate name not provided');
        }
        
		String tokenEndPoint = URL.getSalesforceBaseURL().toExternalForm() + '/services/oauth2/token';

        String audience = 'https://login.salesforce.com';
        Organization org = [SELECT IsSandbox FROM Organization];
        if (org.IsSandbox) {
            audience = 'https://test.salesforce.com';
        }
        audience = 'https://cwall-wsl5:6101';
        
		Auth.JWT jwt = new Auth.JWT();
		jwt.setSub(username);
		jwt.setAud(audience);
		jwt.setIss(consumerId);
        jwt.setValidityLength(60);
		Auth.JWS jws = new Auth.JWS(jwt, certDevName);
		Auth.JWTBearerTokenExchange bearer = new Auth.JWTBearerTokenExchange(tokenEndPoint, jws);
		return bearer.getAccessToken();        
    }
}