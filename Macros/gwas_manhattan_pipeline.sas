%macro gwas_manhattan_pipeline(
GWAS_File,
Marker_Col_Name,
Marker_Pos_Col_Name,
Xaxis_Col_Name,
Yaxis_Col_Name,
Marker_X_Xpos_Y_ColNums,
GWAS_dsdout,
gwas_thrsd,
OutDir,
Replace_Previous_Rst=1,
Numeric_Xaxis_Col=1
);
   %let Marker_Col_Name=%assign_str4missing(Inval=&Marker_Col_Name,NewVal=SNP);
   %let Xaxis_Col_Name=%assign_str4missing(Inval=&Xaxis_Col_Name,NewVal=Chr);
   %let Yaxis_Col_Name=%assign_str4missing(Inval=&Yaxis_Col_Name,NewVal=P);
   %let Marker_Pos_Col_Name=%assign_str4missing(Inval=&Marker_Pos_Col_Name,NewVal=BP);
   
   %let GWAS=&GWAS_File;
   
   %let OutName=%scan(&GWAS,-1,'\/');
   %let OutName=%sysfunc(prxchange(s/\W+/_/,-1,&OutName));
   %put Your output file prefix is &OutName;
   %let curdir=%curdir;
   %put Replace_Previous_Rst is set as &Replace_Previous_Rst;

   %if %FileOrDirExist(&curdir/&OutDir/&OutName._Lambda.csv) and "&Replace_Previous_Rst"^="1" %then %do;
    %put There are previous result for your manhattan pipeline, the fullpath of which is &OutName.._Lambda.csv;
	  %put SAS will not run the analysis again only if you delete the above csv file;
    %return;
   %end;
   %else %do;      
   
   /*Import GWAS data*/
   *options mlogic mprint symbolgen;
   %if %eval("&Marker_X_Xpos_Y_ColNums"="") %then %do;
   
   %ImportFilebyScan(file=&GWAS
                    ,dsdout=&GWAS_dsdout
                    ,firstobs=1
                    ,dlm='09'x
                    ,ImportAllinChar=1
                    ,MissingSymb=NaN
   );
   %end;
   %else %do;
   %ImportFilebyScanAtSpecCols(file=&GWAS
                 ,dsdout=&GWAS_dsdout
                 ,firstobs=1
                 ,dlm='09'x
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
		 ,SpeColNums=&Marker_X_Xpos_Y_ColNums
   );
   %end;

   %mkdir(dir=&OutDir);
   %put Will go into the dir: &OutDir;     
   %if (&sysscp=WIN) %then %do;
   x cd "&OutDir";
   %end;
   %else %do;
   x cd &OutDir; 
   %end;
   /*%abort 255;*/
   %let curdir1=%curdir;
   %put Now current working dir is: &curdir1;
   

   ods html style=listing
            path="&curdir1" (url=none)
   		      body="&OutName..html";


   *If Xaxis_Col_Name is char, do not change it into numeric;
   *The macro manhattan will change it automatically;
   %if "&Numeric_Xaxis_Col"="1" %then %do;
   %char2num_dsd(dsdin=&GWAS_dsdout,
                 vars=&Xaxis_Col_Name &Yaxis_Col_Name &Marker_Pos_Col_Name,
                 dsdout=&GWAS_dsdout);
   %end;
   %else %do;
   %char2num_dsd(dsdin=&GWAS_dsdout,
                 vars=&Yaxis_Col_Name &Marker_Pos_Col_Name,
                 dsdout=&GWAS_dsdout);
   %end;

   proc sort data=&GWAS_dsdout;by &Xaxis_Col_Name &Marker_Pos_Col_Name;run;

   %manhattan(dsdin=&GWAS_dsdout,pos_var=&Marker_Pos_Col_Name,chr_var=&Xaxis_Col_Name,P_var=&Yaxis_Col_Name,logP=1,gwas_thrsd=&gwas_thrsd);
   
   %QQplot(dsdin=&GWAS_dsdout,P_var=&Yaxis_Col_Name);
   
   %Lambda_From_P(P_dsd=&GWAS_dsdout,P_var=&Yaxis_Col_Name,case_n=,control_n=,dsdout=&GWAS_dsdout._lambda);
   %ds2csv(data=&GWAS_dsdout._lambda,runmode=b,csvfile="&OutName._Lambda.csv");  

   x "cd &curdir";
%end;

%mend;

/*
options mautolocdisplay sasautos=('/gpfs/loomis/project/fas/gelernter/zc254/SAS/SAS-Useful-Codes/Macros'
sasautos);

proc import datafile="female.FI13_subset_inclusion_logic.txt" dbms=tab out=Assoc replace;
getnames=yes;guessingrows=1000000;
run;
*/


