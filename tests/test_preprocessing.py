from pathlib import Path

import pandas as pd

from src.model.preprocessing import process_unrate, process_infrate, main
from src.model.preprocessing_misery import compute_misery


def test_process_unrate_filters_november_and_years(tmp_path):
    csv_path = tmp_path / "unrate.csv"
    pd.DataFrame(
        {
            "observation_date": [
                "2000-11-01",
                "2000-12-01",
                "2002-11-01",
                "2004-11-01",
            ],
            "UNRATE": [3.1, 3.2, 5.5, 6.0],
        }
    ).to_csv(csv_path, index=False)

    output_path = tmp_path / "processed_unrate.csv"
    process_unrate(str(csv_path), [2000, 2002, 2004], str(output_path))

    result = pd.read_csv(output_path)
    assert list(result["observation_date"]) == [2000, 2002, 2004]
    assert list(result.columns) == ["observation_date", "UNRATE"]


def test_process_infrate_filters_november_and_years(tmp_path):
    csv_path = tmp_path / "cpi.csv"
    pd.DataFrame(
        {
            "observation_date": [
                "1990-11-01",
                "1990-12-01",
                "1994-11-01",
                "1998-11-01",
            ],
            "CPIAUCSL": [1.0, 1.1, 2.0, 2.5],
        }
    ).to_csv(csv_path, index=False)

    output_path = tmp_path / "processed_infl.csv"
    process_infrate(str(csv_path), [1990, 1994, 1998], str(output_path))

    result = pd.read_csv(output_path)
    assert list(result["observation_date"]) == [1990, 1994, 1998]
    assert list(result.columns) == ["observation_date", "CPIAUCSL"]


def test_compute_misery_combines_inflation_and_unemployment(tmp_path):
    unemployment = pd.DataFrame(
        {
            "observation_date": [2000, 2002],
            "UNRATE": [4.0, 5.0],
        }
    )
    inflation = pd.DataFrame(
        {
            "observation_date": [2000, 2002],
            "CPIAUCSL": [2.0, 3.0],
        }
    )

    result = compute_misery(unemployment, inflation)

    assert list(result.columns) == ["observation_date", "misery_index"]
    assert result["misery_index"].tolist() == [6.0, 8.0]


def test_main_creates_project_relative_outputs(tmp_path):
    project_root = Path(__file__).resolve().parents[1]
    output_dir = project_root / "src" / "model" / "data" / "historical" / "processed"

    main(project_root=project_root)

    assert (output_dir / "unrate.csv").exists()
    assert (output_dir / "inflrate.csv").exists()


def test_process_unrate_defaults_to_project_root_output(tmp_path, monkeypatch):
    project_root = Path(__file__).resolve().parents[1]
    csv_path = tmp_path / "unrate.csv"
    pd.DataFrame(
        {
            "observation_date": ["2000-11-01", "2002-11-01"],
            "UNRATE": [4.0, 5.0],
        }
    ).to_csv(csv_path, index=False)

    monkeypatch.chdir(tmp_path)
    process_unrate(str(csv_path), [2000, 2002])

    expected = project_root / "src" / "model" / "data" / "historical" / "processed" / "unrate.csv"
    assert expected.exists()
    assert pd.read_csv(expected)["observation_date"].tolist() == [2000, 2002]


def test_merge_combines_yearly_feature_tables(tmp_path):
    processed_dir = tmp_path / "processed"
    processed_dir.mkdir()

    pd.DataFrame({"observation_date": [2000, 2002], "misery_index": [4.0, 6.0]}).to_csv(
        processed_dir / "misery.csv", index=False
    )
    pd.DataFrame({"observation_date": [2000, 2002], "approval": [55.0, 50.0]}).to_csv(
        processed_dir / "pres_approval.csv", index=False
    )
    pd.DataFrame({"observation_date": [2000, 2002], "generic_ballot": [1.0, -1.0]}).to_csv(
        processed_dir / "generic_ballot_midterms.csv", index=False
    )

    merge(
        processed_dir=processed_dir,
        misery_path="misery.csv",
        approval_path="pres_approval.csv",
        ballot_path="generic_ballot_midterms.csv",
        output_path="features.csv",
        year_column="observation_date",
    )

    result = pd.read_csv(processed_dir / "features.csv")
    assert list(result.columns) == ["year", "misery_index", "approval", "generic_ballot"]
    assert result["year"].tolist() == [2000, 2002]
