# Migration to Reference Functions Framework

The following migration steps assume that you have an existing Heroku account.  If not, see [Get started on Heroku today](https://signup.heroku.com/).

If you're new to Heroku or for a refresher, see [How Heroku Works](https://devcenter.heroku.com/articles/how-heroku-works).

Migration requires the [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli).

## Overview
Migration to the Reference Functions Framework includes these one-time setup steps (details in steps below):
- Copying and deploying Reference Functions Framework metadata and source to your SFDX project and the language-specific 
proxy and build artifacts to your functions.
- Creating and configuring Heroku Apps for each function. 
- Updating Salesforce Function Apex API references to Reference Functions Framework Apex APIs. 
- Creating and configuring the authentication and authorization Connected Apps and their associated Permission Sets.
- Creating `FunctionReference_mdt` Custom Metadata Type records for each function.
- Creating a Remote Site Setting for each function.

After migrating to the Reference Functions Framework, function and integration development and testing iterations are 
done per usual. 

Follow the detailed steps below.

### Example Reference Functions Framework Implementations
This repository also includes examples of Reference Functions Framework Java and Typescript implementations.

Example Apex invocations:
 - Apex class `InvokeJavaFunction` invokes a `Java` function.
 - Apex class `InvokeTypescriptFunction` invokes a `Typescript` function.

Example metadata and source includes:
- Apex Class in `force-app/main/default/classes/`
- Custom Metadata in `force-app/main/default/customMetadata/`
- Visualforce Pages in `force-app/main/default/pages/`
- Permission Sets in `force-app/main/default/permissionsets/`
- Remote Site Settings in `force-app/main/default/remoteSiteSettings/`

> **Note**  
> Example source and metadata is intended to illustrate Reference Functions Framework implementations for Java and Typescript functions and may be excluded from copying to your SFDX project.  
> Before migrating your Salesforce Functions to the Reference Functions Framework, review example metadata and source.


## 1. Copy Reference Functions Framework artifacts
### 1. Copy Reference Functions Framework's Salesforce Platform metadata and source to your SFDX project.
Metadata and source includes:
- Apex Classes in `force-app/main/default/classes/functions/`
- Apex Triggers in `force-app/main/default/triggers/functions/`
- Custom Objects in `force-app/main/default/objects/`

### 2. Copy language-specific Reference Functions Framework proxy artifacts to your function
See language-specific instructions:
- Java [README](https://github.com/heroku/function-migration/blob/main/functions/javafunction/README.md#user-content-artifacts)
- Node [README](https://github.com/heroku/function-migration/blob/main/functions/typescriptfunction/README.md#user-content-artifacts)

## 2. Apply function project changes
See language-specific instructions:
- Java [README](https://github.com/heroku/function-migration/blob/main/functions/javafunction/README.md#user-content-changes)
- Node [README](https://github.com/heroku/function-migration/blob/main/functions/typescriptfunction/README.md#user-content-changes)

## 3. Update Apex that invokes functions
Update `functions.Function` Salesforce Function API references removing the `functions.` Apex namespace, 
eg `functions.Function.get()` becomes `Function.get()`.  See example below.

### Function.get()
The Reference Functions Framework's `Function.get()` API must resolve to a `FunctionReference_mdt` record.  The reference 
given to `get()` is the `Object Name` of `FunctionReference_mdt` record.

The `Function.get()` API supports existing Salesforce Function references with the `.` delimiter: 
`Function.get(<project>.<function>)`.  The framework also supports the `_` delimiter: `<project>_<function>`.  The 
framework does not require a `project` qualifier: `Function.get(<function>)`.

The `Function.get(<namespace>, <function>)` API supports namespace.  If namespace is not provided, namespace will default 
to the Organization's namespace.

For cross-namespace support - invoking a function in another namespace - the function's `FunctionReference_mdt` record must be set 
to unprotected (`Protected Component` is `false`). 

### Example of Apex Changes
```java
public void invoke() {
    // Note: functions.Function is now Function
    Function javaFunction = Function.get('sfhxhello.javafunction');

    // Sync
    // Note: functions.FunctionInvocation is now FunctionInvocation
    FunctionInvocation invocation = javaFunction.invoke(JSON.serialize(params));

    // Async
    invocation = javaFunction.invoke(JSON.serialize(params), new MyCallback());
}

// Note: functions.FunctionCallback is now FunctionCallback
public class MyCallback implements FunctionCallback {
    // Note: functions.FunctionInvocation is now FunctionInvocation
    public void handleResponse(FunctionInvocation invocation) {
        System.debug(invocation.getStatus().name() + ': ' + invocation.getResponse());
    }
}
```

## 4. For each function, create a Heroku App and configure its deployment
For enterprise-grade security, use [Private Spaces](https://www.heroku.com/private-spaces) as a secure container for your 
Heroku Apps.  A Private Space, part of Heroku Enterprise, is a network isolated group of apps and data services with a 
dedicated runtime environment, provisioned to Heroku in a geographic region you specify. With Private Spaces you can build 
modern apps with the powerful Heroku developer experience and get enterprise-grade secure network topologies. This enables 
your Heroku applications to securely connect to on-premise systems on your corporate network and other cloud services, 
including Salesforce.

See language-specific instructions:
- Java [README](https://github.com/heroku/function-migration/blob/main/functions/javafunction/README.md#user-content-app)
- Node [README](https://github.com/heroku/function-migration/blob/main/functions/typescriptfunction/README.md#user-content-app)


## 5. Create a Connected App used to mint access tokens for function's Organization access
Create an authorization Connected App used by the proxy to mint access tokens for associated function(s). The token is used by a function
for Organization access.

This Connected App and session-based Permission Set (create in the next step) determine what a function is authorized 
to do, eg invoke Salesforce APIs.

You may create a Connected App for each function or use a single Connected App for all functions. However, each 
lifecycle stage (ie Production, Sandbox, Scratch) should configure their own Connected app to ensure isolation.

This document will refer to this Connected App as the **authorization** or **authZ** Connected App.

The following setups are done in your Organization's Setup.

1. Create an RSA Self-Signed Certificate used to generate an access token for a function.  The certificate will be 
uploaded to the Connected App in the next step.
   For more info, see [Create a Private Key and Self-Signed Digital Certificate](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_auth_key_and_cert.htm).
2. Create an internal JWT-based Connected App used by the proxy to validate function callers.
    1. On the **App Manager** page, click on **New Connected App**.
    2. Fill in Connected App required fields, for example name as the name of the function (eg, for accompanying example function, "Java Function Authorization") for single-function use or "Functions Authorization" when used for all or multiple functions.
    2. Enable OAuth Settings and enter an arbitrary callback URL such as http://localhost:1717/OauthRedirect.  Select **Use Digital Signatures** and upload the certificate file (.crt) created in step 1.
    3. The Connected App should have the following scopes:
        - **Manage user data via APIs** - used by the proxy to access Salesforce's oauth API
        - **Perform requests at any time** - used by the proxy to mint an authorization token for function's Organization access
    4. On the **Manage** or **Edit Policies** page, set **Permitted Users** to **Admin-approved users are pre-authorized**.  This enables using a Permission Set to assign who can access this Connected App.
    5. On the **Manage Consumer Details** page, reveal and then copy **Consumer Key** value (also referred to as Issuer). 
    > **Note**
    > In a later step, you will need the **Consumer Key** and certificate key file for use as config vars (i.e. `CONSUMER_KEY` and `ENCODED_PRIVATE_KEY`) with each of your Heroku apps.

For more information on creating a JWT Connected App, see [OAuth 2.0 JWT Bearer Flow for Server-to-Server Integration](https://help.salesforce.com/s/articleView?id=sf.remoteaccess_oauth_jwt_flow.htm&type=5).

Keep Connected Apps secure by periodically rotating your Consumer Key.  For more information, 
see [Rotate the Consumer Key and Consumer Secret of a Connected App](https://help.salesforce.com/s/articleView?id=sf.connected_app_rotate_consumer_details.htm&type=5).

## 6. Create a session-based Permission Set that specifies function's Organization access
Once a function token is minted, the proxy will activate given session-based Permission Sets authorizing specific 
capabilities, for example Standard and Custom Object access.

A session-based Permission Set may be created for each function or a single session-based Permission Set for all 
functions.  A Permission Set Group, referencing multiple session-based Permission Sets, is also supported.

A session-based Permission Set or a Permission Set Group is associated to functions via 
a function's `FunctionReference.PermissionSetOrGroup__c` Custom Metadata field.  More below.

For more information on session-based Permission Sets, see [Session-based Permission Sets](https://help.salesforce.com/s/articleView?id=sf.perm_sets_session_map.htm&type=5).

This document will refer to this Permission Set as the **authorization** or **authZ** Permission Set.

The following setups are done in your Organization's Setup.

Before creating an authorization, session-based Permission Set, deploy the `AsyncFunctionInvocationRequest__c` 
Custom Object that we'll grant **Edit** access in the following Permission Set.  `AsyncFunctionInvocationRequest__c` is 
used by the Example Function Framework for asynchronous function requests.
```bash
$ sfdx force:source:deploy -p force-app/main/default/objects/AsyncFunctionInvocationRequest__c/
...
=== Deployed Source

 FULL NAME                                         TYPE         PROJECT PATH                                                                                                       
 ───────────────────────────────────────────────── ──────────── ────────────────────────────────────────────────────────────────────────────────────────────────────────────────── 
 AsyncFunctionInvocationRequest__c.CallbackType__c CustomField  force-app/main/default/objects/AsyncFunctionInvocationRequest__c/fields/CallbackType__c.field-meta.xml             
 AsyncFunctionInvocationRequest__c.Callback__c     CustomField  force-app/main/default/objects/AsyncFunctionInvocationRequest__c/fields/Callback__c.field-meta.xml                 
 AsyncFunctionInvocationRequest__c.Context__c      CustomField  force-app/main/default/objects/AsyncFunctionInvocationRequest__c/fields/Context__c.field-meta.xml                  
 AsyncFunctionInvocationRequest__c.ExtraInfo__c    CustomField  force-app/main/default/objects/AsyncFunctionInvocationRequest__c/fields/ExtraInfo__c.field-meta.xml                
 AsyncFunctionInvocationRequest__c.RequestId__c    CustomField  force-app/main/default/objects/AsyncFunctionInvocationRequest__c/fields/RequestId__c.field-meta.xml                
 AsyncFunctionInvocationRequest__c.Request__c      CustomField  force-app/main/default/objects/AsyncFunctionInvocationRequest__c/fields/Request__c.field-meta.xml                  
 AsyncFunctionInvocationRequest__c.Response__c     CustomField  force-app/main/default/objects/AsyncFunctionInvocationRequest__c/fields/Response__c.field-meta.xml                 
 AsyncFunctionInvocationRequest__c.StatusCode__c   CustomField  force-app/main/default/objects/AsyncFunctionInvocationRequest__c/fields/StatusCode__c.field-meta.xml               
 AsyncFunctionInvocationRequest__c.Status__c       CustomField  force-app/main/default/objects/AsyncFunctionInvocationRequest__c/fields/Status__c.field-meta.xml                   
 AsyncFunctionInvocationRequest__c                 CustomObject force-app/main/default/objects/AsyncFunctionInvocationRequest__c/AsyncFunctionInvocationRequest__c.object-meta.xml 
```

1. On the **Permission Sets** pages, select **New** to create a new Permission Set.  
2. Provide a name and enable **Session Activation Required**.  For function-specific Permission Set,
   name the Permission Set to associate to its function, for example "Java Function Authorization".
3. Under **Assigned Connected Apps**, assign the authorization Connected App created above.
4. Under **Object Settings**, assign **Edit** access to `Async Function Invocation Requests` - required for asynchronous function invocation responses.
    1. Ensure **Edit** access to fields: `ExtraInfo__c`, `Response__c`, `Status__c`, and `StatusCode__c`.
5. Enable other App and System settings need by the function.  The example `Java` and `Typescript` functions require 
**Read** access to the **Account** object.
6. Under **Manage Assignments**, assign function invoking users to the Permission Set.

For Apex Batch, Scheduled Flows, and other Automated Process User function invocations, ensure the Automated Process
User is assigned to the authorization Connected App and Permission Set.

To set and view field-level security via Permission Sets, see [Set Field-Level Security for a Field on Permission Sets Instead of Profiles During Field Creation (Beta)](https://help.salesforce.com/s/articleView?id=release-notes.rn_forcecom_fls_permsets.htm&release=240&type=5).

## 7. Create a JWT-based Connected App for function authentication
This Connected App is used by the Reference Functions Framework to generate a token that is included in each function payload.
The proxy uses the token to authenticate function requests. Function requests must originate from the "owning" Organization
and function invoking users must have authorized access to this Connected App via a Permission Set and assignment.

For more information on Connected Apps, see [Connected Apps](https://help.salesforce.com/s/articleView?id=sf.connected_app_overview.htm&type=5).

This document will refer to this Connected App as the **authentication** or **authN** Connected App.

The following setups are done in your Organization's Setup.

1. On the **Certificate and Key Management** page, create a Self-Signed Certificate used to generate an access token to validate function callers.  Once created, download the certificate.  
   A Self-Signed Certificate must be created via **Certificate and Key Management** as it's referenced in the Reference Functions Framework API's `FunctionsMetadataAuthProvider` class.
   <br>For more information, see [Generate a Self-Signed Certificate](https://help.salesforce.com/s/articleView?id=sf.security_keys_creating.htm&type=5).
2. Create an internal JWT-based Connected App used by the proxy to validate function callers.
    1. On the **App Manager** page, click on **New Connected App**.
    2. Fill in Connected App required fields, for example name "Functions Authentication".
    2. Select **Use Digital Signatures** and upload the certificate file (.crt) created in step 1.
    3. The Connected App should have the following scopes:
        - **Manage user data via APIs** - used to activate session-based Permission Sets
        - **Access custom permissions** - used to activate session-based Permission Sets
        - **Access the identity URL service** - used by the proxy to verify function request callers
        - **Perform requests at any time** - used to mint an authentication token used by the proxy to verify function request callers
    4. On the **Manage** or **Edit Policies** page, set **Permitted Users** to **Admin-approved users are pre-authorized**.
    5. On the **Manage Consumer Details** page, reveal and then copy **Consumer Key** value (also referred to as Issuer).

The **Certificate** name and **Consumer Key** will be stored in each function's associated `FunctionReference__mdt` Custom Metadata.  More below.

See [Create a Connected App -> Enable OAuth Settings for API Integration](https://help.salesforce.com/s/articleView?id=sf.connected_app_create_api_integration.htm&type=5).

Keep Connected Apps secure by periodically rotating your Consumer Key.  For more information,
see [Rotate the Consumer Key and Consumer Secret of a Connected App](https://help.salesforce.com/s/articleView?id=sf.connected_app_rotate_consumer_details.htm&type=5).

## 8. Create a Permission Set for function authentication
A Permission Set is needed to grant function invoking users access to the authentication Connected App created above.

For more information on Permission Sets, see [Permission Sets](https://help.salesforce.com/s/articleView?id=sf.perm_sets_overview.htm&type=5).

This document will refer to this Permission Set as the **authentication** or **authN** Permission Set.

The following setups are done in your Organization's Setup.

1. On the **Permission Sets** pages, select **New** to create a new Permission Set.  Name may be "Functions 
Authentication".  Do *not* check Session Activation Required for this Permission Set.
2. Under **Assigned Connected Apps**, assign the authentication Connected App created above and all authorization 
Connected Apps (eg, "Functions Authorization" created above)
3. Under **Manage Assignments**, assign function invoking users to the Permission Set.

For Apex Batch, Scheduled Flows, and other Automated Process User function invocations, ensure the Automated Process 
User is assigned to the authentication Connected App and Permission Set.

## 9. Configure function Apps
The authorization Connected App's **Consumer Key** and certificate key file are needed for this step.

See language-specific instructions:
- Java [README](https://github.com/heroku/function-migration/blob/main/functions/javafunction/README.md#user-content-config)
- Node [README](https://github.com/heroku/function-migration/blob/main/functions/typescriptfunction/README.md#user-content-config)

## 10. Deploy proxy and function to Heroku
See language-specific instructions:
- Java [README](https://github.com/heroku/function-migration/blob/main/functions/javafunction/README.md#user-content-deploy)
- Node [README](https://github.com/heroku/function-migration/blob/main/functions/typescriptfunction/README.md#user-content-deploy)

When switching between functions, update the `remote` to the target function:
```bash
$ heroku git:remote -a javafunction
set git remote heroku to https://git.heroku.com/javafunction.git

$ git push heroku main
...
```

## 11. Verify proxy and function started up
See language-specific instructions:
- Java [README](https://github.com/heroku/function-migration/blob/main/functions/javafunction/README.md#user-content-startup)
- Node [README](https://github.com/heroku/function-migration/blob/main/functions/typescriptfunction/README.md#user-content-startup)

## 12. Create FunctionReference__mdt Custom Metadata Type for each function
Functions are represented in your Organization as `FunctionReference__mdt` Custom Metadata Type.  `Function.get('<myproject>.<function>')` API reference
a `FunctionReference__mdt` Custom Metadata record.  The `FunctionReference__mdt` Custom Metadata Type enables each function to have custom Platform behavior
such as associating session-based Permission Sets that are activated on the function's access token to authorize specific Org access.

`FunctionReference__mdt` Custom Metadata fields:
- `ConsumerKey__c` - Consumer Key of the authentication Connected App (eg, "Function Authentication") used by `FunctionsMetadataAuthProvider` Apex class to generate an access token for the proxy to authenticate function invokers.
- `Certificate__c` - Name of certificate associated with the authentication Connected App (eg, "Function Authentication") used by `FunctionsMetadataAuthProvider` Apex class to generate an access token for the proxy to authenticate function invokers.
- `Endpoint__c` - URL of function.
- `PermissionSetOrGroup__c` - (Optional) the API name of session-based Permission Set name (eg, "Java Function Authentication") activated on function's token grant function access.  If a Permission Set is not associated, function invoking users must be assigned `AsyncFunctionInvocationRequest__c` access via another Permission Set.

For cross-namespace support - invoking a function in another namespace - the function's `FunctionReference_mdt` record must be set
to unprotected, ie `Protected Component` is `false`.  To prevent cross-namespace invocations, set `Protected Component` to `true`.

For more information on Custom Metadata, see [Custom Metadata Types](https://help.salesforce.com/s/articleView?id=sf.custommetadatatypes_overview.htm&language=en_US&type=5).

For each function, create a `FunctionReference__mdt` Custom Metadata record:
1. First, capture your function's URL.
```bash
# Once an app is deployed, you can get the URL  via the CLI. If not, you can still set 
# metadata if you know the name of your app, in this example it was `javafunction`.
# Set function URL in FunctionReference Custom Metadata
$ heroku apps:info -s  | grep web_url | cut -d= -f2
https://javafunction.herokuapp.com/
```

2. Create a `FunctionReference__mdt` metadata file.  

In the example below, `sffxhello` in `FunctionReference.sfhxhello_javafunction.md-meta.xml` is the project name - 
change to your own project (value of `sfdx-project.json#name`). Project name as a function qualifier is not require by 
the Reference Functions Framework.  If an Organization's source and metadata span multiple repositories, project name 
may be used to ensure that `FunctionReference__mdt` records are unique.
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

## 13. Create Remote Site Settings for each function
A Remote Site Setting permits Apex callouts to the registered URL.  For each function, create a Remote Site Setting in Setup or metadata, example below.

Additionally, to mint an authentication token, create a Remote Site Setting for the Organization's domain.

For more information, see [Configure Remote Site Settings](https://help.salesforce.com/s/articleView?id=sf.configuring_remoteproxy.htm&type=5).

```bash
# Used to generate an authentication token in Apex.  The token is sent with the function payload and used by the
# proxy to authenticate the request.
$ cat force-app/main/default/remoteSiteSettings/ThisOrg.remoteSite-meta.xml 
<?xml version="1.0" encoding="UTF-8"?>
<RemoteSiteSetting xmlns="http://soap.sforce.com/2006/04/metadata">
    <disableProtocolSecurity>false</disableProtocolSecurity>
    <isActive>true</isActive>
    <url>https://mycompany.my.salesforce.com</url>
</RemoteSiteSetting>

# Access to function
$ cat force-app/main/default/remoteSiteSettings/JavaFunction.remoteSite-meta.xml 
<?xml version="1.0" encoding="UTF-8"?>
<RemoteSiteSetting xmlns="http://soap.sforce.com/2006/04/metadata">
    <disableProtocolSecurity>false</disableProtocolSecurity>
    <isActive>true</isActive>
    <url>https://javafunction.herokuapp.com</url>
</RemoteSiteSetting>

$ cat force-app/main/default/remoteSiteSettings/TypescriptFunction.remoteSite-meta.xml 
<?xml version="1.0" encoding="UTF-8"?>
<RemoteSiteSetting xmlns="http://soap.sforce.com/2006/04/metadata">
    <disableProtocolSecurity>false</disableProtocolSecurity>
    <isActive>true</isActive>
    <url>https://typescriptfunction.herokuapp.com</url>
</RemoteSiteSetting>
```

## 14. Deploy SFDX source to your Organization
Deploy Reference Functions Framework APIs - Apex Classes, Trigger, Custom Objects - and your integrations - Apex, `FunctionReference__mdt` Custom Metadata, etc - to your Organization.

Before deploying, ensure that `force-app/main/default/customMetadata/FunctionReference.sfhxhello_javafunction.md-meta.xml` and 
`force-app/main/default/customMetadata/FunctionReference.sfhxhello_typescriptfunction.md-meta.xml` fields are set to your 
function endpoint and Organization settings, for example Connected App Consumer Key and Certificate. 

```bash
$ sfdx force:source:deploy -p force-app/
Deploying v57.0 metadata to admin@functions.org using the v57.0 SOAP API
Deploy ID: 0AfB000000pmfwpKAA
DEPLOY PROGRESS | ████████████████████████████████████████ | 48/48 Components

=== Deployed Source

 FULL NAME                                         TYPE              PROJECT PATH                                                                                                       
 ───────────────────────────────────────────────── ───────────────── ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────                                               
 Function                                          ApexClass         force-app/main/default/classes/functions/Function.cls                                                              
 Function                                          ApexClass         force-app/main/default/classes/functions/Function.cls-meta.xml                                                     
 FunctionCallback                                  ApexClass         force-app/main/default/classes/functions/FunctionCallback.cls                                                      
 FunctionCallback                                  ApexClass         force-app/main/default/classes/functions/FunctionCallback.cls-meta.xml                                             
 FunctionCallbackQueueable                         ApexClass         force-app/main/default/classes/functions/FunctionCallbackQueueable.cls                                             
 FunctionCallbackQueueable                         ApexClass         force-app/main/default/classes/functions/FunctionCallbackQueueable.cls-meta.xml                                    
...                                         
 AsyncResponseHandlerTrigger                       ApexTrigger       force-app/main/default/triggers/functions/AsyncResponseHandlerTrigger.trigger                                      
 AsyncResponseHandlerTrigger                       ApexTrigger       force-app/main/default/triggers/functions/AsyncResponseHandlerTrigger.trigger-meta.xml                                             
 ..                   
 AsyncFunctionInvocationRequest__c                 CustomObject      force-app/main/default/objects/AsyncFunctionInvocationRequest__c/AsyncFunctionInvocationRequest__c.object-meta.xml 
 FunctionReference__mdt                            CustomObject      force-app/main/default/objects/FunctionReference__mdt/FunctionReference__mdt.object-meta.xml                       
...                                   
Deploy Succeeded.
```

## 15. Invoke the function
Example Apex code that invokes a function using Reference Functions Framework APIs:
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
public static void invokeAsync() {
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

See language-specific examples:
- Java [README](https://github.com/heroku/function-migration/blob/main/functions/javafunction/README.md#user-content-invoke)
- Node [README](https://github.com/heroku/function-migration/blob/main/functions/typescriptfunction/README.md#user-content-invoke)

# Reference Functions Framework Examples
See [InvokeJavaFunction](force-app/main/default/classes/InvokeJavaFunction.cls) and [InvokeTypescriptFunction](force-app/main/default/classes/InvokeTypescriptFunction.cls).

For convenience, `InvokeJavaFunction` and `InvokeTypescriptFunction` may be invoked via Visualforce pages, see [pages/ directory](force-app/main/default/pages).  Visualforce Pages may be configured as List View buttons.

# Local Development
See language-specific instructions:
- Java [README](https://github.com/heroku/function-migration/blob/main/functions/javafunction/README.md#user-content-dev)
- Node [README](https://github.com/heroku/function-migration/blob/main/functions/typescriptfunction/README.md#user-content-dev)

## Testing Function Invocations
### Writing Tests
The Reference Functions Framework provides testing utilities to mock authentication token generation, `FunctionReference_mdt` look up, and function callout responses.
```bash
force-app/main/default/classes/functions/tests/
├── FunctionInvocationCalloutMocks.cls
├── FunctionsTestAuthProviderMocks.cls
└── FunctionsTestDataFactory.cls
```

[InvokeJavaFunctionTest.cls](https://github.com/heroku/function-migration/blob/main/force-app/main/default/classes/tests/InvokeJavaFunctionTest.cls) is an 
example on how to test function invocations.  For example, the following snippet demonstrates using 
`FunctionInvocationCalloutMocks` to mock the function response and `FunctionsTestAuthProviderMocks.FakeAuthProvider` 
to mock the authentication token generation.
```java
@isTest
static void testInvoke_sync() {
    String responseBody='{}';
    Test.setMock(HttpCalloutMock.class,FunctionInvocationCalloutMocks.respondSuccess(responseBody));

    Test.startTest();

    FunctionInvocation invocation=InvokeJavaFunction.invokeSyncWork(new FunctionsTestAuthProviderMocks.FakeAuthProvider());

    Test.stopTest();

    // Asserts
    ...
}
```
For more information, see [Testing HTTP Callouts](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_restful_http_testing.htm).

### Running Tests
```bash
$ sfdx apex run test --code-coverage --result-format human --detailed-coverage
=== Test Summary
NAME                 VALUE                   
───────────────────  ────────────────────────
Outcome              Passed                  
Tests Ran            10                      
Pass Rate            100%                    
Fail Rate            0%                      
Skip Rate            0%                      
Test Run Id          707B0000024qbxR         
Test Execution Time  4497 ms                 
Org Id               00DB0000000gJmXMAU      
Username             admin@admin.org
Org Wide Coverage    73%                     


=== Apex Code Coverage for Test Run 707B0000024qbxR
TEST NAME                                                CLASS BEING TESTED                     OUTCOME  PERCENT  MESSAGE  RUNTIME (MS)
───────────────────────────────────────────────────────  ─────────────────────────────────────  ───────  ───────  ───────  ────────────
<log output deleted>         
InvokeJavaFunctionTest.testInvoke_sync                   Function                               Pass     60%               143         
InvokeJavaFunctionTest.testInvoke_sync                   FunctionInvocationRequest              Pass     79%               143         


=== Apex Code Coverage by Class
CLASSES                                PERCENT  UNCOVERED LINES      
─────────────────────────────────────  ───────  ─────────────────────
FunctionReferenceMetadataProviderImpl  100%                          
FunctionInvocationImpl                 86%      40,42,55,56,90...    
FunctionInvocationErrorImpl            71%      14,15                
InvokeJavaFunction                     69%      8,10,12,14,15...     
FunctionCallbackQueueable              100%                          
Function                               93%      35,37,56,73,74...    
FunctionErrorType                      0%                            
FunctionInvocationStatus               0%                            
FunctionInvocationRequest              80%      45,113,116,119,122...
AsyncResponseHandlerTrigger            89%      11,32    
```

# Appendix
## Selecting and Setting Dyno Type
Heroku offers a variety of dyno types to support apps of all sizes, from small-scale projects to high-traffic production 
services.  For more information, see [Dyno Types](https://devcenter.heroku.com/articles/dyno-types).

If a function encounters `Memory quota exceeded`, configure the function's dyno type selecting a dyno having 
increased memory and CPU characteristics.
```bash
- 2023-04-06T19:13:35.124858+00:00 heroku[web.1]: Process running mem=591M(115.5%)
- 2023-04-06T19:13:35.126587+00:00 heroku[web.1]: Error R14 (Memory quota exceeded)
```

## Dyno Scaling
Heroku Apps can be scaled to run on multiple dynos simultaneously (except on Eco or Basic dynos). You can scale your 
app's dyno formation up and down manually from the Heroku Dashboard or CLI.

You can also configure Heroku Autoscaling for Performance-tier dynos, and for dynos running in Private Spaces. Threshold 
autoscaling adds or removes web dynos from your app automatically based on current request latency.

For more information, see [Scaling Your Dyno Formation](https://devcenter.heroku.com/articles/scaling)

Dynos have default scaling characteristics per dyno type.  For more information, see [Default Scaling Limits](https://devcenter.heroku.com/articles/dyno-types#default-scaling-limits).

[Heroku Add-ons Dynos](https://elements.heroku.com/addons#dynos) provides several add-on options to schedule, scale, 
and manage your dyno usage to your app's needs.

## Function Health Check API
To check the health of a deployed function, the `<function-url>/healthcheck` API.  The `x-org-id-18` header must 
match env/config var `ORG_ID_18` value.
```bash
$ curl -H "x-org-id-18: 00DDH00000000002AQ" https://javafunction.herokuapp.com/healthcheck
"OK"
```
#### Restart
If a function process has died, `/healthcheck` will attempt to restart the function.

Function logs:
```bash
14:03:18.113 INFO  [RUNTIME] c.s.f.p.c.HealthCheckController - [healthcheck-1680811398112]: Received /healthcheck request
14:03:18.119 INFO  [RUNTIME] c.s.f.p.s.InvokeFunctionService - [healthcheck-1680811398112]: Invoking function https://javafunction.herokuapp.com...
14:03:18.141 INFO  [RUNTIME] c.s.f.p.s.InvokeFunctionService - [healthcheck-1680811398112]: Invoked function https://javafunction.herokuapp.com in 18ms
14:03:18.142 WARN  [RUNTIME] c.s.f.p.c.HealthCheckController - [healthcheck-1680811398112]: Received /healthcheck exception: I/O error on POST request for "https://javafunction.herokuapp.com": Connection refused (Connection refused); nested exception is java.net.ConnectException: Connection refused (Connection refused)
14:03:18.142 INFO  [RUNTIME] c.s.f.p.c.HealthCheckController - [healthcheck-1680811398112]: Attempting to restart function...
14:03:18.142 INFO  [RUNTIME] c.s.f.p.service.StartFunctionService - Starting function w/ args: /app/.jdk/bin/java -XX:+UseContainerSupport -Xmx671m -XX:CICompilerCount=2 -Dfile.encoding=UTF-8 -jar /app/proxy/target/sf-fx-runtime-java-runtime-1.1.3-jar-with-dependencies.jar serve /app -h 0.0.0.0 -p 8080
14:03:18.145 INFO  [RUNTIME] c.s.f.p.service.StartFunctionService - Started function started on port 8080, process pid 134600
...
14:03:20.688 INFO  [RUNTIME] c.s.f.j.r.c.AbstractDetectorCommandImpl - Found 1 function(s) after 399ms.
14:03:20.689 INFO  [RUNTIME] c.s.f.j.r.commands.ServeCommandImpl - Found function: com.example.JavafunctionFunction
14:03:20.715 INFO  [RUNTIME] io.undertow - starting server: Undertow - 2.2.19.Final
...
14:03:21.145 INFO  [RUNTIME] c.s.f.p.c.HealthCheckController - [healthcheck-1680811398112]: Retrying function /healthcheck...
14:03:21.145 INFO  [RUNTIME] c.s.f.p.s.InvokeFunctionService - [healthcheck-1680811398112]: Invoking function https://javafunction.herokuapp.com...
14:03:21.237 INFO  [RUNTIME] c.s.f.p.s.InvokeFunctionService - [healthcheck-1680811398112]: Invoked function https://javafunction.herokuapp.com in 91ms
```

## Delete obsolete `AsyncFunctionInvocationRequest__c` records
Efficiently manage your Organization's storage by deleting obsolete `AsyncFunctionInvocationRequest__c` records.

```bash
$ sfdx data query --query "SELECT Id, LastModifiedDate FROM AsyncFunctionInvocationRequest__c ORDER BY LastModifiedDate"
 ID                 LASTMODIFIEDDATE             
 ────────────────── ──────────────────────────── 
 a00B000000Otu7cIAB 2023-04-06T19:13:00.000+0000 
Total number of records retrieved: 1.
Querying Data... done

# Delete obsolete record
$ sfdx data delete record --sobject AsyncFunctionInvocationRequest__c --record-id a00B000000Otu7cIAB
Successfully deleted record: a00B000000Otu7cIAB.
Deleting Record... Success
```

## Long-running Processes
Background jobs can dramatically improve the scalability of a web app by enabling it to offload slow or CPU-intensive 
tasks from its front-end. This helps ensure that the front-end can handle incoming web requests promptly, reducing the 
likelihood of performance issues that occur when requests become backlogged.

For more information, see [Worker Dynos, Background Jobs and Queueing](https://devcenter.heroku.com/articles/background-jobs-queueing).

## Data
Heroku provides three managed data services all available to function Apps:
- Heroku Postgres
- Heroku Redis
- Apache Kafka on Heroku

For more information, see [Databases & Data Management](https://devcenter.heroku.com/categories/data-management).

## Additional Security Features
Heroku Shield is a set of Heroku platform services that offer additional security features needed for building high 
compliance applications. Use Heroku Shield to build HIPAA or PCI compliant apps for regulated industries, such as 
healthcare, life sciences, or financial services. Heroku Shield simplifies the complexity associated with regulatory 
compliance, so you can enjoy same great developer experience when building, deploying, and managing your high compliance apps.

For more information, see [Heroku Shield](https://www.heroku.com/shield).
