public class FunctionsMetadataAuthProvider implements FunctionsAuthProvider {
    
    private FunctionReference__mdt functionReference;
    
    public FunctionsMetadataAuthProvider(FunctionReference__mdt functionReference) {
        this.functionReference = functionReference;
    }
    
    public String generateToken() {        
		String tokenEndPoint = URL.getSalesforceBaseURL().toExternalForm() + '/services/oauth2/token';

        String audience = 'https://login.salesforce.com';
        Organization org = [SELECT IsSandbox FROM Organization];
        if (org.IsSandbox) {
            audience = 'https://test.salesforce.com';
        }
        
		Auth.JWT jwt = new Auth.JWT();
		jwt.setSub(UserInfo.getUserName());
		jwt.setAud(audience);  //'3MVG9MwiKwcReohz8QkMzSy9xZYq7bA9OgEgrB.8mYEIj8mQqJCEnhANn.Tvqeyihvz92XkzlAbbIFrJiVsOi';
		jwt.setIss(functionReference.ConsumerId__c);
		Auth.JWS jws = new Auth.JWS(jwt, functionReference.Certificate__c);
		String token = jws.getCompactSerialization();

		Auth.JWTBearerTokenExchange bearer = new Auth.JWTBearerTokenExchange(tokenEndPoint, jws);
		return bearer.getAccessToken();        
    }
}