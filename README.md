# split-tests

[![Smoke Tests](https://github.com/scruplelesswizard/split-tests/actions/workflows/smoke-tests.yaml/badge.svg)](https://github.com/scruplelesswizard/split-tests/actions/workflows/smoke-tests.yaml)
[![Latest release](https://img.shields.io/github/v/release/scruplelesswizard/split-tests)](https://github.com/scruplelesswizard/split-tests/releases)

_GitHub Action for splitting a test suite into equal time groups for parallel execution._

## Introduction

This action splits a suite of tests so they can run in parallel across a fleet of runners. The goal is to reduce developer feedback time by distributing the load evenly, so no single runner is left running the slow tests while the others sit idle.

- **Any test runner.** The action only decides which test _files_ each runner gets, and outputs them as a space-separated string. Pass that string to RSpec, pytest, Jest, `go test` or anything else.
- **Three ways to split:** by file count, by line count, or by real durations from a previous JUnit report.
- **Pinned and checksummed.** The `split_tests` binary is pinned to a specific release and verified by SHA256. A weekly workflow opens a PR when upstream releases a new version.

Runs on `ubuntu` (Linux) runners only, because `split_tests` is installed as a Linux binary.

## Quick start

```yaml
- uses: actions/checkout@v4
- uses: scruplelesswizard/split-tests@v1
  id: split
  with:
    glob: "test/**/*_test.py"
    split-total: 4
    split-index: ${{ matrix.index }}   # 0..3, one per matrix job
- run: pytest ${{ steps.split.outputs.test-suite }}
```

The `glob` default is `spec/**/*_spec.rb` (RSpec), so set it for other languages. See the full matrix example [below](#example-workflow).

## Usage

### Splitting Methods

#### File Count (Default)

This is a naive split into an even number of files per group. It is the default splitting method.

#### Line Count

Another naive split, but this time based on the number of lines per test. It is used by setting `line-count: true`

#### JUnit Report

This is the most intelligent split mechanism, using previous execution durations for each test from the JUnit report. It is used by setting the `junit-path` to the location of a previous execution's JUnit results report in your repository

Timings must be per test **file**. If your runner writes one report per worker, or per-test-case reports, merge them first with [junit-munger](https://github.com/scruplelesswizard/junit-munger), then point `junit-path` at the merged file.

### Inputs

|      NAME      |                         DESCRIPTION                           |   TYPE    | REQUIRED |       DEFAULT       |
|----------------|---------------------------------------------------------------|-----------|----------|---------------------|
| `split-index`  | Index of this instance executing the tests                    | `integer` | ✅       |                     |
| `split-total`  | Total number of instances executing the tests                 | `integer` | ✅       |                     |
| `glob`         | Glob pattern to find test files (default "spec/**/*_spec.rb") | `string`  |          | `spec/**/*_spec.rb` |
| `exclude-glob` | Glob pattern to exclude test files                            | `string`  |          | `""`                |
| `junit-path`   | Path to a JUnit XML report to use for test timings            | `string`  |          | `""`                |
| `line-count`   | Use line count to estimate test duration                      | `bool`    |          | `false`             |

### Outputs

|      NAME      |                            DESCRIPTION                         |   TYPE   |
|----------------|----------------------------------------------------------------|----------|
| `test-suite`   | A subset of tests, based on the the split index and split type | `string` |
| `split-index`  | Index of this instance executing the tests                     | `number` |
| `split-total`  | Total number of instances executing the tests                  | `number` |

### Example Workflow

```yaml
env:
  total-runners: 5

jobs:
  runner-indexes:
    runs-on: ubuntu-latest
    name: Generate runner indexes
    outputs:
      json: ${{ steps.generate-index-list.outputs.json }}
    steps:
      - id: generate-index-list
        run: |
          MAX_INDEX=$((${{ env.total-runners }}-1))
          INDEX_LIST=$(seq 0 ${MAX_INDEX})
          INDEX_JSON=$(jq --null-input --compact-output '. |= [inputs]' <<< ${INDEX_LIST})
          echo "json=${INDEX_JSON}" >> "$GITHUB_OUTPUT"

  run-parallel-tests:
    runs-on: ubuntu-latest
    name: "Runner #${{ matrix.runner-index }}: Run test suite in parallel"
    needs:
      - runner-indexes
    strategy:
      matrix:
        runner-index: ${{ fromjson(needs.runner-indexes.outputs.json) }}
    steps:
      - uses: actions/checkout@v4
      - uses: scruplelesswizard/split-tests@v1
        id: split-tests
        name: Split tests
        with:
          glob: examples/spec/**/*_spec.rb
          split-total: ${{ env.total-runners }}
          split-index: ${{ matrix.runner-index }}
      - run: 'echo "This runner will execute the following tests: ${{ steps.split-tests.outputs.test-suite }}"'
```

The complete workflow can be found at [.github/workflows/example.yaml](.github/workflows/example.yaml)

## Dependencies

This action uses [leonid-shevtsov/split_tests](https://github.com/leonid-shevtsov/split_tests) under-the-hood to accomplish the test splitting
