""" This runs both preprocessing and trains the ridge regressor. """
from pathlib import Path
import subprocess
import sys

def main():
    """ This is the main path of the program """
    project_root = Path(__file__).resolve().parents[3]
    scripts = [
        project_root / "src" / "model" / "main.py",
        project_root / "src" / "model" / "model" / "regression_nationallean.py",
    ]

    for script in scripts:
        subprocess.run(
            [sys.executable, str(script)],
            cwd=project_root,
            check=True,
        )


if __name__ == "__main__":
    main()
