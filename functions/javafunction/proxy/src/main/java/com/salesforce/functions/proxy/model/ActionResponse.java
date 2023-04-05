package com.salesforce.functions.proxy.model;

import java.util.List;
import java.util.Map;

public class ActionResponse {

    private String actionName;
    private List<Map<String,String>> errors;
    private boolean isSuccess;
    private List<Map<String,String>> outputValues;

    public String getActionName() {
        return actionName;
    }

    public void setActionName(String actionName) {
        this.actionName = actionName;
    }

    public List<Map<String, String>> getErrors() {
        return errors;
    }

    public void setErrors(List<Map<String, String>> errors) {
        this.errors = errors;
    }

    public boolean isSuccess() {
        return isSuccess;
    }

    public void setIsSuccess(boolean success) {
        isSuccess = success;
    }

    public List<Map<String, String>> getOutputValues() {
        return outputValues;
    }

    public void setOutputValues(List<Map<String, String>> outputValues) {
        this.outputValues = outputValues;
    }
}
