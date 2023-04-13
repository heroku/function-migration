# Migration to Reference Function Framework
## 1. Copy Reference Function Framework artifacts.
### 1. Salesforce Platform metadata and source to your SFDX project. Metadata and source includes:
- Apex Class in `force-app/main/default/classes/functions/`
- Apex Trigger in `force-app/main/default/triggers/functions/`
- Custom Objects in `force-app/main/default/objects/`

This repo also includes an example implementation of the Reference Function Framework.  Example metadata and source includes:
- Apex Class in `force-app/main/default/classes/`
- Custom Metadata in `force-app/main/default/classes/customMetadata/`
- Visualforce Pages in `force-app/main/default/pages/`
- Permission Sets in `force-app/main/default/permissionsets/`
- Remote Site Settings in `force-app/main/default/remoteSiteSettings/`

### 2. Copy language-specific Reference Functions Framework artifacts to your function.
See language-specific instructions:
- [Java](functions/javafunction/README.md#artifacts)
- [Node](functions/typescriptfunction/README.md#artifacts)

## 2. Apply project changes.
See language-specific instructions:
- [Java](functions/javafunction/README.md#changes)
- [Node](functions/typescriptfunction/README.md#changes)

## 3. Update Apex that invokes functions
- Update `functions.Function` Function API references removing `functions.` namespace from Function API calls.  See example below.
- For each `Function.get('<myproject>.<function>')`, replace the `.` delimiter with `_`.  See example below.

For example:
```java
public void invoke() {
    Function javaFunction = Function.get('sfhxhello_javafunction');

    // Sync
    FunctionInvocation invocation = javaFunction.invoke(JSON.serialize(params));

    // Async
    invocation = javaFunction.invoke(JSON.serialize(params), new MyCallback());
}

public class MyCallback implements FunctionCallback {    
    public void handleResponse(FunctionInvocation invocation) {
        System.debug(invocation.getStatus().name() + ': ' + invocation.getResponse());
    }
}
```

## 4. Create and configure a Heroku App for function
See language-specific instructions:
- [Java](functions/javafunction/README.md#app)
- [Node](functions/typescriptfunction/README.md#app)


## 5. Create a Connected App used to mint access tokens for function's Organization access
This Connected App is used by the proxy to mint access tokens for associated function(s). The token is used by a function
for Organization access.

This Connected App and session-based Permission Set (create in the next step) determine what a function is authorized to do.

You may create a Connected App for each function or use a single Connected App for all functions.

This document will refer to this Connected App as the authorization or authZ Connected App.

The following setups are done in your Organization's Setup.

1. Create a Self-Signed Certificate used to generate an access token for a function.  
   For more info, see [Generate a Self-Signed Certificate](https://help.salesforce.com/s/articleView?id=sf.security_keys_creating.htm&type=5) and [Create a Private Key and Self-Signed Digital Certificate](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_auth_key_and_cert.htm).
2. Create an internal JWT-based Connected App used by the proxy to validate function callers.
    1. On the **App Manager** page, click on **New Connected App**.
    2. Fill in Connected App required fields, eg name as the name of the function (eg, for accompanying example function, "Java Function") for single-function use or "Functions Authentication" when used for all or multiple functions.
    2. Select **Use Digital Signatures** and upload the certificate file (.crt) created in step 1.
    3. The Connected App should have the following scopes:
        - **Manage user data via APIs** - used to proxy to access Salesforce APIs
        - **Perform requests at any time** - used by the proxy to mint an authorization token for function's Organization access
    4. On the **Manage** or **Edit Policies** page, set **Permitted Users** to **Admin-approved users are pre-authorized**.
    5. On the **Manage Consumer Details** page, reveal and then copy **Consumer Key** value (also referred to as Issuer).


## 6. Create a session-based Permission Set that specifies function's Organization access
Once a function token is minted, the proxy will activate given session-based Permission Sets authorizing specific capabilities, eg Standard and Custom Object access.

A session-based Permission Set may be created for each function or a single session-based Permission Set for all functions.  Permission Set Groups references session-based multiple session-based Permission Sets are also supported.

Session-based Permission Set or Permission Set Group are associated to functions via `FunctionReference` Custom Metadata.  More below.

For more information on session-based Permission Sets, see [Session-based Permission Sets](https://help.salesforce.com/s/articleView?id=sf.perm_sets_session_map.htm&type=5).

This document will refer to this Permission Set as the **authorization** or **authZ** Permission Set.

The following setups are done in your Organization's Setup.

A prerequisite is to deploy the `AsyncFunctionInvocationRequest__c` Custom Object that we'll grant **Edit** access in the following Permission Set.
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

1. On the **Permission Sets** pages, select **New** to create a new Permission Set.  For function-specific Permission Set, name the Permission Set to associate to its function, eg "Java Function".
2. Provide a name and enable **Session Activation Required**.
3. Under **Assigned Connected Apps**, assign the authorization Connected App created above.
4. Under **Object Settings**, assign **Edit** access to `Async Function Invocation Requests` - required for asynchronous function invocation responses.
    1. Ensure **Edit** access to fields: `ExtraInfo__c`, `Response__c`, `Status__c`, and `StatusCode__c`.
5. Enable other App and System settings need by the function.  The example functions require **Read** access to the **Account** object.
6. Under **Manage Assignments**, assign function invoking users to the Permission Set.

For Apex Batch and other Automated Process User invocations, ensure the "autoproc" user is assigned to the authentication Connected App.

To set and view field-level security via Permission Sets, see [Set Field-Level Security for a Field on Permission Sets Instead of Profiles During Field Creation (Beta)](https://help.salesforce.com/s/articleView?id=release-notes.rn_forcecom_fls_permsets.htm&release=240&type=5).

## 7. Create a JWT-based Connected App for function authentication
This Connected App is used by example function APIs to generate a token that is included in each function payload.
The proxy uses the token to authenticate function requests. Function requests must originate from the "owning" Organization
and function invoking users must have authorized access to this Connected App via a Permission Set and assignment.

For more information on Connected Apps, see [Connected Apps](https://help.salesforce.com/s/articleView?id=sf.connected_app_overview.htm&type=5).

This document will refer to this Connected App as the **authentication** or **authN** Connected App.

The following setups are done in your Organization's Setup.

1. On the **Certificate and Key Management** page, create a Self-Signed Certificate used to generate an access token to validate function callers.  
   A Self-Signed Certificate must be created via **Certificate and Key Management** as it's referenced in the example API's `FunctionsMetadataAuthProvider` class.
   <br>For more information, see [Generate a Self-Signed Certificate](https://help.salesforce.com/s/articleView?id=sf.security_keys_creating.htm&type=5).
2. Download the certificate to be used in setup 3.
3. Create an internal JWT-based Connected App used by the proxy to validate function callers.
    1. On the **App Manager** page, click on **New Connected App**.
    2. Fill in Connected App required fields, for example name *Functions Authentication*.
    2. Select **Use Digital Signatures** and upload the certificate file (.crt) created in step 1.
    3. The Connected App should have the following scopes:
        - **Manage user data via APIs** - used to activate session-based Permission Sets
        - **Access custom permissions** - used to activate session-based Permission Sets
        - **Access the identity URL service** - used by the proxy to verify function request callers
        - **Perform requests at any time** - used to mint an authentication token used by the proxy to verify function request callers
    4. On the **Manage** or **Edit Policies** page, set **Permitted Users** to **Admin-approved users are pre-authorized**.
    5. On the **Manage Consumer Details** page, reveal and then copy **Consumer Key** value (also referred to as Issuer).

The **Certificate** and **Consumer Key** will be stored in each function's associated `FunctionReference` Custom Metadata.  More below.

See [Create a Connected App -> Enable OAuth Settings for API Integration](https://help.salesforce.com/s/articleView?id=sf.connected_app_create_api_integration.htm&type=5).


## 8. Create a Permission Set for function authentication
A Permission Set is needed to grant function invoking users access to the authentication Connected App created above.

For more information on Permission Sets, see [Permission Sets](https://help.salesforce.com/s/articleView?id=sf.perm_sets_overview.htm&type=5).

This document will refer to this Permission Set as the authentication or authN Permission Set.

The following setups are done in your Organization's Setup.

1. On the **Permission Sets** pages, select **New** to create a new Permission Set.  Name may be *Functions Authentication*.
2. Under **Assigned Connected Apps**, assign the authentication Connected App created above and all authorization Connected Apps (eg, *Functions Authentication* created above)
3. Under **Manage Assignments**, assign function invoking users to the Permission Set.

For Apex Batch and other Automated Process User invocations, ensure the "autoproc" user is assigned to the authentication Connected App.

## 9. Set function config vars
See language-specific instructions:
- [Java](functions/javafunction/README.md#config)
- [Node](functions/typescriptfunction/README.md#config)

## 10. Deploy proxy and function to Heroku
See language-specific instructions:
- [Java](functions/javafunction/README.md#deploy)
- [Node](functions/typescriptfunction/README.md#deploy)

When switching between functions, update the `remote` to the target function:
```bash
$ heroku git:remote -a javafunction
set git remote heroku to https://git.heroku.com/javafunction.git

$ git push heroku main
...
```

## 11. Verify that proxy and function started up
See language-specific instructions:
- [Java](functions/javafunction/README.md#startup)
- [Node](functions/typescriptfunction/README.md#startup)

## 12. Create FunctionReference Custom Metadata for each function
Functions are represented in your Org as `FunctionReference` Custom Metadata.  `Function.get('<myproject>.<function>')` API reference
a `FunctionReference` Custom Metadata record.  `FunctionReference` Custom Metadata enable each function to have custom Platform behavior
such as associating session-based Permission Sets that are activated on the function's access token to authorize specific Org access.

`FunctionReference` Custom Metadata fields:
- `Endpoint__c` - URL of function.
- `PermissionSetOrGroup__c` - the API name of session-based Permission Set name (eg, "Java Function") activated on function's token grant function access.
- `ConsumerKey__c` - Consumer Key of the authentication Connected App (eg, "Function Authentication") used by `FunctionsMetadataAuthProvider` Apex class to authenticate function invokers.
- `Certificate__c` - Certificate associated with the authentication Connected App (eg, "Function Authentication") used by `FunctionsMetadataAuthProvider` Apex class to authenticate function invokers.

For each function, create a `FunctionReference` Custom Metadata record:
```bash
# Set function URL in FunctionReference Custom Metadata
$ heroku apps:info -s  | grep web_url | cut -d= -f2
https://javafunction.herokuapp.com/
```

For example:
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
# Used to generate an authorization token in Apex.  The token is sent with the function payload and used by the
# proxy to authorize the request.
$ cat force-app/main/default/remoteSiteSettings/ThisOrg.remoteSite-meta.xml 
<?xml version="1.0" encoding="UTF-8"?>
<RemoteSiteSetting xmlns="http://soap.sforce.com/2006/04/metadata">
    <disableProtocolSecurity>false</disableProtocolSecurity>
    <isActive>true</isActive>
    <url>https://mycompany.my.salesforce.com</url>
</RemoteSiteSetting>

# Used to generate an authentication token by the proxy and passsed to the function for Organization access.
$ cat force-app/main/default/remoteSiteSettings/JavaFunction.remoteSite-meta.xml 
<?xml version="1.0" encoding="UTF-8"?>
<RemoteSiteSetting xmlns="http://soap.sforce.com/2006/04/metadata">
    <disableProtocolSecurity>false</disableProtocolSecurity>
    <isActive>true</isActive>
    <url>https://javafunction.herokuapp.com</url>
</RemoteSiteSetting>
```

## 15. Deploy SFDX source to Org
Deploy Function APIs - Apex Classes, Trigger, Custom Objects - and your integrations - Apex, `FunctionReference` Custom Metadata, etc - to your Organization.

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
Example Apex code that invokes a function using the example function APIs:
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

See language-specific instructions:
- [Java](functions/javafunction/README.md#invoke)
- [Node](functions/typescriptfunction/README.md#invoke)

# Reference Functions Framework Examples
See [InvokeJavaFunction](force-app/main/default/classes/InvokeJavaFunction.cls) and [InvokeTypescriptFunction](force-app/main/default/classes/InvokeTypescriptFunction.cls).

See `InvokeJavaFunction` and `InvokeTypescriptFunction` may be invoked via Visualforce pages, see [pages/ directory](force-app/main/default/pages).

# Local Development
See language-specific instructions:
- [Java](functions/javafunction/README.md#dev)
- [Node](functions/typescriptfunction/README.md#dev)

# Appendix
## Selecting and Setting Dyno Type
<mark style="background-color: #FFFF00;font-weight:bold">TODO</mark>

If a function is encountering `Memory quota exceeded`, configure the function's Dyno type selecting a Dyno having increased memory and CPU characteristics.
```bash
- 2023-04-06T19:13:35.124858+00:00 heroku[web.1]: Process running mem=591M(115.5%)
- 2023-04-06T19:13:35.126587+00:00 heroku[web.1]: Error R14 (Memory quota exceeded)
```

For more information, see [Dyno Types](https://devcenter.heroku.com/articles/dyno-types).

## Dyno Scaling
<mark style="background-color: #FFFF00;font-weight:bold">TODO</mark>

For more information, see [Scaling Your Dyno Formation](https://devcenter.heroku.com/articles/scaling)

## Function Health Check API
To check the health of a deployed function, invoke `curl -H "x-org-id-18: 00DDH0000005zbM2AQ' <function-url>/healthcheck`.  `x-org-id-18` header must match env/config var `ORG_ID_18` value.
```bash
$ curl https://javafunction.herokuapp.com/healthcheck
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
14:03:18.142 INFO  [RUNTIME] c.s.f.p.service.StartFunctionService - Starting function w/ args: /home/cwall/blt/tools/Linux/jdk/openjdk_11.0.18_11.62.18_x64/bin/java -jar /home/cwall/git/function-migration/functions/javafunction/proxy/target/sf-fx-runtime-java-runtime-1.1.3-jar-with-dependencies.jar serve /home/cwall/git/function-migration/functions/javafunction -h 0.0.0.0 -p 8080
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
Manage Org storage by deleting obsolete `AsyncFunctionInvocationRequest__c` records.

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
<mark style="background-color: #FFFF00;font-weight:bold">TODO: Something about workers</mark>