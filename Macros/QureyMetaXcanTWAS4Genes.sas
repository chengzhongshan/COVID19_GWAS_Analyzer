%macro QureyMetaXcanTWAS4Genes(
metaxcan_twas_file,
ukb_twas_file,
genes,
dsdout,
rawp_cutoff=0.01
);
proc import datafile="&metaxcan_twas_file" dbms=tab out=TWAS replace;
getnames=yes;guessingrows=100000;
run;

proc import datafile="&ukb_twas_file" dbms=tab out=UKB replace;
getnames=yes;guessingrows=100000;
run;

*combine EWAS data;
data all;
set TWAS UKB;
run;

proc sql;
create table Final as 
select a.*,a.pvalue as raw_p,
       -log10(pvalue) as logP
from all as a
where a.gene_name in (%quotelst(&genes));

%QQplot(dsdin=final,P_var=raw_p);
%Lambda_From_P(P_dsd=Final,P_var=raw_p,case_n=,control_n=,dsdout=OUT);

proc multtest pdata=final bon fdr out=&dsdout noprint;
run;

/*Make heatmap for the result;*/
/*add these P values <0.01 for genes in forheatmap*/
proc sql;
create table forheatmap as
select prxchange('s/_ccn_30.txt//',-1,a.FileName) as GWAS,
       a.gene_name,a.logP
from Final_fdr as a
where FileName in (
 select FileName 
 from &dsdout
 where Pvalue<&rawp_cutoff
);

%longformdsd4heatmap(dsdin=forheatmap,
row_var=gwas,
col_var=gene_name,
value_var=logP,
value_upperthres=10,
Newvalue4upper=10,
value_lowerthres=3,
Newvalue4lower=0,
cluster=1,
htmap_colwgt=0.2 0.8,
htmap_rowwgt=0.2 0.8,
dsdout=x
);

%mend;

/*Demo:

x cd "J:\MetaXcan\MetaXcan_TWAS4TopLocus";

%QureyMetaXcanTWAS4Genes(
metaxcan_twas_file=ALL_MetaXcan_Plos_Genetic_GWAS.txt,
ukb_twas_file=UKB_All_MetaXcan.txt,
genes=CD55 JAK2,
dsdout=final_fdr,
rawp_cutoff=0.01
);

*/





