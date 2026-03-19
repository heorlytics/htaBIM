# Launch the htaBIM interactive Shiny dashboard

Opens the `htaBIM` interactive budget impact modelling dashboard in the
default web browser. Requires the `shiny` package to be installed.

## Usage

``` r
launch_shiny(...)
```

## Arguments

- ...:

  Additional arguments passed to
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html).

## Value

Called for its side effect (launches a Shiny app). Returns invisibly.

## Examples

``` r
if (interactive() && requireNamespace("shiny", quietly = TRUE)) {
  launch_shiny()
}
```
