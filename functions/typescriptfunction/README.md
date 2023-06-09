# Node Functions
The following instructions describe how to apply and configure the Reference Functions Framework for `Node` (`Javascript` and `Typescript`) functions.

## Node Proxy Overview
The Node Proxy is a [Fastify](https://www.fastify.io/) based app - deployed alongside `Node` functions - that has the following APIs:
- `/sync` for synchronous function requests, proxies to the function server using [@fastify/http-proxy](https://github.com/fastify/fastify-http-proxy)
- `/async` for asynchronous function requests, uses the `onResponse` hook to return `200` to the client and then handles proxying the request the function
- `/healthcheck` to monitor the function server and restart, if needed.

To learn Fastify, check out the [Fastify documentation](https://www.fastify.io/docs/latest/).

## <a name="artifacts"></a>Example Function Framework Artifacts
Copy the following `proxy/` and `bin/` directories to the root of your `Node` function directories.

`proxy/` contents are proxy source and artifacts.

`bin/` contents are an [Inline buildpack](https://elements.heroku.com/buildpacks/heroku/heroku-buildpack-inline) 
invoked on deployment to build the proxy.

```bash
# Inline buildpack
functions/typescriptfunction/bin/
├── compile  // Compiles Node proxy
├── detect
└── release  // App startup command

# Proxy app
functions/typescriptfunction/proxy/
├── bin
├── config
├── index.js
├── lib
├── node_modules
├── package.json
├── package-lock.json
├── README.md
└── test
```

## <a name="changes"></a>Function Project Changes
If not already present, install `@heroku/sf-fx-runtime-nodejs` as a production dependency.
In each `Node` function's root directory:
```bash
$ npm install @heroku/sf-fx-runtime-nodejs --save-prod 
```
`package.json`:
```json
"dependencies": {
    "@heroku/sf-fx-runtime-nodejs": "^0.14.0"
}
```

## <a name="app"></a>Function App Creation and Build Configuration
For each function, create a Heroku App.  Function source will be deployed to an App.

The following App creation and buildpack configuration requires the [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli).

Buildpacks are responsible for transforming deployed code into a deployment unit.  For more information on buildpacks, see [Buildpacks](https://devcenter.heroku.com/articles/buildpacks).  The proxy and function use the following buildpacks:
- `lstoll/heroku-buildpack-monorepo` - support for multiple apps in a single repo, eg SFDX projects will have SFDX source and may have multiple functions.
- `heroku/nodejs` - the official Heroku buildpack for `Node` apps.
- `heroku/heroku-buildpack-inline` - supports an app that builds itself, in this case, the proxy.

The above buildpacks are required to build the Examples Reference Framework.  Additional buildpacks may be applied to
fulfill your function's requirements such as libraries for PDF generation, custom application metrics, or apt-based
dependencies.  For more information, see officially supported buildpacks and 3rd-party buildpacks: [Heroku Buildpacks](https://elements.heroku.com/buildpacks).

For more information on how buildpacks are part of Heroku application development and deployment, see [How Heroku Works](https://devcenter.heroku.com/articles/how-heroku-works).

```bash
# Create app for function
$ heroku create typescriptfunction

# Apply remote to repo
heroku git:remote -a typescriptfunction

# Apply buildpacks
$ heroku buildpacks:add -a typescriptfunction \
    https://github.com/lstoll/heroku-buildpack-monorepo
$ heroku buildpacks:add -a typescriptfunction heroku/nodejs
$ heroku buildpacks:add -a typescriptfunction heroku-community/inline

# List buildpacks
$ heroku buildpacks -a typescriptfunction
=== typescriptfunction Buildpack URLs

1. https://github.com/lstoll/heroku-buildpack-monorepo
2. heroku/nodejs
3. heroku-community/inline
```

## <a name="config"></a>Function App Configuration
The following config vars are required for each function.

Config var configuration requires the [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli).

Connected App config, `CONSUMER_KEY` and `ENCODED_PRIVATE_KEY`, are values for the authorization Connected App.
You should complete the following steps in [MIGRATION.md](../../MIGRATION.md) before proceeding:
* 5 Create an authorization Connected App used to mint access tokens for function's Organization access
* 6 Create a session-based Permission Set that specifies function's Organization access
* 7 Create an authentication Connected App to validate function request identity
* 8 Create a Permission Set for function authentication

Ensure to target commands to your function via `-a <function app name>`.
```bash
# For repos with multiple functions, the heroku-buildpack-monorepo needs APP_BASE to point to the base dir of the function
$ heroku config:set -a typescriptfunction APP_BASE=functions/typescriptfunction

# In your Org under Company Settings -> Company Information find your Org's OrgId and convert to 18-char
$ heroku config:set -a typescriptfunction ORG_ID_18=00DDH0000005zbM2AQ

# Set the function's authorization Connected App's Consumer Key (from step 5 in MIGRATION.md)
$ heroku config:set -a typescriptfunction CONSUMER_KEY=3MVG9bm...

# Set the function's authorization Connected App's digital certificate/key, base64 encoded
# For macOs, use -b instead of -w to wrap or insert line breaks
$ heroku config:set -a typescriptfunction ENCODED_PRIVATE_KEY=`cat server.key | base64 -w 0`

# List config vars
$ heroku config -a typescriptfunction
=== typescriptfunction Config Vars

APP_BASE:            functions/typescriptfunction
CONSUMER_KEY:        3MVG9bm...
ENCODED_PRIVATE_KEY: LS0tLSx...
ORG_ID_18:           00DB0000000EjT0MAK
```

## <a name="deploy"></a>Function App Deployment
Once development and testing is complete, deploy your function to Heroku.

```bash
$ heroku git:remote -a typescriptfunction
set git remote heroku to https://git.heroku.com/typescriptfunction.git

$ git push heroku main
Enumerating objects: 466, done.
Counting objects: 100% (466/466), done.
Delta compression using up to 36 threads
Compressing objects: 100% (361/361), done.
Writing objects: 100% (442/442), 318.44 KiB | 5.22 MiB/s, done.
Total 442 (delta 194), reused 16 (delta 5)
remote: Resolving deltas: 100% (194/194), completed with 15 local objects.
remote: Updated 194 paths from ca2964f
remote: Compressing source files... done.
remote: Building source:
remote: 
...
<log output deleted>
...
remote: 
remote: -----> Compressing...
remote:        Done: 125M
remote: -----> Launching...
remote:        Released v21
remote:        https://typescriptfunction.herokuapp.com/ deployed to Heroku
remote: 
remote: Verifying deploy... done.
To https://git.heroku.com/typescriptfunction.git
   079575a..a13f0b2  main -> main
```

## <a name="startup"></a>Function App Startup
```bash
$ $ heroku logs -a typescriptfunction -t
...
2023-04-06T21:20:55.141367+00:00 heroku[web.1]: Starting process with command `cd proxy && npm start`
2023-04-06T21:20:57.143644+00:00 app[web.1]: 
2023-04-06T21:20:57.143662+00:00 app[web.1]: > proxy@0.0.1 start
2023-04-06T21:20:57.143663+00:00 app[web.1]: > node index.js
2023-04-06T21:20:57.143663+00:00 app[web.1]: 
2023-04-06T21:20:57.540789+00:00 app[web.1]: {"level":30,"time":1680816057540,"pid":20,"hostname":"c3a624ba-d308-4253-ae50-634ff7c76442","msg":"Starting function w/ args: /app/proxy/../node_modules/@heroku/sf-fx-runtime-nodejs/bin/cli.js serve /app/proxy/.. -p 8080"}
2023-04-06T21:20:57.564002+00:00 app[web.1]: {"level":30,"time":1680816057545,"pid":20,"hostname":"c3a624ba-d308-4253-ae50-634ff7c76442","msg":"Started function started on port 8080, process pid 31"}
2023-04-06T21:20:57.564004+00:00 app[web.1]: {"level":30,"time":1680816057563,"pid":20,"hostname":"c3a624ba-d308-4253-ae50-634ff7c76442","msg":"Server listening at http://0.0.0.0:32780"}
2023-04-06T21:20:57.917174+00:00 heroku[web.1]: State changed from starting to up
2023-04-06T21:20:59.251062+00:00 app[web.1]: {"level":30,"time":1680816059250,"pid":20,"hostname":"c3a624ba-d308-4253-ae50-634ff7c76442","msg":"[fn] name=functionLogger hostname=c3a624ba-d308-4253-ae50-634ff7c76442 pid=42 worker=1 level=30 msg=\"started function worker 1\" time=2023-04-06T21:20:59.250Z v=0\n"}
```

## <a name="invoke"></a>Function Invocation
### Sync
```bash
2023-04-10T15:02:31.956768+00:00 app[web.1]: {"level":30,"time":1681138951956,"pid":20,"hostname":"7c0e8423-9bd4-4091-8fe0-fc411c137df5","reqId":"00DB0000000gJmXMAU-4pHPy-10T0VBNUIdp8TgJ--4HrUCSDR72O1CitPdjgC2ES3czY=-sffxtest1.sfhxhello_typescriptfunction-2023-04-10T08:02:31.591-0700","req":{"method":"POST","url":"/sync","hostname":"typescriptfunction.herokuapp.com","remoteAddress":"10.1.90.50","remotePort":25862},"msg":"incoming request"}
2023-04-10T15:02:32.336330+00:00 app[web.1]: {"level":30,"time":1681138952336,"pid":20,"hostname":"7c0e8423-9bd4-4091-8fe0-fc411c137df5","reqId":"00DB0000000gJmXMAU-4pHPy-10T0VBNUIdp8TgJ--4HrUCSDR72O1CitPdjgC2ES3czY=-sffxtest1.sfhxhello_typescriptfunction-2023-04-10T08:02:31.591-0700","msg":"[cdf3e6a5-93ad-4f8c-ba87-9d7e9eed5ce3] Handling com.salesforce.function.invoke.sync request to function 'sfhxhello_typescriptfunction'..."}
2023-04-10T15:02:32.340266+00:00 app[web.1]: {"level":30,"time":1681138952338,"pid":20,"hostname":"7c0e8423-9bd4-4091-8fe0-fc411c137df5","reqId":"00DB0000000gJmXMAU-4pHPy-10T0VBNUIdp8TgJ--4HrUCSDR72O1CitPdjgC2ES3czY=-sffxtest1.sfhxhello_typescriptfunction-2023-04-10T08:02:31.591-0700","msg":"[cdf3e6a5-93ad-4f8c-ba87-9d7e9eed5ce3] Minting function  token for user admin@functions.org, audience https://login.salesforce.com, url https://mycompany.my.salesforce.com/services/oauth2/token, issuer 3MVG9..."}
...
<log output deleted>
...
2023-04-10T15:02:33.185142+00:00 app[web.1]: {"level":30,"time":1681138953184,"pid":20,"hostname":"7c0e8423-9bd4-4091-8fe0-fc411c137df5","reqId":"00DB0000000gJmXMAU-4pHPy-10T0VBNUIdp8TgJ--4HrUCSDR72O1CitPdjgC2ES3czY=-sffxtest1.sfhxhello_typescriptfunction-2023-04-10T08:02:31.591-0700","res":{"statusCode":200},"responseTime":1228.1788830161095,"msg":"request completed"}
2023-04-10T15:02:33.185682+00:00 heroku[router]: at=info method=POST path="/sync" host=typescriptfunction.herokuapp.com request_id=cdf3e6a5-93ad-4f8c-ba87-9d7e9eed5ce3 fwd="136.147.46.8" dyno=web.1 connect=0ms service=1229ms status=200 bytes=2113 protocol=https
```
### Async
```bash
2023-04-10T23:07:12.334645+00:00 app[web.1]: {"level":30,"time":1681168032334,"pid":20,"hostname":"97e7e956-a995-4dcc-9619-0635dd01c996","reqId":"00DB0000000gJmXMAU-4pHpPcjoiD_NZpmt-SUG---a00B000000OtzVjIAJ-sffxtest1.sfhxhello_typescriptfunction-2023-04-10T16:07:11.768-0700","req":{"method":"POST","url":"/async","hostname":"typescriptfunction.herokuapp.com","remoteAddress":"10.1.93.65","remotePort":12329},"msg":"incoming request"}
2023-04-10T23:07:12.345209+00:00 app[web.1]: {"level":30,"time":1681168032336,"pid":20,"hostname":"97e7e956-a995-4dcc-9619-0635dd01c996","reqId":"00DB0000000gJmXMAU-4pHpPcjoiD_NZpmt-SUG---a00B000000OtzVjIAJ-sffxtest1.sfhxhello_typescriptfunction-2023-04-10T16:07:11.768-0700","msg":"[c836fe3f-2a99-4fe4-8ef3-0665132bcc3e] Validated context headers - well done"}
...
<log output deleted>
...
2023-04-10T23:07:14.460591+00:00 app[web.1]: {"level":30,"time":1681168034460,"pid":20,"hostname":"97e7e956-a995-4dcc-9619-0635dd01c996","reqId":"00DB0000000gJmXMAU-4pHpPcjoiD_NZpmt-SUG---a00B000000OtzVjIAJ-sffxtest1.sfhxhello_typescriptfunction-2023-04-10T16:07:11.768-0700","msg":"[c836fe3f-2a99-4fe4-8ef3-0665132bcc3e] Updated function response [200] to sffxtest1__AsyncFunctionInvocationRequest__c [a00B000000OtzVjIAJ]"}
2023-04-10T23:07:14.460934+00:00 app[web.1]: {"level":30,"time":1681168034460,"pid":20,"hostname":"97e7e956-a995-4dcc-9619-0635dd01c996","reqId":"00DB0000000gJmXMAU-4pHpPcjoiD_NZpmt-SUG---a00B000000OtzVjIAJ-sffxtest1.sfhxhello_typescriptfunction-2023-04-10T16:07:11.768-0700","res":{"statusCode":201},"responseTime":1058.924006998539,"msg":"request completed"}
```

Asynchronous function invocations are tracked and responses handled via the `AsyncFunctionInvocationRequest__c` Custom Object.
```bash
sfdx data query --query "SELECT Id, Response__c, Status__c, StatusCode__c, ExtraInfo__c, LastModifiedDate FROM AsyncFunctionInvocationRequest__c ORDER BY LastModifiedDate DESC LIMIT 1" --json 
{
  "status": 0,
  "result": {
    "records": [
      {
        "attributes": {
          "type": "AsyncFunctionInvocationRequest__c",
          "url": "/services/data/v58.0/sobjects/AsyncFunctionInvocationRequest__c/a00B000000OuIquIAF"
        },
        "Id": "a00B000000OuIquIAF",
        "Response__c": "{\"accounts\":[{\"id\":\"001B000001PH6aOIAT\",\"name\":\"Sample Account for Entitlements\"},{\"id\":\"001B000001PH6ZwIAL\",\"name\":\"GenePoint\"},{\"id\":\"001B000001PH6ZxIAL\",\"name\":\"United Oil \\u0026 Gas, UK\"},{\"id\":\"001B000001PH6ZyIAL\",\"name\":\"United Oil \\u0026 Gas, Singapore\"},{\"id\":\"001B000001PH6ZzIAL\",\"name\":\"Edge Communications\"},{\"id\":\"001B000001PH6a0IAD\",\"name\":\"Burlington Textiles Corp of America\"},{\"id\":\"001B000001PH6a1IAD\",\"name\":\"Pyramid Construction Inc.\"},{\"id\":\"001B000001PH6a2IAD\",\"name\":\"Dickenson plc\"},{\"id\":\"001B000001PH6a3IAD\",\"name\":\"Grand Hotels \\u0026 Resorts Ltd\"},{\"id\":\"001B000001PH6a4IAD\",\"name\":\"Express Logistics and Transport\"},{\"id\":\"001B000001PH6a5IAD\",\"name\":\"University of Arizona\"},{\"id\":\"001B000001PH6a6IAD\",\"name\":\"United Oil \\u0026 Gas Corp.\"}]}",
        "Status__c": "SUCCESS",
        "StatusCode__c": 200,
        "ExtraInfo__c": "%7B%22requestId%22%3A%2200DB0000000gJmXMAU-4pa5Qlzen5qguUIdp8TgJ--a00B000000OuIquIAF-sffxtest1.sfhxhello_typescriptfunction-2023-04-26T08%3A42%3A28.344-0700%22%2C%22source%22%3A%22urn%3Aevent%3Afrom%3Asalesforce%2FGS0%2F00DB0000000gJmXMAU%2Fapex%22%2C%22execTimeMs%22%3A246%2C%22statusCode%22%3A200%2C%22isFunctionError%22%3Afalse%2C%22stack%22%3A%5B%5D%7D",
        "LastModifiedDate": "2023-04-26T15:42:33.000+0000"
      }
    ],
    "totalSize": 1,
    "done": true
  },
  "warnings": []
}
```

## <a name="dev"></a>Local Development
### Start Proxy and Function
Starting the proxy will also start the function.

Ensure that the target function (eg, `typescriptfunction`) is locally installed and built (`npm install && npm run build`).

Ensure that the proxy (`typescriptfunction/proxy`) is locally installed and built (`npm install && npm run build`).

The following environment variables must be set:
- `CONSUMER_KEY` - Consumer Key of the function's authorization Connected App.
- `ENCODED_PRIVATE_KEY` - `base64` encoded private key of the function's authorization Connected App.
- `HOME` - full path to function directory.
- `ORG_ID_18` - ID of the function owning Organization.

#### Command-line
```bash
$ pwd
/home/functions/git/function-migration/functions/typescriptfunction/proxy

$ npm start
...
```

In addition, the following `npm` scripts are available:
- `npm run dev`: to start the proxy app in debug mode.
- `npm run test`: run tests.

#### IDE
Run `proxy/index.js` or `npm start` via IDE configuration.

### Invocation Bash Scripts
The following scripts invoke local functions sync and asynchronously.
```bash
/home/functions/git/function-migration/functions/typescriptfunction/proxy/bin
├── invokeAsync.sh
├── invokeSync.sh
├── queryAsync.sh
├── sfContext.json
├── sfContextStdUser.json
├── sfFnAsyncContext.json
└── sfFnSyncContext.json
```
Edit the `.json` files that reflect your Organization and function payload.

Supply an access token provided by `sfdx force org display`.
```bash
$ sfdx org display
=== Org Description

 KEY              VALUE                                                                                                            
 ──────────────── ──────────────────────────────────────────────────────────────────────────────────────────────────────────────── 
 Access Token     00DB0000000gJmX!AQEA... 
...

# Sync invoke function
$ ./invokeSync.sh '00DB0000000gJmX!AQEA...'
...

# Async invoke function
$ ./invokeAsync.sh '00DB0000000gJmX!AQEA...'
...
```

For async requests, use `./queryAsync.sh` to query for last `AsyncFunctionInvocationRequest__c` record.  Ensure that the
querying user has `Read` access to `AsyncFunctionInvocationRequest__c` and fields.

If your Organization is namespaced, edit `./queryAsync.sh` prepending namespace to `AsyncFunctionInvocationRequest__c` and each field.  

```bash
$ ./queryAsync.sh
{
  "status": 0,
  "result": {
    "records": [
      {
        "attributes": {
          "type": "AsyncFunctionInvocationRequest__c",
          "url": "/services/data/v57.0/sobjects/AsyncFunctionInvocationRequest__c/a00xx000000bz3tAAA"
        },
        "Id": "a00xx000000bz3tAAA",
        "Response__c": "[{\"type\":\"Account\",\"fields\":{...}]",
        "Status__c": "SUCCESS",
        "StatusCode__c": 200,
        "ExtraInfo__c": "%7B%22requestId%22%3A%2200DB0000000gJmXMAU-4pU5ZP6e4Yo6spmt-SLE3--a00B000000OuAvYIAV-sffxtest1.sfhxhello_javafunction-2023-04-20T15%3A55%3A15.519-0700%22%2C%22source%22%3A%22urn%3Aevent%3Afrom%3Asalesforce%2FGS0%2F00DB0000000gJmXMAU%2Fapex%22%2C%22execTimeMs%22%3A763%2C%22statusCode%22%3A200%2C%22isFunctionError%22%3Afalse%2C%22stack%22%3A%5B%5D%7D",
        "Callback__c": "{\"functionName\":\"TypescriptFunction\"}",
        "CallbackType__c": "InvokeTypescriptFunction.Callback",
        "LastModifiedDate": "2023-04-10T22:48:12.000+0000"
      }
    ],
    "totalSize": 1,
    "done": true
  }
}
```

`AsyncFunctionInvocationRequest__c.ExtraInfo__c` is URL encode.  To decode and view using the `jq` utility:
```bash
$ (IFS="+"; read _z; echo -e ${_z//%/\\x}"") <<< `queryAsync.sh | jq -r '.result.records[0].sffxtest1__ExtraInfo__c'` | jq
{
  "requestId": "00DB0000000gJmXMAU-4pU5ZP6e4Yo6spmt-SLE3--a00B000000OuAvYIAV-sfhxhello_typescriptfunction-2023-04-20T15:55:15.519-0700",
  "source": "urn:event:from:salesforce/GS0/00DB0000000gJmXMAU/apex",
  "execTimeMs": 763,
  "statusCode": 200,
  "isFunctionError": false,
  "stack": []
}
```
