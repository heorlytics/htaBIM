## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

* local Ubuntu 24.04, R 4.3.3
* GitHub Actions: ubuntu-latest (R release + R devel)
* GitHub Actions: windows-latest (R release)
* GitHub Actions: macos-latest (R release)
* win-builder: R-release, R-devel

## Downstream dependencies

This is a new submission — there are no downstream dependencies.

## Notes

* The package uses only base R in `Imports` (stats, utils, grDevices, graphics).
  All feature-enhancing packages (ggplot2, shiny, officer, etc.) are in
  `Suggests` and are loaded with `requireNamespace()` checks.

* All examples run in under 5 seconds. Slow examples are wrapped in
  `\dontrun{}`.

* The `bim_example` dataset is 13 KB compressed.

* No internet access is required at any point.

## CRAN policy compliance

* No `T`/`F` used for `TRUE`/`FALSE`.
* No `library()` or `require()` calls inside package functions.
* No modification of global state (no `options()`, `par()` changes retained).
* `on.exit()` used to restore `par()` in all plot functions.
* No `cat()` or `print()` in non-interactive functions (only in S3 print/summary methods).
