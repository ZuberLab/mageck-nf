#!/usr/bin/env nextflow

def helpMessage() {
    log.info"""
    ================================================================
     mageck-nf
    ================================================================

    Statistical analysis of multiplexed CRISPR-Cas9 / shRNA screens

    Usage:
    nextflow run zuberlab/mageck-nf

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
                        MAGeCK 0.5.7 (http://mageck.sourceforge.net)

        --resultsDir    Directory name to save results to. (Defaults to
                        'results')

    Profiles:
        standard        local execution
        docker          local execution with docker
        singularity     local execution with singularity
        slurm           IMPIMBA2 cluster execution with singularity

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

    publishDir path: "${params.resultsDir}/${parameters.name}",
               mode: 'copy',
               overwrite: 'true',
               saveAs: {filename ->
                   if (filename.indexOf(".log") > 0) "$filename"
                   else if (filename.indexOf(".normalized.txt") > 0) "$filename"
                   else null
               }
    input:
    val(parameters) from contrastsMageck
    each file(counts) from countsMageck

    output:
    set val("${parameters.name}"), file('*.sgrna_summary.txt'), file('*.gene_summary.txt') into resultsMageck
    file('*.log') into logsMageck
    file('*.normalized.txt') into normalizedMageck

    script:
    rra_params = params.min_rra_window > 0 ? "--additional-rra-parameters '-p ${params.min_rra_window}'" : ''
    """
    prefilter_counts.R \
        ${counts} \
        ${parameters.control} \
        ${params.min_count} > counts_filtered.txt

    mageck test \
        --output-prefix ${parameters.name} \
        --count-table counts_filtered.txt \
        --control-id ${parameters.control} \
        --treatment-id ${parameters.treatment} \
        --norm-method ${parameters.norm_method} \
        --adjust-method ${parameters.fdr_method} \
        --gene-lfc-method ${parameters.lfc_method} \
        --normcounts-to-file \
        ${rra_params}
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
    file('*.pdf') into qcMageck

    script:
    """
    postprocess_mageck.R ${guides} ${genes}
    """
}

workflow.onComplete {
	println ( workflow.success ? "COMPLETED!" : "FAILED" )
}
