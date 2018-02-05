# mageck-nf
Statistical Analysis of multiplexed CRISPR/shRNA Screens using MAGeCK

## Installation
The most convenient way is to use nextflow's built-in 'pull' command
```bash
nextflow pull zuberlab/mageck-nf
```

## Computing Environment

### Docker
Execute pipeline using the pre-built docker container. You must have docker installed.

```bash
nextflow run zuberlab/mageck-nf -profile docker
```

### Singularity
Execute pipeline using the pre-built docker container with singularity. You must have singularity >= 2.4 installed.

```bash
nextflow run zuberlab/mageck-nf -profile singularity
```

### Miniconda

Install Miniconda following the instructions at https://conda.io/docs/user-guide/install/index.html

Create a virtual enviroment using the environment file in the git repository.

```bash
conda env create --file environment.yml
```

Activate the environment using
```bash
source activate mageck-nf
```

Execute the pipeline in the virtual enviroment.

```bash
nextflow run zuberlab/mageck-nf -profile conda
```

## Documentation
nextflow run zuberlab/mageck-nf --help

## Credits
Nextflow:  Paolo Di Tommaso - https://github.com/nextflow-io/nextflow

MAGeCK:    Wei Li / Shirley Liu  - http://mageck.sourceforge.net
