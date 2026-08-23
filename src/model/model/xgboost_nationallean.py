# !! Currently broken !!

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
params = dict(
    n_estimators=150
    max_depth=4
    learning_rate=0.07
    subsample=1.0
    colsample_bytree=1.0
    reg_lambda=1.3
    random_state=1984
)

model = 