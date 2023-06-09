ACCESS_TOKEN=$1
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
FUNCTION_CONTEXT=$(cat $SCRIPTPATH/sfFnSyncContext.json | tr -d '\n\r ' | base64 -w 0)
SF_CONTEXT=$(cat $SCRIPTPATH/sfContext.json | tr -d '\n\r ' | base64 -w 0)
CMD="curl -v \
  http://localhost:3000/sync \
  -X POST \
  -H \"Content-Type: application/json\" \
  -H \"Authorization: Bearer $ACCESS_TOKEN\" \
  -H \"X-Request-Id: 00Dxx0000006IYJEA2-4Y4W3Lw_LkoskcHdEaZze--MyFunction-2020-09-03T20:56:27.608444Z\" \
  -H \"ce-specversion: 1.0\" \
  -H \"ce-id: 00Dxx0000006IYJEA2-4Y4W3Lw_LkoskcHdEaZze-a00xx000000bxi1AAA-MyFunction-2020-09-03T20:56:27.608444Z\" \
  -H \"ce-source: urn:event:from:salesforce/xx/00Dxx0000006IYJEA2/apex\" \
  -H \"ce-datacontenttype: application/json\" \
  -H \"ce-type: com.salesforce.function.invoke.sync\" \
  -H \"ce-sffncontext: `echo $FUNCTION_CONTEXT`\" \
  -H \"ce-sfcontext: `echo $SF_CONTEXT`\" \
  -d '{\"Hello\":\"There!\"}'"
echo $CMD
eval $CMD
