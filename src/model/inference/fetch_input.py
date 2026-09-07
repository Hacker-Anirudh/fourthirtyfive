""" This gets the current values of the model features to compute the current predicted national lean."""
from pathlib import Path
from fredapi import Fred

# Set up the environment
project_root = Path(__file__).resolve().parents[3]
keypath = project_root / "src" / "model" / "inference" / ".key"

with open(keypath, "r") as apikey:
    API_KEY = apikey.read() # Get a FRED API key at https://fred.stlouisfed.org/docs/api/api_key.html and place it in .key on your machine.

def compute_current_misery():
    """ This computes the current misery index using the inflation rate YoY and the unemployment rate. """
    fred = Fred(api_key=API_KEY)
    unrate = fred.get_series('UNRATE')
    cpi = fred.get_series('CPIAUCNS')

    cpi = cpi.pct_change(periods=12) * 100

    misery = (unrate + cpi).dropna()
    return round(float(misery.iloc[-1]),2)

def get_genballot():
    """ Empty as I couldn't find an API to interface with it"""
