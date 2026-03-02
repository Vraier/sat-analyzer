library(ggplot2)
library(readr)
library(dplyr)
library(stringr)

dataset_name <- "variables____empty_and_clauses____empty_and_variables___10000_and_clauses___10000"

metrics_file <- paste0("data/results/", dataset_name, "_cnf_metrics.csv")
meta_file    <- "data/gbd_meta_flattened.csv"
base_file    <- "data/gbd_base_flattened.csv"

pdf_out      <- paste0("plots/", dataset_name, "_solvability.pdf")
png_out      <- paste0("plots/", dataset_name, "_solvability.png")

metrics_data <- read_csv(metrics_file, show_col_types = FALSE)
meta_data    <- read_csv(meta_file, show_col_types = FALSE)
base_data    <- read_csv(base_file, show_col_types = FALSE) 

meta_solved <- meta_data %>%
  group_by(hash) %>%
  summarise(
    is_solved = any(tolower(result) %in% c("sat", "unsat"), na.rm = TRUE),
    minisat1m = ifelse(any(tolower(minisat1m) == "yes", na.rm = TRUE), "yes", "no")
  ) %>%
  ungroup()

metrics_data <- metrics_data %>%
  mutate(hash = str_sub(as.character(instance), 1, 32))

master_data <- metrics_data %>%
  inner_join(meta_solved, by = "hash") %>%
  left_join(base_data, by = "hash")


buckets <- 30
step <- 1/buckets

summary_data <- master_data %>%
  mutate(
    gini_x = floor(gini_var_occurrence / step) * step + step/2,
    overlap_y = floor(avg_overlap_vars / step) * step + step/2 
  ) %>%
  group_by(gini_x, overlap_y) %>%
  summarise(
    total_instances = n(),
    minisat_solved = sum(minisat1m == "yes", na.rm = TRUE),
    minisat_percent = (minisat_solved / total_instances) * 100,
    .groups = "drop" 
  ) %>%
  filter(!is.na(gini_x) & !is.na(overlap_y) & total_instances > 0)

p <- ggplot(summary_data, aes(x = gini_x, y = overlap_y)) +
  geom_point(aes(size = total_instances, color = minisat_percent)) +
  scale_color_viridis_c(option = "plasma", name = "Minisat\nSolved (%)", limits = c(0, 100)) +
  scale_size_continuous(
    name = "Number of\nInstances", 
    range = c(1, 15), 
    trans = "log10", 
    breaks = c(1, 10, 100, 1000)
  ) +  scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, by = 0.1)) +
  scale_y_continuous(limits = c(0.1, 0.7), breaks = seq(0, 1, by = 0.1)) +
  labs(
    x = "Variable Occurrence Heterogeneity (Gini)",
    y = "Clause Overlap"
  ) +
  theme_minimal()

dir.create(dirname(pdf_out), showWarnings = FALSE, recursive = TRUE)
ggsave(pdf_out, plot = p, width = 10, height = 7) # Increased height slightly for the legend
ggsave(png_out, plot = p, width = 10, height = 7, dpi = 300)
p