from pathlib import Path
import shutil
import sys

if __package__ in (None, ""):
    project_root = Path(__file__).resolve().parents[2]
    if str(project_root) not in sys.path:
        sys.path.insert(0, str(project_root))

from src.model.preprocessing_inflationrate import process_infrate
from src.model.preprocessing_unrate import process_unrate
from src.model.preprocessing_misery import compute_misery


def _copy_if_present(source_path: Path, destination_path: Path) -> None:
    if source_path.exists():
        destination_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source_path, destination_path)


def main(project_root=None):
    if project_root is None:
        project_root = Path(__file__).resolve().parents[2]
    project_root = Path(project_root)

    historical_dir = project_root / "src" / "model" / "data" / "historical"
    processed_dir = historical_dir / "processed"
    processed_dir.mkdir(parents=True, exist_ok=True)

    for generated_file in [
        processed_dir / "unrate.csv",
        processed_dir / "inflrate.csv",
        processed_dir / "misery.csv",
        processed_dir / "national_lean_midterms.csv",
        processed_dir / "state_pvi_midterms.csv",
        processed_dir / "pres_approval.csv",
    ]:
        if generated_file.exists():
            generated_file.unlink()

    _copy_if_present(historical_dir / "national_lean_midterms.csv", processed_dir / "national_lean_midterms.csv")
    _copy_if_present(historical_dir / "state_pvi_midterms.csv", processed_dir / "state_pvi_midterms.csv")
    _copy_if_present(historical_dir / "pres_approval.csv", processed_dir / "pres_approval.csv")
    _copy_if_present(historical_dir / "generic_ballot_midterms_1978_2022.csv", processed_dir / "generic_ballot_midterms.csv")

    needed_years = [1978, 1982, 1986, 1990, 1994, 1998, 2002, 2006, 2010, 2014, 2018, 2022]
    unemployment_df = process_unrate(
        historical_dir / "fredgraph.csv",
        needed_years,
        processed_dir / "unrate.csv",
    )
    inflation_df = process_infrate(
        historical_dir / "CPIAUCSL.csv",
        needed_years,
        processed_dir / "inflrate.csv",
    )

    compute_misery(unemployment_df, inflation_df, processed_dir / "misery.csv")
    return processed_dir


if __name__ == "__main__":
    main()
