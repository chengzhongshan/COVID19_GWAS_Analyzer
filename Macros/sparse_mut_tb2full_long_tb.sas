%macro sparse_mut_tb2full_long_tb(
/*
The macro is able to merge a full table with at least one variable, i.e.,
sample id, with the other smaller table only containing
observed muts in samples along with its membership by grp_var4mut,
the macro will first create a cross join table between the fulltable and 
the muts and then merge it with the mutation sparse table and create
a new variable to indicate the occurrence of each mut in these samples
from the full table.
*/
sparse_mut_tb=,	/*This table only contains mutations from different individual*/
mut_var=,/*character variable to define mutations*/
sample_var=,/*variable to define sample id in the sparse_mut_tb*/
grp_var4mut=,/*For the sparse_mut_tb, a variable to stratify muts into different groups, such as genes,
which will be used together with sample_var to lookup with a simple table containing all samples harboring or not harboring muts*/
sample_info_full_tb=,/*A table contains all samples and grp_var4mut that will be
subjected to merger with the sparase_mut_tb based on identical sample id, grp_var4mut, and mut_vars*/
fsample_var=,/*For the full sample information table, a variable to define sample id in the sparse_mut_tb*/
newvar4mut_occurrence=mutoccurrence,/*A new variable put into the the new outdsd indicating the occurrence of
the mut in the sample along with its grp_var4mut*/
outdsd=fulldsd4muts /*Long format output with sample ID, mut ID, mut grp, as well
as a new variable indicating the occurrence with 1 or 0 for the mut in each sample*/
);

*perform cross join between full table and the sparse muts table for each  grp_var4mut;
proc sql;
create table &outdsd as
select a.*,b.&grp_var4mut
from &sample_info_full_tb as a 
cross join
(select distinct &grp_var4mut from &sparse_mut_tb) as b;

create table &outdsd as
select a.*,b.&mut_var,
             case
              when b.&mut_var="" then 0
              else 1
              end as &newvar4mut_occurrence
from &outdsd as a
left join
&sparse_mut_tb as b
on a.&fsample_var=b.&sample_var 
    and a.&grp_var4mut=b.&grp_var4mut
order by a.&grp_var4mut;
;

%mend;

/*Demo codes:;

proc import datafile="E:\NTU_Testing/NTU_plus_panALL_pathgenic_vars4fisher_test_with_SAS.txt" dbms=tab 
out=muts replace;
getnames=yes;guessingrows=max;
run;
data muts;
set muts;
snv=catx("_",trim(left(chr)),trim(left(put(hg38_pos,best32.))),trim(left(geno)));
run;

proc import datafile="E:\NTU_Testing/NTU_plus_panALL_sample_age_sex_subtypes.txt" dbms=tab 
out=clininfo replace;
getnames=yes;guessingrows=max;
run;

*perform cross join between clininfo and muts for each gene;
proc sql;
create table clininfo4gene as
select a.*,b.gene
from clininfo as a
cross join
(select distinct gene from muts) as b
;
proc sql;
create table clininfo_plus_muts as
select a.*,b.snv,case 
               when b.snv="" then 0
               else 1
               end as MutObserved
from clininfo4gene as a
left join
muts as b
on a.ID=b.SampleID and a.gene=b.gene
order by a.cohort, a.gene;
*Assign 0 and 1 for unmatched and matched records;

*Now use the macro to generate similar results;
%sparse_mut_tb2full_long_tb(
sparse_mut_tb=muts,	
mut_var=snv,
sample_var=sampleID,
grp_var4mut=gene,
sample_info_full_tb=clininfo,
fsample_var=ID,
newvar4mut_occurrence=mutoccurrence,
outdsd=fulldsd4muts
);

*The newly generated table can be used to do fisher exact test;
*Alternatively, it will be useful for proc glm for differential analysis;
data fulldsd4muts;
set fulldsd4muts;
if grp^="BALL-LowHypo" then grp="Others";
proc sort data=fulldsd4muts;by cohort descending grp mutoccurrence;

proc freq data=fulldsd4muts order=data;
where gene="TP53";
table grp*mutoccurrence/fisher OR measures relrisk exact;
by cohort;
run;

*/
