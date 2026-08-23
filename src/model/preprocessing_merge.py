from pathlib import Path

import pandas as pd


def _normalize_year_column(df, year_column="observation_date"):
    candidates = [year_column, "observation_date", "year", "Year"]
    for candidate in candidates:
        if candidate in df.columns:
            return df.rename(columns={candidate: "year"})
    raise KeyError(f"No year-like column found in dataframe columns: {list(df.columns)}")


def merge(
    processed_dir=None,
    misery_path="misery.csv",
    approval_path="pres_approval.csv",
    ballot_path="generic_ballot_midterms.csv",
    output_path="features.csv",
    year_column="observation_date",
):
    if processed_dir is None:
        project_root = Path(__file__).resolve().parents[2]
        processed_dir = project_root / "src" / "model" / "data" / "historical" / "processed"
    processed_dir = Path(processed_dir)
    processed_dir.mkdir(parents=True, exist_ok=True)

    misery = _normalize_year_column(pd.read_csv(processed_dir / misery_path), year_column)
    approval = _normalize_year_column(pd.read_csv(processed_dir / approval_path), year_column)
    ballot = _normalize_year_column(pd.read_csv(processed_dir / ballot_path), year_column)

    merged = misery.copy()
    for data in [approval, ballot]:
        merged = merged.merge(data, on="year", how="outer")

    merged = merged.sort_values("year").reset_index(drop=True)
    output_file = processed_dir / output_path
    merged.to_csv(output_file, index=False)
    return merged