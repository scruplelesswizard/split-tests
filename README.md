# split-tests

_Github Action for splitting a test suite into equal time groups for parallel execution._

## Introduction

This actions allows you to split up a suite of tests so they can be executed in parallel across a fleet of runners. The overall goal is to reduce developer feedback time by distributing the load.

## Usage

### Splitting Methods

#### File Count (Default)

This is a naive split into an even number of files per group. It is the default splitting method.

#### Line Count

Another naive split, but this time based on the number of lines per test. It is used by setting `line-count: true`

#### JUnit Report

This is the most intelligent split mechanism, using previous execution durations for each test from the JUnit report. It is used by setting the `junit-path` to the location of a previous execution's JUnit results report in your repository

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
          echo "::set-output name=json::${INDEX_JSON}"

  run-parallel-tests:
    runs-on: ubuntu-latest
    name: "Runner #${{ matrix.runner-index }}: Run test suite in parallel"
    needs:
      - runner-indexes
    strategy:
      matrix:
        runner-index: ${{ fromjson(needs.runner-indexes.outputs.json) }}
    steps:
      - uses: actions/checkout@v2
      - uses: chaosaffe/split-tests@v1-alpha.1
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
