/**
 * Implementations return FunctionReference_mdt records.
 * 
 * Supports Custom Metadata or External Objects or another integration point where function metadata is stored.
 *
 * For further integration support, method getFunctionReference could return a domain object that encapsulates required
 * data.  Implementations would gather required data and then load and return this domain object.
 * 
 * Useful for testing.
 */
public interface FunctionReferenceProvider {
    
    FunctionReference__mdt getFunctionReference(String projectFunctionRef);
}