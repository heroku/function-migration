# Java Functions

## [Java Proxy Overview](#overview)

The Java Proxy is a [Spring Boot](https://spring.io/) app that has the following APIs:
- `/sync` for synchronous function requests.
- `/async` for asynchronous function requests.
- `/healthcheck` to monitor the function server and restart, if needed.

To learn Spring Boot, check out the [Sprint Bookt Guides](https://spring.io/guides).

## [Example Function Framework Artifacts](#artifacts)
Copy the following `bin/` and `proxy/` directories to the root of your function directories.

```bash
# Inline buildpack
functions/javafunction/bin/
├── compile
├── detect
└── release

# Proxy app
functions/javafunction/proxy/
├── bin
├── mvnw
├── mvnw.cmd
├── pom.xml
├── README.md
├── src
└── target
```

## [Function Project Changes](#changes)
Update Java source version to Java 11.
```
<properties>
    <java.version>11</java.version>
    <maven.compiler.source>${java.version}</maven.compiler.source>
    <maven.compiler.target>${java.version}</maven.compiler.target>    
    <sf.functions.version>1.1.0</sf.functions.version>
</properties>
```

## [Function App Creation and Setup](#app)
For each function, create a Heroku App.  Function source will be deployed to an App.

Buildpacks are responsible for transforming deployed code into a deployment unit.  For more information on Buildpacks, see [Buildpacks](https://devcenter.heroku.com/articles/buildpacks).  The proxy and function use the following buildpacks:  
- `lstoll/heroku-buildpack-monorepo` - support for multiple apps in a single repo, eg SFDX projects will have SFDX source and multiple functions.
- `heroku/heroku-buildpack-java` - the official Heroku buildpack for Java apps that uses Maven to build.
- `heroku/heroku-buildpack-inline` - supports an app that builds itself, in this case, the proxy. 

For more information, see [How Heroku Works](https://devcenter.heroku.com/articles/how-heroku-works).

```bash
# Create app for function
$ heroku create javafunction

# Apply remote to repo
heroku git:remote -a javafunction

# Apply buildpacks
$ heroku buildpacks:add -a javafunction \
    https://github.com/lstoll/heroku-buildpack-monorepo
$ heroku buildpacks:add -a javafunction \
    https://github.com/heroku/heroku-buildpack-java.git
$ heroku buildpacks:add -a javafunction heroku-community/inline

# List buildpacks
$ heroku buildpacks -a javafunction
=== javafunction Buildpack URLs

  1. https://github.com/lstoll/heroku-buildpack-monorepo
  2. https://github.com/heroku/heroku-buildpack-java.git
  3. heroku-community/inline
```

## [Function App Configuration](#config)
The following config vars are required for each function.

Connected App config, `CONSUMER_KEY` and `ENCODED_PRIVATE_KEY`, are values for the authorization Connected App - the Connected App used to validate and authorize function requests. 

Ensure to target commands to your function via `-a <function app name>`.
```bash
# For repos with multiple functions, the heroku-buildpack-monorepo needs APP_BASE to point to the base dir of the function
$ heroku config:set -a javafunction APP_BASE=functions/javafunction

# In your Org under Company Settings -> Company Information find your Org's OrgId and convert to 18-char
$ heroku config:set -a javafunction ORG_ID_18=00DDH0000005zbM2AQ

# Set the function's authorization Connected App's Consumer Key
$ heroku config:set -a javafunction CONSUMER_KEY=3MVG9bm...

# Set the function's authorization Connected App's digital certificate/key, base64 encoded
$ heroku config:set -a javafunction ENCODED_PRIVATE_KEY=`cat ~/sfdc/jwt/server.key | base64 -w 0`

# List config vars
$ heroku config -a javafunction
=== javafunction Config Vars

APP_BASE:            functions/javafunction
CONSUMER_KEY:        3MVG9bm...
ENCODED_PRIVATE_KEY: LS0tLSx...
ORG_ID_18:           00DB0000000EjT0MAK
```

## [Function App Deployment](#deploy)
Once development and testing is complete, deploy your function to Heroku.

```bash
$ git push heroku main
Enumerating objects: 346, done.
Counting objects: 100% (346/346), done.
Delta compression using up to 36 threads
Compressing objects: 100% (255/255), done.
Writing objects: 100% (321/321), 300.37 KiB | 6.67 MiB/s, done.
Total 321 (delta 137), reused 32 (delta 14)
remote: Resolving deltas: 100% (137/137), completed with 16 local objects.
remote: Updated 194 paths from 281041e
remote: Compressing source files... done.
remote: Building source:
remote: 
remote: -----> Building on the Heroku-22 stack
remote: -----> Using buildpacks:
remote:        1. https://github.com/lstoll/heroku-buildpack-monorepo
remote:        2. https://github.com/heroku/heroku-buildpack-java.git
remote:        3. heroku-community/inline
remote: -----> Monorepo app detected
remote:       Copied functions/javafunction to root of app successfully
remote: -----> Java app detected
remote: -----> Installing OpenJDK 11... done
remote: -----> Executing Maven
remote:        $ ./mvnw -DskipTests clean dependency:list install
remote: --2023-04-05 20:01:12--  https://repo.maven.apache.org/maven2/io/takari/maven-wrapper/0.5.6/maven-wrapper-0.5.6.jar
remote: Resolving repo.maven.apache.org (repo.maven.apache.org)... 146.75.32.215
remote: Connecting to repo.maven.apache.org (repo.maven.apache.org)|146.75.32.215|:443... connected.
remote: HTTP request sent, awaiting response... 200 OK
remote: Length: 50710 (50K) [application/java-archive]
remote: Saving to: ‘/tmp/build_603e5c00/.mvn/wrapper/maven-wrapper.jar’
remote: 
remote:      0K .......... .......... .......... .......... ......... 100% 18.2M=0.003s
remote: 
remote: 2023-04-05 20:01:12 (18.2 MB/s) - ‘/tmp/build_603e5c00/.mvn/wrapper/maven-wrapper.jar’ saved [50710/50710]
remote: 
remote:        [INFO] Scanning for projects...
remote:        [INFO] Downloading from...
remote:        [INFO] Downloaded from...
...
remote:        [INFO] Installing /tmp/build_603e5c00/pom.xml to /tmp/codon/tmp/cache/.m2/repository/com/example/javafunction/1.0-SNAPSHOT/javafunction-1.0-SNAPSHOT.pom
remote:        [INFO] Installing /tmp/build_603e5c00/target/javafunction-1.0-SNAPSHOT.jar to /tmp/codon/tmp/cache/.m2/repository/com/example/javafunction/1.0-SNAPSHOT/javafunction-1.0-SNAPSHOT.jar
remote:        [INFO] ------------------------------------------------------------------------
remote:        [INFO] BUILD SUCCESS
remote:        [INFO] ------------------------------------------------------------------------
remote:        [INFO] Total time:  8.994 s
remote:        [INFO] Finished at: 2023-04-05T20:01:24Z
remote:        [INFO] ------------------------------------------------------------------------
remote: -----> https://buildpack-registry.s3.amazonaws.com/buildpacks/heroku-community/inline.tgz app detected
remote: [INFO] Scanning for projects...
remote: Downloading from...
remote: Downloaded from...
...
remote: [INFO] Replacing main artifact with repackaged archive
remote: [INFO] ------------------------------------------------------------------------
remote: [INFO] BUILD SUCCESS
remote: [INFO] ------------------------------------------------------------------------
remote: [INFO] Total time:  28.312 s
remote: [INFO] Finished at: 2023-04-05T20:01:55Z
remote: [INFO] ------------------------------------------------------------------------
remote: -----> Discovering process types
remote:        Procfile declares types     -> (none)
remote:        Default types for buildpack -> web
remote: 
remote: -----> Compressing...
remote:        Done: 117.7M
remote: -----> Launching...
remote:        Released v12
remote:        https://javafunction.herokuapp.com/ deployed to Heroku
remote: 
remote: Verifying deploy... done.
To https://git.heroku.com/javafunction.git
   2065336..b4d61f1  main -> main
```

## [Function App Startup](#startup)
```bash
$ heroku logs -a javafunction -t
2023-04-05T20:24:15.000000+00:00 app[api]: Build succeeded
2023-04-05T20:24:16.078429+00:00 heroku[web.1]: Starting process with command `java -jar /app/proxy/target/proxy-0.0.1.jar com.salesforce.functions.proxy.ProxyApplication`
... 
2023-04-05T20:24:19.818625+00:00 app[web.1]: .   ____          _            __ _ _
2023-04-05T20:24:19.818675+00:00 app[web.1]: /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
2023-04-05T20:24:19.818723+00:00 app[web.1]: ( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
2023-04-05T20:24:19.818769+00:00 app[web.1]: \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
2023-04-05T20:24:19.818829+00:00 app[web.1]: '  |____| .__|_| |_|_| |_\__, | / / / /
2023-04-05T20:24:19.818877+00:00 app[web.1]: =========|_|==============|___/=/_/_/_/
2023-04-05T20:24:19.820129+00:00 app[web.1]: :: Spring Boot ::               (v2.7.10)
2023-04-05T20:24:19.820156+00:00 app[web.1]: 
...
2023-04-05T20:24:22.498583+00:00 app[web.1]: 20:24:22.498 INFO  [RUNTIME] o.s.b.w.s.c.ServletWebServerApplicationContext - Root WebApplicationContext: initialization completed in 2252 ms
2023-04-05T20:24:22.875918+00:00 app[web.1]: 20:24:22.875 INFO  [RUNTIME] c.s.f.proxy.command.StartFunction - Starting function w/ args: /app/.jdk/bin/java -jar /app/proxy/target/sf-fx-runtime-java-runtime-1.1.3-jar-with-dependencies.jar serve /app -h 0.0.0.0 -p 8080
...
2023-04-05T20:24:23.850188+00:00 app[web.1]: 20:24:23.849 INFO  [RUNTIME] c.s.functions.proxy.ProxyApplication - Started ProxyApplication in 4.817 seconds (JVM running for 6.029)
...
2023-04-05T20:24:38.718919+00:00 app[web.1]: 20:24:38.718 INFO  [RUNTIME] c.s.f.j.r.commands.ServeCommandImpl - Found function: com.example.JavafunctionFunction
```


## [Function Invocation](#invoke)
#### Sync
```bash
$ heroku logs -a javafunction -t
...
2023-04-06T19:07:53.080741+00:00 app[web.1]: 19:07:53.080 INFO  [RUNTIME] c.s.f.p.controller.SyncController - Received /sync request
2023-04-06T19:07:53.108711+00:00 app[web.1]: 19:07:53.108 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [null]: Invoking handler ValidateHeadersHandler...
2023-04-06T19:07:53.109026+00:00 app[web.1]: 19:07:53.108 INFO  [RUNTIME] c.s.f.p.h.ValidateHeadersHandler - [41c904a8-891f-413e-9c10-c084c7041b1e]: Validated request headers - looks good
2023-04-06T19:07:53.116333+00:00 app[web.1]: 19:07:53.116 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [41c904a8-891f-413e-9c10-c084c7041b1e]: Invoked handler ValidateHeadersHandler in 1ms
2023-04-06T19:07:53.116364+00:00 app[web.1]: 19:07:53.116 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [41c904a8-891f-413e-9c10-c084c7041b1e]: Invoking handler ValidateContexts...
2023-04-06T19:07:53.251895+00:00 app[web.1]: 19:07:53.251 INFO  [RUNTIME] c.s.f.proxy.handler.ValidateContexts - [41c904a8-891f-413e-9c10-c084c7041b1e]: Validated context headers - well done
2023-04-06T19:07:53.251911+00:00 app[web.1]: 19:07:53.251 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [41c904a8-891f-413e-9c10-c084c7041b1e]: Invoked handler ValidateContexts in 135ms
2023-04-06T19:07:53.251927+00:00 app[web.1]: 19:07:53.251 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [41c904a8-891f-413e-9c10-c084c7041b1e]: Invoking handler ValidateCaller...
2023-04-06T19:07:54.214947+00:00 app[web.1]: 19:07:54.214 INFO  [RUNTIME] c.s.f.proxy.handler.ValidateCaller - [41c904a8-891f-413e-9c10-c084c7041b1e]: Validated client - good to go
2023-04-06T19:07:54.214992+00:00 app[web.1]: 19:07:54.214 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [41c904a8-891f-413e-9c10-c084c7041b1e]: Invoked handler ValidateCaller in 963ms
2023-04-06T19:07:54.215057+00:00 app[web.1]: 19:07:54.215 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [41c904a8-891f-413e-9c10-c084c7041b1e]: Invoking handler MintTokenHandler...
2023-04-06T19:07:54.394856+00:00 app[web.1]: 19:07:54.394 INFO  [RUNTIME] c.s.f.proxy.handler.MintTokenHandler - [41c904a8-891f-413e-9c10-c084c7041b1e]: Minting function  token for user admin@functions.org, audience https://login.salesforce.com, url https://mycompany.my.salesforce.com/services/oauth2/token, issuer 3MVG9...
2023-04-06T19:07:54.531669+00:00 app[web.1]: 19:07:54.531 INFO  [RUNTIME] c.s.f.proxy.handler.MintTokenHandler - [41c904a8-891f-413e-9c10-c084c7041b1e]: Minted function's token - hooray
2023-04-06T19:07:54.531725+00:00 app[web.1]: 19:07:54.531 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [41c904a8-891f-413e-9c10-c084c7041b1e]: Invoked handler MintTokenHandler in 316ms
2023-04-06T19:07:54.531762+00:00 app[web.1]: 19:07:54.531 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [41c904a8-891f-413e-9c10-c084c7041b1e]: Invoking handler ActivatePermissionSets...
2023-04-06T19:07:54.731283+00:00 app[web.1]: 19:07:54.731 INFO  [RUNTIME] c.s.f.p.h.ActivatePermissionSets - [41c904a8-891f-413e-9c10-c084c7041b1e]: Activated session-based Permission Set(s): JavaFunction - yessir
2023-04-06T19:07:54.731316+00:00 app[web.1]: 19:07:54.731 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [41c904a8-891f-413e-9c10-c084c7041b1e]: Invoked handler ActivatePermissionSets in 200ms
2023-04-06T19:07:54.731356+00:00 app[web.1]: 19:07:54.731 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [41c904a8-891f-413e-9c10-c084c7041b1e]: Invoking handler PrepareFunctionRequestHandler...
2023-04-06T19:07:54.736458+00:00 app[web.1]: 19:07:54.736 INFO  [RUNTIME] c.s.f.p.h.PrepareFunctionRequestHandler - [41c904a8-891f-413e-9c10-c084c7041b1e]: Prepared function request - let's go
2023-04-06T19:07:54.736497+00:00 app[web.1]: 19:07:54.736 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [41c904a8-891f-413e-9c10-c084c7041b1e]: Invoked handler PrepareFunctionRequestHandler in 5ms
2023-04-06T19:07:54.747912+00:00 app[web.1]: 19:07:54.747 INFO  [RUNTIME] c.s.f.p.s.InvokeFunctionService - [41c904a8-891f-413e-9c10-c084c7041b1e]: Sync invoking function sfhxhello_javafunction...
2023-04-06T19:07:55.659088+00:00 heroku[router]: at=info method=POST path="/sync" host=javafunction.herokuapp.com request_id=41c904a8-891f-413e-9c10-c084c7041b1e fwd="136.147.46.8" dyno=web.1 connect=0ms service=3395ms status=200 bytes=1930 protocol=https
2023-04-06T19:07:55.576637+00:00 app[web.1]: dateTime=2023-04-06T19:07:55.561947Z level=INFO loggerName=com.example.JavafunctionFunction message="Function successfully queried 16 account records!" invocationId="00DB0000000gJmXMAU-4pCi1GpefXmLx9-qbx2Ds--5x288sArftLunEDYmdR3+/wd5Co=-sffxtest1.sfhxhello_javafunction-2023-04-06T12:07:51.978-0700"
2023-04-06T19:07:55.641666+00:00 app[web.1]: 19:07:55.641 INFO  [RUNTIME] c.s.f.p.s.InvokeFunctionService - [41c904a8-891f-413e-9c10-c084c7041b1e]: Invoked function sfhxhello_javafunction in 893ms
```
#### Async
```bash
2023-04-10T23:10:48.212761+00:00 app[web.1]: 23:10:48.212 INFO  [RUNTIME] c.s.f.p.controller.SyncController - Received /async request
2023-04-10T23:10:48.212806+00:00 app[web.1]: 23:10:48.212 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [null]: Invoking handler ValidateHeadersHandler...
2023-04-10T23:10:48.212845+00:00 app[web.1]: 23:10:48.212 INFO  [RUNTIME] c.s.f.p.h.ValidateHeadersHandler - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: Validated request headers - looks good
2023-04-10T23:10:48.212886+00:00 app[web.1]: 23:10:48.212 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: Invoked handler ValidateHeadersHandler in 0ms
2023-04-10T23:10:48.212913+00:00 app[web.1]: 23:10:48.212 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: Invoking handler ValidateContexts...
2023-04-10T23:10:48.213518+00:00 app[web.1]: 23:10:48.213 INFO  [RUNTIME] c.s.f.proxy.handler.ValidateContexts - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: Validated context headers - well done
2023-04-10T23:10:48.213571+00:00 app[web.1]: 23:10:48.213 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: Invoked handler ValidateContexts in 1ms
2023-04-10T23:10:48.213605+00:00 app[web.1]: 23:10:48.213 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: Invoking handler ValidateCaller...
2023-04-10T23:10:48.553437+00:00 app[web.1]: 23:10:48.553 INFO  [RUNTIME] c.s.f.proxy.handler.ValidateCaller - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: Validated client - good to go
2023-04-10T23:10:48.553483+00:00 app[web.1]: 23:10:48.553 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: Invoked handler ValidateCaller in 340ms
2023-04-10T23:10:48.553516+00:00 app[web.1]: 23:10:48.553 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: Invoking handler MintTokenHandler...
2023-04-10T23:10:48.572532+00:00 app[web.1]: 23:10:48.572 INFO  [RUNTIME] c.s.f.proxy.handler.MintTokenHandler - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: Minting function  token for user admin@functions.org, audience https://login.salesforce.com, url https://mycompany.my.salesforce.com/services/oauth2/token, issuer 3MVG9...
2023-04-10T23:10:48.709131+00:00 app[web.1]: 23:10:48.709 INFO  [RUNTIME] c.s.f.proxy.handler.MintTokenHandler - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: Minted function's token - hooray
2023-04-10T23:10:48.709149+00:00 app[web.1]: 23:10:48.709 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: Invoked handler MintTokenHandler in 156ms
2023-04-10T23:10:48.709171+00:00 app[web.1]: 23:10:48.709 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: Invoking handler ActivatePermissionSets...
2023-04-10T23:10:48.709418+00:00 app[web.1]: 23:10:48.709 DEBUG [RUNTIME] c.s.f.p.h.ActivatePermissionSets - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: POST /actions/standard/activateSessionPermSet: {"inputs":[{"PermSetName":"JavaFunction","PermSetNamespace":"sffxtest1"}]}
2023-04-10T23:10:48.839065+00:00 heroku[router]: at=info method=POST path="/async" host=javafunction.herokuapp.com request_id=8f5d2869-fc78-4aee-8749-de7d57a4c481 fwd="136.147.46.8" dyno=web.1 connect=0ms service=630ms status=201 bytes=92 protocol=https
2023-04-10T23:10:48.836047+00:00 app[web.1]: 23:10:48.835 INFO  [RUNTIME] c.s.f.p.h.ActivatePermissionSets - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: Activated session-based Permission Set(s): sffxtest1__JavaFunction - yessir
2023-04-10T23:10:48.836119+00:00 app[web.1]: 23:10:48.836 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: Invoked handler ActivatePermissionSets in 127ms
2023-04-10T23:10:48.836152+00:00 app[web.1]: 23:10:48.836 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: Invoking handler PrepareFunctionRequestHandler...
2023-04-10T23:10:48.836340+00:00 app[web.1]: 23:10:48.836 INFO  [RUNTIME] c.s.f.p.h.PrepareFunctionRequestHandler - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: Prepared function request - let's go
2023-04-10T23:10:48.836399+00:00 app[web.1]: 23:10:48.836 DEBUG [RUNTIME] c.s.f.p.controller.SyncController - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: Invoked handler PrepareFunctionRequestHandler in 0ms
2023-04-10T23:10:48.836584+00:00 app[web.1]: 23:10:48.836 INFO  [RUNTIME] c.s.f.p.s.InvokeFunctionService - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: Async invoking function sfhxhello_javafunction...
2023-04-10T23:10:49.162923+00:00 app[web.1]: dateTime=2023-04-10T23:10:49.162387Z level=INFO loggerName=com.example.JavafunctionFunction message="Function successfully queried 13 account records!" invocationId=00DB0000000gJmXMAU-4pHpaaleaxhJju-qbvTdk--a00B000000OtzVoIAJ-sffxtest1.sfhxhello_javafunction-2023-04-10T16:10:36.485-0700
2023-04-10T23:10:49.165325+00:00 app[web.1]: 23:10:49.165 DEBUG [RUNTIME] c.s.f.p.s.InvokeFunctionService - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: POST /sobjects/sffxtest1__AsyncFunctionInvocationRequest__c/a00B000000OtzVoIAJ?_HttpMethod=PATCH: {"sffxtest1__ExtraInfo__c":"{\"requestId\":\"00DB0000000gJmXMAU-4pHpaaleaxhJju-qbvTdk--a00B000000OtzVoIAJ-sffxtest1.sfhxhello_javafunction-2023-04-10T16:10:36.485-0700\",\"source\":\"urn:event:from:salesforce/GS0/00DB0000000gJmXMAU/apex\",\"execTimeMs\":324,\"statusCode\":200,\"isFunctionError\":false,\"stack\":[]}","sffxtest1__Response__c":"{\"accounts\":[{\"id\":\"001B000001U1oCLIAZ\",\"name\":\"JavaFunction/async/SUCCESS/00DB0000000gJmXMAU-4pHpPcjoiD_NZpmt-SUG---a00B000000OtzVjIAJ-sffxtest1.sfhxhello_javafunction-2023-04-10T16:07:11.768-0700\"},{...}","sffxtest1__Status__c":"SUCCESS","sffxtest1__StatusCode__c":200}
2023-04-10T23:10:49.907141+00:00 app[web.1]: 23:10:49.906 INFO  [RUNTIME] c.s.f.p.s.InvokeFunctionService - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: Updated function response [SUCCESS] to AsyncFunctionInvocationRequest__c [a00B000000OtzVoIAJ]
2023-04-10T23:10:49.907310+00:00 app[web.1]: 23:10:49.907 INFO  [RUNTIME] c.s.f.p.s.InvokeFunctionService - [8f5d2869-fc78-4aee-8749-de7d57a4c481]: Invoked function sfhxhello_javafunction in 1071ms
```

## [Local Development](#dev)
### Start Proxy and Function
Starting the proxy will also start the function.

Ensure that the target function (eg, `javafunction`) is installed and built (`mvn package`).

The following environment variables must be set:
- `CONSUMER_KEY` - Consumer Key of the function's authorization Connected App.
- `ENCODED_PRIVATE_KEY` - encoded private key of the function's authorization Connected App.
- `HOME` - function directory.
- `ORG_ID_18` - ID of the function owning Organization.
- `JAVA_TOOL_OPTIONS` - (Optional) set to configuration Java options for the function. 

#### Command-line
```bash
$ pwd
/home/functions/git/function-migration/functions/javafunction
$ java $JAVA_TOOL_OPTIONS -jar /home/functions/git/function-migration/functions/javafunction/proxy/target/proxy-0.0.1.jar com.salesforce.functions.proxy.ProxyApplication
...
```

#### IDE
Set the above environment variables.

Run `com.salesforce.functions.proxy.ProxyApplication` with Java or Spring Boot configuration.

### Invocation Bash Scripts
The following scripts invoke local functions sync and asynchronously.
```bash
$ pwd
/home/functions/git/function-migration/functions/javafunction/proxy/bin

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
        "ExtraInfo__c": "{\"requestId\":\"00Dxx0000006IYJEA2-4Y4W3Lw_LkoskcHdEaZze-a00xx000000bxi1AAA-javafunction-2020-09-03T20:56:27.608444Z\",\"source\":\"urn:event:from:salesforce/xx/00Dxx0000006IYJEA2/apex\",\"execTimeMs\":170.45832300186157,\"isFunctionError\":false,\"stack\":\"\",\"statusCode\":200}",
        "Callback__c": "{\"functionName\":\"JavaFunction\"}",
        "CallbackType__c": "InvokeJavaFunction.Callback",
        "LastModifiedDate": "2023-04-10T22:48:12.000+0000"
      }
    ],
    "totalSize": 1,
    "done": true
  }
}
```