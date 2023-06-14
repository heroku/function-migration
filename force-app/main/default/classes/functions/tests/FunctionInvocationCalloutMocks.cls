@isTest
public class FunctionInvocationCalloutMocks {

    public static final String EXTRA_INFO_SUCCESS = '%7B%22requestId%22%3A%2200DB0000000gJmXMAU-4pU5ZP6e4Yo6spmt-SLE3--a00B000000OuAvYIAV-sffxtest1.sfhxhello_javafunction-2023-04-20T15%3A55%3A15.519-0700%22%2C%22source%22%3A%22urn%3Aevent%3Afrom%3Asalesforce%2FGS0%2F00DB0000000gJmXMAU%2Fapex%22%2C%22execTimeMs%22%3A763%2C%22statusCode%22%3A200%2C%22isFunctionError%22%3Afalse%2C%22stack%22%3A%5B%5D%7D';
    public static final String EXTRA_INFO_ERROR = '%7B%22requestId%22%3A%2200DB0000000gJmXMAU-4pU5ZP6e4Yo6spmt-SLE3--a00B000000OuAvYIAV-sffxtest1.sfhxhello_javafunction-2023-04-20T15%3A55%3A15.519-0700%22%2C%22source%22%3A%22urn%3Aevent%3Afrom%3Asalesforce%2FGS0%2F00DB0000000gJmXMAU%2Fapex%22%2C%22execTimeMs%22%3A763%2C%22statusCode%22%3A503%2C%22isFunctionError%22%3Afalse%2C%22stack%22%3A%5B%5D%7D';
    public static final String EXTRA_INFO_ERROR_599 = '%7B%22requestId%22%3A%2200DB0000000gJmXMAU-4pU5ZP6e4Yo6spmt-SLE3--a00B000000OuAvYIAV-sffxtest1.sfhxhello_javafunction-2023-04-20T15%3A55%3A15.519-0700%22%2C%22source%22%3A%22urn%3Aevent%3Afrom%3Asalesforce%2FGS0%2F00DB0000000gJmXMAU%2Fapex%22%2C%22execTimeMs%22%3A763%2C%22statusCode%22%3A599%2C%22isFunctionError%22%3Afalse%2C%22stack%22%3A%5B%5D%7D';
    public static final String EXTRA_INFO_FUNCTION_ERROR = '%7B%22requestId%22%3A%2200DB0000000gJmXMAU-4pU5ZP6e4Yo6spmt-SLE3--a00B000000OuAvYIAV-sffxtest1.sfhxhello_javafunction-2023-04-20T15%3A55%3A15.519-0700%22%2C%22source%22%3A%22urn%3Aevent%3Afrom%3Asalesforce%2FGS0%2F00DB0000000gJmXMAU%2Fapex%22%2C%22execTimeMs%22%3A763%2C%22statusCode%22%3A500%2C%22isFunctionError%22%3Atrue%2C%22stack%22%3A%5B%5D%7D';

    public class FunctionInvocationCalloutMock implements HttpCalloutMock {

        private final Map<String,String> headers;
        private final String body;
        private final Integer statusCode;

        public FunctionInvocationCalloutMock(Map<String,String> headers, String body, Integer statusCode) {
            this.headers = headers;
            this.body = body;
            this.statusCode = statusCode;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            for (String header: headers.keySet()) {
                res.setHeader(header, headers.get(header));
            }            
            res.setBody(body);
            res.setStatusCode(statusCode);
            return res;
        }
    }

    public static FunctionInvocationCalloutMock respondSuccess(String body) {
        Map<String,String> headers = new Map<String,String>();
        headers.put('Content-Type', 'application/json');
        headers.put('X-Extra-Info', EXTRA_INFO_SUCCESS);
        return new FunctionInvocationCalloutMock(headers, body, 200);
    }

    public static FunctionInvocationCalloutMock asyncRespondSuccess() {
        Map<String,String> headers = new Map<String,String>();
        headers.put('Content-Type', 'application/json');
        headers.put('X-Extra-Info', EXTRA_INFO_SUCCESS);
        return new FunctionInvocationCalloutMock(headers, '', 201);
    }

    public static FunctionInvocationCalloutMock respondError(String body) {
        Map<String,String> headers = new Map<String,String>();
        headers.put('Content-Type', 'application/json');
        headers.put('X-Extra-Info', EXTRA_INFO_ERROR);
        return new FunctionInvocationCalloutMock(headers, body, 503);
    }

    public static FunctionInvocationCalloutMock respondFunctionError(String body) {
        Map<String,String> headers = new Map<String,String>();
        headers.put('Content-Type', 'application/json');
        headers.put('X-Extra-Info', EXTRA_INFO_FUNCTION_ERROR);
        return new FunctionInvocationCalloutMock(headers, body, 500);
    }

    public static FunctionInvocationCalloutMock asyncRespondError() {
        Map<String,String> headers = new Map<String,String>();
        headers.put('Content-Type', 'application/json');
        headers.put('X-Extra-Info', EXTRA_INFO_ERROR);
        return new FunctionInvocationCalloutMock(headers, '', 503);
    }

    public static FunctionInvocationCalloutMock asyncRespondErrorNoRetry() {
        Map<String,String> headers = new Map<String,String>();
        headers.put('Content-Type', 'application/json');
        headers.put('X-Extra-Info', EXTRA_INFO_ERROR_599);
        return new FunctionInvocationCalloutMock(headers, '', 599);
    }
}