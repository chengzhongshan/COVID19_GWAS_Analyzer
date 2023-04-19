%macro VarscanIDs2Annovar(VarscanID_dsd,
                           Tbl_or_File,
                           VarName,
                           dsdout,
                           annovar_input,
                           annovar_dir,
                           annovar_outdir,
                           Anno_dsd_out);
options compress=yes;
*Be caution that the start of position in ANNOVAR is equal to the start position -1 of UCSC;
%if &Tbl_or_File %then %do;
 data ANNOVAR;
	 length A1 A2 $32767.;
	 /*This is for avoiding truncation of large deletion*/
     set &VarscanID_dsd (keep=&VarName);
	 &VarName=compress(&VarName);
	 if (prxmatch('/[()]/',&VarName)) then do;
      /*For Mut: chr22:19111641 ( G->T )*/
	 &VarName=prxchange('s/^((?:chr)*[\dxyXY]+)[:-](\d+)\(([acgtnACGTN]+)->([+-acgtnACGTN]+)\)/$1 $2 $3 $4/',-1,&VarName);
	 rsID=prxchange('s/\s+/:/',-1,strip(left(&VarName)));
	 rsID=strip(left(rsID));
	 end;
	 else do;
      /*For Mut: chr22:19111641-G|T*/
	 &VarName=prxchange('s/^((?:chr)*[\dxyXY]+)[:-](\d+)[-:](\S+)[\|:](\S+)/$1 $2 $3 $4/',-1,&VarName);
	 rsID=prxchange('s/\s+/:/',-1,strip(left(&VarName)));
	 rsID=strip(left(rsID));
	 end;
	 _chr_=scan(&VarName,1,' ');
	 Chr=prxchange('s/chr//',-1,_chr_)+0;
	 if _chr_="chrX" then chr=23;
	 if _chr_="chrY" then chr=24;
		 
     Pos=input(scan(&VarName,2,' '),best12.);
     A1=scan(&VarName,3,' ');
	 A2=scan(&VarName,4,' ');

	 st=pos;
	 end=pos;

     if index(A2,"-") then do;
     st=pos;
     end=pos; 
	 A1='-';
	 A2=prxchange('s/-//',-1,A2);
	 end;
/*Change A1 and A2 for ANNOVAR*/
     if index(A2,"+") then do;
     st=pos;
     A1=A2;
	 A1=prxchange('s/\+//',-1,A1);
	 end=pos+length(A1)-1;
	 A2='-';
	 end;
	 output;
     run;
%end;
%else %do;
 data ANNOVAR;
	 length A1 A2 $32767.;*This is for avoiding truncation of large deletion;
     infile "&VarscanID_dsd" dlm='09'x dsd truncover lrecl=32767 length=linelen firstobs=1;
     input;
	 _infile_=compress(_infile_);
	 if (prxmatch('/[()]/',_infile_)) then do;
      /*For Mut: chr22:19111641 ( G->T )*/
	 _infile_=prxchange('s/^((?:chr)*[\dxyXY]+)[:-](\d+)\(([acgtnACGTN]+)->([+-acgtnACGTN]+)\)/$1 $2 $3 $4/',-1,_infile_);
	 rsID=prxchange('s/ /:/',-1,_infile_);
	 end;
	 else do;
      /*For Mut: chr22:19111641-G|T*/
	 _infile_=prxchange('s/^((?:chr)*[\dxyXY]+)[:-](\d+)[:-](\S+)[\|:](\S+)/$1 $2 $3 $4/',-1,_infile_);
	 rsID=_infile_;
	 end;
	 _chr_=scan(_infile_,1,' ');
	 Chr=prxchange('s/chr//',-1,_chr_)+0;
	 if _chr_="chrX" then chr=23;
	 if _chr_="chrY" then chr=24;
		 
     Pos=input(scan(_infile_,2,' '),best12.);
     A1=scan(_infile_,3,' ');
	 A2=scan(_infile_,4,' ');

	 st=pos;
	 end=pos;

     if index(A2,"-") then do;
     st=pos;
     end=pos; 
	 A1='-';
	 A2=prxchange('s/-//',-1,A2);
	 end;
/*Change A1 and A2 for ANNOVAR*/
     if index(A2,"+") then do;
     st=pos;
     A1=A2;
	 A1=prxchange('s/\+//',-1,A1);
	 end=pos+length(A1)-1;
	 A2='-';
	 end;
	 output;
     run;
%end;

 
proc sql;
	 create table &dsdout as 
	 select Chr, st,end, A1, A2, rsID  
	 from ANNOVAR;

data _null_;
set &dsdout;
file "&annovar_outdir/&annovar_input" lrecl=32767;*Avoid trunction of string longer than 256 bytes;
put Chr st end A1 A2 rsID;
run;
*Map variants to RefSeq gene;
%let ANNOVAR_CMD1=perl &Annovar_dir/annotate_variation.pl --geneanno &annovar_outdir/&annovar_input 
                 &Annovar_dir/humandb -buildver hg19 --outfile &annovar_outdir/Annovar;
