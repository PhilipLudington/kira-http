# kira-http Design Document

HTTP client/server library with tracked effects for the Kira programming language.

**Repository:** https://github.com/PhilipLudington/kira-http

## Overview

kira-http provides HTTP client and server functionality that leverages Kira's effect system. All network operations are explicitly marked as effectful, making it clear where IO occurs in your code.

## Core Types

### HTTP Methods

```kira
type Method =
    | GET
    | POST
    | PUT
    | DELETE
    | PATCH
    | HEAD
    | OPTIONS
```

### Status Codes

```kira
type Status =
    | OK
    | Created
    | Accepted
    | NoContent
    | MovedPermanently
    | Found
    | NotModified
    | BadRequest
    | Unauthorized
    | Forbidden
    | NotFound
    | MethodNotAllowed
    | Conflict
    | InternalError
    | NotImplemented
    | BadGateway
    | ServiceUnavailable
    | Custom(i32)
```

### Headers

```kira
type Header = {
    name: string,
    value: string
}

type Headers = List[Header]
```

### Request

```kira
type Request = {
    method: Method,
    url: string,
    path: string,
    headers: Headers,
    body: Option[string],
    query: List[{key: string, value: string}]
}
```

### Response

```kira
type Response = {
    status: Status,
    headers: Headers,
    body: string
}
```

### Errors

```kira
type HttpError =
    | ConnectionFailed(string)
    | Timeout
    | InvalidUrl(string)
    | InvalidResponse(string)
    | TlsError(string)
```

## Client API

### Simple Functions

```kira
// GET request
effect fn get(url: string) -> Result[Response, HttpError]

// POST with body
effect fn post(url: string, body: string) -> Result[Response, HttpError]

// PUT with body
effect fn put(url: string, body: string) -> Result[Response, HttpError]

// DELETE
effect fn delete(url: string) -> Result[Response, HttpError]

// Generic request
effect fn request(req: Request) -> Result[Response, HttpError]
```

### Request Builder

```kira
type RequestBuilder = {
    method: Method,
    url: string,
    headers: Headers,
    body: Option[string],
    timeout: Option[i32]
}

fn newRequest(method: Method, url: string) -> RequestBuilder

fn withHeader(builder: RequestBuilder, name: string, value: string) -> RequestBuilder

fn withHeaders(builder: RequestBuilder, headers: Headers) -> RequestBuilder

fn withBody(builder: RequestBuilder, body: string) -> RequestBuilder

fn withJson[T](builder: RequestBuilder, data: T) -> RequestBuilder

fn withTimeout(builder: RequestBuilder, ms: i32) -> RequestBuilder

effect fn send(builder: RequestBuilder) -> Result[Response, HttpError]
```

### Client Example

```kira
effect fn fetchUser(id: i32) -> Result[User, AppError] {
    let url: string = "https://api.example.com/users/" + std.string.fromInt(id)

    let response: Result[Response, HttpError] = http.get(url)

    match response {
        Ok(r) => {
            match r.status {
                OK => {
                    let user: Result[User, JsonError] = json.parse(r.body)
                    match user {
                        Ok(u) => { return Ok(u) }
                        Err(e) => { return Err(ParseError(e)) }
                    }
                }
                NotFound => { return Err(UserNotFound) }
                _ => { return Err(ApiError(r.status)) }
            }
        }
        Err(e) => { return Err(NetworkError(e)) }
    }
}

// Using builder for complex requests
effect fn createUser(user: User) -> Result[User, AppError] {
    let response: Result[Response, HttpError] =
        http.newRequest(POST, "https://api.example.com/users")
        |> http.withHeader("Content-Type", "application/json")
        |> http.withHeader("Authorization", "Bearer " + token)
        |> http.withJson(user)
        |> http.send()

    // handle response...
}
```

## Server API

### Route Types

```kira
type Handler = fn(Request) -> Response

type Route =
    | Route(Method, string, Handler)

type Router = {
    routes: List[Route],
    notFound: Handler,
    middleware: List[Middleware]
}
```

### Route Helpers

```kira
fn get(path: string, handler: Handler) -> Route
fn post(path: string, handler: Handler) -> Route
fn put(path: string, handler: Handler) -> Route
fn delete(path: string, handler: Handler) -> Route
fn route(method: Method, path: string, handler: Handler) -> Route
```

### Server Functions

```kira
fn newRouter() -> Router

fn addRoute(router: Router, route: Route) -> Router

fn addRoutes(router: Router, routes: List[Route]) -> Router

fn setNotFound(router: Router, handler: Handler) -> Router

effect fn serve(port: i32, router: Router) -> Result[void, HttpError]

effect fn serveRoutes(port: i32, routes: List[Route]) -> Result[void, HttpError]
```

### Server Example

