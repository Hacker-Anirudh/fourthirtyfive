# !! Currently broken !!
# No plans to fix, transitioning to ridge regression

# Imports
import pandas as pd
import numpy as np

from xgboost import XGBRegressor

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

# Train the actual model
print("Training model:")
params = dict(
    max_depth=5,
    n_estimators=125,
    learning_rate=0.03,
    subsample=0.9,
    random_state=42,
)

model = XGBRegressor(**params)
model.fit(X,y)

# Quick sanity check
print("Done training model.")
prediction_input = pd.DataFrame(
    [[3, -5,3.3]],
    columns=features,
)
trump = model.predict(prediction_input)
print(f"Model predicts {trump}% national lean in 2026.")

# Export model 
model.save_model("prediction_model.json")
print("Exported model to prediction_model.json")