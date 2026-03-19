## data-raw/bim_example.R
## Run this script to regenerate data/bim_example.rda
## (not part of the built package — listed in .Rbuildignore)

bim_example <- list(

  population_params = list(
    indication     = "Disease X",
    country        = "GB",
    years          = 1:5,
    prevalence     = 0.003,
    n_total_pop    = 42e6,
    diagnosed_rate = 0.60,
    treated_rate   = 0.45,
    eligible_rate  = 0.30,
    growth_rate    = 0.005,
    approach       = "prevalent",
    data_source    = "Illustrative — not from a real submission"
  ),

  market_share_params = list(
    treatments = c(
      "Drug C (SoC)",
      "Drug B",
      "Drug A (new)",
      "Drug D"
    ),
    new_drug       = "Drug A (new)",
    shares_current = c(
      "Drug C (SoC)" = 0.68,
      "Drug B"       = 0.22,
      "Drug A (new)" = 0.00,
      "Drug D"       = 0.10
    ),
    shares_new = c(
      "Drug C (SoC)" = 0.54,
      "Drug B"       = 0.18,
      "Drug A (new)" = 0.18,
      "Drug D"       = 0.10
    ),
    dynamics      = "linear",
    uptake_params = list(ramp_years = 3),
    scenarios = list(
      conservative = c(
        "Drug C (SoC)" = 0.62,
        "Drug B"       = 0.18,
        "Drug A (new)" = 0.10,
        "Drug D"       = 0.10
      ),
      optimistic = c(
        "Drug C (SoC)" = 0.44,
        "Drug B"       = 0.16,
        "Drug A (new)" = 0.30,
        "Drug D"       = 0.10
      )
    )
  ),

  cost_params = list(
    treatments = c(
      "Drug C (SoC)",
      "Drug B",
      "Drug A (new)",
      "Drug D"
    ),
    currency   = "GBP",
    price_year = 2025L,
    drug_costs = c(
      "Drug C (SoC)" =   220,
      "Drug B"       = 22400,
      "Drug A (new)" = 28800,
      "Drug D"       = 31200
    ),
    admin_costs = c(
      "Drug C (SoC)" =     0,
      "Drug B"       =     0,
      "Drug A (new)" =   480,
      "Drug D"       =     0
    ),
    monitoring_costs = c(
      "Drug C (SoC)" =   650,
      "Drug B"       =  1550,
      "Drug A (new)" =  1950,
      "Drug D"       =  1750
    ),
    ae_costs = c(
      "Drug C (SoC)" =   80,
      "Drug B"       =  210,
      "Drug A (new)" =  240,
      "Drug D"       =  290
    )
  )
)

save(bim_example, file = "data/bim_example.rda", compress = "bzip2")
message("bim_example.rda saved.")
