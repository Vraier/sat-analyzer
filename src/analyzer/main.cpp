#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <sstream>
#include <cmath>
#include <algorithm>
#include <unordered_map>
#include <unordered_set>
#include <set>

// Computes Gini using the formula: \frac{\sum_{i=1}^n (2i - n - 1) x_i}{n \sum_{i=1}^n x_i}
double compute_gini(std::vector<double>& counts) {
    if (counts.empty()) return 0.0;
    std::sort(counts.begin(), counts.end());
    
    double total = 0.0;
    for (double x : counts) total += x;
    if (total == 0.0) return 0.0;
    
    double n = counts.size();
    double coef = 0.0;
    for (size_t i = 0; i < counts.size(); ++i) {
        coef += (2.0 * (i + 1) - n - 1.0) * counts[i];
    }
    return coef / (n * total);
}

// Fast calculation of average overlap using an inverted index and sorted vectors
double compute_average_overlap(const std::vector<std::vector<int>>& clause_sets) {
    std::unordered_map<int, std::vector<int>> inverted_index;
    for (size_t i = 0; i < clause_sets.size(); ++i) {
        for (int item : clause_sets[i]) {
            inverted_index[item].push_back(i);
        }
    }

    double total_overlap = 0.0;
    long long pairs_counted = 0;

    for (size_t i = 0; i < clause_sets.size(); ++i) {
        std::unordered_set<int> neighbors;
        for (int item : clause_sets[i]) {
            for (int j : inverted_index[item]) {
                if (j > i) neighbors.insert(j); // Only look forward to avoid double-counting
            }
        }
        
        double size1 = clause_sets[i].size();
        for (int j : neighbors) {
            double size2 = clause_sets[j].size();
            double min_size = std::min(size1, size2);
            if (min_size > 0) {
                // Fast sorted array intersection
                int intersect = 0;
                size_t idx1 = 0, idx2 = 0;
                while (idx1 < clause_sets[i].size() && idx2 < clause_sets[j].size()) {
                    if (clause_sets[i][idx1] < clause_sets[j][idx2]) idx1++;
                    else if (clause_sets[j][idx2] < clause_sets[i][idx1]) idx2++;
                    else { intersect++; idx1++; idx2++; }
                }
                total_overlap += intersect / min_size;
                pairs_counted++;
            }
        }
    }
    return pairs_counted > 0 ? total_overlap / pairs_counted : 0.0;
}

int main(int argc, char* argv[]) {
    std::ios_base::sync_with_stdio(false);
    std::cin.tie(NULL);

    std::string input_file = "";
    std::string output_file = "";

    // Basic arg parsing
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "-i" && i + 1 < argc) input_file = argv[++i];
        else if (arg == "-o" && i + 1 < argc) output_file = argv[++i];
    }

    if (input_file.empty() || output_file.empty()) {
        std::cerr << "Usage: " << argv[0] << " -i <input.cnf> -o <output.csv>\n";
        return 1;
    }

    // Extract instance name from path
    std::string instance_name = input_file;
    size_t last_slash = instance_name.find_last_of("/\\");
    if (last_slash != std::string::npos) instance_name = instance_name.substr(last_slash + 1);
    size_t ext = instance_name.find(".cnf");
    if (ext != std::string::npos) instance_name = instance_name.substr(0, ext);

    std::ifstream file(input_file);
    if (!file.is_open()) {
        std::cerr << "Error opening file: " << input_file << "\n";
        return 1;
    }

    std::vector<std::vector<int>> clauses_vars;
    std::vector<std::vector<int>> clauses_lits;
    std::unordered_map<int, int> var_counts_map;
    std::unordered_map<int, int> lit_counts_map;

    std::set<int> current_vars;
    std::set<int> current_lits;

    std::string line;
    while (std::getline(file, line)) {
        if (line.empty() || line[0] == 'c' || line[0] == 'p') continue;

        std::stringstream ss(line);
        int lit;
        while (ss >> lit) {
            if (lit == 0) {
                if (!current_lits.empty()) {
                    clauses_vars.push_back(std::vector<int>(current_vars.begin(), current_vars.end()));
                    clauses_lits.push_back(std::vector<int>(current_lits.begin(), current_lits.end()));
                    current_vars.clear();
                    current_lits.clear();
                }
            } else {
                int var = std::abs(lit);
                current_vars.insert(var);
                current_lits.insert(lit);
                var_counts_map[var]++;
                lit_counts_map[lit]++;
            }
        }
    }

    // Compute Gini for clauses
    std::vector<double> clause_sizes;
    for (const auto& c : clauses_vars) clause_sizes.push_back(c.size());
    double gini_clause_size = compute_gini(clause_sizes);

    // Compute Gini for variables and literals
    int max_var = 0;
    for (const auto& pair : var_counts_map) max_var = std::max(max_var, pair.first);
    
    std::vector<double> var_counts(max_var, 0.0);
    for (const auto& pair : var_counts_map) var_counts[pair.first - 1] = pair.second;
    
    std::vector<double> lit_counts;
    for (const auto& pair : lit_counts_map) lit_counts.push_back(pair.second);

    double gini_var_occ = compute_gini(var_counts);
    double gini_lit_occ = compute_gini(lit_counts);

    // Compute Overlaps
    double avg_overlap_vars = compute_average_overlap(clauses_vars);
    double avg_overlap_lits = compute_average_overlap(clauses_lits);

    // Write to CSV
    std::ofstream out(output_file);
    out << "instance,gini_clause_size,gini_var_occurrence,gini_lit_occurrence,avg_overlap_vars,avg_overlap_lits\n";
    out << instance_name << ","
        << gini_clause_size << ","
        << gini_var_occ << ","
        << gini_lit_occ << ","
        << avg_overlap_vars << ","
        << avg_overlap_lits << "\n";

    return 0;
}