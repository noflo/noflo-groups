# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## [2.0.0-alpha.1] - 2026-10-09

### Added

- The package is renamed to `@noflo/groups`; graph component identifiers are unaffected and keep resolving under the `groups/` namespace

### Changed

- All 18 components are converted from CoffeeScript to modern JavaScript ES modules for NoFlo 2.x (esm-only), with TypeScript-checked sources and Biome formatting
- Components follow the 2.x Process API contract: preconditions are checked with `has`/`hasData`/`hasStream` before any `get`/`getData` call, and per-scope, per-connection state is kept in Maps cleared on `tearDown`
- `GenerateGroup` uses the Web-standard `crypto.randomUUID()` instead of the `uuid` package, which is dropped. The 1.x `noflo-core` runtime dependency is also dropped: the `ObjectifyByGroup` graph resolves `core/Split` from whatever the host application has installed, per the 2.x cross-library component discovery
- The `ObjectifyByGroup` graph's exported ports are renamed to lowercase (`in`, `regexp`, `out`) to satisfy the 2.x port-name validation, and the redundant empty-component `Regexp()` edge is replaced by a second edge from the `Regexp` Split node. Consuming graphs that wire the uppercase export names need updating
- Forwarded packets no longer carry the source connection index, matching the 2.x rule that non-addressable out ports reject indexed sends

### Fixed

- Test suite rebuilt on `@noflo/fbp-spec-runner` (fbp-spec YAML cases) and `node:test` (68 tests), replacing the Mocha CoffeeScript suite
