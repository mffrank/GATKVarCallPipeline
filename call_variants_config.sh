# Config File for all input parameters nescessary to run the pipeline
# Change parameters according to your input

# Genome reference FASTA file (full path)
reference=/nfs/nas21.ethz.ch/nas/fs2102/biol_ibt_usr_s1/mfrank/Master_Project/data/Human_genome/GRCh38/Gencode_v25/GRCh38.primary_assembly.genome.fa

# Genome annotation File (full path)
# annotation=/nfs/nas21.ethz.ch/nas/fs2102/biol_ibt_usr_s1/mfrank/Master_Project/data/Human_genome/GRCh38/Gencode_v25/gencode.v25.primary_assembly.annotation.gtf
#Fastq input Files (do not need to be trimmed), if single-end reads second file is ignored (full path)
# in_fq_1=/nfs/nas21.ethz.ch/nas/fs2102/biol_ibt_usr_s1/mfrank/Master_Project/data/HeLa/RNA_seq/Raw_sequences/Yansheng_Hela-8_AGTTCC_L002_R1_001.fastq
# in_fq_2=/cluster/scratch/mfrank/SRR2549078_2.fastq


#---------------------------------------------------

# Picard-MarkDuplicates

	# Setting stringency to SILENT can improve performance when processing a BAM file in which variable-length data (read, qualities, tags) do not otherwise need to be decoded.
	VALIDATION_STRINGENCY=SILENT
	
	# Additional Parameters
	MD_additional_params=""
#---------------------------------------------------

# HaplotypeCaller Parameters

	# The minimum phred-scaled confidence threshold at which variants should be called
	stand_call_conf=20.0
	stand_emit_conf=20.0

	# Additional Parameters
	HC_additional_params=""

#--------------------------------------------------

# VariantFiltration Parameters

	# The window size (in bases) in which to evaluate clustered SNPs
	window=35 
	
	# The number of SNPs which make up a cluster
	cluster=3

	# Filter Fisher Strand values in the info column above a threshold
	FSfilter="FS > 30.0"

	# Filter Qual By Depth values in the info column above a threshold
	QDfilter="QD < 2.0"

	# Additional Parameters
	VF_additional_params=""

#-----------------------------------------------

# CollectVariantCallingMetrics Parameters

	#Path to dbSNP vcf file for the right species (must be indexed, e.g. with igvtools)
	DBSNP=/nfs/nas21.ethz.ch/nas/fs2102/biol_ibt_usr_s1/mfrank/Master_Project/data/Human_genome/GRCh38/dbSNP/All_20161122.vcf



# STAR inputs

	# Set number of cores STAR will use for indexing the genome and read mapping
	st_threads=48

	# speciﬁes path to the directory (henceforth called ”genome directory” where thevgenome indices are stored. This directory has to be created (with mkdir) before STAR run and needs to writing permissions
	genomeDir=/nfs/nas21.ethz.ch/nas/fs2102/biol_ibt_usr_s1/mfrank/Master_Project/data/Human_genome/GRCh38/Gencode_v25/STAR_genome_index

	# specifies one or more FASTA ﬁles with the genome reference sequences
	genomeFastaFiles=$reference

	#  speciﬁes the path to the ﬁle with annotated transcripts in the standard GTF format
	sjdbGTFfile=$annotation

	# speciﬁes the length of the genomic sequence around the annotated junction to be used in constructing the splice junctions database. Ideally, this length should be equal to the ReadLength-1, where ReadLength is the length of the reads
	sjdbOverhang=99

	# Remove non-canonical splice junctions (Recommended in STAR manual for cufflinks compatibility)
	outFilterIntronMotifs=RemoveNoncanonicalUnannotated


#-----------------------------------------------


# Samtools inputs

	# Sets number of cores Samtools uses for sorting bam files, recommended: 8
	sa_threads=8


#----------------------------------------------





