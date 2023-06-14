@isTest
public class FunctionsTestDataFactory {

    public class MockFunctionReferenceProviderImpl implements FunctionReferenceProvider {

        private String functionName;
        private String fqPermSetName; // if applicable, namespace__permsetname

        MockFunctionReferenceProviderImpl(String functionName, String fqPermSetName) {
            this.functionName = functionName;
            this.fqPermSetName = fqPermSetName;
        }

        public FunctionReference__mdt getFunctionReference(String projectFunctionRef) {
            return new FunctionReference__mdt(Label=functionName, 
                                              DeveloperName=functionName, 
                                              APIVersion__c='57.0',
                                              Endpoint__c='http://localhost:80', 
                                              PermissionSetOrGroup__c=fqPermSetName);
        }
    }

    public class NullFunctionReferenceProviderImpl implements FunctionReferenceProvider {

        public FunctionReference__mdt getFunctionReference(String projectFunctionRef) {
            return null;
        }
    }

    public static PermissionSet createPermissionSetRecord(String permSetName, Boolean isSessionBased) {        
        PermissionSet permSet = new PermissionSet(Label=permSetName, Name=permSetName, HasActivationRequired=isSessionBased);
        insert permSet;
        System.debug('Created Permission Set ' + permSet.Name + ' [' + permSet.Id + '], isSessionBased? ' + permSet.HasActivationRequired);
        return permSet;
    }

    public static void assignPermissionSetRecord(PermissionSet permSet, Id userId) {
        PermissionSetAssignment permSetAssignment = new PermissionSetAssignment(PermissionSetId=permSet.Id, AssigneeId=userId);
        insert permSetAssignment;
        System.debug('Assigned user ' + PermissionSetAssignment.AssigneeId + ' to Permission Set ' + permSet.Name + ' [' + permSet.Id + ']');
    }
    
    public static FunctionReferenceProvider createFunctionReferenceRecord(String functionName, String permissionSetName) {        
        return new MockFunctionReferenceProviderImpl(functionName, permissionSetName);
    }
}