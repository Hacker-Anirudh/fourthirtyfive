from pathlib import Path

import pandas as pd


def _default_project_output(filename: str) -> Path:
    project_root = Path(__file__).resolve().parents[2]
    return project_root / "src" / "model" / "data" / "historical" / "processed" / filename


def process_infrate(inflationrate_csv, needed_years, output=None):
    if output is None:
        output = _default_project_output("inflrate.csv")

    inflationrate = pd.read_csv(inflationrate_csv)

    if "observation_date" not in inflationrate.columns:
        raise ValueError("Input inflation CSV must contain an 'observation_date' column.")

    inflationrate["observation_date"] = pd.to_datetime(inflationrate["observation_date"])
    inflationrate = inflationrate[inflationrate["observation_date"].dt.month == 11].copy()
    inflationrate["observation_date"] = inflationrate["observation_date"].dt.year
    inflationrate = inflationrate[inflationrate["observation_date"].isin(needed_years)].copy()
    inflationrate = inflationrate.sort_values("observation_date").reset_index(drop=True)

    output_path = Path(output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    inflationrate.to_csv(output_path, index=False)

    return inflationrate