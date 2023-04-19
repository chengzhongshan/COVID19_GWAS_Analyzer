%macro GDC_MutIDs2Bed(GDC_MutID_dsd,
                           Tbl_or_File,
                           VarName,
                           dsdout,
						   outbed_fullpath
                           );
options compress=yes;
/*Be caution that the start of position in BedInfo is equal to the start position -1 of UCSC!;*/
%if &Tbl_or_File %then %do;
 data BedInfo;
	 length A1 A2 $32767.;
    /*This is for avoiding truncation of large deletion;*/
     set &GDC_MutID_dsd;
	 &VarName=compress(&VarName);
	 if (prxmatch('/[()]/',&VarName)) then do;
      /*For Mut: chr22:19111641 ( G->T )*/
	 &VarName=prxchange('s/^((?:chr)*[\dxyXY]+)[:-](\d+)\(([acgtnACGTN]+)->([+-acgtnACGTN]+)\)/$1 $2 $3 $4/',-1,&VarName);
	 rsID=prxchange('s/\s+/:/',-1,strip(left(&VarName)));
	 rsID=strip(left(rsID));
	 end;
	 else do;
      /*For Mut: chr17:g.7674894G>A; chr17:g.7675096delAACCTCCG; chr17:g.7673755_7673756insATTCTCTT*/
	 &VarName=prxchange('s/^((?:chr)*[\dxyXY]+)[:-]g\.(\d+)(?:_\d+)*([TCGAN]|del|ins)>*([TCGAN]+)/$1 $2 $3 $4/i',-1,&VarName);
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
	 end=pos+1;

     if index(A1,"del") then do;
     st=pos;
     end=pos+1; 
	 A1='-';
	 A2=prxchange('s/[^ATGCN]+//',-1,A2);
	 end;
/*Change A1 and A2 for BedInfo*/
     if index(A1,"ins") then do;
     st=pos;
     A1='+';
	 A2=prxchange('s/[^ATGCN]+//',-1,A2);
	 end=pos+length(A2);
	 end;
	 output;
     run;
%end;
%else %do;
 data BedInfo;
	 length A1 A2 $32767.;
/*     This is for avoiding truncation of large deletion;*/
     infile "&GDC_MutID_dsd" dlm='09'x dsd truncover lrecl=32767 length=linelen firstobs=1;
     input;
	 _infile_=compress(_infile_);
	 if (prxmatch('/[()]/',_infile_)) then do;
      /*For Mut: chr22:19111641 ( G->T )*/
	 _infile_=prxchange('s/^((?:chr)*[\dxyXY]+)[:-](\d+)\(([acgtnACGTN]+)->([+-acgtnACGTN]+)\)/$1 $2 $3 $4/i',-1,_infile_);
	 rsID=prxchange('s/ /:/',-1,_infile_);
	 end;
      /*For Mut: chr17:g.7674894G>A; chr17:g.7675096delAACCTCCG; chr17:g.7673755_7673756insATTCTCTT*/
	 &VarName=prxchange('s/^((?:chr)*[\dxyXY]+)[:-]g\.(\d+)(?:_\d+)*([TCGAN]|del|ins)>*([TCGAN]+)/$1 $2 $3 $4/i',-1,&VarName);
	 rsID=_infile_;
	 end;
	 _chr_=scan(_infile_,1,' ');
	 Chr=prxchange('s/chr//',-1,_chr_)+0;
	 if _chr_="chrX" then chr=23;
	 if _chr_="chrY" then chr=24;
		 
     Pos=input(scan(_infile_,2,' '),best12.);
     A1=scan(_infile_,3,' ');
	 A1=prxchange('s/>//',-1,A1);
	 A2=scan(_infile_,4,' ');

	 st=pos;
	 end=pos+1;

     if index(A1,"del") then do;
     st=pos;
     end=pos+1; 
	 A1='-';
	 A2=prxchange('s/\W+//',-1,A2);
	 end;

     if index(A1,"ins") then do;
     st=pos;
	 A1='+';
	 A2=prxchange('s/\W+//',-1,A2);
	 end=pos+length(A2);
	 end;
	 output;
     run;
%end;

%VarnamesInDsd(indsd=BedInfo,Rgx=(chr|Chr|st|end|A1|A2|rsID|mut|label),match_or_not_match=0,outdsd=x);
proc sql noprint;
select name into: colnames separated by ' '
from x
where type=2;

data BedInfo;
length label $200.;
set BedInfo;
%if %length(&colnames)>1 %then %do;
array All{*} &colnames;
do i=1 to dim(All);
if i=1 then Label=All{1};
else Label=catx(":",Label,All{i});
end;
drop i;
%end;
run;
 
proc sql;
	 create table &dsdout as 
	 select Chr, st,end, A1, A2, rsID,Label  
	 from BedInfo;
proc sort data=&dsdout nodupkeys;
/*by _all_;*/
by chr st end A1 A2;
run;
data _null_;
set &dsdout;
file "&outbed_fullpath" lrecl=32767;
/*Avoid trunction of string longer than 256 bytes;*/
put 'chr' Chr st end _n_ A1 A2 rsID;
/*put Chr st end A1 A2 rsID Label;*/
run;

%mend;

/*
x cd "E:\Temp\TCGA_Paper_Scripts\To-do-list";
proc import datafile="TP53_GDC_frequent-mutations.2018-12-27.tsv" dbms=tab replace out=TP53;
getnames=yes;guessingrows=1000;
run;

*If input is file, make sure the file only contain one column for mutations;
*options mprint mlogic symbolgen;
%GDC_MutIDs2Bed(GDC_MutID_dsd=TP53
                ,Tbl_or_File=1
				,VarName=DNA_Change
                ,dsdout=test
                ,outbed_fullpath=TP53_GDC_Muts.bed
);

*/
