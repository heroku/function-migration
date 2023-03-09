#!/bin/sh
export HEROKU_HOST=https://api.staging.herokudev.com
export HEROKU_LOGIN_HOST=https://auth-staging-cloud.herokai.com
export SALESFORCE_FUNCTIONS_API=$HEROKU_HOST
export SALESFORCE_FUNCTIONS_IDENTITY_URL=$HEROKU_LOGIN_HOST

echo "Logging into functions..."
sf login functions

echo "\nEDIT sfdx-project.json:"
echo "  \"sfdcLoginUrl\": \"https://na45.test1.pc-rnd.salesforce.com\""    
echo "  \"signupTargetLoginUrl\": \"https://cs4.test1.pc-rnd.salesforce.com\"\n"