package com.salesforce.functions.proxy.model;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import com.google.common.collect.ImmutableList;

import java.io.IOException;
import java.util.List;

/**
 * Encapsulates a /AsyncFunctionInvocationRequest__c API request.
 */
@JsonSerialize(using = AsyncFunctionInvocationRequest.AsyncFunctionInvocationRequestSerializer.class)
public class AsyncFunctionInvocationRequest {

    static final List<String> FIELDS = ImmutableList.<String>of("ExtraInfo__c", "Response__c", "Status__c", "StatusCode__c");

    // Handle object and field namespace
    public static class AsyncFunctionInvocationRequestSerializer extends StdSerializer<AsyncFunctionInvocationRequest> {

        public AsyncFunctionInvocationRequestSerializer() {
            this(AsyncFunctionInvocationRequest.class);
        }

        public AsyncFunctionInvocationRequestSerializer(Class<AsyncFunctionInvocationRequest> t) {
            super(t);
        }

        @Override
        public void serialize(AsyncFunctionInvocationRequest afir,
                              JsonGenerator jsonGenerator,
                              SerializerProvider serializerProvider) throws IOException {
            jsonGenerator.writeStartObject();
            jsonGenerator.writeStringField(getFullyQualifiedFieldName(afir.namespace, "ExtraInfo__c"), afir.getExtraInfo());
            jsonGenerator.writeStringField(getFullyQualifiedFieldName(afir.namespace, "Response__c"), afir.getResponse());
            jsonGenerator.writeStringField(getFullyQualifiedFieldName(afir.namespace, "Status__c"), afir.getStatus());
            jsonGenerator.writeNumberField(getFullyQualifiedFieldName(afir.namespace, "StatusCode__c"), afir.getStatusCode());
            jsonGenerator.writeEndObject();
        }

        private String getFullyQualifiedFieldName(String namespace, String field) {
            return namespace != null && !"".equals(namespace) ? namespace + "__" + field : field;

        }
    }

    private String namespace;
    private String extraInfo;
    private String response;
    private String status;
    private int statusCode;

    public AsyncFunctionInvocationRequest(String namespace, String extraInfo, String response, String status, int statusCode) {
        this.namespace = namespace;
        this.extraInfo = extraInfo;
        this.response = response;
        this.status = status;
        this.statusCode = statusCode;
    }


    public String getExtraInfo() {
        return extraInfo;
    }

    public String getResponse() {
        return response;
    }

    public String getStatus() {
        return status;
    }

    public int getStatusCode() {
        return statusCode;
    }
}
