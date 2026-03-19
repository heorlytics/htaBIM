## tests/testthat/helper.R
## Shared helpers loaded automatically by testthat

# Suppress messages during tests (e.g. built-in population lookup messages)
suppressMessages_quietly <- function(expr) {
  suppressMessages(suppressWarnings(expr))
}
