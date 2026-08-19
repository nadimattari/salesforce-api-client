# Salesforce API Client

> *"A little copying is better than a little dependency."* — Go Proverb. Watch [Rob Pike's talk](https://www.youtube.com/watch?v=PAAkCSZUG1c&t=9m28s)

A lightweight, zero-dependency Apex HTTP client wrapper for Salesforce. Instead of importing bloated third-party frameworks or installing managed packages, this single-class client provides a clean fluent interface for JSON and URL-encoded HTTP callouts. It assumes JSON responses by default and can be easily customized directly in your codebase.

---

## Usage Examples

### 1. Form URL-Encoded Request (OAuth Token Fetch)

```java
String API_ENDPOINT = 'https://api.example.com/auth';

String reqPayload = 'grant_type=password' +
    '&client_id='     + EncodingUtil.urlEncode(clientID,     'UTF-8') +
    '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8') +
    '&username='      + EncodingUtil.urlEncode(userName,     'UTF-8') +
    '&password='      + EncodingUtil.urlEncode(passWord,     'UTF-8');

APIClient req = (new APIClient())
    .setApiEndpoint(API_ENDPOINT)
    .setContentType('application/x-www-form-urlencoded')
    .setHttpMethod('POST')
    .setPayloadStr(reqPayload)
    .fetch();

if (req.statusCode == 200 || req.statusCode == 201) {
    String accessToken = (String) req.jsonResponse.get('access_token');
}
else {
    System.debug('Authentication failed: ' + req.errorMsg);
}
```

### 2. JSON Request with Headers & Early Exit Design

```java
Map<String, Object> reqPayload = new Map<String, Object>();
reqPayload.put('id', UUID.randomUUID().toString());
reqPayload.put('key1', 'value1');
reqPayload.put('key2', 'value2');

Map<String, String> headers = new Map<String, String>();
headers.put('Authorization', 'Bearer long_token_here');

APIClient req = (new APIClient())
    .setApiEndpoint(API_ENDPOINT)
    .setContentType('application/json')
    .setHttpMethod('POST')
    .setHeaders(headers)
    .setPayloadMap(reqPayload)
    .fetch();

// Guard Clause 1: HTTP Status check
if (req.statusCode != 200 && req.statusCode != 201) {
    throw new CalloutException('API Request failed with status: ' + req.statusCode);
}

// Guard Clause 2: Business Logic Payload check
if (req.jsonResponse == null || req.jsonResponse.get('status') != 'SUCCESS') {
    throw new CalloutException('Operation did not succeed.');
}

// Happy path stays left-aligned
String result = (String) req.jsonResponse.get('some_key');
```

## Key Features & Code Patterns

### Method Chaining (Fluent Interface)
The `APIClient` class uses method chaining by returning `this` from every setter. This builder pattern lets you instantiate, configure headers, attach payloads, and execute the HTTP request in a single, fluent expression:

```java
APIClient req = (new APIClient())
    .setApiEndpoint(API_ENDPOINT)
    .setHttpMethod('POST')
    .setContentType('application/json')
    .setHeaders(headers)
    .setPayloadMap(reqPayload)
    .fetch();
```

### Design Pattern: Keep the Happy Path Left-Aligned

The second example utilizes the **Early Exit (Guard Clause)** pattern.

By handling errors and bad response statuses immediately at the top of the block, you can return early or throw exceptions before proceeding. This keeps the primary logic ("happy path") completely unindented, improving readability and reducing deeply nested `if/else` blocks across your service layer.