```kira
fn handleHome(req: Request) -> Response {
    return Response {
        status: OK,
        headers: [Header { name: "Content-Type", value: "text/plain" }],
        body: "Welcome to Kira!"
    }
}

fn handleUser(req: Request) -> Response {
    let id: Option[string] = http.pathParam(req, "id")

    match id {
        Some(userId) => {
            return Response {
                status: OK,
                headers: [Header { name: "Content-Type", value: "application/json" }],
                body: "{\"id\": \"" + userId + "\"}"
            }
        }
        None => {
            return Response {
                status: BadRequest,
                headers: [],
                body: "Missing user ID"
            }
        }
    }
}

fn handleCreateUser(req: Request) -> Response {
    match req.body {
        Some(body) => {
            // Parse and create user
            return Response {
                status: Created,
                headers: [],
                body: body
            }
        }
        None => {
            return Response {
                status: BadRequest,
                headers: [],
                body: "Request body required"
            }
        }
    }
}

effect fn main() -> void {
    let router: Router = http.newRouter()
        |> http.addRoute(http.get("/", handleHome))
        |> http.addRoute(http.get("/users/:id", handleUser))
        |> http.addRoute(http.post("/users", handleCreateUser))

    std.io.println("Server starting on port 8080...")
    http.serve(8080, router)
}
```

## Middleware

```kira
type Middleware = fn(Handler) -> Handler

fn logging() -> Middleware
fn cors(origins: List[string]) -> Middleware
fn timeout(ms: i32) -> Middleware

fn useMiddleware(router: Router, mw: Middleware) -> Router
```

### Middleware Example

```kira
fn loggingMiddleware(next: Handler) -> Handler {
    return fn(req: Request) -> Response {
        std.io.println(req.method + " " + req.path)
        let response: Response = next(req)
        std.io.println("-> " + response.status)
        return response
    }
}
```

## Response Helpers

```kira
// Create common responses
fn ok(body: string) -> Response
fn created(body: string) -> Response
fn noContent() -> Response
fn badRequest(message: string) -> Response
fn notFound() -> Response
fn internalError(message: string) -> Response

// JSON responses
fn jsonResponse[T](status: Status, data: T) -> Response

// Status checks
fn isSuccess(status: Status) -> bool
fn isRedirect(status: Status) -> bool
fn isClientError(status: Status) -> bool
fn isServerError(status: Status) -> bool

fn statusCode(status: Status) -> i32
fn statusFromCode(code: i32) -> Status
```

## Header Utilities

```kira
fn getHeader(headers: Headers, name: string) -> Option[string]
fn setHeader(headers: Headers, name: string, value: string) -> Headers
fn removeHeader(headers: Headers, name: string) -> Headers

// Common headers
fn contentType(value: string) -> Header
fn authorization(value: string) -> Header
fn accept(value: string) -> Header

// Content types
let contentTypeJson: Header = Header { name: "Content-Type", value: "application/json" }
let contentTypeHtml: Header = Header { name: "Content-Type", value: "text/html" }
let contentTypeText: Header = Header { name: "Content-Type", value: "text/plain" }
```

## URL Utilities

```kira
type Url = {
    scheme: string,
    host: string,
    port: Option[i32],
    path: string,
    query: Option[string],
    fragment: Option[string]
}

fn parseUrl(url: string) -> Result[Url, HttpError]
fn buildUrl(url: Url) -> string

fn getQueryParam(req: Request, name: string) -> Option[string]
fn getQueryParams(req: Request, name: string) -> List[string]
fn pathParam(req: Request, name: string) -> Option[string]
```

## Project Structure

```
kira-http/
├── src/
│   ├── lib.ki          # Main exports
│   ├── types.ki        # Core types (Method, Status, Request, Response)
│   ├── client.ki       # HTTP client implementation
│   ├── server.ki       # HTTP server implementation
│   ├── request.ki      # Request builder
│   ├── response.ki     # Response helpers
│   ├── router.ki       # Routing logic
│   ├── middleware.ki   # Middleware types and helpers
│   ├── status.ki       # Status code utilities
│   ├── headers.ki      # Header utilities
│   └── url.ki          # URL parsing and building
├── examples/
│   ├── simple_get.ki   # Basic GET request
│   ├── api_client.ki   # REST API client
│   ├── hello_server.ki # Simple server
│   └── rest_api.ki     # REST API server
├── tests/
│   ├── client_test.ki
│   ├── server_test.ki
│   ├── router_test.ki
│   └── url_test.ki
├── README.md
└── LICENSE
```

## Dependencies

- **kira-json** - JSON serialization for API requests/responses
- **kira-pcl** - URL parsing

## Implementation Notes

### Effect Tracking

All functions that perform network IO must be marked with `effect`. This includes:
- `http.get()`, `http.post()`, etc.
- `http.send()` (builder)
- `http.serve()` (server)

Pure functions (no `effect` keyword):
- Request/response builders
- Header manipulation
- URL parsing
- Status code helpers

### Path Parameters

Routes support path parameters with `:param` syntax:
- `/users/:id` matches `/users/123` with `id = "123"`
- `/posts/:postId/comments/:commentId` matches nested params

### Query String Parsing

Query strings are automatically parsed into the request's `query` field:
- `/search?q=kira&limit=10` produces `[{key: "q", value: "kira"}, {key: "limit", value: "10"}]`

## Future Considerations

- HTTPS/TLS support
- WebSocket support
- HTTP/2
- Connection pooling
- Request retries with backoff
- Cookie handling
- Multipart form data
- Streaming responses
