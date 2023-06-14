@isTest
public class FunctionsTestAuthProviderMocks {

    public class FakeAuthProvider implements FunctionsAuthProvider {
    
        public String generateFunctionAuthenticationToken() {
            return 'FAKE_ACCESS_TOKEN';
        }
    }

    public class NullAuthProvider implements FunctionsAuthProvider {
    
        public String generateFunctionAuthenticationToken() {
            return null;
        }
    }

}
