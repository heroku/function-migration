SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
CONTEXT=$(cat $SCRIPTPATH/asyncContext.json | tr -s '\n' ' ' | base64)
CMD="curl -v \
  http://localhost:3000/async \
  -X POST \
  -H \"Content-Type: application/json\" \
  -H \"Authorization: Bearer 00Dxx0000006JX6!AQEAQEr5UkZ3k.LpVsH3IXPc2BcaBySI5HXXnpWWJFb_fQeR6X2COXLQWQqZAOLfbXsxdtWFSRgKbeGHlDcMHMXEkHGVG3rK\" \
  -H \"X-Request-Id: 00Dxx0000006IYJEA2-4Y4W3Lw_LkoskcHdEaZze-a00xx000000bxi1AAA-MyFunction-2020-09-03T20:56:27.608444Z\" \
  -H \"X-Context: `echo $CONTEXT`\" \
  -d '{\"Hello\":\"There!\"}'"
echo $CMD
eval $CMD