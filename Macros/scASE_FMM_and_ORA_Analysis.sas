%macro scASE_FMM_and_ORA_Analysis(
pathway_gene_dsd=base,/*a dataset containing genes that will be used to overlapped with ASE genes from the following celltype_level_dsd*/
pathway_gene_var=gene,/*variable name for genes in the pathway_gene_dsd*/
ASE_gene_var=gene,/*variable name for genes in the celltype_level_dsd*/
celltype_level_dsd=celltype_level_dsd,/*single cell type level aggregated gene-level ASE for each indv and cell type;
Note: the input dsd can be subsetted by providing this celltype_level_dsd(where=(subj="FCA7167221"))*/
celltype_var=celltype,/*variable name for cell type in the celltype_level_dsd*/
sample_var=subj,/*ASE sample variable in the celltype_level_dsd
Note: for single sample analysis, leave the sample_var EMPTY*/
coverage_cutoff=20,/*Total read counts less than the cutoff will be excluded from the celltype_level_dsd*/
tgt_coverage_bins=20 30 40 50 60 70 80 90 100 200 300 400 500 600 1000 10000, /*Coverage bins that used to evaluate pathway enrichment*/
total_read_var=n,/*colname for the total number of reads for each ASE gene in the dataset celltype_level_dsd*/
ref_allele_cnt_var=y,/*colname for the reference allele counts*/
use_abs_ASE=1,/*If the ref_allele_cnt_var < alternative allele counts (total_read_var - ref_allele_cnt_var), 
the macro will arbitrarily assign the alternative allele counts to the ref_allele_cnt_var, which is equivalent to calculating absolute ASE*/
shuffle_ASE_dsd=0,/*shuffle ASE records by randomize them at each coverage bins, which will shuffle sample, celltype, and gene labels*/
fmm_by_sample=1,/*Default is to aggreate all samples to perform proc fmm; otherwise to assign value 1 to conduct proc fmm by individual sample*/
topASE_where_condition=%nrbquote(max(ASE,1-ASE) >= 0.6),/*where condition to filter the topASE genes based on absolute ASE*/
ASE_gene_count_cutoff=1,/*For each gene, after determination of its ASE mixture group, count how may cell types among all samples showing imbalanced ASE, 
then apply the ASE_gene_count_cutoff to keep genes showing ASE imbalance at least in a specific number of cell types for enrichment analysis!*/
FMM_out_dsd=FMM_Result /*proc fmm output dsd containing ASE finite mixture group labels for each ASE gene*/
);

*Prepare a new dataset called_celltype_level_dsd_ based input ASE data;
 data _celltype_level_dsd_;
 set &celltype_level_dsd;
%if %length(&sample_var)=0 %then %do;
 subj="SingleSample";
 %let sample_var=subj;
%end;

*Switch ref and alternative allele by choosing the read counts from the largest allele;
*This is equivalent to calculate absolute ASE;
%if &use_abs_ASE=1 %then %do;
 if &total_read_var-&ref_allele_cnt_var>&ref_allele_cnt_var then &ref_allele_cnt_var=&total_read_var-&ref_allele_cnt_var;
%end;
 ASE=&ref_allele_cnt_var/&total_read_var;

*Delete these ASE records with less of total reads relative to the total reads cutoff;
 if &total_read_var<&coverage_cutoff then delete;

 run;

*Create a coverage bin format for downstream analysis;
 %make_bin_format(bins=&tgt_coverage_bins,out_format_name=coverage_bins,bindsdout=bingrpnames);

*Prepare shufllted ASE records by coverage bin;
%if &shuffle_ASE_dsd=1 %then %do;
data _x_;
set _celltype_level_dsd_;
coverbingrps=put(n,coverage_bins.);
run;

proc freq data=_x_;
table coverbingrps/list out=cvbin_list;
run;
proc sql;
create table cvbin_list as 
select a.*
from cvbin_list as a
left join 
bingrpnames as b
on a.coverbingrps=b.bingrps
order by b.num_grps;

proc sort data=_x_ out=_celltype_level_dsd_;
by &sample_var &celltype_var coverbingrps;
run;

