"""
Generates *.dataset files, which are JSON-formatted files containing the
paths and labels of the training data test data. The *.dataset format is
required by the original OSRCI project by Neal et al.

A *.dataset file collects the following information for every record:
{"filename":"path/to/file/2663-018.jpg","label":"neut","fold":"train"}

NOTE: Pandas always escapes the slash character for paths when converting
      text to JSON, as recommended by the JSON standard.
TODO: Implement a decent dataloader in PyTorch. This requires considerable
      refactoring of the code base.

Author: Norman Juchler, juch@zhaw.ch
Date: 2022/2023
"""

from pathlib import Path
import pandas as pd
import numpy as np
import random
import json
import os

data_dir = os.getenv("OSR4H_DATA", None)
assert data_dir is not None, "Set environment variable OSR4H_DATA."
data_dir = Path(data_dir)

###############################################################################
# SETTTINGS
###############################################################################

# Classes to include
classes = ["nrbc", "neut", "mono", "lymph", "ig", "eo", "blast", "baso"]

# Split ratio for train and test data
split = 0.2

# Seed for RNG
seed = 42

# Input directory
in_dir = data_dir / "BOSTON"

# Files extension of the images
file_ext = ".jpg"

# Naming pattern of the output files
out_file_pattern = "./boston%s.dataset"

# Optionally set the data root of a target machine.
# This is useful if this script is run on a different machine
# If None, target_root is set to in_dir
target_root = "/mnt/data/BOSTON"
target_root = None



###############################################################################
# UTILITIES
###############################################################################
def split_dataset(df, split):
    df = df.sample(frac=1, random_state=seed)
    n_test = round(len(df)*split)
    n_train = len(df) - n_test
    #"fold": "train" if i < n_train else "test"
    df["fold"] = "train"
    df.loc[df.index[-n_test:], "fold"] = "test"

    # Make sure that train comes before test
    df = pd.concat([df[df["fold"]=="train"], df[df["fold"]=="test"]])
    df = df.reset_index(drop=True)
    return df


###############################################################################
# MAIN
###############################################################################
if target_root is None:
    target_root = in_dir
data = []
seed = np.random.RandomState(seed)

for subdir in sorted(in_dir.glob("*/")):
    label = subdir.name
    files = sorted(subdir.glob("*"+file_ext))
    files = [f for f in files if not f.stem.startswith("._")]
    for f in files:
        f = Path(target_root) / f.relative_to(in_dir)
        item = { "filename": str(f.absolute()),
                 "label": label}
        data.append(item)

df = pd.DataFrame(data)
# Split all labels separately.
df = df.groupby("label").apply(split_dataset, split=split)
df = df.reset_index(drop=True)
df.to_json(out_file_pattern % "", orient="records", lines=True)

for c in classes:
    mask = df["label"]==c
    df_loc = df[~mask].copy()
    df_loc = split_dataset(df_loc, split=split)
    df_loc.to_json(out_file_pattern % ("-loc-"+c),
                   orient="records", lines=True)

    df_class = df[mask].copy()
    df_class = split_dataset(df_class, split=split)
    df_class.to_json(out_file_pattern % ("-class-"+c),
                     orient="records", lines=True)


