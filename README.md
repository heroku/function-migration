# Salesforce Function Migration

## Introduction
This guide and repo is an example of how Salesforce Functions may be ported to Heroku Apps.

The contents of this repository are available for you to modify and use under the Apache License Version 2.0 license. See the LICENSE file for more info.

## Heroku
Heroku is a platform as a service based on a managed container system, with integrated data services and a powerful ecosystem for deploying and running modern apps. The Heroku developer experience is an app-centric approach for 
software delivery, integrated with today’s most popular developer tools and workflows.

Heroku makes the processes of deploying, configuring, scaling, tuning, and managing apps as simple and straightforward 
as possible, so that developers can focus on what’s most important: building great apps that delight and engage customers.

Deploying and maintaining apps should be frictionless, and these capabilities should be a part of a company's DNA.

Using Heroku is required for these example deployments and if you are not familiar with how it works, please see the [How Heroku Works](https://devcenter.heroku.com/articles/how-heroku-works) article at the Heroku DevCenter.

## Reference Functions Framework

### Overview
The Reference Functions Framework is an example of how to lift-and-shift Salesforce Functions to run securely as Heroku Apps run in [Private Spaces](https://devcenter.heroku.com/articles/private-spaces).

The Reference Functions Framework includes:
- Apex Classes and an Apex Trigger as APIs to invoke functions, suporting  both synchronous and asynchronous invocation.
- A new Custom Metadata type representing deployed, invocable functions (`FunctionReference`).
- A new Custom Object that tracks asynchronous requests and handles asynchronous responses (`AsyncFunctionInvocationRequest`).
- Language-specific proxies (Java and Node) to be deployed alongside and in front of a function to validate and manage function requests.



#### Architecture
The following diagram shows how the new classes and Custom Objects interact with the function code and proxy deployed as a Heroku app. Yellow boxes indicated code provided in this example repo and green boxes indicate customer Apex or function code. Salesforce and Heroku platforms are indicated in blue and purple.

![Architecture](assets/images/reference-functions-framework.png)

Notes:

> Synchronous requests are Apex callouts to the function.  Standard Apex callout limits apply.

> Asynchronous requests are Apex callouts via `@Future`.  Function responses are stored in an associated 
`AsyncFunctionInvocationRequest`.  An Apex Trigger handles invoking the associated callback implementation.

> License-based Salesforce API considerations and limits 
([API Request Limits and Allocations](https://developer.salesforce.com/docs/atlas.en-us.salesforce_app_limits_cheatsheet.meta/salesforce_app_limits_cheatsheet/salesforce_app_limits_platform_api.htm)) apply.

### Reference Apex Function API
The Reference Functions Framework provides Apex classes as APIs to invoke functions.

#### Classes and Trigger
```bash
force-app/main/default/classes/functions/
├── FunctionCallback.cls
├── FunctionCallbackQueueable.cls
├── Function.cls
├── FunctionErrorType.cls
├── FunctionInvocation.cls
├── FunctionInvocationError.cls
├── FunctionInvocationErrorImpl.cls
├── FunctionInvocationImpl.cls
├── FunctionInvocationRequest.cls
├── FunctionInvocationStatus.cls
├── FunctionsAuthProvider.cls
├── FunctionsMetadataAuthProvider.cls
└── FunctionsMetadataAuthProvider.cls

force-app/main/default/triggers/functions/
└── AsyncResponseHandlerTrigger.trigger
```

#### Functions API
The Reference Functions Framework's `Function` API is similar to Salesforce Functions' `Function` API, see [Function Class](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_functions_Function.htm#apex_class_functions_Function).

The `get(...)` method takes a `FunctionReference` Custom Metadata name reference.  The method will query for the `FunctionReference` record and validate the invocation configuration (i.e. ensure that the invoking user is assign to the 
given session-based Permission Set). 

The `invoke(...)` method invokes the `FunctionReference` Custom Metadata record's function with given parameters.  And as with the standard Salesforce Function API, if a `FunctionCallback` implementation is given, the function will be invoked asynchronously.

Apex's callout considerations ([Invoking Callouts Using Apex](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_callouts.htm)) and limits ([Callout Limits and Limitations](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_callouts_timeouts.htm)) apply.

```java
 // Get Custom Metadata reference to function
 Function javafunction = Function.get('mynamespace', 'sfhxhello_javafunction');
 // Invoke sync...
 FunctionInvocation invocation = javafunction.invoke('{}');
 // Aync invoke
 FunctionInvocation invocation = javaFunction.invoke('{}', new Callback('sfhxhello_javafunction'));

```

#### FunctionsAuthProvider API
`FunctionsAuthProvider` generates a token for function request authentication.  An implementation is required to invoke 
a function.

```java
global interface FunctionsAuthProvider {
    String generateToken();
}
```

`FunctionsMetadataAuthProvider` is provided to generate an accessToken via a Connected App referenced by 
`FunctionReference__mdt` fields `ConsumerKey__c` and `Certificate__c`.

#### Example
```java
// Invoke sync function
public static void invokeSync() {
    // Get reference to function
    Function javafunction = Function.get('mynamespace', 'sfhxhello_javafunction');
    Map<String,String> params = new Map<String,String>();

    // Invoke sync...
    FunctionInvocation invocation = javafunction.invoke(JSON.serialize(params));
}

// Invoke async function
public static void invokeSync() {
    // Get reference to function
    Function javafunction = Function.get(''mynamespace'', 'sfhxhello_javafunction');
    Map<String,String> params = new Map<String,String>();

    // Aync invoke
    FunctionInvocation invocation = javaFunction.invoke(JSON.serialize(params), new Callback('sfhxhello_javafunction'));
}

// Callback
public class Callback implements FunctionCallback {
    String functionName;

    Callback(String functionName) {
        this.functionName = functionName;
    }

    public void handleResponse(FunctionInvocation invocation) {
        System.debug(invocation.getStatus().name() + ': ' + invocation.getResponse());
    }
}
```

### FunctionReference__mdt Custom Metadata
Metadata enables customers and partners to extend, expose to Admins, package, and progress their Platform apps from deployment environment to deployment environment.

`FunctionReference` Custom Metadata records represent deployed, invocable functions.

Fields:
- **Endpoint__c** - URL of function.  Function endpoints change per deployment environment, eg Scratch, Sandbox, and 
Production Organizations will each have their own deployed function.
- **PermissionSetOrGroup__c** - session-based Permission Set API name activated on function's token grant function access.  If applicable, include namespace, eg `mynamespace__MyPermissionSet`.
- **ConsumerKey__c** - Consumer Key or Issuer of the authentication Connected App (eg, the *Functions Authentication* 
Connected App create below) used by `FunctionsMetadataAuthProvider` Apex class to authenticate function invokers.
- **Certificate__c** - Certificate name, created via Salesforce [Certificates and Keys](https://help.salesforce.com/s/articleView?id=sf.security_keys_about.htm&type=5), 
that is associated with the authentication Connected App (eg, the *Functions Authentication* Connected App created below) 
used by `FunctionsMetadataAuthProvider` Apex class to authenticate function invokers.

Change `FunctionReference` Custom Metadata fields per deployment environment.  Code stays the same, metadata changes, 
eg stage-specific (Scratch, Sandbox, etc) function endpoints.

For each function, create a `FunctionReference` Custom Metadata record:
```bash
# If you have already deployed your app, get the app URL from Heroku 
$ heroku apps:info -s  | grep web_url | cut -d= -f2
https://javafunction.herokuapp.com/
# Use this URL as the function's FunctionReference.Endpoint__c.
# If you have not yet deployed, be sure to name your app to match the Endpoint reference.
```

#### Example
```bash
$ cat force-app/main/default/customMetadata/FunctionReference.sfhxhello_javafunction.md-meta.xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Java Function</label>
    <protected>false</protected>
    <values>
        <field>Endpoint__c</field>
        <value xsi:type="xsd:string">https://javafunction.herokuapp.com</value>
    </values>
    <values>
        <field>PermissionSetOrGroup__c</field>
        <value xsi:type="xsd:string">JavaFunction</value>
    </values>
    <values>
        <field>ConsumerKey__c</field>
        <value xsi:type="xsd:string">3MVG9i...</value>
    </values>
    <values>
        <field>Certificate__c</field>
        <value xsi:type="xsd:string">Functions_Internal_Cert</value>
    </values>
</CustomMetadata>
```

The Reference Function Framework queries to the `FunctionReference__mdt` record for each `Functions.get(<function name>)` 
call.  The `get()` API will validate the reference, validate that `PermissionSetOrGroup__c` exists (if provided) and 
ensure that the invoking user is assigned.  `Endpoint__c` is used by `invoke()` to invoke the function.

### AsyncFunctionInvocationRequest__c Custom Object

`AsyncFunctionInvocationRequest` Custom Object manages and tracks asynchronous function invocations.

On async invocation, a `AsyncFunctionInvocationRequest` record is created and updated by the proxy capturing the 
function's response or any failure.  Once the record is updated, a trigger invokes the given `FunctionCallback` implementation.

`StatusCode__c` of `500` generally means an error occurred in the function.  `StatusCode__c` of `503` generally means 
an error occurred in the framework, Salesforce, Heroku, or somewhere in-between.. 

> Note: `AsyncFunctionInvocationRequest` records must be deleted on a regular basis to ensure efficient Organization storage.

```bash
force-app/main/default/objects/AsyncFunctionInvocationRequest__c/
├── AsyncFunctionInvocationRequest__c.object-meta.xml
└── fields
    ├── Callback__c.field-meta.xml
    ├── CallbackType__c.field-meta.xml
    ├── Context__c.field-meta.xml
    ├── ExtraInfo__c.field-meta.xml
    ├── Request__c.field-meta.xml
    ├── RequestId__c.field-meta.xml
    ├── Response__c.field-meta.xml
    ├── Status__c.field-meta.xml
    └── StatusCode__c.field-meta.xml
```

## Proxy
A Function's Heroku App consists of 2 apps - a language-specific proxy app that listens on the external port and the function app that accepts requests from the proxy.

For **synchronous** requests, the proxy:
1. Validates the request ensure expected payload and that the caller is from the owner org.
2. Enriches the function payload:
   1. Mints an org-accessible token for the function
   2. Activates given session-based Permission Sets on the function's token, if applicable.
3. Forwards the request to the function.

For **asynchronous** requests, the proxy:
1. Validates the request ensure expected payload and that the caller is from the owner org.
2. Enriches the function payload:
    1. Mints an org-accessible token for the function
    2. Activates given session-based Permission Sets on the function's token, if applicable.
3. Disconnects from the client sending a `201` response.
4. Forwards the request to the function.
5. Handles the function's response update associate `AsyncFunctionInvocationRequest__c` record.

The Reference Functions Framework proxy for Java and Node are provided in the `javafunction` and `typescriptfunction` directories, respectively.

For more information, see language-specific proxy:
- [Java](functions/javafunction/README.md#overview)
- [Node](functions/typescriptfunction/README.md#jverview)

## Migrating Salesforce Functions to Reference Function Framework
See [Migration to Reference Function Framework](MIGRATION.md).
