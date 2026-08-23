# Imports
import pandas as pd
import numpy as np
import os

from xgboost import XGBRegressor
from sklearn.model_selection import RandomizedSearchCV, LeaveOneOut
from sklearn.metrics import mean_absolute_error

from pathlib import Path

# Based on - https://stackoverflow.com/a/51326509
# Posted by Jeroen
# Retrieved 2026-08-23, License - CC BY-SA 4.0

pd.set_option('display.max_columns', 69420)
pd.set_option('display.width', 50)


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
    "subsample": [0.95, 0.9, 0.85, 0.8, 0.75]
}

# find amount of cores
cores = 1
cores = os.cpu_count() # comment out if you get an OOM error

# test them out
idk = LeaveOneOut()
model = XGBRegressor()
search = RandomizedSearchCV(
    estimator=model,
    param_distributions=params,
    n_iter=1000,  # Number of parameter settings sampled
    scoring="neg_mean_absolute_error",
    cv=idk,
    n_jobs=cores,
    random_state=57  # Pass random_state here for reproducibility
)

search.fit(X,y)
df = pd.DataFrame(search.cv_results_)
df["score"] = -df["mean_test_score"]

cols = [f"param_{k}" for k in params.keys()]
print(df[["score"] + cols].sort_values("score").head(10))

# Best result from run: 
