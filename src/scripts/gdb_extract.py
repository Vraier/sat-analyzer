import argparse
import os
import sqlite3

import pandas as pd


def convert_gbd_to_csv(db_path, output_csv):
    """
    Reads a GBD SQLite database, extracts all feature tables,
    and merges them into a single wide CSV file based on the MD5 hash.
    """
    if not os.path.exists(db_path):
        print(f"Error: Could not find database at {db_path}")
        return

    print(f"Connecting to {db_path}...")
    conn = sqlite3.connect(db_path)

    # 1. Get a list of all tables in the SQLite database
    query = "SELECT name FROM sqlite_master WHERE type='table';"
    tables = pd.read_sql_query(query, conn)["name"].tolist()

    # Filter out internal SQLite tables
    tables = [t for t in tables if not t.startswith("sqlite_")]
    print(f"Found {len(tables)} feature tables. Merging...")

    master_df = pd.DataFrame()

    # 2. Iterate through each table, extract data, and merge
    for table in tables:
        df = pd.read_sql_query(f"SELECT * FROM {table}", conn)

        # GBD typically stores data as (hash, value).
        # We rename 'value' to the table name so the final CSV has correct headers.
        if "value" in df.columns:
            df = df.rename(columns={"value": table})

        # Merge with the master dataset
        if master_df.empty:
            master_df = df
        else:
            # We use an outer join so we don't lose instances that might be missing a specific feature
            if "hash" in df.columns and "hash" in master_df.columns:
                master_df = pd.merge(master_df, df, on="hash", how="outer")

    conn.close()

    # 3. Save the final flattened CSV
    os.makedirs(os.path.dirname(output_csv), exist_ok=True)
    master_df.to_csv(output_csv, index=False)
    print(
        f"Successfully saved merged data to {output_csv} (Rows: {len(master_df)}, Columns: {len(master_df.columns)})\n"
    )


if __name__ == "__main__":
    # You can pass arguments, but we'll default to the standard GBD names
    parser = argparse.ArgumentParser(description="Flatten GBD SQLite databases to CSV")
    parser.add_argument("--meta", default="data/meta.db", help="Path to meta.db")
    parser.add_argument("--base", default="data/base.db", help="Path to base.db")
    args = parser.parse_args()

    # Convert meta.db
    convert_gbd_to_csv(args.meta, "data/gbd_meta_flattened.csv")

    # Convert base.db
    convert_gbd_to_csv(args.base, "data/gbd_base_flattened.csv")
