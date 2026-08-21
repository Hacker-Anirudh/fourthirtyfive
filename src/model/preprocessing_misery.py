import pandas as pd


def compute_misery(unemployment_df, inflation_df, output_path=None):
    unemployment = unemployment_df.copy()
    inflation = inflation_df.copy()

    merged = unemployment[["observation_date", "UNRATE"]].merge(
        inflation[["observation_date", "CPIAUCSL"]],
        on="observation_date",
        how="inner",
    )
    merged["misery_index"] = merged["UNRATE"] + merged["CPIAUCSL"]
    merged = merged[["observation_date", "misery_index"]].sort_values("observation_date").reset_index(drop=True)

    if output_path is not None:
        merged.to_csv(output_path, index=False)

    return merged