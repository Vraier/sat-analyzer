import os
import re

import pandas as pd

# Snakemake maps 'input: stats=...' to snakemake.input.stats
input_files = snakemake.input.stats
output_file = snakemake.output[0]

data = []

patterns = {
    "variables": r"Number of variables:\s+(\d+)",
    "clauses": r"Number of clauses:\s+(\d+)",
    "conflicts": r"conflicts\s+:\s+(\d+)",
    "decisions": r"decisions\s+:\s+(\d+)",
    "propagations": r"propagations\s+:\s+(\d+)",
    "memory_mb": r"Memory used\s+:\s+([\d\.]+)\s+MB",
    "cpu_time_s": r"CPU time\s+:\s+([\d\.]+)\s+s",
}

for file_path in input_files:
    # Safely extract instance name assuming path 'data/results/dataset/instance.stats'
    instance_name = os.path.basename(file_path).replace(".stats", "")

    row = {"instance": instance_name, "status": "TIMEOUT"}
    for key in patterns:
        row[key] = None

    try:
        with open(file_path, "r") as f:
            content = f.read()

            for key, pattern in patterns.items():
                match = re.search(pattern, content)
                if match:
                    val = match.group(1)
                    row[key] = float(val) if "." in val else int(val)

            if "UNSATISFIABLE" in content:
                row["status"] = "UNSATISFIABLE"
            elif "SATISFIABLE" in content:
                row["status"] = "SATISFIABLE"
    except Exception as e:
        print(f"Error parsing {file_path}: {e}")
        row["status"] = "ERROR"

    data.append(row)

# Save to CSV
df = pd.DataFrame(data)
os.makedirs(os.path.dirname(output_file), exist_ok=True)
df.to_csv(output_file, index=False)
