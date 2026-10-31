# FourThirtyFive
My attempt at predicting the results of the 2026 United States general election (aka the "midterms").

If you have a better idea for the naming, please tell me.

# Current scope
At present, this project only predicts the results of the US Senate races, as I believe them to be the most interesting. If this is well received and after further feedback I will be adding gubernatorial/House races as well, using the same general style and methodology (in fact, the national_lean model itself can be reused).

# Model architecture
This project is a two-part system:

- A Python forecasting pipeline that turns historical political and economic data into a national lean estimate.
- A Flutter dashboard that consumes the model output and visualizes state-by-state forecasts with a date-based polling weighting adjustment.

## Rough forecast logic
The implementation follows a simple structure:

- National lean:
  - lean = intercept + w1 * misery_index + w2 * approval_rating + w3 * generic_ballot

- State-level forecast:
  - state_margin = (2 * pvi_2022) + national_lean + candidate_quality + polling_adjustment

This is intentionally lightweight and explainable: the model is not trying to be a huge black box. It is a transparent forecast system built from macroeconomic conditions, partisan baseline, and polling pressure as election day nears.

## Repository layout

- `src/model/` — data prep, training, and inference code
- `src/model/data/historical/` — raw historical data and processed feature files
- `src/model/inference/` — the serialized model and current runtime inputs
- `src/interface/lib/` — Flutter forecast UI and logic
- `src/interface/inference/` — bundled forecast assets used by the app

The model is designed to be understandable and editable: the data pipeline, model training logic, and UI are separated into distinct components instead of being embedded in a single script.

## Polling and stats updates
Polling and the current_stats are updated daily for the most competetive races, and weekly for the rest.
While the data is sourced from others, I believe the almost purely data-driven approach of this model with little subjectivity should in theory yield better results. Whether I turn out to be right remains to be seen!
