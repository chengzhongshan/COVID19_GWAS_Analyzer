%macro Varscan2Annovar(VarscanTable_fullpath,dsdout,annovar_input,annovar_dir,annovar_outdir,Anno_dsd_out);
options compress=yes;
*Be caution that the start of position in ANNOVAR is equal to the start position -1 of UCSC!;
data ANNOVAR;
	 length A1 A2 $32767.;*This is for avoiding truncation of large deletion;
     infile "&VarscanTable_fullpath" dlm='09'x dsd truncover lrecl=32767 length=linelen firstobs=1;
     input;

	 _chr_=scan(_infile_,1,'09'x);
	 if _chr_="X" then chr=23;
	 else if _chr_="Y" then chr=24;
	 else Chr=input(_chr_,best12.);

     Pos=input(scan(_infile_,2,'09'x),best12.);
     A1=scan(_infile_,3,'09'x);
	 A2=scan(_infile_,4,'09'x);
	 rsID=cat("chr",chr,":",pos,"-",strip(left(A1)),"|",strip(left(A2)));
	 st=pos;
	 end=pos;

     if index(A2,"-") then do;
     st=pos;
     end=pos; 
	 A1='-';
	 A2=prxchange('s/-//',-1,A2);
	 end;

     if index(A2,"+") then do;
     st=pos;
     A1=A2;
	 A1=prxchange('s/\+//',-1,A1);
	 end=pos+length(A1)-1;
	 A2='-';
	 end;
     
	 output;

     run;
     
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
/* &annovar_outdir/Annovar.exonic_variant_function*/
/*import annotated coding mutations.*/
%ImportFilebyScan(file=D:\NGS_lib\annovar\Annovar.exonic_variant_function
                 ,dsdout=Coding
                 ,firstobs=0
                 ,dlm='09'x
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
);

data Coding(keep=coding_type Functional_Info SNV);
set Coding;
SNV=prxchange('s/(\S+\s){5}(\S+)/$2/',-1,V4);
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


/*x cd "D:\F_tmp\NewTCGAAssocRst\BLCA";*/
/*/*options mprint mlogic symbolgen; */*/
/**/
/*%Varscan2Annovar(VarscanTable_fullpath=D:\F_tmp\NewTCGAAssocRst\BLCA\somatic_variants\0cfcdefd-603d-4cc2-a651-88d3e5f5c56c_TCGA-DK-A3IQ*/
/*                ,dsdout=test*/
/*                ,annovar_input=test_input*/
/*                ,annovar_dir=D:\NGS_lib\annovar*/
/*                ,annovar_outdir=D:\NGS_lib\annovar*/
/*                ,Anno_dsd_out=varscan_anno);*/

