# htaBIM: Budget Impact Modelling for Health Technology Assessment

The `htaBIM` package implements a structured, reproducible framework for
budget impact modelling (BIM) in health technology assessment (HTA),
following the ISPOR Task Force guidelines.

## Details

### Workflow

A complete `htaBIM` analysis follows five steps:

1.  **Population** – estimate the annual eligible patient population
    using
    [`bim_population()`](https://heorlytics.github.io/htaBIM/reference/bim_population.md)

2.  **Market share** – specify treatment shares with and without the new
    drug using
    [`bim_market_share()`](https://heorlytics.github.io/htaBIM/reference/bim_market_share.md)

3.  **Costs** – build per-patient annual costs by treatment and category
    using
    [`bim_costs()`](https://heorlytics.github.io/htaBIM/reference/bim_costs.md)

4.  **Model** – assemble and run the BIM using
    [`bim_model()`](https://heorlytics.github.io/htaBIM/reference/bim_model.md)

5.  **Outputs** – extract tables, plots, and reports using
    [`bim_table()`](https://heorlytics.github.io/htaBIM/reference/bim_table.md),
    [`plot.bim_model()`](https://heorlytics.github.io/htaBIM/reference/plot.bim_model.md),
    and
    [`bim_report()`](https://heorlytics.github.io/htaBIM/reference/bim_report.md)

### Key references

Sullivan SD, Mauskopf JA, Augustovski F et al. (2014). Budget impact
analysis–principles of good practice: report of the ISPOR 2012 Budget
Impact Analysis Good Practice II Task Force. *Value Health*, 17(1):5-14.
[doi:10.1016/j.jval.2013.08.2291](https://doi.org/10.1016/j.jval.2013.08.2291)

Mauskopf JA, Sullivan SD, Annemans L et al. (2007). Principles of good
practice for budget impact analysis. *Value Health*, 10(5):336-347.
[doi:10.1111/j.1524-4733.2007.00187.x](https://doi.org/10.1111/j.1524-4733.2007.00187.x)

## See also

Useful links:

- <https://github.com/heorlytics/htaBIM>

- <https://heorlytics.github.io/htaBIM>

- Report bugs at <https://github.com/heorlytics/htaBIM/issues>

## Author

**Maintainer**: Shubhram Pandey <shubhram.pandey@heorlytics.com>
([ORCID](https://orcid.org/0009-0005-2303-1592))

Other contributors:

- Heorlytics Ltd \[copyright holder\]
