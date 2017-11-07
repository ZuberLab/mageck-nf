#!/usr/bin/env Rscript

################################################################################
# post-process MAGeCK test output files
# part of ZuberLab/mageck-nf pipeline at https://github.com/ZuberLab/mageck-nf
#
# Jesse J. Lipp
# Institute of Molecular Pathology (IMP), Vienna, Austria
# started 2017/09/27
################################################################################

# ------------------------------------------------------------------------------
# setup
# ------------------------------------------------------------------------------
# packages
library(readr)
library(dplyr)
library(stringr)
library(tidyr)
library(purrr)

# command line arguments
args       <- commandArgs(trailingOnly = TRUE)
sgrna_file <- args[1]
gene_file  <- args[2]

# ------------------------------------------------------------------------------
# import
# ------------------------------------------------------------------------------
sgrna_raw <- read_tsv(sgrna_file)
genes_raw <- read_tsv(gene_file)

# ------------------------------------------------------------------------------
# format sgRNA results
# ------------------------------------------------------------------------------
sgrna <- sgrna_raw %>%
  rename_all(str_replace, "[.]", "_") %>%
  mutate_at(c("control_count", "treatment_count"), str_replace_all, "[/]", ";") %>%
  rename(id = sgrna,
         group = Gene,
         treatment_mean = treat_mean,
         adjusted_var = adj_var,
         lfc = LFC,
         fdr = FDR) %>%
  select(id,
         group,
         control_count,
         treatment_count,
         control_mean,
         treatment_mean,
         control_var,
         adjusted_var,
         lfc,
         score,
         p_low,
         p_high,
         p_twosided,
         fdr)

sgrna %>%
  write_tsv("guides_stats.txt")

# ------------------------------------------------------------------------------
# format gene results
# ------------------------------------------------------------------------------
genes <- genes_raw %>%
  rename_all(str_replace, "[|]", "_") %>%
  rename(gene = id, guides = num) %>%
  gather(metric, value, neg_score:pos_lfc) %>%
  separate(metric, into = c("direction", "metric"), sep = "_") %>%
  spread(metric, value) %>%
  rename(p = `p-value`, guides_good = goodsgrna) %>%
  select(direction, gene, guides, guides_good, lfc, score, p, fdr) %>%
  arrange(fdr)

genes %>%
  nest(-direction) %>%
  walk2(.x = .$data, .y = .$direction, .f = ~ write_tsv(.x, paste0("genes_", .y, "_stats.txt")))
