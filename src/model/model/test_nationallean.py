# Imports
import pandas as pd
import numpy as np

import itertools
from xgboost import XGBRegressor
from sklearn.model_selection import LeaveOneOut
from sklearn.metrics import mean_absolute_error

from pathlib import Path

# Set up the environment
project_root = Path(__file__).resolve().parents[3]
processed_dir = project_root / "src" / "model" / "data" / "historical" / "processed"

data_dir = Path(processed_dir)

# Guard against misalignment in case I mess with the data at some point
X = pd.read_csv(processed_dir / "features.csv")
y = pd.read_csv(processed_dir / "labels.csv")

train_df = X.merge(y, on="year", how="inner").sort_values("year")

target = "national_house_lean"
features = ["misery_index", "approval_rating", "ballot"]

X = train_df[features]
y = train_df[target]

# Find best parameters

# Parameter grid
params = {
    "max_depth" : [2,3,4,5],
    "n_estimators": [25, 50, 75, 100, 125, 150, 175, 200],
    "learning_rate": [0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.1],
    "random_state": [69, 420, 489, 67, 1488, 57, 1, 35293509],
    "subsample": [0.95, 0.9, 0.85, 0.8, 0.75]
}

# test them out
def loo(params):
    lo = LeaveOneOut()
    preds, actuals = [], []
    for train_idx, test_idx in lo.split(X):
        model = XGBRegressor(**params)
        model.fit(X.iloc[train_idx], y.iloc[train_idx])
        preds.append(model.predict(X.iloc[test_idx])[0])
        actuals.append(y.iloc[test_idx].values[0])
    return mean_absolute_error(actuals, preds)

key = list(params.keys())
combinations = list(itertools.product(*params.values()))

results = []
for combo in combinations:
    parames = dict(zip(key, combo))
    scores = [loo(parames)]
    results.append({
        **parames,
        "avg_loo" : sum(scores) / len(scores),
    })

df = pd.DataFrame(results).sort_values("avg_loo")

print(df.head(10))