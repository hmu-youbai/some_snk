import pandas as pd
# Snakemake RNA-seq pipeline

# Define the input files

SAMPLES = [ "orbFrontalC30", "orbFrontalC31", "orbFrontalC32", "orbFrontalC33", "orbFrontalC34", "orbFrontalC35", "orbFrontalC36", "orbFrontalC37", "orbFrontalC38", "orbFrontalC39", "orbFrontalC40", "orbFrontalC41", "orbFrontalC42", "orbFrontalC43", "orbFrontalC44", "orbFrontalC45", "orbFrontalC46", "orbFrontalC47", "orbFrontalC48", "orbFrontalC49", "orbFrontalC50", "orbFrontalC51", "orbFrontalC52", "orbFrontalC53", "orbFrontalC54", "orbFrontalC55", "orbFrontalC56", "orbFrontalC57", "orbFrontalC58", "orbFrontalC59", "orbFrontalC60"]

# Define the rule to run fastp on each sample
rule all:
    input:
        "output/expression_matrix.txt"


rule run_fastp:
    input:
        r1="data/{sample}.fastq.gz"
    output:
        r1_trimmed="output/{sample}.trimmed.fastq.gz"
    params:
        report="output/{sample}_fastp_report.html",
        json="output/{sample}_fastp_report.json"
    threads: 4
    shell:
        """
        fastp --in1 {input.r1} --out1 {output.r1_trimmed} \
              --html {params.report} --json {params.json} --thread {threads}
        """


# Define the rule to run STAR alignment on each sample


rule run_star:
    input:
        r1="output/{sample}.trimmed.fastq.gz"
    output:
        bam="output/{sample}.star.Aligned.sortedByCoord.out.bam"
    params:
        genome_index="/home/index/hg38_star"  
    threads: 8
    shell:
        """
        STAR --genomeDir {params.genome_index} --readFilesIn {input.r1} \
             --outFileNamePrefix output/{wildcards.sample}.star. --runThreadN {threads} \
             --outSAMtype BAM SortedByCoordinate --limitBAMsortRAM 10000000000 --readFilesCommand zcat
        """



rule generate_expression_matrix:
    input:
        bam="output/{sample}.star.Aligned.sortedByCoord.out.bam"
    output:
        expression_matrix="output/{sample}_expression_matrix.txt" 
    params:
        gtf_file="/home/index/gencode.v44.chr_patch_hapl_scaff.annotation.gtf"  
    shell:
        """
        featureCounts -T 8  -t exon -g gene_id -a {params.gtf_file} -o {output.expression_matrix} {input.bam}
        """

rule link_expression_matrix:
    input:
        expand("output/{sample}_expression_matrix.txt", sample=SAMPLES)
    output:
        "output/expression_matrix.txt"
    run:
        with open(output[0], "w") as out, open(input[0]) as f:
            out.write(f.read())

