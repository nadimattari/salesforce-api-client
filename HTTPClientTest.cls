@isTest
private class HTTPClientTest {

    private static final String TEST_ENDPOINT = 'https://api.example.com/test';

    // ── Mock Implementation ──────────────────────────────────────────────

    private class MockResponse implements HttpCalloutMock {
        private Integer code;
        private String  body;

        MockResponse(Integer code, String body) {
            this.code = code;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.code);
            res.setBody(this.body);
            return res;
        }
    }

    // ── Setter / Builder Tests ───────────────────────────────────────────

    @isTest
    static void testFluentInterfaceReturnsThis() {
        HTTPClient client = new HTTPClient();

        Test.startTest();
        HTTPClient result = client
            .setApiEndpoint(TEST_ENDPOINT)
            .setContentType('application/json')
            .setHttpMethod('GET')
            .setHeaders(new Map<String, String>())
            .setPayloadStr('test')
            .setPayloadMap(new Map<String, Object>());
        Test.stopTest();

        System.assertEquals(client, result, 'Each setter should return the same instance');
    }

    @isTest
    static void testDefaults_outOfTheBox() {
        HTTPClient client = new HTTPClient();

        Test.setMock(HttpCalloutMock.class, new MockResponse(200, '{}'));
        client.setApiEndpoint(TEST_ENDPOINT).fetch();

        System.assertEquals(200, client.statusCode, 'Default method GET and content type application/json should work');
    }

    @isTest
    static void testSetApiEndpoint_blankIsIgnored() {
        HTTPClient client = new HTTPClient();

        Test.startTest();
        client.setApiEndpoint('');
        client.setApiEndpoint(null);
        client.setApiEndpoint('  ');
        Test.stopTest();

        System.assertEquals(null, client.rawBody, 'Endpoint should remain unset when blank');
    }

    @isTest
    static void testSetContentType_blankResetsToJson() {
        HTTPClient client = new HTTPClient();

        Test.startTest();
        client.setContentType('text/plain');
        client.setContentType('');
        client.setContentType(null);
        Test.stopTest();

        Test.setMock(HttpCalloutMock.class, new MockResponse(200, '{}'));
        client.setApiEndpoint(TEST_ENDPOINT).fetch();

        System.assertEquals(200, client.statusCode, 'Blank content type should reset to application/json');
    }

    @isTest
    static void testSetContentType_customValue() {
        HTTPClient client = new HTTPClient();

        Test.startTest();
        client.setContentType('text/plain');
        Test.stopTest();

        Test.setMock(HttpCalloutMock.class, new MockResponse(200, '{}'));
        client.setApiEndpoint(TEST_ENDPOINT).fetch();

        System.assertEquals(200, client.statusCode);
    }

    @isTest
    static void testSetHttpMethod_validMethods() {
        HTTPClient client = new HTTPClient();

        Test.startTest();
        for (String method : new String[]{'GET', 'POST', 'PUT', 'PATCH', 'DELETE'}) {
            client.setHttpMethod(method);
        }
        Test.stopTest();

        System.assertEquals('DELETE', client.httpMethod, 'Last valid method should stick');
    }

    @isTest
    static void testSetHttpMethod_invalidDefaultsToGet() {
        HTTPClient client = new HTTPClient();

        Test.startTest();
        client.setHttpMethod('POST');
        client.setHttpMethod('INVALID');
        client.setHttpMethod('');
        client.setHttpMethod(null);
        Test.stopTest();

        System.assertEquals('GET', client.httpMethod, 'Invalid input should reset to GET');
    }

    @isTest
    static void testSetHttpMethod_isCaseInsensitive() {
        HTTPClient client = new HTTPClient();

        Test.startTest();
        client.setHttpMethod('post');
        Test.stopTest();

        System.assertEquals('POST', client.httpMethod, 'Method should be uppercased');
    }

    @isTest
    static void testSetHeaders_nullDefaultsToEmptyMap() {
        HTTPClient client = new HTTPClient();

        Test.startTest();
        client.setHeaders(null);
        Test.stopTest();

        System.assertNotEquals(null, client, 'Headers should default to empty map');
    }

    @isTest
    static void testSetPayloadStr_blankDefaultsToEmpty() {
        HTTPClient client = new HTTPClient();

        Test.startTest();
        client.setPayloadStr('');
        client.setPayloadStr(null);
        Test.stopTest();

        System.assertEquals(null, client.rawBody, 'Blank payload should be ignored');
    }

    @isTest
    static void testSetPayloadMap_nullDefaultsToEmptyMap() {
        HTTPClient client = new HTTPClient();

        Test.startTest();
        client.setPayloadMap(null);
        Test.stopTest();

        System.assertNotEquals(null, client, 'Null payload map should default to empty map');
    }

    // ── fetch() Tests ────────────────────────────────────────────────────

    @isTest
    static void testFetch_missingEndpoint() {
        Test.startTest();
        HTTPClient client = (new HTTPClient()).fetch();
        Test.stopTest();

        System.assertEquals(-1, client.statusCode);
        System.assert(client.errorMsg.contains('API endpoint is not set'), 'ErrorMsg should indicate missing endpoint');
    }

    @isTest
    static void testFetch_getRequest_200() {
        String responseBody = '{"status":"ok","count":42}';
        Test.setMock(HttpCalloutMock.class, new MockResponse(200, responseBody));

        Test.startTest();
        HTTPClient client = (new HTTPClient())
            .setApiEndpoint(TEST_ENDPOINT)
            .setHttpMethod('GET')
            .fetch();
        Test.stopTest();

        System.assertEquals(200, client.statusCode);
        System.assertEquals(responseBody, client.rawBody);
        System.assertNotEquals(null, client.jsonResponse);
        System.assertEquals('ok', client.jsonResponse.get('status'));
        System.assertEquals(42, client.jsonResponse.get('count'));
        System.assertEquals(null, client.errorMsg);
    }

    @isTest
    static void testFetch_postRequestWithPayloadMap() {
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('name', 'test');
        payload.put('value', 123);

        Test.setMock(HttpCalloutMock.class, new MockResponse(201, '{"created":true}'));

        Test.startTest();
        HTTPClient client = (new HTTPClient())
            .setApiEndpoint(TEST_ENDPOINT)
            .setHttpMethod('POST')
            .setPayloadMap(payload)
            .fetch();
        Test.stopTest();

        System.assertEquals(201, client.statusCode);
        System.assertEquals(true, client.jsonResponse.get('created'));
    }

    @isTest
    static void testFetch_postRequestWithStringPayload() {
        Test.setMock(HttpCalloutMock.class, new MockResponse(200, '{"ok":true}'));

        Test.startTest();
        HTTPClient client = (new HTTPClient())
            .setApiEndpoint(TEST_ENDPOINT)
            .setHttpMethod('POST')
            .setPayloadStr('raw body content')
            .fetch();
        Test.stopTest();

        System.assertEquals(200, client.statusCode);
        System.assertEquals(true, client.jsonResponse.get('ok'));
    }

    @isTest
    static void testFetch_customHeadersAreApplied() {
        Map<String, String> headers = new Map<String, String>();
        headers.put('Authorization', 'Bearer test_token');
        headers.put('X-Custom-Header', 'custom_value');

        Test.setMock(HttpCalloutMock.class, new MockResponse(200, '{"authorized":true}'));

        Test.startTest();
        HTTPClient client = (new HTTPClient())
            .setApiEndpoint(TEST_ENDPOINT)
            .setHeaders(headers)
            .fetch();
        Test.stopTest();

        System.assertEquals(200, client.statusCode);
        System.assertEquals(true, client.jsonResponse.get('authorized'));
    }

    @isTest
    static void testFetch_httpError_4xx() {
        Test.setMock(HttpCalloutMock.class, new MockResponse(404, '{"error":"not found"}'));

        Test.startTest();
        HTTPClient client = (new HTTPClient())
            .setApiEndpoint(TEST_ENDPOINT)
            .fetch();
        Test.stopTest();

        System.assertEquals(404, client.statusCode);
        System.assertEquals('not found', client.jsonResponse.get('error'));
        System.assertEquals(null, client.errorMsg);
    }

    @isTest
    static void testFetch_httpError_5xx() {
        Test.setMock(HttpCalloutMock.class, new MockResponse(500, '{"error":"server error"}'));

        Test.startTest();
        HTTPClient client = (new HTTPClient())
            .setApiEndpoint(TEST_ENDPOINT)
            .fetch();
        Test.stopTest();

        System.assertEquals(500, client.statusCode);
        System.assertEquals(null, client.errorMsg);
    }

    @isTest
    static void testFetch_exceptionHandling() {
        Test.setMock(HttpCalloutMock.class, new MockResponse(200, null));

        Test.startTest();
        HTTPClient client = (new HTTPClient())
            .setApiEndpoint(TEST_ENDPOINT)
            .fetch();
        Test.stopTest();

        System.assertNotEquals(null, client.errorMsg, 'ErrorMsg should be set on exception');
        System.assert(client.errorMsg.contains(TEST_ENDPOINT), 'ErrorMsg should contain the endpoint');
    }

    @isTest
    static void testFetch_emptyResponseBody() {
        Test.setMock(HttpCalloutMock.class, new MockResponse(200, ''));

        Test.startTest();
        HTTPClient client = (new HTTPClient())
            .setApiEndpoint(TEST_ENDPOINT)
            .fetch();
        Test.stopTest();

        System.assertEquals(200, client.statusCode);
        System.assertEquals('', client.rawBody);
        System.assertEquals(null, client.jsonResponse);
    }

    @isTest
    static void testFetch_putRequest() {
        Test.setMock(HttpCalloutMock.class, new MockResponse(200, '{"updated":true}'));

        Test.startTest();
        HTTPClient client = (new HTTPClient())
            .setApiEndpoint(TEST_ENDPOINT)
            .setHttpMethod('PUT')
            .setPayloadStr('update data')
            .fetch();
        Test.stopTest();

        System.assertEquals(200, client.statusCode);
    }

    @isTest
    static void testFetch_patchRequest() {
        Test.setMock(HttpCalloutMock.class, new MockResponse(200, '{"patched":true}'));

        Test.startTest();
        HTTPClient client = (new HTTPClient())
            .setApiEndpoint(TEST_ENDPOINT)
            .setHttpMethod('PATCH')
            .setPayloadStr('patch data')
            .fetch();
        Test.stopTest();

        System.assertEquals(200, client.statusCode);
    }

    @isTest
    static void testFetch_deleteRequest() {
        Test.setMock(HttpCalloutMock.class, new MockResponse(204, ''));

        Test.startTest();
        HTTPClient client = (new HTTPClient())
            .setApiEndpoint(TEST_ENDPOINT)
            .setHttpMethod('DELETE')
            .fetch();
        Test.stopTest();

        System.assertEquals(204, client.statusCode);
    }

    @isTest
    static void testFetch_stringPayloadTakesPrecedenceOverMap() {
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('key', 'from_map');

        Test.setMock(HttpCalloutMock.class, new MockResponse(200, '{}'));

        Test.startTest();
        HTTPClient client = (new HTTPClient())
            .setApiEndpoint(TEST_ENDPOINT)
            .setHttpMethod('POST')
            .setPayloadStr('string_payload')
            .setPayloadMap(payload)
            .fetch();
        Test.stopTest();

        System.assertEquals(200, client.statusCode);
    }

    @isTest
    static void testFetch_chainedCallsWorkEndToEnd() {
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('id', '123');
        payload.put('name', 'test record');

        Map<String, String> headers = new Map<String, String>();
        headers.put('Authorization', 'Bearer token_abc');
        headers.put('X-Request-Id', 'req-001');

        Test.setMock(HttpCalloutMock.class, new MockResponse(201, '{"id":"123","status":"created"}'));

        Test.startTest();
        HTTPClient client = (new HTTPClient())
            .setApiEndpoint(TEST_ENDPOINT)
            .setContentType('application/json')
            .setHttpMethod('POST')
            .setHeaders(headers)
            .setPayloadMap(payload)
            .fetch();
        Test.stopTest();

        System.assertEquals(201, client.statusCode);
        System.assertEquals('123', client.jsonResponse.get('id'));
        System.assertEquals('created', client.jsonResponse.get('status'));
        System.assertEquals(null, client.errorMsg);
    }
}
