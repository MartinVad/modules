process GATK_UNIFIEDGENOTYPER {
    tag "$meta.id"
    label 'process_medium'

    conda 'modules/nf-core/gatk/unifiedgenotyper/environment.yml'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gatk:3.5--hdfd78af_11':
        'biocontainers/gatk:3.5--hdfd78af_11' }"

    input:
    tuple val(meta), path(bam), path(bai)
    tuple val(meta2), path(fasta)
    tuple val(meta3), path(fai)
    tuple val(meta4), path(dict)
    tuple val(meta5), path(intervals)
    tuple val(meta6), path(contamination)
    tuple val(meta7), path(dbsnp)
    tuple val(meta8), path(comp)

    output:
    tuple val(meta), path("*.vcf.gz"), emit: vcf
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def contamination_file = contamination ? "-contaminationFile ${contamination}" : ""
    def dbsnp_file = dbsnp ? "--dbsnp ${dbsnp}" : ""
    def comp_file = comp ? "--comp ${comp}" : ""
    def intervals_file = intervals ? "--intervals ${intervals}" : ""

    def avail_mem = 3072
    if (!task.memory) {
        log.info '[GATK RealignerTargetCreator] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = (task.memory.mega*0.8).intValue()
    }

    """
    gatk3 \\
        -Xmx${avail_mem}M \\
        -nt ${task.cpus} \\
        -T UnifiedGenotyper \\
        -I ${bam} \\
        -R ${fasta} \\
        ${contamination_file} \\
        ${dbsnp_file} \\
        ${comp_file} \\
        ${intervals_file} \\
        -o ${prefix}.vcf \\
        $args

    gzip -n *.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk: \$(echo \$(gatk3 --version))
    END_VERSIONS
    """
}
