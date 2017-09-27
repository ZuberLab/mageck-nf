#!/usr/bin/env nextflow

def helpMessage() {
    log.info"""
    ================================================================
     mageck-nf
    ================================================================

    Statistical analysis of multiplexed CRISPR-Cas9 / shRNA screens

    Usage:
    nextflow run ZuberLab/mageck-nf

    Options:
        --contrasts     Tab-delimited text file specifying the contrasts
                        to be analyzed. (Defaults to 'contrasts.txt')
                        The following columns are required:
                            - name: name of contrasts
                            - control: control samples (comma separated)
                            - treatment: treatment samples (comma separated)
                            - norm_method: normalization method
                            - fdr_method: multiple testing adjustment method
                            - lfc_method: method to combine guides / hairpins

        --counts        Tab-delimited test file containing the raw counts.
                        (Defaults to 'counts_mageck.txt')
                        This file must conform to the input requirements of
                        MAGeCK 0.5.6 (http://mageck.sourceforge.net)

        --resultsDir    Directory name to save results to. (Defaults to
                        'results')

    Profiles:
        standard        local execution with singularity
        sge             SGE execution with singularity

    Docker:
    zuberlab/mageck-nf:latest

    Author:
    Jesse J. Lipp (jesse.lipp@imp.ac.at)

    """.stripIndent()
}

if (params.help){
    helpMessage()
    exit 0
}

Channel
    .fromPath( params.contrasts )
    .splitCsv(sep: '\t', header: true)
    .set { contrastsMageck }

Channel
    .fromPath( params.counts )
    .set { countsMageck }

process mageck {

    tag { parameters.name }

    input:
    val(parameters) from contrastsMageck
    each file(counts) from countsMageck

    output:
    set val("${parameters.name}"), file('*.sgrna_summary.txt'), file('*.gene_summary.txt') into resultsMageck

    script:
    """
    mageck test \
        --output-prefix ${parameters.name} \
        --count-table ${counts} \
        --control-id ${parameters.control} \
        --treatment-id ${parameters.treatment} \
        --norm-method ${parameters.norm_method} \
        --adjust-method ${parameters.fdr_method} \
        --gene-lfc-method ${parameters.lfc_method} \
        --normcounts-to-file
    """
}

process postprocess {

    tag { name }

    publishDir path: "${params.resultsDir}/${name}",
               mode: 'copy',
               overwrite: 'true'

    input:
    set val(name), file(guides), file(genes) from resultsMageck

    output:
    set val(name), file('*_stats.txt') into processedMageck

    script:
    """
    postprocess_mageck.R ${guides} ${genes}
    """
}

workflow.onComplete {
	println ( workflow.success ? "COMPLETED!" : "FAILED" )
}
