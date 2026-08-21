from pathlib import Path

import pandas as pd


def _default_project_output(filename: str) -> Path:
    project_root = Path(__file__).resolve().parents[2]
    return project_root / "src" / "model" / "data" / "historical" / "processed" / filename


def process_unrate(unemployment_csv, needed_years, output_path=None):
    if output_path is None:
        output_path = _default_project_output("unrate.csv")

    unemployment = pd.read_csv(unemployment_csv)

    if "observation_date" not in unemployment.columns:
        raise ValueError("Input unemployment CSV must contain an 'observation_date' column.")

    unemployment["observation_date"] = pd.to_datetime(unemployment["observation_date"])
    unemployment = unemployment[unemployment["observation_date"].dt.month == 11].copy()
    unemployment["observation_date"] = unemployment["observation_date"].dt.year
    unemployment = unemployment[unemployment["observation_date"].isin(needed_years)].copy()
    unemployment = unemployment.sort_values("observation_date").reset_index(drop=True)

    output = Path(output_path)
    output.parent.mkdir(parents=True, exist_ok=True)
    unemployment.to_csv(output, index=False)

    return unemployment