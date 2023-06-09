@isTest
public class FunctionGetTests {

    @isTest
    static void testGet() {
        String permSetName = 'TestGetPermissionSet';
        String functionRef = 'functiontest_testgetfunction';
        PermissionSet permSet = FunctionsTestDataFactory.createPermissionSetRecord(permSetName, true);
        FunctionsTestDataFactory.assignPermissionSetRecord(permSet, UserInfo.getUserId());
        FunctionReferenceProvider functionReferenceHelperMock = FunctionsTestDataFactory.createFunctionReferenceRecord(functionRef, withNamespace(permSetName));

        // Pass on get() lookup
        Function testGetFunction = Function.get(null, functionRef, functionReferenceHelperMock);
        Assert.isNotNull(testGetFunction);
        Assert.areEqual(withDotNamespace(functionRef), testGetFunction.getFunctionName());
        
        // Pass on get lookup - dot delimiter
        functionRef = functionRef.replace('_', '.');
        functionReferenceHelperMock = FunctionsTestDataFactory.createFunctionReferenceRecord(functionRef, withNamespace(permSetName));
        testGetFunction = Function.get(null, functionRef, functionReferenceHelperMock);
        Assert.isNotNull(testGetFunction);
        Assert.areEqual(withDotNamespace(functionRef), testGetFunction.getFunctionName());

        // Pass on get() lookup - no project
        functionRef = 'testgetfunction';
        functionReferenceHelperMock = FunctionsTestDataFactory.createFunctionReferenceRecord(functionRef, withNamespace(permSetName));
        testGetFunction = Function.get('', functionRef, functionReferenceHelperMock);
        Assert.isNotNull(testGetFunction);
        Assert.areEqual(withDotNamespace(functionRef), testGetFunction.getFunctionName());

        // Pass on get() lookup - namespace
        String namespace = 'nshere';
        functionRef = 'testgetfunction';
        functionReferenceHelperMock = FunctionsTestDataFactory.createFunctionReferenceRecord(functionRef, withNamespace(permSetName));
        testGetFunction = Function.get(namespace, functionRef, functionReferenceHelperMock);
        Assert.isNotNull(testGetFunction);
        Assert.areEqual(namespace + '.' + functionRef, testGetFunction.getFunctionName());

        // Fail - not found function reference w/o mock
        try {
            Function.get(null, 'notfoundfunction');
            Assert.fail('Expected Function.InvalidFunctionException');
        } catch(Function.InvalidFunctionException ex) {
            Assert.isTrue(ex.getMessage().contains('Invalid function'), ex.getMessage());
        } catch(Exception ex) {
            Assert.fail('Unexpected exception: ' + ex.getMessage());
        }

        // Fail - not found function reference w/ namespace w/ mock
        try {
            Function.get('invalidns', 'notfoundfunction', new FunctionsTestDataFactory.NullFunctionReferenceProviderImpl());
            Assert.fail('Expected Function.InvalidFunctionException');
        } catch(Function.InvalidFunctionException ex) {
            Assert.isTrue(ex.getMessage().contains('Invalid function'), ex.getMessage());
        } catch(Exception ex) {
            Assert.fail('Unexpected exception: ' + ex.getMessage());
        }
        
    }

    @isTest
    static void testGet_validatePermissionSetOrGroup() {
        String permSetName = 'TestGetPermissionSetFailure';
        String functionRef = 'TestGetPermissionSetFunction';
        FunctionReferenceProvider mockFunctionReferenceProvider = FunctionsTestDataFactory.createFunctionReferenceRecord(functionRef, withNamespace(permSetName));

        // Fail - PermissionSet not found
        try {
            Function.get(null, functionRef, mockFunctionReferenceProvider);
            Assert.fail('Expected Function.InvalidFunctionException');
        } catch(Function.InvalidFunctionException ex) {
            Assert.isTrue(ex.getMessage().contains('not found'), ex.getMessage());
        } catch(Exception ex) {
            Assert.fail('Unexpected exception: ' + ex.getMessage());
        }

        // Fail - PermissionSet not found w/ namespace
        functionRef = 'testgetpermissionsetfunctionns';
        mockFunctionReferenceProvider = FunctionsTestDataFactory.createFunctionReferenceRecord(functionRef, 'ns__' + permSetName);
        try {
            Function.get(null, functionRef, mockFunctionReferenceProvider);
            Assert.fail('Expected Function.InvalidFunctionException');
        } catch(Function.InvalidFunctionException ex) {
            Assert.isTrue(ex.getMessage().contains('not found'), ex.getMessage());
        } catch(Exception ex) {
            Assert.fail('Unexpected exception: ' + ex.getMessage());
        }

        // Fail - PermissionSet not session-based
        functionRef = 'testgetnotsessionbasedfunction';
        PermissionSet permSet = FunctionsTestDataFactory.createPermissionSetRecord(permSetName, false);
        FunctionsTestDataFactory.assignPermissionSetRecord(permSet, UserInfo.getUserId());
        mockFunctionReferenceProvider = FunctionsTestDataFactory.createFunctionReferenceRecord(functionRef, withNamespace(permSetName));
        try {
            Function.get(null, functionRef, mockFunctionReferenceProvider);
            Assert.fail('Expected Function.InvalidFunctionException');
        } catch(Function.InvalidFunctionException ex) {
            Assert.isTrue(ex.getMessage().contains('not session-based'), ex.getMessage());
        } catch(Exception ex) {
            Assert.fail('Unexpected exception: ' + ex.getMessage());
        }

        // Fail - PermissionSet not assigned
        permSetName = 'TestGetNotAssignedFailure';
        functionRef = 'testgetnotassignedfunction';
        FunctionsTestDataFactory.createPermissionSetRecord(permSetName, true);
        mockFunctionReferenceProvider = FunctionsTestDataFactory.createFunctionReferenceRecord(functionRef, withNamespace(permSetName));
        try {
            Function.get(null, functionRef, mockFunctionReferenceProvider);
            Assert.fail('Expected Function.InvalidFunctionException');
        } catch(Function.InvalidFunctionException ex) {
            Assert.isTrue(ex.getMessage().contains('not assigned'), ex.getMessage());
        } catch(Exception ex) {
            Assert.fail('Unexpected exception: ' + ex.getMessage());
        }        
    }

    private static String getNamespace() {
        ApexClass thisCls = [ SELECT NamespacePrefix FROM ApexClass WHERE Name = 'Function' ];
        return thisCls.NamespacePrefix;
    }

    private static String withDotNamespace(String name) {
        String namespace = getNamespace();
        return String.isNotBlank(namespace) ? namespace + '.' + name : name;
    }

    private static String withNamespace(String name) {
        String namespace = getNamespace();
        return String.isNotBlank(namespace) ? namespace + '__' + name : name;
    }
}