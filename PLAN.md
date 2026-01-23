# kira-http Implementation Plan

Development plan for the kira-http library based on DESIGN.md.

## Phase 1: Core Types

Foundation types that all other modules depend on.

### 1.1 Create `src/types.ki`
- [x] Define `Method` sum type (GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS)
- [x] Define `Status` sum type (OK, Created, BadRequest, NotFound, etc.)
- [x] Define `Header` product type `{ name: string, value: string }`
- [x] Define `Headers` type alias `List[Header]`
- [x] Define `HttpError` sum type (ConnectionFailed, Timeout, InvalidUrl, InvalidResponse, TlsError)

### 1.2 Create `src/status.ki`
- [x] Implement `statusCode(status: Status) -> i32`
- [x] Implement `statusFromCode(code: i32) -> Status`
- [x] Implement `isSuccess(status: Status) -> bool`
- [x] Implement `isRedirect(status: Status) -> bool`
- [x] Implement `isClientError(status: Status) -> bool`
- [x] Implement `isServerError(status: Status) -> bool`

### 1.3 Create `src/headers.ki`
- [x] Implement `getHeader(headers: Headers, name: string) -> Option[string]`
- [x] Implement `setHeader(headers: Headers, name: string, value: string) -> Headers`
- [x] Implement `removeHeader(headers: Headers, name: string) -> Headers`
- [x] Implement `contentType(value: string) -> Header`
- [x] Implement `authorization(value: string) -> Header`
- [x] Implement `accept(value: string) -> Header`
- [x] Define constants: `contentTypeJson`, `contentTypeHtml`, `contentTypeText`

### 1.4 Create `tests/test_types.ki`
- [x] Test status code conversion round-trips
- [x] Test status category checks (success, redirect, client error, server error)
- [x] Test header manipulation functions

## Phase 2: URL Handling

URL parsing and query parameter utilities.

### 2.1 Create `src/url.ki`
- [x] Define `Url` product type `{ scheme, host, port, path, query, fragment }`
- [x] Implement `parseUrl(url: string) -> Result[Url, HttpError]`
- [x] Implement `buildUrl(url: Url) -> string`
- [x] Implement `getQueryParam(req: Request, name: string) -> Option[string]`
- [x] Implement `getQueryParams(req: Request, name: string) -> List[string]`
- [x] Implement `pathParam(req: Request, name: string) -> Option[string]`

### 2.2 Create `tests/test_url.ki`
- [x] Test URL parsing (various schemes, ports, paths, queries)
- [x] Test URL building round-trips
- [x] Test query parameter extraction
- [x] Test path parameter extraction
- [x] Test invalid URL handling

## Phase 3: Request/Response

Request and response types with builder pattern.

### 3.1 Create `src/request.ki`
- [x] Define `Request` product type
- [x] Define `RequestBuilder` product type
- [x] Implement `newRequest(method: Method, url: string) -> RequestBuilder`
- [x] Implement `withHeader(builder, name, value) -> RequestBuilder`
- [x] Implement `withHeaders(builder, headers) -> RequestBuilder`
- [x] Implement `withBody(builder, body) -> RequestBuilder`
- [x] Implement `withJson[T](builder, data) -> RequestBuilder`
- [x] Implement `withTimeout(builder, ms) -> RequestBuilder`

### 3.2 Create `src/response.ki`
- [x] Define `Response` product type
- [x] Implement `ok(body: string) -> Response`
- [x] Implement `created(body: string) -> Response`
- [x] Implement `noContent() -> Response`
- [x] Implement `badRequest(message: string) -> Response`
- [x] Implement `notFound() -> Response`
- [x] Implement `internalError(message: string) -> Response`
- [x] Implement `jsonResponse[T](status: Status, data: T) -> Response`

### 3.3 Create `tests/test_request.ki`
- [x] Test request builder chaining
- [x] Test header accumulation
- [x] Test body setting

### 3.4 Create `tests/test_response.ki`
- [x] Test response helper functions
- [x] Test correct status codes and headers

## Phase 4: HTTP Client

Effectful client functions for making HTTP requests.

