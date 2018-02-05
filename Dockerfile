FROM continuumio/miniconda:latest

WORKDIR /mageck-nf

COPY environment.yml /mageck-nf/environment.yml

RUN conda config --add channels bioconda \
    && conda env create --name mageck-nf -f environment.yml \
    && rm -rf /opt/conda/pkgs/*

ENV PATH /opt/conda/envs/mageck-nf/bin:$PATH
