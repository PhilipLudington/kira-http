# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

See `kira-toolkit/reference/REFERENCE.md` for Kira coding guidelines.

## Project Overview

kira-http is an HTTP client/server library for the Kira programming language. It leverages Kira's effect system to track all network IO operations explicitly.

**Status:** Design/specification phase. The `DESIGN.md` contains the complete API specification.

**Dependencies:**
- kira-json (JSON serialization)
- kira-pcl (URL parsing)

## Kira Language Essentials

Kira is a functional language with explicit effect tracking:

- **Pure by default**: Functions without `effect` cannot perform IO
- **Effect functions**: Use `effect fn` for IO operations, return type is `IO[T]`
- **Explicit types**: All bindings require type annotations: `let x: i32 = 42`
- **Explicit return**: All functions must use `return` statements
- **Sum types**: `type Option[T] = | Some(T) | None`
- **Product types**: `type Point = { x: f64, y: f64 }`
- **File extension**: `.ki`

## Project Structure (Intended)

```
kira-http/
├── src/
│   ├── lib.ki          # Main exports
│   ├── types.ki        # Method, Status, Request, Response
│   ├── client.ki       # HTTP client (get, post, put, delete)
│   ├── server.ki       # HTTP server (serve, serveRoutes)
│   ├── request.ki      # RequestBuilder pattern
│   ├── response.ki     # Response helpers (ok, created, notFound)
│   ├── router.ki       # Route matching, path params
│   ├── middleware.ki   # Middleware type and helpers
│   ├── status.ki       # Status code utilities
│   ├── headers.ki      # Header utilities
│   └── url.ki          # URL parsing
├── examples/           # Usage examples
└── tests/              # Test files (test_<module>.ki)
```

## Development Commands

Available Claude Code skills for this project:

| Command | Purpose |
|---------|---------|
| `/kira-check` | Validate structure, syntax, types, patterns, tests |
| `/kira-review` | Full code review against standards |
| `/kira-safety` | Security-focused review |
| `/kira-init` | Create new Kira project structure |

## Running Tests

Always use the GitStat wrapper script to run tests:

```bash
./run-tests.sh
```

Do NOT run `kira test` directly - use the wrapper script to preserve GitStat integration and result tracking.

The wrapper runs all test files in `tests/` and writes results to `.test-results.json`.

To run a single test file for debugging:

```bash
kira test tests/test_types.ki
```

**Note:** Requires Kira v0.2.0+ with module system support (`import` statements).

## Standards

This project uses Kira-Toolkit v0.1.0. Rule files in `.claude/rules/` cover:

- **Naming**: Types `PascalCase`, functions `snake_case`, constants `UPPER_SNAKE_CASE`
- **Purity**: Pure functions cannot call effectful code
- **Pattern matching**: Must be exhaustive
- **Errors**: Fallible operations return `Result[T, E]`, use `?` for propagation
- **API design**: Max 4 parameters, use config records for more
- **Testing**: One test file per module, name tests `test_<function>_<scenario>`
- **Security**: Validate all external input, no shell injection, no secrets in logs

Quick reference: `kira-toolkit/reference/REFERENCE.md`
Full standards: `kira-toolkit/reference/STANDARDS.md`

## Key Architectural Patterns

### Effect Tracking

Network operations are effectful and must be marked:
```kira
// Effectful - performs network IO
effect fn get(url: string) -> Result[Response, HttpError]

// Pure - no IO
fn withHeader(builder: RequestBuilder, name: string, value: string) -> RequestBuilder
```

### Request Builder Pattern

Complex requests use a builder with method chaining via pipe operator:
```kira
http.newRequest(POST, url)
    |> http.withHeader("Content-Type", "application/json")
    |> http.withBody(data)
    |> http.send()
```

### Route Parameters

Routes support `:param` syntax for path parameters:
- `/users/:id` extracts `id` from URL
- Access via `http.pathParam(req, "id")`
