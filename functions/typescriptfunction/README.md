# Javascript/Typescript Functions

## Javascript/Typescript Proxy
Yada yada


## Javascript/Typescript Function Project Changes
ANYTHING?

## Heroku Javascript/Typescript App Creation and Setup
For each function, create a Heroku App.  Function source will be deployed to an App.  For more information, see [How Heroku Works](https://devcenter.heroku.com/articles/how-heroku-works).
```bash
# Create app for function
$ heroku create typescriptfunction

# Apply remote to repo
heroku git:remote -a typescriptfunction

# Apply buildpacks
$ heroku buildpacks:add -a typescriptfunction \
    https://github.com/lstoll/heroku-buildpack-monorepo
$ heroku buildpacks:add -a typescriptfunction heroku/nodejs
$ heroku buildpacks:add -a typescriptfunction heroku/heroku-community/inline

# List buildpacks
$ heroku buildpacks -a typescriptfunction
=== typescriptfunction Buildpack URLs

1. https://github.com/lstoll/heroku-buildpack-monorepo
2. heroku/nodejs
3. heroku-community/inline
```

## Heroku Javascript/Typescript App Deployment
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
remote: -----> Building on the Heroku-22 stack
remote: -----> Using buildpacks:
remote:        1. https://github.com/lstoll/heroku-buildpack-monorepo
remote:        2. heroku/nodejs
remote:        3. heroku-community/inline
remote: -----> Monorepo app detected
remote:       Copied functions/typescriptfunction to root of app successfully
remote: -----> Node.js app detected
remote:        
remote: -----> Creating runtime environment
remote:        
remote:        NPM_CONFIG_LOGLEVEL=error
remote:        NODE_VERBOSE=false
remote:        NODE_ENV=production
remote:        NODE_MODULES_CACHE=true
remote:        
remote: -----> Installing binaries
remote:        engines.node (package.json):  ^18.7
remote:        engines.npm (package.json):   unspecified (use default)
remote:        
remote:        Resolving node version ^18.7...
remote:        Downloading and installing node 18.15.0...
remote:        Using default npm version: 9.5.0
remote:        
remote: -----> Restoring cache
remote:        Cached directories were not restored due to a change in version of node, npm, yarn or stack
remote:        Module installation may take longer for this build
remote:        
remote: -----> Installing dependencies
remote:        Installing node modules
remote:        
remote:        added 807 packages, and audited 808 packages in 23s
...
remote:        
remote: -----> Build
remote:        Running build
remote:        
remote:        > typescriptfunction-function@0.0.1 build
remote:        > tsc
remote:        
remote:        
remote: -----> Caching build
remote:        - npm cache
remote:        
remote: -----> Pruning devDependencies
remote:        
...
remote:        
remote: -----> Build succeeded!
remote:  !     This app may not specify any way to start a node process
remote:        https://devcenter.heroku.com/articles/nodejs-support#default-web-process-type
remote: 
remote: -----> https://buildpack-registry.s3.amazonaws.com/buildpacks/heroku-community/inline.tgz app detected
remote: npm WARN deprecated samsam@1.3.0: This package has been deprecated in favour of @sinonjs/samsam
remote: 
remote: added 459 packages, and audited 808 packages in 18s
...
remote: 
remote: added 109 packages, and audited 110 packages in 2s
remote: 
remote: 16 packages are looking for funding
remote:   run `npm fund` for details
remote: 
remote: found 0 vulnerabilities
remote: -----> Discovering process types
remote:        Procfile declares types     -> (none)
remote:        Default types for buildpack -> web
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

## Heroku Java App Deployment
```bash
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

TODO: More info here