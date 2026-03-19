# htaBIM <img src="man/figures/logo.png" align="right" height="139" alt="" />

<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/htaBIM)](https://CRAN.R-project.org/package=htaBIM)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/metaSurvival)](https://CRAN.R-project.org/package=metaSurvival)
[![R-CMD-check](https://github.com/Heorlytics/htaBIM/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Heorlytics/htaBIM/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

### Download stats for CRAN

<!-- badges: start -->

[![](http://cranlogs.r-pkg.org/badges/grand-total/htaBIM?color=orange)](https://cran.r-project.org/package=htaBIM)
[![](http://cranlogs.r-pkg.org/badges/last-month/htaBIM?color=orange)](https://cran.r-project.org/package=htaBIM)
[![](http://cranlogs.r-pkg.org/badges/last-week/htaBIM?color=orange)](https://cran.r-project.org/package=htaBIM)
<!-- badges: end -->

## Overview

**htaBIM** provides a complete, reproducible framework for **budget impact
modelling (BIM)** in health technology assessment (HTA), following the [ISPOR
Task Force guidelines](https://doi.org/10.1016/j.jval.2013.08.2291).

It replaces error-prone Excel-based BIM workbooks with structured, auditable R
workflows that produce submission-quality outputs for NICE, CADTH, and EU-HTA
dossiers.

### Key features

- 📊 **Epidemiology-driven population estimation** — prevalent, incident, or combined approaches with an eligibility funnel
- 📈 **Flexible market share modelling** — constant, linear ramp, logistic S-curve, or step uptake dynamics
- 💊 **Multi-category cost inputs** — drug, administration, monitoring, adverse events, with rebate support
- 🔄 **Multi-year projections** — annual and cumulative budget impact across scenarios
- 🏥 **Pre-built payer perspectives** — NHS England, CADTH, US commercial, or custom
- 📉 **Deterministic sensitivity analysis** — DSA with tornado diagrams
- 📋 **Submission-ready outputs** — formatted tables, plots, and text/HTML reports
- 🖥️ **Interactive Shiny dashboard** — `launch_shiny()` for stakeholder communication

---

## Installation

```r
# From CRAN
install.packages("htaBIM")

# Development version from GitHub
# install.packages("pak")
pak::pkg_install("Heorlytics/htaBIM")
```

---

## Quick start

```r
library(htaBIM)

# Step 1: Define eligible population
pop <- bim_population(
  indication     = "IgA Nephropathy",
  country        = "custom",
  years          = 1:5,
  prevalence     = 0.003,
  n_total_pop    = 42e6,
  diagnosed_rate = 0.60,
  treated_rate   = 0.45,
  eligible_rate  = 0.30
)

# Step 2: Define market shares
ms <- bim_market_share(
  population     = pop,
  treatments     = c("Standard of Care", "New Drug"),
  new_drug       = "New Drug",
  shares_current = c("Standard of Care" = 1.0, "New Drug" = 0.0),
  shares_new     = c("Standard of Care" = 0.8, "New Drug" = 0.2),
  dynamics       = "linear",
  uptake_params  = list(ramp_years = 3)
)

# Step 3: Define costs
costs <- bim_costs(
  treatments = c("Standard of Care", "New Drug"),
  currency   = "GBP",
  drug_costs = c("Standard of Care" = 1500, "New Drug" = 28000)
)

# Step 4: Assemble and run
model <- bim_model(pop, ms, costs, payer = bim_payer_nhs())
summary(model)

# Step 5: Visualise and report
plot(model, type = "line")
plot(model, type = "bar")
bim_report(model)
```

---

## Shiny dashboard

Launch the interactive dashboard for stakeholder presentations:

```r
# Requires shiny to be installed
install.packages("shiny")
launch_shiny()
```

---

## ISPOR alignment

`htaBIM` implements the methodology described in:

> Sullivan SD, Mauskopf JA, Augustovski F et al. (2014). Budget impact
> analysis—principles of good practice: report of the ISPOR 2012 Budget
> Impact Analysis Good Practice II Task Force. *Value in Health*, 17(1):5–14.
> doi:[10.1016/j.jval.2013.08.2291](https://doi.org/10.1016/j.jval.2013.08.2291)

> Mauskopf JA, Sullivan SD, Annemans L et al. (2007). Principles of good
> practice for budget impact analysis. *Value in Health*, 10(5):336–347.
> doi:[10.1111/j.1524-4733.2007.00187.x](https://doi.org/10.1111/j.1524-4733.2007.00187.x)

---

## Citation

```r
citation("htaBIM")
```

```
Pandey S (2026). htaBIM: Budget Impact Modelling for Health Technology
Assessment. R package version 0.1.0.
https://github.com/Heorlytics/htaBIM
```

---

## Contributing

Contributions, bug reports, and feature requests are welcome via
[GitHub Issues](https://github.com/Heorlytics/htaBIM/issues).

---

## Licence

MIT © 2026 Heorlytics Ltd
