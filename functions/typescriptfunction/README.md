# Node Functions

## [Node Proxy Overview](#overview)
The Node Proxy is a [Fastify](https://www.fastify.io/) based app that has the following APIs:
- `/sync` for synchronous function requests, proxies to the function server using [@fastify/http-proxy](https://github.com/fastify/fastify-http-proxy)
- `/async` for asynchronous function requests, uses the `onResponse` hook to return `200` to the client and then handles proxying the request the function
- `/healthcheck` to monitor the function server and restart, if needed.

To learn Fastify, check out the [Fastify documentation](https://www.fastify.io/docs/latest/).

## [Example Function Framework Artifacts](#artifacts)
Copy the following `bin/` and `proxy/` directories to the root of your function directories.

```bash
# Inline buildpack
functions/typescriptfunction/bin/
├── compile
├── detect
└── release

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

## [Function Project Changes](#changes)
If not already present, install `@heroku/sf-fx-runtime-nodejs` as a production dependency.
```json
"dependencies": {
    "@heroku/sf-fx-runtime-nodejs": "^0.14.0"
  },
```


## [Function App Creation and Setup](#app)
For each function, create a Heroku App.  Function source will be deployed to an App.

Buildpacks are responsible for transforming deployed code into a deployment unit.  For more information on Buildpacks, see [Buildpacks](https://devcenter.heroku.com/articles/buildpacks).  The proxy and function use the following buildpacks:
- `lstoll/heroku-buildpack-monorepo` - support for multiple apps in a single repo, eg SFDX projects will have SFDX source and multiple functions.
- `heroku/nodejs` - the official Heroku buildpack for `node` apps.
- `heroku/heroku-buildpack-inline` - supports an app that builds itself, in this case, the proxy.

For more information, see [How Heroku Works](https://devcenter.heroku.com/articles/how-heroku-works).

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

## [Function App Configuration](#config)
The following config vars are required for each function.

Connected App config, `CONSUMER_KEY` and `ENCODED_PRIVATE_KEY`, are values for the authorization Connected App - the Connected App used to validate and authorize function requests.

Ensure to target commands to your function via `-a <function app name>`.
```bash
# For repos with multiple functions, the heroku-buildpack-monorepo needs APP_BASE to point to the base dir of the function
$ heroku config:set -a typescriptfunction APP_BASE=functions/typescriptfunction

# In your Org under Company Settings -> Company Information find your Org's OrgId and convert to 18-char
$ heroku config:set -a typescriptfunction ORG_ID_18=00DDH0000005zbM2AQ

# Set the function's authorization Connected App's Consumer Key
$ heroku config:set -a typescriptfunction CONSUMER_KEY=3MVG9bm...

# Set the function's authorization Connected App's digital certificate/key, base64 encoded
$ heroku config:set -a typescriptfunction ENCODED_PRIVATE_KEY=`cat ~/sfdc/jwt/server.key | base64 -w 0`

# List config vars
$ heroku config -a typescriptfunction
=== typescriptfunction Config Vars

APP_BASE:            functions/typescriptfunction
CONSUMER_KEY:        3MVG9bm...
ENCODED_PRIVATE_KEY: LS0tLSx...
ORG_ID_18:           00DB0000000EjT0MAK
```

## [Function App Deployment](#deploy)
Once development and testing is complete, deploy your function to Heroku.

```bash
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
<log output deleted.>
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

## [Function App Startup](#startup)
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

## [Function Invocation](#invoke)
### Sync
```bash
2023-04-10T15:02:31.956768+00:00 app[web.1]: {"level":30,"time":1681138951956,"pid":20,"hostname":"7c0e8423-9bd4-4091-8fe0-fc411c137df5","reqId":"00DB0000000gJmXMAU-4pHPy-10T0VBNUIdp8TgJ--4HrUCSDR72O1CitPdjgC2ES3czY=-sffxtest1.sfhxhello_typescriptfunction-2023-04-10T08:02:31.591-0700","req":{"method":"POST","url":"/sync","hostname":"typescriptfunction.herokuapp.com","remoteAddress":"10.1.90.50","remotePort":25862},"msg":"incoming request"}
2023-04-10T15:02:32.336330+00:00 app[web.1]: {"level":30,"time":1681138952336,"pid":20,"hostname":"7c0e8423-9bd4-4091-8fe0-fc411c137df5","reqId":"00DB0000000gJmXMAU-4pHPy-10T0VBNUIdp8TgJ--4HrUCSDR72O1CitPdjgC2ES3czY=-sffxtest1.sfhxhello_typescriptfunction-2023-04-10T08:02:31.591-0700","msg":"[cdf3e6a5-93ad-4f8c-ba87-9d7e9eed5ce3] Handling com.salesforce.function.invoke.sync request to function 'sfhxhello_typescriptfunction'..."}
2023-04-10T15:02:32.340266+00:00 app[web.1]: {"level":30,"time":1681138952338,"pid":20,"hostname":"7c0e8423-9bd4-4091-8fe0-fc411c137df5","reqId":"00DB0000000gJmXMAU-4pHPy-10T0VBNUIdp8TgJ--4HrUCSDR72O1CitPdjgC2ES3czY=-sffxtest1.sfhxhello_typescriptfunction-2023-04-10T08:02:31.591-0700","msg":"[cdf3e6a5-93ad-4f8c-ba87-9d7e9eed5ce3] Minting function  token for user admin@functions.org, audience https://login.salesforce.com, url https://mycompany.my.salesforce.com/services/oauth2/token, issuer 3MVG9..."}
...
<log output deleted.>
...
2023-04-10T15:02:33.185142+00:00 app[web.1]: {"level":30,"time":1681138953184,"pid":20,"hostname":"7c0e8423-9bd4-4091-8fe0-fc411c137df5","reqId":"00DB0000000gJmXMAU-4pHPy-10T0VBNUIdp8TgJ--4HrUCSDR72O1CitPdjgC2ES3czY=-sffxtest1.sfhxhello_typescriptfunction-2023-04-10T08:02:31.591-0700","res":{"statusCode":200},"responseTime":1228.1788830161095,"msg":"request completed"}
2023-04-10T15:02:33.185682+00:00 heroku[router]: at=info method=POST path="/sync" host=typescriptfunction.herokuapp.com request_id=cdf3e6a5-93ad-4f8c-ba87-9d7e9eed5ce3 fwd="136.147.46.8" dyno=web.1 connect=0ms service=1229ms status=200 bytes=2113 protocol=https
```
### Async
```bash
2023-04-10T23:07:12.334645+00:00 app[web.1]: {"level":30,"time":1681168032334,"pid":20,"hostname":"97e7e956-a995-4dcc-9619-0635dd01c996","reqId":"00DB0000000gJmXMAU-4pHpPcjoiD_NZpmt-SUG---a00B000000OtzVjIAJ-sffxtest1.sfhxhello_typescriptfunction-2023-04-10T16:07:11.768-0700","req":{"method":"POST","url":"/async","hostname":"typescriptfunction.herokuapp.com","remoteAddress":"10.1.93.65","remotePort":12329},"msg":"incoming request"}
2023-04-10T23:07:12.345209+00:00 app[web.1]: {"level":30,"time":1681168032336,"pid":20,"hostname":"97e7e956-a995-4dcc-9619-0635dd01c996","reqId":"00DB0000000gJmXMAU-4pHpPcjoiD_NZpmt-SUG---a00B000000OtzVjIAJ-sffxtest1.sfhxhello_typescriptfunction-2023-04-10T16:07:11.768-0700","msg":"[c836fe3f-2a99-4fe4-8ef3-0665132bcc3e] Validated context headers - well done"}
...
<log output deleted.>
...
2023-04-10T23:07:14.460591+00:00 app[web.1]: {"level":30,"time":1681168034460,"pid":20,"hostname":"97e7e956-a995-4dcc-9619-0635dd01c996","reqId":"00DB0000000gJmXMAU-4pHpPcjoiD_NZpmt-SUG---a00B000000OtzVjIAJ-sffxtest1.sfhxhello_typescriptfunction-2023-04-10T16:07:11.768-0700","msg":"[c836fe3f-2a99-4fe4-8ef3-0665132bcc3e] Updated function response [200] to sffxtest1__AsyncFunctionInvocationRequest__c [a00B000000OtzVjIAJ]"}
2023-04-10T23:07:14.460934+00:00 app[web.1]: {"level":30,"time":1681168034460,"pid":20,"hostname":"97e7e956-a995-4dcc-9619-0635dd01c996","reqId":"00DB0000000gJmXMAU-4pHpPcjoiD_NZpmt-SUG---a00B000000OtzVjIAJ-sffxtest1.sfhxhello_typescriptfunction-2023-04-10T16:07:11.768-0700","res":{"statusCode":201},"responseTime":1058.924006998539,"msg":"request completed"}
```


## [Local Development](#dev)
### Start Proxy and Function
Starting the proxy will also start the function.

Ensure that the target function (eg, `typescriptfunction`) is installed and built (`npm install && npm run build`).

The following environment variables must be set:
- `CONSUMER_KEY` - Consumer Key of the function's authorization Connected App.
- `ENCODED_PRIVATE_KEY` - encoded private key of the function's authorization Connected App.
- `HOME` - function directory.
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
$ pwd
/home/functions/git/function-migration/functions/typescriptfunction/proxy/bin

$ tree
.
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
$ ./invokeSync.sh '00Dxx0000006JX6!AQEA...'
...

$ ./invokeAsync.sh '00Dxx0000006JX6!AQEA...'
...
```

For async request, use `./queryAsync.sh` to query for last `AsyncFunctionInvocationRequest__c` record.  Ensure that the invoking user has access to `AsyncFunctionInvocationRequest__c` and fields.
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
        "ExtraInfo__c": "{\"requestId\":\"00Dxx0000006IYJEA2-4Y4W3Lw_LkoskcHdEaZze-a00xx000000bxi1AAA-MyFunction-2020-09-03T20:56:27.608444Z\",\"source\":\"urn:event:from:salesforce/xx/00Dxx0000006IYJEA2/apex\",\"execTimeMs\":170.45832300186157,\"isFunctionError\":false,\"stack\":\"\",\"statusCode\":200}",
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