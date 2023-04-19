 %macro GEO_Pipeline(/*As different GSE and GPL files use specific genesymbol and probe ids,
	it is better to run the macro without knowing these headers for them, If failed, it can be rescued 
	by evaluating these genesymbol and probe ids in the SAS output dataset*/
GSE_matrix_file
,ProbVarInMatrix
,GPL_file
,ProbVarInAnno
,GeneVarInAnno
,SampleInfo_file /*No need to have header: GSM_ID and Sample_details*/
,Avg4gene_exp
,outdir
,Outdsd
);


x cd "&outdir";

%if %eval(&ProbVarInMatrix=) %then %let ProbVarInMatrix=ID_REF;
%if %eval(&ProbVarInAnno=) %then %let ProbVarInAnno=ID;
%if %eval(&GeneVarInAnno=) %then %let GeneVarInAnno=ILMN_Gene;

%put Please make sure these vars are asigned correctly;
%put ProbVarInMatrix=&ProbVarInMatrix;
%put ProbVarInAnno=&ProbVarInAnno;
%put GeneVarInAnno=&GeneVarInAnno;

/*Import Exp data*/
%FilterFile( filefullpath=&GSE_matrix_file     
                  ,ExcludedLineRegx=^! 
                  ,system=Windows 
				  ,fileoutfullpath=&GSE_matrix_file..clean
                 ) ;

proc import datafile="&GSE_matrix_file..clean" dbms=tab out=Exp replace;
/*guessingrows 1000 would be enough*/
getnames=yes;guessingrows=10000;
run;

/*Import Anno data*/
%FilterFile( filefullpath=&GPL_file     
                  ,ExcludedLineRegx=^# 
                  ,system=Windows 
				  ,fileoutfullpath=&GPL_file..clean
                 ) ;
proc import datafile="&GPL_file..clean" dbms=tab out=Anno replace;
/*guessingrows 1000 would be enough*/
getnames=yes;guessingrows=10000;
run;


/*Import Sample Data*/
/*No need to consider header, and it will make it easier to main our script*/
/*as header in the final dataset will not affect the result*/
/*guessingrows 1000 would be enough*/
proc import datafile="&SampleInfo_file" dbms=tab out=Info replace;
getnames=NO;guessingrows=1000;
run;

proc sql;
create table &outdsd as
select a.*,b.&GeneVarInAnno
from Exp as a
left join 
Anno as b
on a.&ProbVarInMatrix=b.&ProbVarInAnno;

data &outdsd;
set &outdsd;
where prxmatch('/^[a-zA-Z]/',&GeneVarInAnno);
run;

%if %eval(&Avg4gene_exp=1) %then %do;
/*Note: _GeneSymbol_ will be created for &dsdout*/
%ApplyFunc_rowwide(dsdin=&outdsd
                  ,row_keys=&GeneVarInAnno
				  ,KeyVar4dsdout=_GeneSymbol_
                  ,Regex4col_vars2apply=GSM
				  ,SQL_Fun4apply=avg
                  ,dsdout=&outdsd._avg
                  ,KeyVar4dsdout_length=20);

data &outdsd;
set &outdsd._avg;
run;
%end;

%mend;
/*If all microarray files were saved in the outdir, don't need to provide fullpath for them*/

/*options mprint mlogic symbolgen;*/

/*Demo
x cd J:\Coorperator_projects\RSV_DEG\PloS_One_RSV_DEG;
%GEO_Pipeline(GSE_matrix_file=GSE69606_series_matrix.txt
,ProbVarInMatrix=ID_REF
,GPL_file=GPL570-55999.txt
,ProbVarInAnno=ID
,GeneVarInAnno=Gene_Symbol
,Avg4gene_exp=1
,SampleInfo_file=sample_info.txt
,Outdir=J:\Coorperator_projects\RSV_DEG\PloS_One_RSV_DEG
,Outdsd=Z);

*DEG for single gene;
*%let gene=YWHAQ;
%let gene=LAMB3;
data x;
set z;
where _GeneSymbol_="&gene";
run;
proc transpose data=x out=x_trans(rename=(_name_=sample col1=exp));
run;
proc sql;
create table x_trans as
select a.*,b.var2 as sample_grps
from x_trans as a
left join
info as b 
on a.sample=b.var1;
data x_trans;
length grps $20.;
set x_trans;
grps=prxchange('s/-\d+[^-]+$//',-1,sample_grps);
log_exp=log2(exp);
run;
ods output diff=pdiff_summary;
proc glm data=x_trans;
class grps;
model log_exp=grps;
lsmeans grps/pdiff=all adjust=tukey;
run;

*/


/*
*SampleInfo_file is optional;
%GEO_Pipeline(GSE_matrix_file=GSE75037_series_matrix.txt
             ,ProbVarInMatrix=
             ,GPL_file=GPL6884.soft
			 ,ProbVarInAnno=
			 ,GeneVarInAnno=
             ,Avg4gene_exp=1
			 ,SampleInfo_file=Lung_cancer_sampleInfo.txt
             ,Outdir=I:\colon_cancer_organoid\Query_GSEs_Pipeline
			 ,Outdsd=Z);

*/

/*
*Row-wide z-score, which is the hardest to perform;
*Need to provide parameter for ByVar4rowwide;
*Make sure no duplicates in column of &ByVar4rowwide*/
*Note: _GeneSymbol_ was created by GEO_Pipeline as a key variable;

/*
%Zscore4matrix(dsdin=Z
,rowwide=1
,ByVar4rowwide=_GeneSymbol_
,dsdout=rowwide_zscore
);
*/













