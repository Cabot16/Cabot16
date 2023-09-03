#!/bin/bash
#该脚本是基于gtf文件提取基因的正义和负义链，使用之前，需要确认gtf和参考基因组的版本，环境下有无bedtools,seqkit软件
gene='TTLL4' #修改查找的基因，不区分大小写
region='CDS' #选择所需要的区域，ALL代表所有，可改为CDS,exon,gene,start_codon,stop_codon


grep -i ".*\"${gene}\";.*" /home/ywf/software/snpEff/data/cattlev1.2/genes.gtf > ${gene}.gtf  #可以修改gtf文件为自己需要的版本
if [ ! -s ${gene}.gtf ]; 
then
  echo "This gene does not exist"
  exit 1
fi
if [ "${region}" != "ALL" ]; 
  then
  awk -F "\t" -v region="${region}" '$3 == region {print}' ${gene}.gtf > tmp.gtf # 使用临时文件
  mv tmp.gtf ${gene}.gtf # 覆盖原文件
fi
if [ ! -s ${gene}.gtf ]; 
then
  echo "This region does not exist"
  exit 1
fi
awk -F'\t' '{printf "%s\t%s\t%s\t%s-%s", $1, $4-1, $5, $3, $2; for(i=6;i<=NF;i++) printf "-%s", $i; print ""}' ${gene}.gtf > ${gene}.pos.gtf #注意这里的-1，如果不加的话，fa序列会少一个，如启动子终止子。这和bedtools的提取逻辑有关
bedtools getfasta -fi /home/ywf/universal/fa-NC/cattle-NC.fa -bed ${gene}.pos.gtf -fo ${gene}.fa -name #同上修改参考基因组的位置，同时需注意其染色体号

col7=$(awk '{print $7}' ${gene}.gtf)

# 判断第七列是否均为+
if [[ $col7 == "+"* ]]; then
  mv ${gene}.fa forward-strand:sense-strand.fa
    seqkit seq -rp -t DNA forward-strand:sense-strand.fa > reverse-strand:antisense-strand.fa #关于正负链的补充说明：https://flying-polarbear.github.io/posts/dna-strand/
    echo "All done!" 
# 判断第七列是否均为-
elif [[ $col7 == "-"* ]]; then
  echo -e "\033[31mWarning, there is no “+” in the {$gene}.fa file, please confirm the {$gene}.gtf file.\033[0m"
  mv ${gene}.fa forward-strand:antisense-strand.fa
  seqkit seq -rp -t DNA forward-strand:antisense-strand.fa > reverse-strand:sense-strand.fa  # 取反向互补序列
  echo "All done"
# 否则，说明第七列有不同的符号
else
  echo -e "\033[31m!Warning!!! The gtf file format is not standard, please check the `${gene}.gtf` file\033[0m"
fi
