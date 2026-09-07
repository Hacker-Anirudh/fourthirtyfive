""" This trains the ridge regressor on the preprocessed data. """
from pathlib import Path
import json

import pandas as pd
import numpy as np

from sklearn.linear_model import RidgeCV
from sklearn.preprocessing import StandardScaler

# Set up the environment
project_root = Path(__file__).resolve().parents[3]
processed_dir = project_root / "src" / "model" / "data" / "historical" / "processed"
artifacts = project_root / "src" / "model" / "inference"

data_dir = Path(processed_dir)

# Guard against misalignment in case I mess with the data at some point
X = pd.read_csv(processed_dir / "features.csv")
y = pd.read_csv(processed_dir / "labels.csv")

train_df = X.merge(y, on="year", how="inner").sort_values("year")

TARGET = "national_house_lean"
FEATURES = ["misery_index", "approval_rating", "ballot"]

X = train_df[FEATURES]
y = train_df[TARGET]

# Find ideal alpha
alphas = np.logspace(-2, 3, 100)
ridgecv = RidgeCV(alphas=alphas, cv=None, scoring="neg_mean_squared_error")

# Scale features
scaler = StandardScaler()
X = scaler.fit_transform(X)

# Train the model
ridgecv.fit(X,y)

#Sanity check

# This test an environment that should produce a comfortable Republican wins
# and a Democratic landslide, respectively.
prediction_input = scaler.transform(pd.DataFrame([[-2.0, -5, -5.1]], columns=FEATURES))
dem_prediction_input = scaler.transform(pd.DataFrame([[55, 45, 15]],columns=FEATURES))

dem_pred = ridgecv.predict(dem_prediction_input)
rep_pred = ridgecv.predict(prediction_input)

print(f"This should be negative (Republican leaning): {rep_pred[0]}")
print(f"This should be very positive (landslide Democratic): {dem_pred[0]}\n")
print("Below is the weightage of the features")
for name, coef in zip(FEATURES, ridgecv.coef_):
    print(f"{name}: {coef:.4f}")

# Export scaler and model itself
pipeline = {
    "scaler": {
        "mean" : scaler.mean_.tolist(),
        "scale" : scaler.scale_.tolist(),
        "var" : scaler.var_.tolist(),
        "feature_names" : FEATURES,
    },
    "model": {
        "alpha": float(ridgecv.alpha_),
        "coefficients": ridgecv.coef_.tolist(),
        "intercept": float(ridgecv.intercept_),
        "target": TARGET,
    }
}

with open(artifacts / "model.json", "w", encoding="utf8") as f:
    json.dump(pipeline, f, indent=4)

print(f"Exported model and scaler to {artifacts / "model.json"}")