*Let randomize sample and celltype label but keeping the coverage fixed by using ranom number for ASE records in each coverage bin;
data _celltype_level_dsd_rnd;
call streaminit(1234567);
set _celltype_level_dsd_;
rnd=rand('uniform');
run;
proc sort data=_celltype_level_dsd_rnd;
by &sample_var &celltype_var  coverbingrps rnd;
data _celltype_level_dsd_;
*Note: use the original order of sample, celltype, and gene, but with the sorted ASE values by the random number;
merge _celltype_level_dsd_ (keep=&sample_var &celltype_var &ASE_gene_var) 
           _celltype_level_dsd_rnd (keep=&ref_allele_cnt_var &total_read_var ASE coverbingrps);
run;
%end;

data _celltype_level_dsd_;
set _celltype_level_dsd_;
coverbingrps=put(&total_read_var,coverage_bins.);
run;

/* proc freq data=celltype_level_dsd noprint;*/
/* table subj*celltype/crosslist out=subj_cell_summary nopercent;*/
/* run;*/
/* proc sort;by descending count;run;*/
/* proc print;where count>4000;run;*/

*Check ASE distribution;
	proc univariate data=_celltype_level_dsd_;
	histogram ASE/vscale=count outhistogram=ASE_counts_by_univariate;
	run;

	*Combining all ASEs together would be the best strategy to detect imblanced ASE cluster via proc fmm;
  *Better to perform fmm analysis in each sc sample;

  %if &fmm_by_sample=1 %then %do;
  proc sort data=_celltype_level_dsd_;by &sample_var;
  %end;

	proc fmm data=_celltype_level_dsd_;
	model &ref_allele_cnt_var/&total_read_var= /dist=betabinomial kmax=2;
	output out=&FMM_out_dsd class=ML;
  %if &fmm_by_sample=1 %then %do;
  by &sample_var;
  %end;
	run;

*Get the finite mixture group with the largest ASE value;
*When perform fmm by sample, some samples may assign different mixture group number to the target top imbalanced ASE group;
*It is thus necessary to keep the misture group labels constant among samples;
*In terms of conducting fmm without of separating sampes, no need to consider the above;
*but need to exclude these ASE < 0.6 in the target mixture group of imbalanced ASE genses with flat distribution covering a small amount of genes with ASE ~0.5;
%if &fmm_by_sample=0 %then %do;

proc sql; 
create table mASE_tb as
select mean(max(ASE,1-ASE)) as mASE, ML 
 from &FMM_out_dsd 
 group by ML;

%if %totobsindsd(work.mASE_tb)=1 %then %do;
					 %put Error: the finite mixture model only detect one group among your input single cell cell type ASE data!;
           %abort 255;
%end;

proc sql noprint;
select distinct ML into: ML_grp
from 	mASE_tb
having mASE=max(mASE);

%put Selected finite mixutre group is &ML_grp;
%if &ML_grp=1 %then %do;
					 %put For consistence, we will arbitrarily assign the imbalance group as 2, thus the selected mixture group will be switched from 1 to 2,;
           %put and its corresponding counterpart group will be changed from value 2 to 1;
           %let ML_grp=2;
            data 	&FMM_out_dsd (drop=_ML_);
            set &FMM_out_dsd (rename=(ML=_ML_));
            if _ML_=1 then ML=2;
            else ML=1;
            run;
            
%end;

%end;

%else %do;

proc sql; 
create table mASE_tb as
select &sample_var,mean(max(ASE,1-ASE)) as mASE, ML 
 from &FMM_out_dsd 
 group by &sample_var, ML;

 create table mASE_tb_good as 
 select &sample_var,mASE,ML
from mASE_tb
group by &sample_var
having count(ML)>1;

create table mASE_tb_good as
select &sample_var,ML,mASE
from mASE_tb_good
group by &sample_var
having mASE=max(mASE);

create table &FMM_out_dsd as 
select a.*,b.ML as _ML_
from &FMM_out_dsd as a
left join 
mASE_tb_good as b
on a.&sample_var=b.&sample_var and a.ML=b.ML;

