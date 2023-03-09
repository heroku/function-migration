SFDX_AUDIENCE_URL="https://test.test1.pc-rnd.salesforce.com/" \
SFDX_JWT_AUTH_RETRY_TIMEOUT=1200 \
SFDX_JWT_AUTH_RETRY_ATTEMPTS=120 \
SFDX_DNS_RETRY_FREQUENCY=10 \
SFDX_DNS_TIMEOUT=1200 \
sfdx force:org:create -v $1 -a $2 -s -f config/functions-scratch-def.json --wait=30