/**
 * Invokes a function.
 */
public class FunctionInvoker {

    private static final List<Integer> RETRY_STATUS_CODES = new List<Integer>();
    private static final Integer RETRY_SLEEP_SEC = 1000;
    
    static {
        RETRY_STATUS_CODES.add(502); // BAD_GATEWAY
        RETRY_STATUS_CODES.add(503); // SERVICE_UNAVAILABLE
        RETRY_STATUS_CODES.add(504); // GATEWAY_TIMEOUT
        // 500 generally means that an exception occurred w/in the function itself
    }

    private final String functionName;
    private final String requestId;
    private final String resource;
    private final String payloadJson;
    private final FunctionInvocationRequest functionRequestContext;
    private final String authenticationToken;
    
    public FunctionInvoker(String functionName,
                           String requestId,
                           String resource,
                           String payloadJson,
                           FunctionInvocationRequest functionRequestContext,
                           String authenticationToken) {
        this.functionName = functionName;
        this.requestId = requestId;
        this.resource = resource;
        this.payloadJson = payloadJson;
        this.functionRequestContext = functionRequestContext;
        this.authenticationToken = authenticationToken;
    }

    /**
     * Invoke function.  If desired, retry once on certain failure status codes.
     */
    public FunctionInvocationImpl invoke(boolean retry) {       
        HttpRequest functionRequest = generateRequest(requestId,
                                                      resource,
                                                      payloadJson,
                                                      functionRequestContext,
                                                      authenticationToken);
        
        FunctionInvocationStatus status;
        Integer statusCode = 0;
        String body = '';
        String error = '';
        String extraInfo = '';
        Long startTime = DateTime.now().getTime();
        System.debug('Invoking sync function ' + functionName + ' [' + requestId + ']...');

        // Invoke!
        try {
            Http httpConn = new Http();
            HttpResponse functionResponse = httpConn.send(functionRequest);
            statusCode = functionResponse.getStatusCode();
            if (retry && RETRY_STATUS_CODES.contains(statusCode)) {
                System.debug('Got statusCode ' + statusCode + '.  Retrying after ' + (RETRY_SLEEP_SEC / 1000) + 's [' + requestId + ']...');
                sleep();
                functionResponse = httpConn.send(functionRequest);
                statusCode = functionResponse.getStatusCode();
            } else {
                System.debug('Got statusCode ' + statusCode + '.  NOT retrying.');
            }
    
            body = functionResponse.getBody();
            // Apex header names are case sensitive
            extraInfo = functionResponse.getHeader('X-Extra-Info');
        } finally {
            Long totalTime = DateTime.now().getTime() - startTime;
            System.debug('Invoked sync function ' + functionName + ' in ' + totalTime + 'ms' + ' [' + requestId + ']');
        }        

        return new FunctionInvocationImpl(requestId,
                                          body,
                                          error,
                                          statusCode,
                                          extraInfo);

    }
    
    private HttpRequest generateRequest(String requestId,
                                        String resource,
                                        String payloadJson,
                                        FunctionInvocationRequest functionRequestContext,
                                        String authenticationToken) {
        HttpRequest functionRequest = new HttpRequest();
        functionRequest.setEndpoint(resource);
        functionRequest.setMethod('POST');
        functionRequest.setHeader('Content-Type', 'application/json');
        functionRequest.setHeader('Authorization', 'Bearer ' + authenticationToken);
        functionRequest.setHeader('request-id', requestId);   // Logged by proxy framework
        functionRequest.setHeader('X-Request-Id', requestId); // Logged by function
        functionRequestContext.setContextHeaders(functionRequest);
        functionRequest.setTimeout(120000);
        functionRequest.setBody(payloadJson);
        return functionRequest;
    }

    private void sleep() {
        Long startTime = DateTime.now().getTime();
        Long finishTime = DateTime.now().getTime();
        while ((finishTime - startTime) < RETRY_SLEEP_SEC) {
            finishTime = DateTime.now().getTime();
        }
    }
}