*Update ML class labels and arbitrarily assign the value 2 and 1 to unbalanced and balanced ASE genes, respectively;
data &FMM_out_dsd(drop=_ML_);
set &FMM_out_dsd;
if _ML_=. then ML=1;
else ML=2;
run;
%let ML_grp=2;

%end;
*Match with pathway genes;
proc sql;
create table &FMM_out_dsd as
select a.*,b.&pathway_gene_var as pathway_gene
from &FMM_out_dsd as a
left join 
&pathway_gene_dsd as b
on a.&ASE_gene_var=b.&pathway_gene_var;

data &FMM_out_dsd;
set &FMM_out_dsd;
if &pathway_gene_var^="" then Matched=1;
else Matched=0;
run;

*Get top ASEs defined by the proc fmm;
  data top_ASE;
	set &FMM_out_dsd;
  where ML=&ML_grp;
	run;


*When perform fmm without by sample;
*the imbalanced ASE group may not be pure;
*because proc fmm recognize this group showing flat distribution compared to the balanced ASE group;
*So it is better to manually select these ASE genes with ASE ratio > 0.6;
%if &fmm_by_sample=0 %then %do;
  data top_ASE;
  set top_ASE;
  if max(ASE,1-ASE)>0.6;
  run;
%end;

*User imposed ASE condition for these top ASE;
%if %length(&topASE_where_condition)>0 %then %do;
  data top_ASE;
  set top_ASE;
  where %unquote(&topASE_where_condition);
  run;

%end;

	proc freq data=top_ASE noprint;
	table gene/list out=ASE_cnt4genes(drop=percent);
	run;

	proc sort data=ASE_cnt4genes;by descending count;run;
  *Get ASEs observed more than once!;
 data highfrqASE;
 set ASE_cnt4genes;
 where count>=&ASE_gene_count_cutoff;
 run;
 proc sql;
 create table highfrqASE as 
 select *
 from Highfrqase
 natural join
 top_ASE;
 

proc sql noprint;
select distinct coverbingrps into: qbins separated by ' '
from highfrqASE;
%put there are the following bins for enrichment test:;
%put &qbins;

%impr_enrich_by_bin(
bins=&qbins,
base=&pathway_gene_dsd,
enrichment_outdsd=enrich_dsd
);

data enrich_dsd;
set enrich_dsd;
where obs_n^=.;
run;

proc datasets lib=work nolist;
delete Perm_dsd Bingrpnames Matched;
run;

%mend;

*Sub-macro;
*Check enrichment of imprinting genes by coverage bin;
%macro impr_enrich_by_bin(
bins=20_30 30_40,
base=base,
enrichment_outdsd=enrich_dsd
);
%let nbins=%ntokens(&bins);

%do bi=1 %to &nbins;
%let bin=%scan(&bins,&bi,%str( ));
 proc sql;
 create table query as
 select distinct &ASE_gene_var	as gene
 from highfrqASE(where=(coverbingrps="&bin"));

 create table ref as
 select distinct &ASE_gene_var as gene
 from &FMM_out_dsd(where=(coverbingrps="&bin"));

create table _base_ as
select distinct &pathway_gene_var as gene
from &base;


%list_ORA(
base_list_dsd=_base_,
base_list_var=gene,
query_list_dsd=query,
query_list_var=gene,
ref_list_dsd=ref,	
ref_list_var=gene,
perm_n=10000,
enrich_dsdout=%str(enrichment_dsd&bi),
printout=1,
label4ORAtitle=%nrbquote(Over-representation analysis for the coverage bin &bin)
);

data enrichment_dsd&bi;
set enrichment_dsd&bi;
bin="&bin";
run;

proc datasets lib=work nolist;
delete query ref;
run;

%end;

*sort these bins by its input order;
*bingrpnames is generated initially by the parent macro;
data &enrichment_outdsd;
set enrichment_dsd:;
run;

proc sql;
create table &enrichment_outdsd as
select a.*,b.num_grps
from &enrichment_outdsd as a,
         bingrpnames as b
where a.bin=b.bingrps
order by b.num_grps;

proc datasets lib=work nolist;
delete enrichment_dsd:;
run;