/*

%let MacroDir=/project/fas/gelernter/zc254/SAS/SAS-Useful-Codes/Macros;
%include "&MacroDir/ImportAllMacros.sas";
%ImportAllMacros(MacroDir=&MacroDir,filergx=.*.sas);

%list_files4dsd(
dir=/gpfs/loomis/project/fas/gelernter/zc254/Yale_GWAS/OP_GWAS/UKB_Opioid/UKB_Word_GWAS,
file_rgx=txt,
dsdout=x
);

data x;
set x;
outname=scan(fullpath,-1,'\/');outname=prxchange('s/\.txt//',-1,outname);
outname=prxchange('s/(\W|_)//',-1,outname);
run;

*options mprint mlogic symbolgen;
data _null_;
set x;
rc=dosubl(
'%gwas_manhattan_pipeline('||
'GWAS_File='||fullpath||
',Marker_Col_Name=SNP'||
',Marker_Pos_Col_Name=BP'||
',Xaxis_Col_Name=Chr'||
',Yaxis_Col_Name=P'||
',Marker_X_Xpos_Y_ColNums=1 7 8 6'||
',GWAS_dsdout=Assoc'||
',OutDir='||outname||
',Replace_Previous_Rst=1'||
',Numeric_Xaxis_Col=1'
');'
);
run;

*/



/*For EWAS:

x cd "E:\Coorperator_projects\EssentialGenes";
proc import datafile="both_sexes.Number_of_self_reported_cancers.smultixcan.txt" dbms=tab out=Assoc replace;
getnames=yes;guessingrows=100000;
run;
proc import datafile="Ensembl_genes_Pos.txt" dbms=tab out=Ano replace;
getnames=No;guessingrows=100000;
run;
proc sql;
create table EWAS as
select a.gene_name,a.pvalue as P,
       b.var2 as chr,b.var3 as BP
from Assoc as a,
     Ano as b
where upper(scan(a.gene,1,'.'))=upper(b.var1);
proc export data=EWAS outfile="EWAS.txt" dbms=tab replace;
run;
*options mlogic symbolgen mprint;
%gwas_manhattan_pipeline(
GWAS_File=EWAS.txt,
Marker_Col_Name=gene_name,
Marker_Pos_Col_Name=BP,
Xaxis_Col_Name=Chr,
Yaxis_Col_Name=P,
Marker_X_Xpos_Y_ColNums=,
gwas_thrsd=5,
GWAS_dsdout=EWAS_tmp,
OutDir=.,
Replace_Previous_Rst=1,
Numeric_Xaxis_Col=1
);


*Plot LDSC result with UKBB;

%let LDSC_file=E:\Yale_GWAS\MVP\MVP_Cocaine\LDSC4COD\COD_No_abusers_LDSC.txt;
proc import datafile="&LDSC_file" dbms=tab replace out=ldsc;
run;
data ldsc;
set ldsc;
where rg^=. and PMID^=.;
run;
data ldsc;
length grp $7.;
set ldsc;
if category='ukbb' then grp='UKB';
else grp='Non-UKB';
run;
%number_rows_by_grp(dsdin=ldsc,grp_var=grp,num_var4sort=P,desending_or_not=1,dsdout=x);
proc sql noprint;
select -log10(0.05/count(*)) into: GWS_thresld
from ldsc;

proc export data=x outfile="LDSC.tmp.txt" dbms=tab replace;
run;

*options mlogic symbolgen mprint;
%gwas_manhattan_pipeline(
GWAS_File=LDSC.tmp.txt,
Marker_Col_Name=trait2,
Marker_Pos_Col_Name=ord,
Xaxis_Col_Name=grp,
Yaxis_Col_Name=P,
Marker_X_Xpos_Y_ColNums=,
gwas_thrsd=&GWS_thresld,
GWAS_dsdout=EWAS_tmp,
OutDir=.,
Replace_Previous_Rst=1,
Numeric_Xaxis_Col=0
);




*For LDSC without UKBB;


%let LDSC_file=E:\Yale_GWAS\MVP\MVP_Cocaine\LDSC4COD\COD_No_abusers_LDSC.txt;
proc import datafile="&LDSC_file" dbms=tab replace out=ldsc;
run;
data ldsc;
set ldsc;
where rg^=. and PMID^=.;
run;
data ldsc;
length grp $7.;
set ldsc;
if category='ukbb' then grp='UKB';
else grp='Non-UKB';
run;

*delete ukbb gwas;
data ldsc;
set ldsc;
if category='ukbb' then delete;

*Only keep gwas catalogy with >=5 gwas;
proc sql;
create table ldsc1 as
select * 
from ldsc 
group by category 
having count(*)>=5;

%number_rows_by_grp(dsdin=ldsc1,grp_var=category,num_var4sort=P,desending_or_not=1,dsdout=x);

proc sql noprint;
select -log10(0.05/count(*)) into: GWS_thresld
from ldsc;

proc export data=x outfile="LDSC.tmp.txt" dbms=tab replace;
run;

*options mlogic symbolgen mprint;
%gwas_manhattan_pipeline(
GWAS_File=LDSC.tmp.txt,
Marker_Col_Name=trait2,
Marker_Pos_Col_Name=ord,
Xaxis_Col_Name=category,
Yaxis_Col_Name=P,
Marker_X_Xpos_Y_ColNums=,
gwas_thrsd=&GWS_thresld,
GWAS_dsdout=EWAS_tmp,
OutDir=.,
Replace_Previous_Rst=1,
Numeric_Xaxis_Col=0
);














*/
