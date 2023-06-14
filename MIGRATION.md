# Migration to Reference Functions Framework

The following migration steps assume that you have an existing Heroku account. If not, see [Get started on Heroku today](https://signup.heroku.com/). 
The migration also requires the [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli).

If you’re new to Heroku or need a refresher, see [How Heroku Works](https://devcenter.heroku.com/articles/how-heroku-works).

## Overview

Migrating to the Reference Functions Framework includes these one-time setup steps, which are detailed in the guide:

- [Copying and deploying Reference Functions Framework metadata and source to your SFDX project and the language-specific proxy and build artifacts to your functions.](https://github.com/heroku/function-migration/blob/main/MIGRATION.md#1-copy-reference-functions-framework-artifacts)
- [Creating and configuring Heroku apps for each function.](https://github.com/heroku/function-migration/blob/main/MIGRATION.md#4-create-heroku-apps-and-configure-deployments)
- [Updating Salesforce Function Apex API references to Reference Functions Framework Apex APIs.](https://github.com/heroku/function-migration/blob/main/MIGRATION.md#3-update-apex-code-that-invokes-functions)
- [Creating and configuring the authentication and authorization connected apps and their associated permission sets.](https://github.com/heroku/function-migration/blob/main/MIGRATION.md#5-create-an-authorization-connected-app)
- [Creating `FunctionReference_mdt` custom metadata type records for each function.](https://github.com/heroku/function-migration/blob/main/MIGRATION.md#12-create-functionreference__mdt-custom-metadata-types-for-each-function)
- [Creating a remote site setting for each function.](https://github.com/heroku/function-migration/blob/main/MIGRATION.md#13-create-remote-site-settings-for-each-function)

After migrating to the Reference Functions Framework, test the function and integration development as usual.

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

## 1. Copy Reference Functions Framework Artifacts

### Copy the Framework's Salesforce Platform Metadata and Source to Your SFDX Project

Metadata and source include:
- Apex Classes in `force-app/main/default/classes/functions/`
- Apex Triggers in `force-app/main/default/triggers/functions/`
- Custom Objects in `force-app/main/default/objects/`

### Copy Language-Specific Proxy Artifacts to Your Function

See language specific-instructions:
- Java [README](https://github.com/heroku/function-migration/blob/main/functions/javafunction/README.md#user-content-artifacts)
- Node [README](https://github.com/heroku/function-migration/blob/main/functions/typescriptfunction/README.md#user-content-artifacts)

## 2. Apply Function Project Changes

See language-specific instructions:
- Java [README](https://github.com/heroku/function-migration/blob/main/functions/javafunction/README.md#user-content-changes)
- Node [README](https://github.com/heroku/function-migration/blob/main/functions/typescriptfunction/README.md#user-content-changes)

## 3. Update Apex Code That Invokes Functions

Update `functions.Function` Salesforce Function API references by removing the `functions`. Apex namespace. For example, `functions.Function.get()` becomes `Function.get()`. 
See [Example of Apex Changes](https://github.com/heroku/function-migration/blob/main/MIGRATION.md#example-of-apex-changes).

### Function.get()

The Reference Functions Framework’s `Function.get()` API must resolve to a `FunctionReference_mdt` record. The reference given to `get()` is the `Object Name` of the `FunctionReference_mdt` record.

The `Function.get()` API supports existing Salesforce Function references with the `. `delimiter: `Function.get(<project>.<function>)`. The framework also supports the `_` delimiter: `<project>_<function>`. 
The framework doesn’t require a `project` qualifier: `Function.get(<function>)`.

The `Function.get(<namespace>, <function>)` API supports a namespace. If a namespace isn’t provided,it defaults to the [Salesforce org’s namespace](https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/namespaces_using_organization.htm).

For cross-namespace support, that is, invoking a function in another namespace, you must set the `Protected Component `field to `false` on the function’s `FunctionReference_mdt` record.

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

## 4. Create Heroku Apps and Configure Deployments

You must create a separate Heroku app for each function and configure its deployment. It’s recommended to deploy apps in [Private Spaces](https://www.heroku.com/private-spaces).

For enterprise-grade security, use Private Spaces as a secure container for your Heroku apps. A Private Space, part of [Heroku Enterprise](https://devcenter.heroku.com/articles/heroku-enterprise), is a network-isolated 
group of apps and data services with a dedicated runtime environment. You can provision it in a geographic region you specify. With Private Spaces, you can build modern apps with the powerful Heroku developer experience 
and get enterprise-grade secure network topologies. Private Spaces enables your Heroku applications to securely connect to on-premises systems on your corporate network and other cloud services, including Salesforce.

See language-specific instructions:
- Java [README](https://github.com/heroku/function-migration/blob/main/functions/javafunction/README.md#user-content-app)
- Node [README](https://github.com/heroku/function-migration/blob/main/functions/typescriptfunction/README.md#user-content-app)

## 5. Create an Authorization Connected App

Create an authorization [connected app](https://help.salesforce.com/s/articleView?id=sf.connected_app_overview.htm&type=5) that the proxy uses to create access tokens for associated functions. 
A function uses the token for Salesforce org access.

This connected app and session-based permission set created in the next step determines what a function is authorized to do, for example, invoke Salesforce APIs.

You can create a connected app for each function or use a single connected app for all functions. To ensure isolation, configure a connected app for each lifecycle stage, production, sandbox, and scratch orgs.

This document refers to this connected app as the **authorization** or **authZ** connected app.

Complete the following steps in **Setup** of your Salesforce org:

1. Create an [RSA self-signed certificate](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_auth_key_and_cert.htm) used to generate an access token for a function. You upload the certificate to the connected app in the next step.
2. To validate function callers, create an internal JWT-based connected app for the proxy:
    1. On the **App Manager** page, click **New Connected App**.
    2. Fill in the Connected App required fields. For a function-specific connected app, name it to associate to its function, for example, “Java Function Authorization”. For a connected app used for multiple functions, name it “Functions Authorization”.
    3. Select **Enable OAuth Settings** and enter an arbitrary callback URL such as [http://localhost:1717/OauthRedirect](http://localhost:1717/OauthRedirect). 
    4. Select **Use Digital Signatures** and upload the certificate file (.crt) created in Step 1.
    5. Add the following scopes:
        1. **Manage user data via APIs**: allows the proxy to access Salesforce’s OAuth APIs
        2. **Perform requests at any time**: allows the proxy to create an authorization token for function’s Salesforce org access.
    6. On the **Manage** or **Edit Policies** page, set **Permitted Users** to **Admin-approved users are pre-authorized**. This setting enables assigning a permission set to who can access this connected app.
    7. On the **Manage Consumer Details** page, reveal and copy the **Consumer Key **value, also referred to as Issuer.

>**Note**  
>In a later step, you need the **Consumer Key** and certificate key file to use as config vars, `CONSUMER_KEY `and `ENCODED_PRIVATE_KEY`, for each of your Heroku apps.

For more information on creating a JWT connected app, see [OAuth 2.0 JWT Bearer Flow for Server-to-Server Integration](https://help.salesforce.com/s/articleView?id=sf.remoteaccess_oauth_jwt_flow.htm&type=5).

Keep Connected Apps secure by periodically rotating your consumer key. For more information, see [Rotate the Consumer Key and Consumer Secret of a Connected App](https://help.salesforce.com/s/articleView?id=sf.connected_app_rotate_consumer_details.htm&type=5).

## 6. Create a Session-Based Permission Set

After the proxy creates a function token, the proxy activates assigned [session-based permission sets](https://help.salesforce.com/s/articleView?id=sf.perm_sets_session_map.htm&type=5). These permission sets authorize specific capabilities, such as access to Standard and Custom objects.

You can create a session-based permission set for each function, or you can create a single session-based permission set for all functions. A [permission set group](https://help.salesforce.com/s/articleView?id=sf.perm_set_groups.htm&language=en_US&type=5#:~:text=A%20permission%20set%20group%20calculates,available%20for%20the%20assigned%20users.), referencing multiple session-based permission sets, is also supported.

A session-based permission set or a permission set group is associated to functions via a function’s `FunctionReference.PermissionSetOrGroup__c` custom metadata field.

This document refers to this permission set as the **authorization** or **authZ** permission set.

To grant **Edit** access to the `AsyncFunctionInvocationRequest__c` custom object, you must deploy it before creating the authorization, session-based permission set. 
The Reference Functions Framework uses `AsyncFunctionInvocationRequest__c` for asynchronous function requests.

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

Complete the following steps in **Setup** of your Salesforce org:

1. On the **Permission Sets** page, click **New** to create a permission set.
2. Provide a name and enable **Session Activation Required**. For a function-specific permission set, name it to associate to its function, for example, “Java Function Authorization”.
3. Under **Assigned Connected Apps**, assign the authorization connected app created [earlier](https://github.com/heroku/function-migration/blob/main/MIGRATION.md#5-create-an-authorization-connected-app).
4. Under **Object Settings**, assign **Edit** access to `Async Function Invocation Requests`, which is required for asynchronous function invocation responses.
    1. Ensure **Edit** access to the fields: `ExtraInfo__c`, `Response__c`, `Status__c`, and `StatusCode__c`.
5. Enable other app and system settings that the function needs. The example `Java` and `Typescript` functions require **Read** access to the **Account** object.
6. Under **Manage Assignments**, assign function-invoking users to the permission set.

For Apex Batch, Scheduled Flows, and other Automated Process User invocations, ensure the Automated Process user is assigned to the authentication connected app.

To set and view field-level security via Permission Sets, see [Set Field-Level Security for a Field on Permission Sets Instead of Profiles During Field Creation (Beta)](https://help.salesforce.com/s/articleView?id=release-notes.rn_forcecom_fls_permsets.htm&release=240&type=5).

## 7. Create an Authentication Connected App

The Reference Functions Framework uses this [connected app](https://help.salesforce.com/s/articleView?id=sf.connected_app_overview.htm&type=5) to generate a token included in each function payload. 
The proxy uses the token to authenticate function requests. Function requests must originate from the authenticated Salesforce org. Function-invoking users must also have authorized access to this connected app via a permission set and assignment.

This document refers to this connected app as the **authentication** or **authN** connected app.

Complete the following steps in **Setup** of your Salesforce org:

1. On the **Certificate and Key Management** page, [create a self-signed certificate](https://help.salesforce.com/s/articleView?id=sf.security_keys_creating.htm&type=5) used to generate an access token to validate function callers. After creating it, download the certificate.
    You must create a self-signed certificate via **Certificate and Key Management** as it’s referenced in the Reference Functions Framework API’s `FunctionsMetadataAuthProvider` class.
2. For the proxy to validate function callers, create an internal JWT-based connected app:
    1. On the **App Manager** page, click **New Connected App**.
    2. Fill in the connected app required fields. For example, the name as “Functions Authentication”
    3. Select **Use Digital Signatures** and upload the certificate file (.crt) created in Step 1.
    4. Add the following scopes:
        1. **Manage user data via APIs**: activates session-based permission sets.
        2. **Access custom permissions**: activates session-based permission sets.
        3. **Access the identity URL servic**e: allows the proxy to verify function request callers
        4. **Perform requests at any time**: allows the proxy to create an authorization token for function’s Salesforce org access.
    5. On the **Manage** or **Edit Policies** page, set **Permitted Users** to **Admin-approved users are pre-authorized**.
    6. On the **Manage Consumer Details** page, reveal and copy the **Consumer Key** value, also referred to as Issuer.

The **Certificate** name and **Consumer Key** are stored in each function’s associated `FunctionReference__mdt `custom metadata.

See [Create a Connected App -> Enable OAuth Settings for API Integration](https://help.salesforce.com/s/articleView?id=sf.connected_app_create_api_integration.htm&type=5).

Keep Connected Apps secure by periodically rotating your consumer key. For more information, see [Rotate the Consumer Key and Consumer Secret of a Connected App](https://help.salesforce.com/s/articleView?id=sf.connected_app_rotate_consumer_details.htm&type=5).

## 8. Create a Permission Set for Function Authentication

You need a [permission set](https://help.salesforce.com/s/articleView?id=sf.perm_sets_overview.htm&type=5) to grant function-invoking users access to the authentication connected app created [earlier](https://github.com/heroku/function-migration/blob/main/MIGRATION.md#7-create-an-authentication-connected-app).

This document refers to this permission set as the **authentication** or **authN** permission set.

Complete the following steps in **Setup** of your Salesforce org:

1. On the **Permission Sets** page, click **New** to create a permission set.
2. Provide a name, for example, “Functions Authentication”. Do *not* check **Session Activation Required** for this permission set.
3. Under **Assigned Connected Apps**, assign the [authentication connected app](https://github.com/heroku/function-migration/blob/main/MIGRATION.md#7-create-an-authentication-connected-app) and all [authorization connected apps](https://github.com/heroku/function-migration/blob/main/MIGRATION.md#5-create-an-authorization-connected-app) created earlier.
4. Under **Manage Assignments**, assign function-invoking users to the permission set.

For Apex Batch, Scheduled Flows, and other Automated Process User invocations, ensure the Automated Process user is assigned to the authentication connected app.

## 9. Configure Function Apps

You need the authorization connected app’s consumer key and certificate key file for this step.

See language-specific instructions:
- Java [README](https://github.com/heroku/function-migration/blob/main/functions/javafunction/README.md#user-content-config)
- Node [README](https://github.com/heroku/function-migration/blob/main/functions/typescriptfunction/README.md#user-content-config)

## 10. Deploy Proxy and Function to Heroku
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

## 11. Verify Proxy and Function Started Up

See language-specific instructions:
- Java [README](https://github.com/heroku/function-migration/blob/main/functions/javafunction/README.md#user-content-startup)
- Node [README](https://github.com/heroku/function-migration/blob/main/functions/typescriptfunction/README.md#user-content-startup)

## 12. Create FunctionReference__mdt Custom Metadata Types for Each Function

The `FunctionReference__mdt` [custom metadata types](https://help.salesforce.com/s/articleView?id=sf.custommetadatatypes_overview.htm&language=en_US&type=5) represent the functions in your Salesforce org. The `Function.get('<myproject>.<function>')` API references a `FunctionReference__mdt `custom metadata record. 
The `FunctionReference__mdt` custom metadata type enables each function to have custom platform behavior. Custom behavior can include associating session-based permission sets that are activated on the function’s access token to authorize specific Org access.

`FunctionReference__mdt `custom metadata fields include:

- `ConsumerKey__c`: Consumer key of the [authentication connected app](https://github.com/heroku/function-migration/blob/main/MIGRATION.md#7-create-an-authentication-connected-app) used by the `FunctionsMetadataAuthProvider `Apex class.
- `Certificate__c`: Name of the certificate associated with the [authentication connected app](https://github.com/heroku/function-migration/blob/main/MIGRATION.md#7-create-an-authentication-connected-app) used by the `FunctionsMetadataAuthProvider` Apex class.
- `Endpoint__c`: URL of the function.
- `PermissionSetOrGroup__c`: (Optional) the session-based permission set API name activated on function’s token grant function access. If a permission set isn’t associated, you must assign function-invoking users access to `AsyncFunctionInvocationRequest__c` via another permission set.

For cross-namespace support, that is, invoking a function in another namespace, you must set the `Protected Component `field to `false` on the function’s `FunctionReference_mdt` record. To prevent cross-namespace invocations, set `Protected Component` to `true`.

For each function, create a `FunctionReference__mdt` custom metadata record: 

1. Capture your function’s URL.

```bash
# Once an app is deployed, you can get the URL  via the CLI. If not, you can still set 
# metadata if you know the name of your app, in this example it was `javafunction`.
# Set function URL in FunctionReference Custom Metadata
$ heroku apps:info -s  | grep web_url | cut -d= -f2
https://javafunction.herokuapp.com/
```

2. Create a `FunctionReference__mdt` metadata file.  

In the example, `sffxhello` is the project name in `FunctionReference.sfhxhello_javafunction.md-meta.xml`. Change it to your own project in the `sfdx-project.json#name` value. 
The Reference Functions Framework doesn’t require a project name as a function qualifier. If a Salesforce org’s source and metadata span multiple repositories, use a project name to ensure that `FunctionReference__mdt` records are unique.

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

## 13. Create Remote Site Settings for Each Function

A [remote site setting](https://help.salesforce.com/s/articleView?id=sf.configuring_remoteproxy.htm&type=5) permits Apex callouts to the registered URL. 
For each function, create a remote site setting in **Setup** or with the [Metadata API](https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_remotesitesetting.htm?q=remote%20site), shown in the example.

Additionally, to create an authentication token, create a remote site setting for the Salesforce org’s domain.

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

## 14. Deploy SFDX Source to Your Salesforce Org

Deploy the following to your Salesforce org:

- Reference Functions Framework APIs: Apex Classes, Apex Trigger, Custom Objects
- Integrations: Apex, `FunctionReference__mdt` Custom Metadata, and so on.

Before deploying, ensure that `force-app/main/default/customMetadata/FunctionReference.sfhxhello_javafunction.md-meta.xml` and `force-app/main/default/customMetadata/FunctionReference.sfhxhello_typescriptfunction.md-meta.xml` fields are set to your function endpoint and Salesforce org settings, like the connected app consumer key and certificate.

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

## 15. Invoke the Function

Here’s example Apex code that invokes a function using Reference Function Framework APIs.

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

For convenience, you can invoke `InvokeJavaFunction` and `InvokeTypescriptFunction `via [Visualforce](https://developer.salesforce.com/docs/atlas.en-us.pages.meta/pages/pages_intro.htm) pages. See [pages/ directory](https://github.com/heroku/function-migration/blob/main/force-app/main/default/pages). You can configure Visualforce pages as [List View buttons](https://help.salesforce.com/s/articleView?id=sf.defining_custom_links_fields.htm&type=5).

# Local Development

See language-specific instructions:
- Java [README](https://github.com/heroku/function-migration/blob/main/functions/javafunction/README.md#user-content-dev)
- Node [README](https://github.com/heroku/function-migration/blob/main/functions/typescriptfunction/README.md#user-content-dev)

## Testing Function Invocations

### Writing Tests
The Reference Functions Framework provides testing utilities to mock authentication token generation, `FunctionReference_mdt` lookup, and function callout responses.

```bash
force-app/main/default/classes/functions/tests/
├── FunctionInvocationCalloutMocks.cls
├── FunctionsTestAuthProviderMocks.cls
└── FunctionsTestDataFactory.cls
```

[InvokeJavaFunctionTest.cls](https://github.com/heroku/function-migration/blob/main/force-app/main/default/classes/tests/InvokeJavaFunctionTest.cls) is an example of how to test function invocations. For example, the following snippet demonstrates using `FunctionInvocationCalloutMocks` to mock the function response. It uses `FunctionsTestAuthProviderMocks.FakeAuthProvider` to mock the authentication token generation.

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

Here’s an example of an Apex test run that displays detailed code coverage results in human-readable form.

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

## Selecting and Setting the Dyno Type

Heroku offers a variety of dyno types to support apps of all sizes, from small-scale projects to high-traffic production services. For more information, see [Dyno Types](https://devcenter.heroku.com/articles/dyno-types).

If a function encounters `Memory quota exceeded`, [resize the function’s dyno type](https://devcenter.heroku.com/articles/dyno-types#setting-dyno-types) to a larger dyno size with increased memory and CPU characteristics.

```bash
- 2023-04-06T19:13:35.124858+00:00 heroku[web.1]: Process running mem=591M(115.5%)
- 2023-04-06T19:13:35.126587+00:00 heroku[web.1]: Error R14 (Memory quota exceeded)
```

## Dyno Scaling

You can scale Heroku apps to run on multiple dynos simultaneously, except on Eco or Basic dynos. You can scale your app’s dyno formation up and down manually from the Heroku Dashboard or CLI.

You can also configure Heroku Autoscaling for Performance-tier dynos, and for dynos running in Private Spaces. Threshold autoscaling adds or removes web dynos from your app automatically based on current request latency.

For more information, see [Scaling Your Dyno Formation](https://devcenter.heroku.com/articles/scaling)

Dynos have default scaling characteristics per dyno type. For more information, see [Default Scaling Limits](https://devcenter.heroku.com/articles/dyno-types#default-scaling-limits).

[Heroku Add-ons](https://elements.heroku.com/addons#dynos) provide several add-on options to schedule, scale, and manage your dyno usage to your app's needs.

## Function Health Check API

To check the health of a deployed function, use the `<function-url>/healthcheck` API. The `x-org-id-18` header must match the app’s env/config var `ORG_ID_18` value.

```bash
$ curl -H "x-org-id-18: 00DDH00000000002AQ" https://javafunction.herokuapp.com/healthcheck
"OK"
```
#### Restart

If a function process dies, then `/healthcheck` attempts to restart the function.

Example function logs:
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

Efficiently manage your Salesforce org’s storage by deleting obsolete `AsyncFunctionInvocationRequest__c` records.

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

## Long-Running Processes

Background jobs can dramatically improve the scalability of a web app by enabling it to offload slow or CPU-intensive tasks from its front-end. 
This helps ensure that the front-end can handle incoming web requests promptly, reducing the likelihood of performance issues that occur when requests become backlogged.

For more information, see [Worker Dynos, Background Jobs and Queueing](https://devcenter.heroku.com/articles/background-jobs-queueing).

## Data
Heroku provides three managed data services all available to Salesforce Functions apps:

- Heroku Postgres
- Heroku Data for Redis
- Apache Kafka on Heroku

For more information, see [Databases & Data Management](https://devcenter.heroku.com/categories/data-management).

## Additional Security Features

Heroku Shield is a set of Heroku platform services that offer additional security features needed for building high compliance applications. 
Use Heroku Shield to build HIPAA or PCI-compliant apps for regulated industries, such as healthcare, life sciences, or financial services. 
Heroku Shield simplifies the complexity associated with regulatory compliance, so you can enjoy same great developer experience when building, deploying, and managing your high compliance apps.

For more information, see [Heroku Shield](https://www.heroku.com/shield).