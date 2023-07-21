/**
 * Default FunctionReference_mdt provider implementation that queries for a specific
 * FunctionReference_mdt Custom Metadata record.
 */
public with sharing class FunctionReferenceMetadataProviderImpl implements FunctionReferenceProvider {
    
    public FunctionReference__mdt getFunctionReference(String functionReferenceSoql) {
        return Database.query(functionReferenceSoql);
    }
}