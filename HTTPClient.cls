public class HTTPClient {
    private String apiEndpoint;
    private String contentType;
    private String httpMethod;
    private String payloadStr;
    private Map<String, String> headers    = new Map<String, String>();
    private Map<String, Object> payloadMap = new Map<String, Object>();

    public Integer             statusCode   { get; private set; }
    public String              rawBody      { get; private set; }
    public Map<String, Object> jsonResponse { get; private set; }
    public String              errorMsg     { get; private set; }

    public HTTPClient setApiEndpoint(String apiEndpoint) {
        if (String.isNotBlank(apiEndpoint)) {
            this.apiEndpoint = apiEndpoint;
        }
        return this;
    }

    public HTTPClient setContentType(String contentType) {
        this.contentType = String.isNotBlank(contentType) ? contentType : 'application/json';
        return this;
    }

    public HTTPClient setHttpMethod(String httpMethod) {
        Set<String> validMethods = new Set<String>{'GET', 'POST', 'PUT', 'PATCH', 'DELETE'};
        if (String.isNotBlank(httpMethod) && validMethods.contains(httpMethod.toUpperCase())) {
            this.httpMethod = httpMethod.toUpperCase();
        } 
        else {
            this.httpMethod = 'GET';
        }
        return this;
    }

    public HTTPClient setPayloadStr(String payloadStr) {
        this.payloadStr = String.isNotBlank(payloadStr) ? payloadStr : '';
        return this;
    }

    public HTTPClient setHeaders(Map<String, String> headers) {
        this.headers = (headers != null) ? headers : new Map<String, String>();
        return this;
    }

    public HTTPClient setPayloadMap(Map<String, Object> payloadMap) {
        this.payloadMap = (payloadMap != null) ? payloadMap : new Map<String, Object>();
        return this;
    }

    public HTTPClient fetch() {
        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();

            req.setHeader('Accept', 'application/json');
            req.setTimeout(10000);
            req.setHeader('Content-Type', String.isNotBlank(this.contentType) ? this.contentType : 'application/json');
            req.setEndpoint(this.apiEndpoint);
            req.setMethod(String.isNotBlank(this.httpMethod) ? this.httpMethod : 'GET');

            if (!this.headers.isEmpty()) {
                for (String key : this.headers.keySet()) {
                    req.setHeader(key, this.headers.get(key));
                }
            }

            if (this.httpMethod == 'POST' || this.httpMethod == 'PUT' || this.httpMethod == 'PATCH') {
                if (String.isNotBlank(this.payloadStr)) {
                    req.setBody(this.payloadStr);
                } 
                else if (!this.payloadMap.isEmpty()) {
                    req.setBody(JSON.serialize(this.payloadMap));
                }
            }

            HttpResponse res = http.send(req);
            this.statusCode  = res.getStatusCode();
            this.rawBody     = res.getBody();
            
            if (String.isNotBlank(this.rawBody)) {
                this.jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(this.rawBody);
            }
        } 
        catch (Exception e) {
            this.statusCode = -1;
            this.errorMsg   = e.getMessage() + ' when consuming ' + this.apiEndpoint;
        }

        return this;
    }
}
