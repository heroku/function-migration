CONTEXT=$(cat syncContext.json | tr -s '\n' ' ')
CMD="curl -v \
  http://localhost:3000/sync \
  -X POST \
  -H \"Content-Type: application/json\" \
  -H \"Authorization: Bearer 00Dxx0000006JX6!AQEAQEr5UkZ3k.LpVsH3IXPc2BcaBySI5HXXnpWWJFb_fQeR6X2COXLQWQqZAOLfbXsxdtWFSRgKbeGHlDcMHMXEkHGVG3rK\" \
  -H \"X-Request-Id: 00Dxx0000006IYJEA2-4Y4W3Lw_LkoskcHdEaZze--MyFunction-2020-09-03T20:56:27.608444Z\" \
  -H \"X-Context: `echo $CONTEXT`\" \
  -d '{\"Hello\":\"There!\"}'"
echo $CMD
eval $CMD