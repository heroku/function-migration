sfdx data query --query \
  "SELECT Id, RequestId__c, Status__c, StatusCode__c, Response__c, ExtraInfo__c, Callback__c, CallbackType__c, LastModifiedDate FROM AsyncFunctionInvocationRequest__c ORDER BY LastModifiedDate DESC LIMIT 1" \
  --json
