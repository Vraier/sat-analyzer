import os

TIMEOUT = 60
DATASET = "variables____empty_and_clauses____empty_and_variables___10000_and_clauses___10000"

rule all:
    input:
        #"data/results/" + DATASET + "_minisat_stats.csv",
        #"data/results/" + DATASET + "_cnf_metrics.csv",
        "plots/" + DATASET + "_solvability.pdf"

rule compile_analyzer:
    input:
        "src/analyzer/main.cpp",
        "CMakeLists.txt"
    output:
        bin="build/cnf_analyzer",
        flag="build/.compiled"
    message:
        "Compiling C++ CNF Analyzer..."
    shell:
        """
        mkdir -p build
        cd build
        cmake -DCMAKE_BUILD_TYPE=Release ..
        make
        touch .compiled
        """


# Returns a minisat result file for every downloaded instance
def get_instances(wildcards):
    ckpt_output = checkpoints.download_dataset.get(**wildcards).output.raw_dir
    downloaded_files = [f for f in os.listdir(ckpt_output) if f.endswith(".cnf.xz")]
    return [f.replace(".cnf.xz", "") for f in downloaded_files]

def get_minisat_stats(wildcards):
    instances = get_instances(wildcards)
    return expand("data/results/{dataset}/{instance}.stats", dataset=wildcards.dataset, instance=instances)

def get_cnf_metrics(wildcards):
    instances = get_instances(wildcards)
    return expand("data/metrics/{dataset}/{instance}.csv", dataset=wildcards.dataset, instance=instances)


checkpoint download_dataset:
    input:
        uri="data/uris/{dataset}.uri"
    output:
        raw_dir=directory("data/raw/{dataset}")
    message:
        "Downloading {wildcards.dataset} instances into {output.raw_dir}..."
    shell:
        """
        mkdir -p {output.raw_dir}
        wget --content-disposition -i {input.uri} -P {output.raw_dir}
        """

rule unpack_instance:
    input:
        xz="data/raw/{dataset}/{instance}.cnf.xz"
    output:
        cnf="data/cnf/{dataset}/{instance}.cnf"
    message:
        "Unpacking {wildcards.instance}..."
    shell:
        """
        mkdir -p data/cnf/{wildcards.dataset}
        xz -d -c {input.xz} > {output.cnf}
        """

rule run_minisat:
    input:
        cnf="data/cnf/{dataset}/{instance}.cnf"
    output:
        stats="data/results/{dataset}/{instance}.stats",
        solution="data/results/{dataset}/{instance}.sol"
    message:
        "Solving {wildcards.instance} with 60s timeout..."
    shell:
        """
        mkdir -p data/results/{wildcards.dataset}
        timeout 60 minisat {input.cnf} {output.solution} > {output.stats} || true
        """

rule compute_cnf_metrics:
    input:
        cnf="data/cnf/{dataset}/{instance}.cnf",
        bin="build/cnf_analyzer" # This forces Snakemake to compile it first!
    output:
        csv="data/metrics/{dataset}/{instance}.csv"
    message:
        "Extracting metrics using C++ from {wildcards.instance}..."
    shell:
        """
        mkdir -p data/metrics/{wildcards.dataset}
        ./{input.bin} -i {input.cnf} -o {output.csv}
        """

rule aggregate_minisat_stats:
    input:
        stats=get_minisat_stats
    output:
        "data/results/{dataset}_minisat_stats.csv"
    message:
        "Aggregating MiniSat stats into {output}..."
    script:
        "src/scripts/aggregate_minisat_stats.py"

rule aggregate_cnf_metrics:
    input:
        metrics=get_cnf_metrics 
    output:
        "data/results/{dataset}_cnf_metrics.csv"
    message:
        "Merging metrics CSVs into {output}..."
    script:
        "src/scripts/aggregate_cnf_metrics.py"

rule plot_solvability:
    input:
        metrics="data/results/{dataset}_cnf_metrics.csv",
        meta="data/gbd_meta_flattened.csv"
    output:
        pdf="plots/{dataset}_solvability.pdf",
        png="plots/{dataset}_solvability.png"
    message:
        "Plotting solvability for {wildcards.dataset}..."
    script:
        "visualization/minisat_percentage.R"