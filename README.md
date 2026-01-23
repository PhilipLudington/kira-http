# kira-http

HTTP client/server library with tracked effects for the Kira programming language.

## Installation

Add `kira-http` as a dependency in your project:

```toml
[dependencies]
kira-http = "0.1.0"
```

### Dependencies

kira-http requires:
- **kira-json** - JSON serialization for API requests/responses
- **kira-pcl** - URL parsing

## Quick Start

### Making HTTP Requests

```kira
use http
use std.io

effect fn main() -> IO[void] {
    // Simple GET request
    let result: Result[http.Response, http.HttpError] = http.get("https://api.example.com/data")

    match result {
        Ok(response) => {
            std.io.println("Status: {http.status_code(response.status)}")
            std.io.println("Body: {response.body}")
            return
        }
        Err(error) => {
            std.io.println("Request failed")
            return
        }
    }
}
```

### Using the Request Builder

```kira
use http

effect fn create_user(user_data: string) -> IO[Result[http.Response, http.HttpError]] {
    return http.new_request(http.Method.POST, "https://api.example.com/users")
        |> http.with_header("Content-Type", "application/json")
        |> http.with_header("Authorization", "Bearer token123")
        |> http.with_body(user_data)
        |> http.send()
}
```

### Creating an HTTP Server

```kira
use http
use std.io

fn handle_home(req: http.Request) -> http.Response {
    return http.ok("Hello, World!")
}

fn handle_user(req: http.Request) -> http.Response {
    let id: Option[string] = http.path_param(req, "id")

    match id {
        Some(user_id) => {
            return http.json_ok("{\"id\": \"{user_id}\"}")
        }
        None => {
            return http.bad_request("Missing user ID")
        }
    }
}

effect fn main() -> IO[void] {
    let router: http.Router = http.new_router()
        |> http.add_route(http.route_get("/", handle_home))
        |> http.add_route(http.route_get("/users/:id", handle_user))

    std.io.println("Server starting on port 8080...")
    http.serve(8080, router)
    return
}
```

## API Overview

### Client Functions

| Function | Description |
|----------|-------------|
| `get(url)` | Make a GET request |
| `post(url, body)` | Make a POST request with body |
| `put(url, body)` | Make a PUT request with body |
| `delete(url)` | Make a DELETE request |
| `request(req)` | Send a custom Request |
| `send(builder)` | Send a request from RequestBuilder |

### Request Builder

Build complex requests with method chaining:

```kira
http.new_request(method, url)
    |> http.with_header(name, value)
    |> http.with_headers(headers)
    |> http.with_body(body)
    |> http.with_json(data)
    |> http.with_timeout(ms)
    |> http.send()
```

### Response Helpers

| Function | Description |
|----------|-------------|
| `ok(body)` | 200 OK response |
| `created(body)` | 201 Created response |
| `no_content()` | 204 No Content response |
| `bad_request(msg)` | 400 Bad Request response |
| `not_found()` | 404 Not Found response |
| `internal_error(msg)` | 500 Internal Server Error response |
| `json_response(status, data)` | JSON response with custom status |

### Routing

```kira
// Create routes
http.route_get(path, handler)
http.route_post(path, handler)
http.route_put(path, handler)
http.route_delete(path, handler)
http.route(method, path, handler)

// Build router
http.new_router()
    |> http.add_route(route)
    |> http.add_routes(routes)
    |> http.set_not_found(handler)
    |> http.use_middleware(middleware)
```

Path parameters use `:param` syntax: `/users/:id/posts/:postId`

### Middleware

```kira
// Built-in middleware
http.logging()                    // Request/response logging
http.cors(allowed_origins)        // CORS headers
http.timeout(ms)                  // Request timeout

// Apply middleware
router |> http.use_middleware(http.logging())
```

### URL Utilities

```kira
http.parse_url(url_string)        // Parse URL into components
http.build_url(url)               // Build URL string from components
http.get_query_param(req, name)   // Get single query parameter
http.get_query_params(req, name)  // Get all values for query parameter
http.path_param(req, name)        // Get path parameter value
```

### Header Utilities

```kira
http.get_header(headers, name)    // Get header value
http.set_header(headers, name, value)  // Set/replace header
http.remove_header(headers, name) // Remove header

// Common header constructors
http.content_type(value)
http.authorization(value)
http.accept(value)

// Predefined content type headers
http.CONTENT_TYPE_JSON
http.CONTENT_TYPE_HTML
http.CONTENT_TYPE_TEXT
```

### Status Utilities

```kira
http.status_code(status)          // Get numeric code (e.g., 200)
http.status_from_code(code)       // Get Status from code
http.is_success(status)           // 2xx status?
http.is_redirect(status)          // 3xx status?
http.is_client_error(status)      // 4xx status?
http.is_server_error(status)      // 5xx status?
```

## Effect Tracking

kira-http leverages Kira's effect system. All network IO operations are marked with `effect`, making it clear where side effects occur:

```kira
// Effectful - performs network IO
effect fn get(url: string) -> Result[Response, HttpError]

// Pure - no IO, safe to call anywhere
fn with_header(builder: RequestBuilder, name: string, value: string) -> RequestBuilder
```

## Examples

See the `examples/` directory for complete working examples:

- **simple_get.ki** - Basic GET requests
- **api_client.ki** - REST API client with JSON
- **hello_server.ki** - Simple HTTP server
- **rest_api.ki** - Full REST API with CRUD operations

## Documentation

For detailed API documentation, see [DESIGN.md](DESIGN.md).

## License

MIT License - see [LICENSE](LICENSE) for details.
