from pathlib import Path
import sys
import pandas as pd
import numpy as np
import tkinter as tk 
from tkinter import ttk

from inference_logic import provide_margin
from fetch_input import compute_current_misery

if __package__ in (None, ""):
    import_root = Path(__file__).resolve().parents[3]
    if str(import_root) not in sys.path:
        sys.path.insert(0, str(import_root))

from src.model.model.main import main

# Set up the environment
project_root = Path(__file__).resolve().parents[3]
statpath = project_root / "src" / "model" / "inference" / "current_stats"
pvipath = project_root / "src" / "model" / "data" / "historical" / "processed" / "state_pvi_midterms.csv"


main()

misery = compute_current_misery()
with open(statpath, "r") as f:
    approval_rating, genballot = f.read().splitlines()

national_lean = provide_margin([np.float16(misery), np.float16(approval_rating), np.float16(genballot)])

state_pvis = pd.read_csv(pvipath)
state_pvis = state_pvis[["state_po", "pvi_2022"]]
state_pvis["pvi"] = state_pvis["pvi_2022"] + national_lean



# Fused off, only for demonstration

def show_results(national_lean, state_pvis):
    results = [
        f"National lean: {national_lean:+.1f}%",
        "Positive margins favor Republicans; negative margins favor Democrats.",
        "",
    ]
    results.extend(
        f"{row.state_po:<4} {row.pvi:+6.1f}%"
        for row in state_pvis.sort_values("pvi", ascending=False).itertuples()
    )
    share_text = "\n".join(results)

    window = tk.Tk()
    window.title("FourThirtyFive | 2026 Midterm Forecast")
    window.geometry("430x720")
    window.minsize(360, 420)
    window.configure(bg="#f4f1ea")

    style = ttk.Style(window)
    style.configure("Forecast.TFrame", background="#f4f1ea")
    style.configure(
        "Title.TLabel",
        background="#f4f1ea",
        foreground="#172121",
        font=("TkDefaultFont", 17, "bold"),
    )
    style.configure(
        "Subtitle.TLabel",
        background="#f4f1ea",
        foreground="#596462",
        font=("TkDefaultFont", 10),
    )
    style.configure("Forecast.TButton", padding=(12, 6))

    frame = ttk.Frame(window, padding=24, style="Forecast.TFrame")
    frame.pack(fill="both", expand=True)
    ttk.Label(frame, text="2026 MIDTERM FORECAST", style="Title.TLabel").pack(anchor="w")
    ttk.Label(
        frame,
        text=f"National lean  {national_lean:+.1f}%",
        style="Subtitle.TLabel",
    ).pack(anchor="w", pady=(4, 16))

    text_frame = ttk.Frame(frame, style="Forecast.TFrame")
    text_frame.pack(fill="both", expand=True)
    output = tk.Text(
        text_frame,
        wrap="none",
        font=("TkFixedFont", 11),
        padx=14,
        pady=12,
        bg="#fffdf8",
        fg="#172121",
        relief="solid",
        borderwidth=1,
        highlightthickness=0,
    )
    scrollbar = ttk.Scrollbar(text_frame, orient="vertical", command=output.yview)
    output.configure(yscrollcommand=scrollbar.set)
    output.pack(side="left", fill="both", expand=True)
    scrollbar.pack(side="right", fill="y")
    output.insert("1.0", share_text)
    output.configure(state="disabled")

    def copy_results():
        window.clipboard_clear()
        window.clipboard_append(share_text)

    ttk.Button(
        frame,
        text="Copy results",
        command=copy_results,
        style="Forecast.TButton",
    ).pack(anchor="e", pady=(14, 0))
    window.mainloop()


show_results(national_lean, state_pvis)
