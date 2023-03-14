/**
 * TODO
 */
global class FunctionsDataSourceConnection extends DataSource.Connection {

    public static final String FUNCTIONS_TABLE_NAME = 'Functions';

    global FunctionsDataSourceConnection(DataSource.ConnectionParams connectionParams) {
    }

    override global List<DataSource.Table> sync() {
        List<DataSource.Column> columns = new List<DataSource.Column>();        
        // general
        addTextColumn(columns, 'Name', 'TODO: Description', 100);
        addTextColumn(columns, 'Endpoint', 'TODO: Description', 100);
        
        // sfdc required
        columns.add(DataSource.Column.text('ExternalId', 18));
        columns.add(DataSource.Column.url('DisplayUrl'));

        List<DataSource.Table> tables = new List<DataSource.Table>();
        tables.add(DataSource.Table.get(FUNCTIONS_TABLE_NAME, 'Function', 'Functions', 
            'TODO: description', 'Function', columns));

        return tables;
    }

    private void addTextColumn(List<DataSource.Column> columns, String name, String description, Integer length) {
        addTextColumn(columns, name, name, description, length);
    }

    private void addTextColumn(List<DataSource.Column> columns, String name, String label, 
            String description, Integer length) {
        DataSource.Column column = DataSource.Column.get(name, label, description, true, true, 
            DataSource.DataType.STRING_SHORT_TYPE, length);
        columns.add(column);
    }

    override global DataSource.TableResult query(DataSource.QueryContext context) {
        List<Map<String,Object>> filteredFunctions = DataSource.QueryUtils.filter(context, getFunctions());
        List<Map<String,Object>> sortedFunctions = DataSource.QueryUtils.sort(context, filteredFunctions);
        List<Map<String,Object>> limitedFunctions = DataSource.QueryUtils.applyLimitAndOffset(context, sortedFunctions);
        return DataSource.TableResult.get(context, limitedFunctions);
    }

    private List<Map<String,Object>> getFunctions() {
        List<Map<String,Object>> foundFunctions = new List<Map<String,Object>>();
        String apiResponse = invokeApi('https://api.heroku.com/apps');
        System.debug('Got function request from API: ' + apiResponse);
        List<Object> apiResponseFunctions = (List<Object>)JSON.deserializeUntyped(apiResponse);
        for (Object apiResponseFunctionTmp : apiResponseFunctions) {
            Map<String,Object> apiResponseFunction = (Map<String,Object>)apiResponseFunctionTmp;
            Map<String, Object> function = new Map<String, Object>();
            foundFunctions.add(function);
            function.put('ExternalId', apiResponseFunction.get('id'));
            function.put('DisplayUrl', apiResponseFunction.get('web_url'));
            function.put('Name', apiResponseFunction.get('name'));
            function.put('Endpoint', apiResponseFunction.get('web_url'));
        }
        return foundFunctions;
    }

    private String invokeApi(String url) {
        Http h = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndPoint(url);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer 45eaeff5-0683-4e97-9003-48ff8efdb091');
        request.setHeader('Accept', 'application/vnd.heroku+json; version=3');
        HttpResponse response = h.send(request);
        return response.getBody();        
    } 
}