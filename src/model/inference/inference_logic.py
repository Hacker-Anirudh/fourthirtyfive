from pathlib import Path
import numpy as np
import json


def provide_margin(features):
    # Convert features to np array just to be safe
    features = np.array(features, dtype=np.float16)

    # Set up the environment
    project_root = Path(__file__).resolve().parents[3]
    statpath = project_root / "src" / "model" / "inference" / "model.json"

    # scale features
    with open(statpath, 'r', encoding='utf-8') as f:
        params = json.load(f)

    scaler_mean = np.array(params["scaler"]["mean"])
    scaler_scale = np.array(params["scaler"]["scale"])

    scaled_features = (features - scaler_mean) / scaler_scale

    # Run inference
    model_coef = np.array(params["model"]["coefficients"])
    intercept = params["model"]["intercept"]
    pred = np.dot(scaled_features, model_coef) + intercept

    # Return prediction
    return pred


# Quick temporary sanity check
# print(provide_margin([3.3, -14, 8.1]))