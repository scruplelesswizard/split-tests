# split-tests

_Github Action for splitting a test suite using [leonid-shevtsov/split_tests](https://github.com/leonid-shevtsov/split_tests)  into equal time groups for running in parallel._

## Introduction

This actions allows you to split up a suite of tests so they can be executed in parallel across a fleet of runners. The overall goal is to reduce developer feedback time by distributing the load.

## Usage

### Inputs

|      NAME      |                         DESCRIPTION                           |   TYPE   | REQUIRED |       DEFAULT       |
|----------------|---------------------------------------------------------------|----------|----------|---------------------|
| `split-index`  | Index of this instance executing the tests                    | `number` | `true`   | `N/A`               |
| `split-total`  | Total number of instances executing the tests                 | `number` | `true`   | `N/A`               |
| `glob`         | Glob pattern to find test files (default "spec/**/*_spec.rb") | `string` | `false`  | `spec/**/*_spec.rb` |
| `exclude-glob` | Glob pattern to exclude test files                            | `string` | `false`  | `N/A`               |
| `junit-path`   | Path to a JUnit XML report to use for test timings            | `string` | `false`  | `N/A`               |
| `line-count`   | Use line count to estimate test times                         | `bool`   | `false`  | `N/A`               |

### Outputs

|      NAME      |                            DESCRIPTION                         |   TYPE   |
|----------------|----------------------------------------------------------------|----------|
| `test-suite`   | A subset of tests, based on the the split index and split type | `string` |
| `split-index`  | Index of this instance executing the tests                     | `number` |
| `split-total`  | Total number of instances executing the tests                  | `number` |

### Example Workflow

```yaml

```
