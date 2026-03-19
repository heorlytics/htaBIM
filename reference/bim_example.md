# Example budget impact model inputs: Disease X

A named list containing example inputs for a hypothetical budget impact
model for a new treatment (Drug A) in a chronic condition (Disease X),
for use in vignettes, examples, and testing. All values are illustrative
only and do not represent any real drug, price, or epidemiological
estimate.

## Usage

``` r
bim_example
```

## Format

A named `list` with three elements:

- `population_params`:

  A `list` of arguments for
  [`bim_population()`](https://heorlytics.github.io/htaBIM/reference/bim_population.md).

- `market_share_params`:

  A `list` of arguments for
  [`bim_market_share()`](https://heorlytics.github.io/htaBIM/reference/bim_market_share.md)
  (excluding `population`).

- `cost_params`:

  A `list` of arguments for
  [`bim_costs()`](https://heorlytics.github.io/htaBIM/reference/bim_costs.md).

## Source

Illustrative values only. Not based on any real submission data.

## Examples

``` r
data(bim_example)
str(bim_example)
#> List of 3
#>  $ population_params  :List of 11
#>   ..$ indication    : chr "IgA Nephropathy (proteinuric, progressive)"
#>   ..$ country       : chr "GB"
#>   ..$ years         : int [1:5] 1 2 3 4 5
#>   ..$ prevalence    : num 0.003
#>   ..$ n_total_pop   : num 4.2e+07
#>   ..$ diagnosed_rate: num 0.6
#>   ..$ treated_rate  : num 0.45
#>   ..$ eligible_rate : num 0.3
#>   ..$ growth_rate   : num 0.005
#>   ..$ approach      : chr "prevalent"
#>   ..$ data_source   : chr "Illustrative -- not from a real submission"
#>  $ market_share_params:List of 7
#>   ..$ treatments    : chr [1:4] "Supportive care / RASi" "Sparsentan" "Sibeprenlimab (new)" "Iptacopan (off-label)"
#>   ..$ new_drug      : chr "Sibeprenlimab (new)"
#>   ..$ shares_current: Named num [1:4] 0.68 0.22 0 0.1
#>   .. ..- attr(*, "names")= chr [1:4] "Supportive care / RASi" "Sparsentan" "Sibeprenlimab (new)" "Iptacopan (off-label)"
#>   ..$ shares_new    : Named num [1:4] 0.54 0.18 0.18 0.1
#>   .. ..- attr(*, "names")= chr [1:4] "Supportive care / RASi" "Sparsentan" "Sibeprenlimab (new)" "Iptacopan (off-label)"
#>   ..$ dynamics      : chr "linear"
#>   ..$ uptake_params :List of 1
#>   .. ..$ ramp_years: num 3
#>   ..$ scenarios     :List of 2
#>   .. ..$ conservative: Named num [1:4] 0.62 0.18 0.1 0.1
#>   .. .. ..- attr(*, "names")= chr [1:4] "Supportive care / RASi" "Sparsentan" "Sibeprenlimab (new)" "Iptacopan (off-label)"
#>   .. ..$ optimistic  : Named num [1:4] 0.44 0.16 0.3 0.1
#>   .. .. ..- attr(*, "names")= chr [1:4] "Supportive care / RASi" "Sparsentan" "Sibeprenlimab (new)" "Iptacopan (off-label)"
#>  $ cost_params        :List of 7
#>   ..$ treatments      : chr [1:4] "Supportive care / RASi" "Sparsentan" "Sibeprenlimab (new)" "Iptacopan (off-label)"
#>   ..$ currency        : chr "GBP"
#>   ..$ price_year      : int 2025
#>   ..$ drug_costs      : Named num [1:4] 220 22400 28800 31200
#>   .. ..- attr(*, "names")= chr [1:4] "Supportive care / RASi" "Sparsentan" "Sibeprenlimab (new)" "Iptacopan (off-label)"
#>   ..$ admin_costs     : Named num [1:4] 0 0 480 0
#>   .. ..- attr(*, "names")= chr [1:4] "Supportive care / RASi" "Sparsentan" "Sibeprenlimab (new)" "Iptacopan (off-label)"
#>   ..$ monitoring_costs: Named num [1:4] 650 1550 1950 1750
#>   .. ..- attr(*, "names")= chr [1:4] "Supportive care / RASi" "Sparsentan" "Sibeprenlimab (new)" "Iptacopan (off-label)"
#>   ..$ ae_costs        : Named num [1:4] 80 210 240 290
#>   .. ..- attr(*, "names")= chr [1:4] "Supportive care / RASi" "Sparsentan" "Sibeprenlimab (new)" "Iptacopan (off-label)"

# Reconstruct the full model
pop   <- do.call(bim_population, bim_example$population_params)
ms    <- do.call(bim_market_share,
                 c(list(population = pop), bim_example$market_share_params))
costs <- do.call(bim_costs, bim_example$cost_params)
model <- bim_model(pop, ms, costs)
summary(model)
#> 
#> == htaBIM Model Summary ==
#> =======================================================
#> Label      : IgA Nephropathy (proteinuric, progressive) BIM
#> Indication : IgA Nephropathy (proteinuric, progressive)
#> Country    : GB
#> Currency   : GBP (2025 prices)
#> New drug   : Sibeprenlimab (new)
#> Payer      : Healthcare system (default)
#> Discount   : 0.0%
#> -------------------------------------------------------
#> Scenario: BASE
#> Year    Budget (curr)    Budget (new)     Impact         
#> 1       GBP 94,770,240   GBP 110,291,920  GBP 15,521,680 
#> 2       GBP 95,259,610   GBP 126,469,240  GBP 31,209,630 
#> 3       GBP 95,723,870   GBP 142,751,790  GBP 47,027,920 
#> 4       GBP 96,190,030   GBP 143,500,890  GBP 47,310,860 
#> 5       GBP 96,679,400   GBP 144,194,360  GBP 47,514,960 
#> 
#> Cumulative impact (5 yrs): GBP 188,585,050
#> 
#> -------------------------------------------------------
#> Scenario: CONSERVATIVE
#> Year    Budget (curr)    Budget (new)     Impact         
#> 1       GBP 94,770,240   GBP 101,990,480  GBP 7,220,240  
#> 2       GBP 95,259,610   GBP 109,774,800  GBP 14,515,190 
#> 3       GBP 95,723,870   GBP 117,604,260  GBP 21,880,390 
#> 4       GBP 96,190,030   GBP 118,199,810  GBP 22,009,780 
#> 5       GBP 96,679,400   GBP 118,771,200  GBP 22,091,800 
#> 
#> Cumulative impact (5 yrs): GBP 87,717,400
#> 
#> -------------------------------------------------------
#> Scenario: OPTIMISTIC
#> Year    Budget (curr)    Budget (new)     Impact         
#> 1       GBP 94,770,240   GBP 121,197,270  GBP 26,427,030 
#> 2       GBP 95,259,610   GBP 148,315,870  GBP 53,056,260 
#> 3       GBP 95,723,870   GBP 175,724,720  GBP 80,000,850 
#> 4       GBP 96,190,030   GBP 176,632,780  GBP 80,442,750 
#> 5       GBP 96,679,400   GBP 177,517,630  GBP 80,838,230 
#> 
#> Cumulative impact (5 yrs): GBP 320,765,120
#> 
```
