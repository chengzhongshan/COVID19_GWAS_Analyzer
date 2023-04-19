
%macro Get_Tested_ASE_Muts(Cancer,normal_aaf,gene);
%if &gene ne %then %do;
 %put Will only query ASE-Mut for single gene &gene;
%end;
%else %do;
 %put Will match ASE-Mut on genome-wide;  
%end;

goptions nonote;

/*Prepare database for analysis*/
%let CancerDir=F:\NewTCGAAssocRst\&Cancer;
%let outpath=%qsysfunc(prxchange(s/\//\\/,-1,&CancerDir\MatlabAnalysis\hits));
%put &outpath;
%if &outpath="" %then %abort 255;
%let drive_bed_dir=&CancerDir\MatlabAnalysis\somatics_calls\&Cancer._Driver_Beds;
%put &drive_bed_dir;
libname OUT "&outpath";

*Load human all tx and its corresponding genes;

/*x cd I:\OV_SNP6_TN_Num420\Matlab_OV\Matrix;*/
/*%ImportFilebyScan(file=tx.txt*/
/*                 ,dsdout=OUT.tx*/
/*                 ,firstobs=0*/
/*                 ,dlm='09'x*/
/*                 ,ImportAllinChar=1*/
/*                 ,MissingSymb=NaN*/
/*);*/
/**/
/*%ImportFilebyScan(file=tx2gene.txt*/
/*                 ,dsdout=OUT.gene*/
/*                 ,firstobs=0*/
/*                 ,dlm='09'x*/
/*                 ,ImportAllinChar=1*/
/*                 ,MissingSymb=NaN*/
/*);*/
/**/
/*data OUT.tx2gene;*/
/*set OUT.tx(rename=(V1=tx));*/
/*set OUT.gene(rename=(V1=gene));*/
/*run;*/


x cd &CancerDir\MatlabAnalysis\hits;
%ImportFilebyScan(file=mut_all.tab
                 ,dsdout=OUT.mut_hits
                 ,firstobs=1
                 ,dlm='09'x
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
);

proc transpose data=OUT.mut_hits out=OUT.mut_trans(rename=(col1=Mut) drop=col2) name=ID;
var TCGA:;
by Rowlabels notsorted;
run;
data OUT.mut_trans;
set OUT.mut_trans;
ID=prxchange("s/_/-/",-1,ID);
where Mut="1";
run;

%ImportFilebyScan(file=fm_all.tab
                 ,dsdout=OUT.mut_fdr
                 ,firstobs=1
                 ,dlm='09'x
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
);

%ImportFilebyScan(file=assoc_P_all.tab
                 ,dsdout=OUT.assoc_P
                 ,firstobs=1
                 ,dlm='09'x
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
);

%ImportFilebyScan(file=fdr_all.tab
                 ,dsdout=OUT.fdr
                 ,firstobs=1
                 ,dlm='09'x
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
);


x cd &CancerDir\MatlabAnalysis\somatics_calls;
%ImportFilebyScan(file=look.tab
                 ,dsdout=OUT.analysis_ids
                 ,firstobs=0
                 ,dlm='09'x
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
);

*Import tumor mutation file ids;
x cd &CancerDir\MatlabAnalysis\mutations;
%ImportFilebyScan(file=collabels.txt
                 ,dsdout=OUT.tumor_analysis_ids
                 ,firstobs=0
                 ,dlm='09'x
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
);
*Get TCGA id from filename;
data OUT.tumor_analysis_ids;
length TCGA $12.;
set OUT.tumor_analysis_ids;
TCGA=strip(left(scan(V1,2,":")));
run;
*Link WGS filename with all driver ids;
proc sql;
create table OUT.mut_tumor_ids as 
select a.*,b.V1
from OUT.mut_trans as a
left join
OUT.tumor_analysis_ids as b
on b.TCGA=a.id;


*Change &Cancer into other cancer type globally;
%let Cancer_type=&Cancer;
%let driver_mut_file=F:\NewTCGAAssocRst\&Cancer\MatlabAnalysis\&Cancer._All_Tested_Muts4FiveFeatures.txt;
%let driver_gene_info=F:\NewTCGAAssocRst\&Cancer\MatlabAnalysis\&Cancer._All_Tested_GeneInfo4FiveFeatures.txt;
%let ASE_Read_cutoff=20;
%let CancerDir=F:\NewTCGAAssocRst\&Cancer_type;

%ImportFilebyScan(file=&driver_mut_file
                 ,dsdout=all_muts
                 ,firstobs=0
                 ,dlm='09'x
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
);
%ImportFilebyScan(file=&driver_gene_info
                 ,dsdout=driver_info
                 ,firstobs=0
                 ,dlm=':'
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
);
 
/*Get samples having both ASE and WGS mutations;*/
%ImportFilebyScan(file=F:\NewTCGAAssocRst\&Cancer\MatlabAnalysis\matrix\tumor.collabels
                 ,dsdout=RNASeq
                 ,firstobs=0
                 ,dlm='09'x
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
);
%ImportFilebyScan(file=F:\NewTCGAAssocRst\&Cancer\MatlabAnalysis\mutations\collabels.txt
                 ,dsdout=WGS
                 ,firstobs=0
                 ,dlm=':'
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
);
proc sql;
create table UsedIDs as
select unique(a.V1)
from RNASeq as a
where V1 in (
  select V2
  from WGS
);

/*Import ASE-Mut Assoc P and FDR*/
%ImportFilebyScan(file=F:\NewTCGAAssocRst\&Cancer\MatlabAnalysis\&Cancer._AssocInfo4FiveFeatures.txt
                 ,dsdout=AssocInfo
                 ,firstobs=1
                 ,dlm='09'x
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
);


data driver_mut_info;
set all_muts(rename=(V1=mut));
set driver_info(rename=(V1=tx V2=gene V3=feature V4=cancer));
gene_feature=strip(left(gene))||'-'||strip(left(feature));
%if &gene ne  %then %do;
if gene="&gene";
%end;
run;

/*%abort 255;*/

libname OUT "&CancerDir\MatlabAnalysis\hits";
*For output driver sas dsd;
options noxwait;
proc sql;
create table tgt_info as
select a.*,b.ID as SampleID label '',b.V1 as VarscanFile
from driver_mut_info as a 
left join 
Out.Mut_tumor_ids as b
on b.Rowlabels=a.gene_feature;

proc sort nodupkeys;by _all_;run;
%StandardizeVarscanIDs(VarscanID_dsd=tgt_info,VarName=mut,outdsd=tgt_info1);

proc sql;
create table tgt_info2 as
select a.ref,a.var,a.normal_reads1,a.normal_reads2,
       a.tumor_reads1,a.tumor_reads2,b.*
from OUT.all_varscan as a,
     tgt_info1 as b
where a.gp=b.VarscanFile and
      a.chr=b.chr and
      a.st=b.pos and
      a.somatic_status='Somatic';

data tgt_info3;
set tgt_info2;
/*x=catx('-',_chr_,Pos,cat(ref,'|',var));*/
where catx('-',_chr_,Pos,cat(ref,'|',var))=_mut_;
run; 
data tgt_mut;
set tgt_info3;
drop ref var;
run;
/*proc sort data=tgt_info3 nodupkeys;by _all_;run;*/
proc sql;
create table tgt_ase as
select a.*
from Out.All_ASE as a,
     (select unique(tx) as tx from tgt_mut) as b
where a.tx=b.tx;
data tgt_ase;
length ID $12.;
set tgt_ase;
ID=scan(gp,2,'_:');
/*ID=prxchange('s/-[^-]+$//',-1,ID);*/
sum=input(V5,8.)+input(V6,8.);
*Reads cutoff for gene-level ASE;
/*if sum>=50;*/
run;
/*Get all gene and its feature for making a table containing all availabe TCGA ASE;*/
proc sql;
create table tx_feature(drop=key) as
select unique(tx||feature) as key,gene,tx,feature
from Tgt_mut;
proc sql;
create table ASE_Mut as
select a.gene,a.feature,
	   b.ID,b.V5 as ASE_a,b.V6 as ASE_b,b.sum as ASE_sum,b.tx as ASE_tx
from tx_feature as a
right join
Tgt_ase as b
on b.tx=a.tx;
create table ASE_Mut_Final as
select a.mut,a.tumor_reads1 as tumor_ref,
       a.tumor_reads2 as tumor_mut,
	   a.normal_reads1 as normal_ref,
	   a.normal_reads2 as normal_alt,
	   b.*
from tgt_mut as a
right join
ASE_Mut as b
on b.ASE_tx=a.tx and b.feature=a.feature and b.ID=a.SampleID;
quit;

%char2num_dsd(dsdin=ASE_Mut_Final,
              vars=normal_ref normal_alt,
              dsdout=ASE_Mut_Final);
data ASE_Mut_Final0;
set ASE_Mut_Final;
where normal_alt/(normal_ref+normal_alt)<=&normal_aaf;
run;

data ASE_Mut_Final1(drop=normal_ref normal_alt gene feature ASE_tx);
length rowlabels $5000.;
set ASE_Mut_Final0;
if mut="" then mut="NaN";
if tumor_ref="" then tumor_ref="NaN";
if tumor_mut="" then tumor_mut="NaN";
rowlabels=catx(':',ASE_tx,gene,feature,"&Cancer");
run;

/*remove duplicates*/
proc sort data=ASE_mut_final1 nodupkeys;by rowlabels mut id;run;

%if &gene ne %then %do;
 proc export data=ASE_Mut_Final1 outfile="F:\NewTCGAAssocRst\&Cancer\MatlabAnalysis\&Cancer._AllTestedMutASE4Matlab.&gene..txt" dbms=tab replace;
 run;
 data ASE_mut_Final1;
 set ASE_mut_Final1;
 a=ASE_a+0.01;b=ASE_b+0.01;
 g=0;
 if mut^="NaN" then g=1;
 Ratio=abs(log2(a/b));
 if Ratio>=10 then Ratio=10;
 run;
 proc glm data=ASE_mut_Final1;
 class g;
 model Ratio=g;
 by rowlabels;
 run;

%end;
%else %do;
 proc export data=ASE_Mut_Final1 outfile="F:\NewTCGAAssocRst\&Cancer\MatlabAnalysis\&Cancer._AllTestedMutASE4Matlab.txt" dbms=tab replace;
 run;
%end;

%mend;

/*options mprint mlogic symbolgen;*/

/*%Get_Tested_ASE_Muts(BRCA,normal_aaf=0.02,gene=);*/

/*
%Get_Tested_ASE_Muts(PRAD,normal_aaf=0.02,gene=);
%Get_Tested_ASE_Muts(COAD,normal_aaf=0.02,gene=);
%Get_Tested_ASE_Muts(STAD,normal_aaf=0.02,gene=);
%Get_Tested_ASE_Muts(SKCM,normal_aaf=0.02,gene=);
%Get_Tested_ASE_Muts(LGG,normal_aaf=0.02,gene=); 
%Get_Tested_ASE_Muts(OV,normal_aaf=0.02,gene=);  
%Get_Tested_ASE_Muts(HNSC,normal_aaf=0.02,gene=);
%Get_Tested_ASE_Muts(LUAD,normal_aaf=0.02,gene=);
%Get_Tested_ASE_Muts(LAML,normal_aaf=0.02,gene=);
*/





