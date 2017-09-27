#!/usr/bin/env nextflow

Channel
    .fromPath( params.input )
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