title;

%mend;


/*Demo codes:;
*Previous cell level ASE results were derived from the SAS script:;
*calculate_celltype_level_ASE_with_nlmixed_vs_DAESC_R_package_revised_May_2024;

x cd "E:\scASE";
libname SC "E:\scASE";

*Prepare gene list for imprinting genes;
 proc import datafile="Reported_imprinting_genes.csv" out=tgt_imp_genes dbms=csv replace;
 run;
 data tgt_imp_genes;
 set tgt_imp_genes;
 genes=prxchange("s/[*]//",-1,genes);
 run;
*Create the base dataset for imprint gene enrichment test;
 data base;
 set tgt_imp_genes;
 keep gene;
 run;

*Prepare cell type level ASE dataset;
 data celltype_level_dsd;
 set sc.celltype_level_dsd;
*Get back the original alleleA;
 y=n-alleleB;
 run;

*Only focus on high quality placenta samples and it turns out that only one ASE group is identified;
*suggesting that it is necessary to have ASE data from blood samples as background to identify the imbalanced ASE group;
*Finally figure out that the it is better to perform fmm model by individual to separate ASE genes into two groups in each sample;
%scASE_FMM_and_ORA_Analysis(
pathway_gene_dsd=base,
pathway_gene_var=gene,
ASE_gene_var=gene,
celltype_level_dsd=celltype_level_dsd(
where=(
subj in ("FCA7196220" "FCA7196226" "FCA7474064" "FCA7474065" "FCA7474068" "FCA751184")
 )
),
celltype_var=celltype,
sample_var=subj,
coverage_cutoff=20,
tgt_coverage_bins=20 200 400  600 1000 10000, 
total_read_var=n,
ref_allele_cnt_var=y,
use_abs_ASE=0,
shuffle_ASE_dsd=0,
fmm_by_sample=0,
topASE_where_condition=%nrbquote(max(ASE,1-ASE) >= 0.6),
FMM_out_dsd=FMM_Result
);

*Now check these blood samples;
*No enrichment of imprinting genes;
 %scASE_FMM_and_ORA_Analysis(
pathway_gene_dsd=base,
pathway_gene_var=gene,
ASE_gene_var=gene,
celltype_level_dsd=celltype_level_dsd(
where=(
subj in ("FCA7196229" "FCA7196231" "FCA7167230" "FCA7167231" "FCA7167232" )
 )
),
celltype_var=celltype,
sample_var=subj,
coverage_cutoff=20,
tgt_coverage_bins=20 200 400  600 1000 10000, 
total_read_var=n,
ref_allele_cnt_var=y,
use_abs_ASE=1,
shuffle_ASE_dsd=0,
fmm_by_sample=1,
topASE_where_condition=%nrbquote(max(ASE,1-ASE) >= 0.6),
FMM_out_dsd=FMM_Result
);


*If only focus on these non-placenta samples, there are not enrichment of imprinting genes;
%scASE_FMM_and_ORA_Analysis(
pathway_gene_dsd=base,
pathway_gene_var=gene,
ASE_gene_var=gene,
celltype_level_dsd=celltype_level_dsd(
where=(
subj not in ("FCA7196220" "FCA7196226" "FCA7474064" "FCA7474065" "FCA7474068" "FCA751184")
 )
),
celltype_var=celltype,
sample_var=subj,
coverage_cutoff=20,
tgt_coverage_bins=20 200 400  600 1000 10000, 
total_read_var=n,
ref_allele_cnt_var=y,
use_abs_ASE=1,
shuffle_ASE_dsd=0,
fmm_by_sample=1,
topASE_where_condition=%nrbquote(max(ASE,1-ASE) >= 0.6),
FMM_out_dsd=FMM_Result
);

*Test each sample individually;
%scASE_FMM_and_ORA_Analysis(
pathway_gene_dsd=base,
pathway_gene_var=gene,
ASE_gene_var=gene,
celltype_level_dsd=celltype_level_dsd(
where=(
subj in ("FCA7474065" )
 )
),
celltype_var=celltype,
sample_var=subj,
coverage_cutoff=20,
tgt_coverage_bins=20 200 400  600 1000 10000, 
total_read_var=n,
ref_allele_cnt_var=y,
use_abs_ASE=1,
shuffle_ASE_dsd=0,
fmm_by_sample=1,
topASE_where_condition=%nrbquote(max(ASE,1-ASE) >= 0.6),
FMM_out_dsd=FMM_Result
);


*%debug_macro;
%scASE_FMM_and_ORA_Analysis(
pathway_gene_dsd=base,
pathway_gene_var=gene,
ASE_gene_var=gene,
celltype_level_dsd=celltype_level_dsd,
celltype_var=celltype,
sample_var=subj,
coverage_cutoff=20,
tgt_coverage_bins=20 30 40 50 60 70 80 90 100 200 300 400 500 600 1000 10000, 
total_read_var=n,
ref_allele_cnt_var=y,
use_abs_ASE=0,
shuffle_ASE_dsd=0,
fmm_by_sample=1,
topASE_where_condition=%nrbquote(max(ASE,1-ASE) >= 0.6),
FMM_out_dsd=FMM_Result
);

%scASE_FMM_and_ORA_Analysis(
pathway_gene_dsd=base,
pathway_gene_var=gene,
ASE_gene_var=gene,
celltype_level_dsd=celltype_level_dsd(where=(subj="FCA7196220")),
celltype_var=celltype,
sample_var=subj,
coverage_cutoff=20,
tgt_coverage_bins=20 200 400  600 1000 10000, 
total_read_var=n,
ref_allele_cnt_var=y,
use_abs_ASE=0,
shuffle_ASE_dsd=0,
fmm_by_sample=1,
topASE_where_condition=%nrbquote(max(ASE,1-ASE) >= 0.6),
FMM_out_dsd=FMM_Result
);

*conduct fmm by aggregating all samples together;
%scASE_FMM_and_ORA_Analysis(
pathway_gene_dsd=base,
pathway_gene_var=gene,
ASE_gene_var=gene,
celltype_level_dsd=celltype_level_dsd,
celltype_var=celltype,
sample_var=subj,
coverage_cutoff=20,
tgt_coverage_bins=20 200 400  600 1000 10000, 
total_read_var=n,
ref_allele_cnt_var=y,
use_abs_ASE=0,
shuffle_ASE_dsd=0,
fmm_by_sample=1,
topASE_where_condition=%nrbquote(max(ASE,1-ASE) >= 0.6),
FMM_out_dsd=FMM_Result
);

*Run the above with setting fmm_by_sample=0; 
data fmm_result_not_by_sample;
set fmm_result;
run;
proc sort data=fmm_result_not_by_sample;
by subj celltype gene n y;
run;

*Run the above with setting fmm_by_sample=1; 
data fmm_result_by_sample;
set fmm_result;
proc sort data=fmm_result_by_sample;
by subj celltype gene n y;
run;

*By running the above setting twice, one with proc fmm by sample and the other without by sample;
*it is informative to compare the total number of imblanced ASE genes derived from the two running;
proc compare base=fmm_result_not_by_sample compare=fmm_result_by_sample OUT=diff_fmm printall;
run;
data merged;
merge fmm_result_by_sample(rename=(ML=ML_by_sample))
            fmm_result_not_by_sample(rename=(ML=ML_not_by_sample));
run;
*It seems that the fmm group labels, including 1 and 2, are not consistantly used to refer to the imblanced ASE group;
*In detail, ML_by_sample uses 1 to represent the imblanced ASE group, while the other dataset assign 2 to the same ASE group;
proc freq data=merged;
table ML_by_sample*ML_not_by_sample/nopercent norow nocol nocum;
run;
data diff;
set merged;
where ML_by_sample^=ML_not_by_sample;
run;
proc sgplot data=diff;
histogram ASE/group=ML_not_by_sample scale=count;
*histogram ASE/group=ML_not_by_sample;
run;
*Check how many imprinting genes from each ML group;

*Testing;
proc sgplot data=fmm_result;
*histogram ASE/group=ML scale=count;
histogram ASE/group=ML ;
*where subj^="FCA7474064";
run;

*/
