library(ggplot2)
library(readr)
library(dplyr)

# 1. Define file paths based on your Snakemake pipeline output
dataset_name <- "minisat1m_yes_and_variables___30"
stats_file <- paste0("../data/results/", dataset_name, "_minisat_stats.csv")
metrics_file <- paste0("../data/results/", dataset_name, "_cnf_metrics.csv")

# 2. Read the datasets
cat("Loading data...\n")
stats_data <- read_csv(stats_file, show_col_types = FALSE)
metrics_data <- read_csv(metrics_file, show_col_types = FALSE)

# 3. Merge them strictly on the instance name
master_data <- inner_join(stats_data, metrics_data, by = "instance")

# 4. Clean the data for plotting
master_data <- master_data %>% 
  mutate(
    # If a run timed out or failed, cap it at the 60-second limit
    cpu_time_s = ifelse(is.na(cpu_time_s) | status == "TIMEOUT", 60, cpu_time_s),
    # Add a tiny epsilon to perfect 0.0s times so the log10 scale doesn't throw an error
    cpu_time_s = ifelse(cpu_time_s <= 0, 0.0001, cpu_time_s) 
  )

# 5. Create the scatterplot
p <- ggplot(master_data, aes(x = gini_var_occurrence, y = avg_overlap_vars, color = cpu_time_s)) +
  geom_point(size = 3, alpha = 0.85) +
  # Using the plasma color palette: dark blue for fast, bright yellow for slow/timeouts
  scale_color_viridis_c(
    option = "plasma", 
    trans = "log10",
    name = "CPU Time (s)\n(Log10)"
  ) +
  labs(
    title = "Empirical Hardness of SAT Instances",
    subtitle = paste("Variable Heterogeneity vs. Clause Overlap (Dataset:", dataset_name, ")"),
    x = "Variable Occurrence Heterogeneity (Gini)",
    y = "Average Clause Overlap (Ratio)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    legend.position = "right",
    panel.grid.minor = element_blank()
  )

# 6. Save the plot to disk
dir.create("../../plots", showWarnings = FALSE)
ggsave("../plots/hardness_scatter.pdf", plot = p, width = 8, height = 6)
ggsave("../plots/hardness_scatter.png", plot = p, width = 8, height = 6, dpi = 300)

cat("Successfully merged data and saved plots to the 'plots/' directory.\n")