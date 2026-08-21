# Decided to scrap this approach, code does not work, leaving in here for transparency


import pandas as pd
import numpy as np

sen7624 = pd.read_csv("~/fourthirtyfive/src/model/data/historical/7624_sen.csv")
sen7624ByState = [group for name, group in sen7624.groupby(["state_po", "year"])]

leadsByYear = []

for _ in sen7624ByState:
    demVotes = _.loc[_["party_simplified"] == "DEMOCRAT", "candidatevotes"].sum()
    repVotes = _.loc[_["party_simplified"] == "REPUBLICAN", "candidatevotes"].sum()
    totalVotes = _["totalvotes"].iat[0]
    __ =  [_["state_po"].iloc[0], np.int16(_["year"].iloc[0]), np.float16(((demVotes - repVotes) / totalVotes * 100))]
    leadsByYear.append(__)

leadsDf = pd.DataFrame(leadsByYear, columns=["state_po", "year", "lean"])
avgLeadByState = leadsDf.groupby("state_po")["lean"].mean()
def nationalLean(g):
    dem = g.loc[g["party_simplified"] == "DEMOCRAT", "candidatevotes"].sum()
    rep = g.loc[g["party_simplified"] == "REPUBLICAN", "candidatevotes"].sum()
    total = g.drop_duplicates(["state_po"])["totalvotes"].sum()
    return pd.Series({"lean": (dem - rep) / total * 100})