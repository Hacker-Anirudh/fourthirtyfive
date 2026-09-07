""" This combines the YoY inflation rate and the unemployment rate to get a basic "misery index" """
import pandas as pd


def compute_misery(unemployment_df, inflation_df, output_path=None):
    """This does the heavy lifting!"""
    dem_years = [1978, 1994, 1998, 2010, 2014, 2022]
    unemployment = unemployment_df.copy()
    inflation = inflation_df.copy()

    unemployment["UNRATE"] = pd.to_numeric(unemployment["UNRATE"])
    inflation["CPIAUCNS"] = pd.to_numeric(inflation["CPIAUCNS"])

    merged = unemployment[["observation_date", "UNRATE"]].merge(
        inflation[["observation_date", "CPIAUCNS"]],
        on="observation_date",
        how="inner",
    )
    merged["misery_index"] = merged["UNRATE"] + merged["CPIAUCNS"]
    merged = merged[["observation_date",
                     "misery_index"]].sort_values("observation_date").reset_index(drop=True)
    print(merged["misery_index"].mean())
    merged["misery_index"] = merged["misery_index"] - merged["misery_index"].mean()

    # Invert the sign for years with an incumbent Republican POTUS
    mask = pd.to_numeric(merged["observation_date"]).astype(int).isin(dem_years)
    merged.loc[mask, "misery_index"] = merged.loc[mask, "misery_index"] * -1

    if output_path is not None:
        merged.to_csv(output_path, index=False)

    return merged