%put &ANNOVAR_CMD1;
X "&ANNOVAR_CMD1";

*Annotate variants with conservation dataset mce46way from UCSC;
%let ANNOVAR_CMD2=perl &Annovar_dir/annotate_variation.pl -regionanno -dbtype mce46way &annovar_outdir/&annovar_input 
                 &Annovar_dir/humandb -buildver hg19 --outfile &annovar_outdir/Annovar;
%put &ANNOVAR_CMD2;
X "&ANNOVAR_CMD2";
*Annotate variants with DNaseCluster data from Encode data;
%let ANNOVAR_CMD3=perl &Annovar_dir/annotate_variation.pl -regionanno -dbtype wgEncodeRegDnaseClustered &annovar_outdir/&annovar_input 
                 &Annovar_dir/humandb -buildver hg19 --outfile &annovar_outdir/Annovar;
%put &ANNOVAR_CMD3;
X "&ANNOVAR_CMD3";
*Annotate variants with transcription factor binding data from Encode;
%let ANNOVAR_CMD4=perl &Annovar_dir/annotate_variation.pl -regionanno -dbtype wgEncodeRegTfbsClustered &annovar_outdir/&annovar_input 
                 &Annovar_dir/humandb -buildver hg19 --outfile &annovar_outdir/Annovar -scorecolumn 5;
%put &ANNOVAR_CMD4;
X "&ANNOVAR_CMD4";

*Summarize the above annotation into single file;
X "perl &Annovar_dir/ANNOVAR_Summary.pl &annovar_outdir";

*Import result into SAS;
proc import datafile="&annovar_outdir/AnnovarAnnotationResult.txt"
            dbms=tab out=&Anno_dsd_out replace;
			getnames=yes;
			guessingrows=10000;
run;

/*%ImportFilebyScan(file=&annovar_outdir/AnnovarAnnotationResult.txt*/
/*                 ,dsdout=&Anno_dsd_out replace*/
/*                 ,firstobs=1*/
/*                 ,dlm='09'x*/
/*                 ,ImportAllinChar=1*/
/*                 ,MissingSymb=NaN*/
/*);*/

/* &annovar_outdir/Annovar.exonic_variant_function*/
/*import annotated coding mutations.*/
%ImportFilebyScan(file=&Annovar_dir\Annovar.exonic_variant_function
                 ,dsdout=Coding
                 ,firstobs=0
                 ,dlm='09'x
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
);

data Coding(keep=coding_type Functional_Info SNV);
set Coding;
SNV=prxchange('s/(\S+\s){5}(.*)/$2/',-1,V4);
SNV=strip(left(SNV));
where V2^="unknown";
rename V2=coding_type
       V3=Functional_Info
	   ;
run;
proc sql;
create table &Anno_dsd_out as
select a.*,coding_type,Functional_Info
from &Anno_dsd_out as a
left join
Coding as b
on strip(left(a.SNP))=strip(left(b.SNV));

data &Anno_dsd_out;
score=0;
set &Anno_dsd_out;  
array anno{*} hg19_phastConsElements46way hg19_wgEncodeRegDnaseClustered hg19_wgEncodeRegTfbsClustered;
do i=1 to dim(anno);
 if (anno{i}^="-") then score=score+1;
end;
drop i;
run;
options compress=no;
%del_file_with_fullpath(fullpath=&annovar_outdir/Annovar.exonic_variant_function);
%del_file_with_fullpath(fullpath=&annovar_outdir/AnnovarAnnotationResult.txt);
%del_file_with_fullpath(fullpath=&annovar_outdir/Annovar.log);
%del_file_with_fullpath(fullpath=&annovar_outdir/test_input);
%mend;

/*
x cd "D:\F_tmp\NewTCGAAssocRst\BLCA";
libname MUT "D:\F_tmp\NewTCGAAssocRst\BLCA\MatlabAnalysis\mutations";
*If input is file, make sure the file only contain one column for mutations;
%VarscanIDs2Annovar(VarscanID_dsd=C:\Users\Sam\Desktop\driverMutations.txt
                ,Tbl_or_File=0
				,VarName=
                ,dsdout=test
                ,annovar_input=test_input
                ,annovar_dir=D:\NGS_lib\annovar
                ,annovar_outdir=D:\NGS_lib\annovar
                ,Anno_dsd_out=varscan_anno);
proc sort data=varscan_anno nodupkeys;
by SNP;
run;
data varscan_anno;
g="raw";
set varscan_anno;
run;
proc boxplot data=varscan_anno;
plot score*g;
run;
proc freq data=varscan_anno;
table score/plot=all;
run;

libname Mut clear;
*/
