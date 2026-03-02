import os

import pandas as pd

# Snakemake maps 'input: metrics=...' to snakemake.input.metrics
input_files = snakemake.input.metrics
output_file = snakemake.output[0]

# Read all individual CSVs from the C++ analyzer
dataframes = []
for file_path in input_files:
    try:
        df = pd.read_csv(file_path)
        dataframes.append(df)
    except Exception as e:
        print(f"Error reading {file_path}: {e}")

# Concatenate them all at once
if dataframes:
    master_df = pd.concat(dataframes, ignore_index=True)
else:
    master_df = pd.DataFrame()

# Save the final merged CSV
os.makedirs(os.path.dirname(output_file), exist_ok=True)
master_df.to_csv(output_file, index=False)
