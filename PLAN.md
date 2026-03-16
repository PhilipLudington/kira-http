# kira-http — Implementation Plan

## Overview

HTTP client/server library with tracked effects for the Kira programming language. The core library (types, request/response, router, middleware, server, client) is complete with 281 tests passing. The runtime dependency `std.net` is now fully implemented in the Kira compiler (Phases 0-3 complete, including HTTPS/TLS).

All source and example files have been migrated to Kira v0.12.0 `import` syntax. The kira-json library is integrated as a dependency for typed JSON serialization in examples.

Reference: DESIGN.md

Current status: Phase 3 complete (JSON). All planned phases are done.

## Phase 0: Core Library ✅

**Status:** Complete (2026-03-14)

**Goal:** Implement all HTTP types, request/response handling, routing, middleware, and client/server modules.

### Deliverables
- All source modules: types, headers, url, request, response, status, router, middleware, server, client
- 281 tests passing
- All examples (hello_server, simple_get, rest_api, api_client) updated and passing `kira check`
- Migrated all source and examples from `use` to `import` syntax (Kira v0.12.0) (completed 2026-03-15)
- Integrated kira-json dependency in `kira.toml`; examples use `json.decode`/`json.encode` for typed serialization (completed 2026-03-15)

---

## Phase 1: HTTP Client Redirects ✅

**Status:** Complete (2026-03-15)

**Goal:** Handle HTTP redirects (301, 302, 307, 308) automatically in the client layer
**Estimated Effort:** 1–2 days

### Deliverables
- `request()` in `client.ki` follows redirects automatically (up to a configurable limit)
- `with_max_redirects(builder, n)` builder option to control redirect behavior
- Redirect-related error variant for too many redirects

### Tasks
- [x] Add `TooManyRedirects` variant to `HttpError` in `types.ki` (completed 2026-03-15)
- [x] Add `TemporaryRedirect` (307) and `PermanentRedirect` (308) to `Status` in `types.ki` (completed 2026-03-15)
- [x] Add `max_redirects: Option[i32]` field to `RequestBuilder` in `request.ki` (completed 2026-03-15)
- [x] Add `with_max_redirects(builder, n)` builder function in `request.ki` (completed 2026-03-15)
- [x] Implement redirect logic in `client.ki`'s `request()` function (completed 2026-03-15):
  - Check if response status is 301, 302, 307, or 308
  - Extract `Location` header from response
  - Re-issue request to the new URL (preserving method for 307/308, switching to GET for 301/302)
  - Decrement redirect counter; return `Err(TooManyRedirects)` when exhausted
  - Default to 10 max redirects when `max_redirects` is `None`
- [x] Add helper `get_header(headers, name) -> Option[string]` in `headers.ki` for case-insensitive header lookup (completed 2026-03-15)
- [x] Add tests for redirect chain handling (completed 2026-03-15)
- [x] Test with real redirect URLs via httpbin.org integration tests (completed 2026-03-15)

### Implementation Notes

Redirect logic in `request()`:
```kira
effect fn request(req: Request) -> Result[Response, HttpError] {
    // ... existing validation ...
    let result: Result[Response, HttpError] = std.net.http_request(req)
    match result {
        Ok(response) => {
            if is_redirect(response.status) {
                match get_header(response.headers, "location") {
                    Some(location) => {
                        // Build new request to location
                        // For 301/302: change method to GET, drop body
                        // For 307/308: preserve method and body
                        return request(new_req)  // recursive
                    }
                    None => { return Ok(response) }
                }
            }
            return Ok(response)
        }
        Err(e) => { return Err(e) }
    }
}
```

### Testing Strategy
1. `http://httpbin.org/redirect/3` follows 3 redirects and returns 200
2. `http://httpbin.org/redirect/20` returns `Err(TooManyRedirects)` with default limit of 10
3. 307 redirect preserves POST method and body
4. 301 redirect switches to GET

---

## Phase 2: Request Timeouts ✅

**Status:** Complete (2026-03-16)

**Goal:** Honor the `timeout` field in `RequestBuilder`
**Estimated Effort:** 1 day

### Deliverables
- `timeout: Option[i32]` field added to `Request` type, passed through from `RequestBuilder`
- Kira runtime (`std.net.http_request`) reads timeout from request record and applies it as socket read timeout
- Default timeout remains 30s when not specified; configurable via `with_timeout(builder, ms)`
- Timeout preserved across redirect chains
- Fixed non-exhaustive match patterns in `server.ki` for `TemporaryRedirect`, `PermanentRedirect`, `TooManyRedirects`

### Tasks
- [x] Add `timeout: Option[i32]` field to `Request` type in `request.ki` (completed 2026-03-16)
- [x] Update `build()` to pass `builder.timeout` through to `Request` (completed 2026-03-16)
- [x] Update `with_path_params()` to preserve timeout (completed 2026-03-16)
- [x] Update redirect request construction in `client.ki` to preserve timeout (completed 2026-03-16)
- [x] Update server-side `Request` construction in `server.ki` with `timeout: None` (completed 2026-03-16)
- [x] Modify Kira runtime `std.net.http_request` to read `timeout` field from request record (completed 2026-03-16)
- [x] Add 307/308 status codes to runtime `statusCodeToVariant` (completed 2026-03-16)
- [x] Fix non-exhaustive match patterns in `server.ki` (completed 2026-03-16)
- [x] Update all test files with new `Request` type and constructions (completed 2026-03-16)
- [x] Add tests for timeout pass-through in `build()` (completed 2026-03-16)
- [x] All 314 tests passing (completed 2026-03-16)

---

## Phase 3: JSON Support ✅

**Status:** Complete (2026-03-16)

**Goal:** Add JSON serialization/deserialization helpers
**Estimated Effort:** 3–5 days (revised: 1 day, since kira-json handles parsing/serialization)

### Deliverables
- `json_body(response) -> Result[Json, JsonError]` helper in `response.ki` for parsing response bodies as JSON
- kira-json types documented in `lib.ki` import guide for typed decode/encode workflows
- 8 new tests for json_body (valid objects, string/number/boolean extraction, null, arrays, error cases)

### Tasks
- [x] Implement JSON parse/stringify — provided by kira-json dependency (`json.parser.parse`, `json.serializer.stringify`) (completed 2026-03-15)
- [x] Add `with_json(builder, json_string)` convenience — exists in `request.ki` (completed 2026-03-14)
- [x] Add response helper: `json_body(response) -> Result[Json, JsonError]` using kira-json (completed 2026-03-16)
- [x] Document kira-json imports in `lib.ki` for typed decode/encode workflows (completed 2026-03-16)
- [x] Add tests for `json_body` (completed 2026-03-16)
- [x] All 322 tests passing (completed 2026-03-16)

---

## Risk Register

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Redirect loops (A → B → A) | Medium | Medium | Track visited URLs and detect cycles |
| Relative redirect URLs (Location: /new-path) | Medium | High | Resolve relative URLs against the request URL |
| Cross-origin redirects leaking auth headers | Medium | Medium | Strip Authorization header on cross-origin redirects |

## Timeline

Phase 1 (redirects) → Phase 2 (timeouts) → Phase 3 (JSON).

Phase 1 is the immediate priority since `std.net` deferred redirects to this layer.