### 4.1 Create `src/client.ki`
- [x] Implement `effect fn get(url: string) -> Result[Response, HttpError]`
- [x] Implement `effect fn post(url: string, body: string) -> Result[Response, HttpError]`
- [x] Implement `effect fn put(url: string, body: string) -> Result[Response, HttpError]`
- [x] Implement `effect fn delete(url: string) -> Result[Response, HttpError]`
- [x] Implement `effect fn request(req: Request) -> Result[Response, HttpError]`
- [x] Implement `effect fn send(builder: RequestBuilder) -> Result[Response, HttpError]`

### 4.2 Create `tests/test_client.ki`
- [x] Test successful requests
- [x] Test error handling (connection failed, timeout, invalid URL)
- [x] Test request builder send

## Phase 5: Routing

Router and route matching for server-side handling.

### 5.1 Create `src/router.ki`
- [x] Define `Handler` type alias `fn(Request) -> Response`
- [x] Define `Route` sum type
- [x] Define `Router` product type
- [x] Implement `newRouter() -> Router`
- [x] Implement `addRoute(router: Router, route: Route) -> Router`
- [x] Implement `addRoutes(router: Router, routes: List[Route]) -> Router`
- [x] Implement `setNotFound(router: Router, handler: Handler) -> Router`
- [x] Implement route helpers: `get`, `post`, `put`, `delete`, `route`
- [x] Implement path parameter matching (`:param` syntax)

### 5.2 Create `tests/test_router.ki`
- [x] Test route matching by method and path
- [x] Test path parameter extraction
- [x] Test not found handler
- [x] Test route priority/ordering

## Phase 6: Middleware

Middleware system for request/response processing.

### 6.1 Create `src/middleware.ki`
- [x] Define `Middleware` type alias `fn(Handler) -> Handler`
- [x] Implement `useMiddleware(router: Router, mw: Middleware) -> Router`
- [x] Implement `logging() -> Middleware`
- [x] Implement `cors(origins: List[string]) -> Middleware`
- [x] Implement `timeout(ms: i32) -> Middleware`

### 6.2 Create `tests/test_middleware.ki`
- [x] Test middleware chaining
- [x] Test logging middleware output
- [x] Test CORS header injection

## Phase 7: HTTP Server

Effectful server that listens and handles requests.

### 7.1 Create `src/server.ki`
- [x] Implement `effect fn serve(port: i32, router: Router) -> Result[void, HttpError]`
- [x] Implement `effect fn serveRoutes(port: i32, routes: List[Route]) -> Result[void, HttpError]`
- [x] Implement request parsing from raw HTTP
- [x] Implement response serialization to raw HTTP

### 7.2 Create `tests/test_server.ki`
- [x] Test server startup/shutdown
- [x] Test request routing
- [x] Test middleware execution order

## Phase 8: Library Entry Point

Main exports and public API.

### 8.1 Create `src/lib.ki`
- [x] Re-export all public types
- [x] Re-export client functions
- [x] Re-export server functions
- [x] Re-export builder functions
- [x] Re-export helper functions

## Phase 9: Examples

Working examples demonstrating library usage.

### 9.1 Create `examples/simple_get.ki`
- [ ] Basic GET request example

### 9.2 Create `examples/api_client.ki`
- [ ] REST API client with JSON parsing

### 9.3 Create `examples/hello_server.ki`
- [ ] Simple "Hello World" server

### 9.4 Create `examples/rest_api.ki`
- [ ] Full REST API server with CRUD operations

## Phase 10: Documentation

Final documentation updates.

### 10.1 Update `README.md`
- [ ] Installation instructions
- [ ] Quick start examples
- [ ] API overview
- [ ] Link to full documentation

## Dependencies

```
Phase 1 (Core Types)
    |
    v
Phase 2 (URL) -----> Phase 3 (Request/Response)
                          |
                          v
                     Phase 4 (Client)
                          |
Phase 5 (Routing) <-------+
    |
    v
Phase 6 (Middleware)
    |
    v
Phase 7 (Server)
    |
    v
Phase 8 (Library Entry)
    |
    v
Phase 9 (Examples) --> Phase 10 (Documentation)
```

## Notes

- All effectful functions must use `effect fn` and return `IO[...]`
- Pure functions handle data transformation only
- Follow Kira-Toolkit standards in `.claude/rules/`
- Run `/kira-check` after each phase
- Run `/kira-review` before completing each phase
