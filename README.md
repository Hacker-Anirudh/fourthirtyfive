# FourThirtyFive
My attempt at predicting the results of the 2026 United States general election (aka the "midterms").

If you have a better idea for the naming, please tell me.

# Current scope
After considering it, I decided not to include House elections. This is both because I'm lazy and because in a highly polarized midterm like this I don't think they'd diverge much from the upballot races. It still includes seperate Governor and Senate predictions since Senate races are more nationalized and more importantly, they're both prominent enough that a big scandal can affect them significantly (see the Vivek Ramaswamy ad-scandel for example). Try it out [here](https://fourthirtyfive.sudothelinuxwizard.com/).

The reason it may seem that states are "missing" from the prediction is because unlike a presidential race, senatorial and gubernatorial elections are not all held on the same year. For example, Arkansas holds their gubernatorial election every midterm, North Carolina holds theirs with every presidential race, and Virginia holds them the year after each presidential year. Same things goes for senatorial races, because senators are elected in three "classes", so every 2 years only 1/3rd of seats face an election barring special elections.

# Model architecture
This project is a two-part system:

- A Python forecasting pipeline that turns historical political and economic data into a national lean estimate.
- A Flutter dashboard (Material Design) that consumes the model output and visualizes state-by-state forecasts with a date-based polling weighting adjustment.

## Rough forecast logic
The implementation follows a simple structure:

- National lean:
  - lean = intercept + w1 * misery_index + w2 * approval_rating + w3 * generic_ballot
  - The model itself is a simple ridge regressor.

- State-level forecast:
  - state_margin = (2 * pvi_2022) + national_lean + candidate_quality + polling_adjustment

This is intentionally lightweight and explainable: the model is not trying to be a huge black box. It is a transparent forecast system built from macroeconomic conditions, partisan baseline, and polling pressure as election day nears.

A flaw I've noted is that the national lean model weights the two factors besides generic ballot extremely lightly, which makes the whole model sort of redundant, however, I don't believe it makes accuracy worse, so I kept it.

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
