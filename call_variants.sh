#!/bin/bash

# Input arguments to script
INPUT=$1
RUN_NAME=$2
OUT_DIR=$3
PARAMS=$4

# show usage if we don't have the last command-line argument

if [ "$PARAMS" == "" ]; then
        echo "-----------------------------------------------------------------";
        echo "Calls variants, according to the recommended gatk practice (see https://software.broadinstitute.org/gatk/guide/article?id=3891). Requires an aligned input file from star and a reference genome.  ";
        echo "";
        echo "USAGE INFORMATION:";
        echo "";
        echo "rna-seq-pipeline INPUT  RUN_NAME OUT_DIR Path/to/parameter_file";
        echo "";
        echo "INPUT	Input file, Sam file produced by STAR";
        echo "RUN_NAME  Name of the Sequencing run, output files will be saved under that name"
        echo "OUT_DIR   Path to desired output directory";
        echo "Path/to/parameter_file Path to shell script containing parameter variables";
        echo "";
        exit 1;
fi
#Function that exits after printing its text argument
#   in a standard format which can be easily grep'd.
err() {
  echo "$1...exiting";
  exit 1; # any non-0 exit code signals an error
}
# function to check return code of programs.
# exits with standard message if code is non-zero;
# otherwise displays completiong message and date.
#   arg 1 is the return code (usually $?)
#   arg2 is text describing what ran
ckRes() {
  if [ "$1" == "0" ]; then
    echo "..Done $2 `date`";
  else
    err "$2 returned non-0 exit code $1";
  fi
}
# function that checks if a file exists
#   arg 1 is the file name
#   arg2 is text describing the file (optional)
ckFile() {
  if [ ! -e "$1" ]; then
    err "$2 File '$1' not found";
  fi
}
# function that checks if a file exists and
#   that it has non-0 length. needed because
#   programs don't always return non-0 return
#   codes, and worse, they also create their
#   output file with 0 length so that just
#   checking for its existence is not enough
#   to ensure the program ran properly
ckFileSz() {
  ckFile $1 $2;
  SZ=`ls -l $1 | awk '{print $5}'`;
  if [ "$SZ" == "0" ]; then
    err "$2 file '$1' is zero length";
  else
    echo "$2 file '$1' checked";
  fi
}

# Load Parameters from config File
ckFile $PARAMS "Config File";
source $PARAMS

ckFileSz $reference "Reference Fasta";
ckFileSz $INPUT "STAR Alignment File";

echo "";

# Set up folder structure for output files

if [ ! -d ${OUT_DIR} ]; then mkdir ${OUT_DIR}; fi #OUT_DIR s a parameter defined in the function input
if [ ! -d ${OUT_DIR}/genome_2pass ]; then mkdir ${OUT_DIR}/genome_2pass; fi
if [ ! -d ${OUT_DIR}/star_2pass ]; then mkdir ${OUT_DIR}/star_2pass; fi
if [ ! -d ${OUT_DIR}/bam ]; then mkdir ${OUT_DIR}/bam; fi
if [ ! -d ${OUT_DIR}/variant_output ]; then mkdir ${OUT_DIR}/variant_output; fi
if [ ! -d ${OUT_DIR}/variant_output ]; then err "OUT_DIR variable seems not to have been set correctly"; fi

module load java;
module load samtools;
module load picard-tools/2.0.1;
module load gatk;


echo "Submitting jobs to sort/index SAM file and mark duplicates (AddOrReplaceReadGroups + MarkDuplicates)";

bsub -J "sort" -oo ${OUT_DIR}/bam/sorting_euler_log -eo ${OUT_DIR}/bam/sorting_log picard AddOrReplaceReadGroups I=$INPUT O=${OUT_DIR}/bam/${RUN_NAME}_added_sorted.bam SO=coordinate RGID=${RUN_NAME}_id RGLB=${RUN_NAME}_lib RGPL=ILLUMINA RGPU=${RUN_NAME}_lane RGSM=$RUN_NAME

bsub -J "markdup" -w "done(sort)" -oo ${OUT_DIR}/bam/markduplicates_euler_log -eo ${OUT_DIR}/bam/markduplicates_log picard MarkDuplicates I=${OUT_DIR}/bam/${RUN_NAME}_added_sorted.bam O=${OUT_DIR}/bam/${RUN_NAME}_deduped.bam CREATE_INDEX=TRUE VALIDATION_STRINGENCY=$VALIDATION_STRINGENCY M=${OUT_DIR}/bam/${RUN_NAME}_markdup.metrics $MD_additional_params

echo "Submitting Split'N'Trim Job to hardclip splice junction overhangs (SplitNCigarReads)";

bsub -J "trim" -w "done(markdup)" -oo ${OUT_DIR}/bam/SplitNCigarReads_euler_log -eo ${OUT_DIR}/bam/SplitNCigarReads_log GATK -T SplitNCigarReads -R $reference -I ${OUT_DIR}/bam/${RUN_NAME}_deduped.bam -o ${OUT_DIR}/bam/${RUN_NAME}_split.bam -rf ReassignOneMappingQuality -RMQF 255 -RMQT 60 -U ALLOW_N_CIGAR_READS

echo "Submitting Variant calling Job (HaplotypeCaller)";

bsub -J "callvar" -w "done(trim)" -oo ${OUT_DIR}/variant_output/HaplotypeCaller_euler_log -eo ${OUT_DIR}/variant_output/HaplotypeCaller_log GATK -T HaplotypeCaller -R $reference -I ${OUT_DIR}/bam/${RUN_NAME}_split.bam -o ${OUT_DIR}/variant_output/${RUN_NAME}_raw_variants.vcf -dontUseSoftClippedBases -stand_call_conf $stand_call_conf -stand_emit_conf $stand_emit_conf $HC_additional_params

echo "Submitting Variant filtering Job (VaraintFiltration)";

bsub -J "filtvar" -w "done(callvar)" -oo ${OUT_DIR}/variant_output/VariantFiltration_euler_log -eo ${OUT_DIR}/variant_output/VariantFiltration_log GATK -T VariantFiltration -R $reference -V ${OUT_DIR}/variant_output/${RUN_NAME}_raw_variants.vcf -o ${OUT_DIR}/variant_output/${RUN_NAME}_filtered_variants.vcf -window $window -cluster $cluster -filterName FS -filter "$FSfilter" -filterName QD -filter "$QDfilter" $VF_additional_params

echo "Submitting Quality Control comparison to dbSNP Job (CollectVariantCallingMetrics)";

bsub -J "QCfilt" -w "done(filtvar)" -oo ${OUT_DIR}/variant_output/CollectVariantCallingMetrics_euler_log -eo ${OUT_DIR}/variant_output/CollectVariantCallingMetrics_log picard CollectVariantCallingMetrics I=${OUT_DIR}/variant_output/${RUN_NAME}_filtered_variants.vcf O=${OUT_DIR}/variant_output/${RUN_NAME}_filtered_variants_metrics DBSNP=$DBSNP

bsub -J "QCraw" -w "done(callvar)" -oo ${OUT_DIR}/variant_output/CollectVariantCallingMetrics_raw_euler_log -eo ${OUT_DIR}/variant_output/CollectVariantCallingMetrics_raw_log picard CollectVariantCallingMetrics I=${OUT_DIR}/variant_output/${RUN_NAME}_raw_variants.vcf O=${OUT_DIR}/variant_output/${RUN_NAME}_raw_variants_metrics DBSNP=$DBSNP

echo "done"
