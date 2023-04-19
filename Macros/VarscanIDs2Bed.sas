%macro VarscanIDs2Bed(VarscanID_dsd,
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
     set &VarscanID_dsd;
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
/*Change A1 and A2 for BedInfo*/
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
 data BedInfo;
	 length A1 A2 $32767.;
/*     This is for avoiding truncation of large deletion;*/
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
/*Change A1 and A2 for BedInfo*/
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
put 'chr' Chr st end A1 A2 rsID Label;
/*put Chr st end A1 A2 rsID Label;*/
run;

%mend;

/*
libname VAF "D:\F_tmp\NewTCGAAssocRst\VAF_SAS";
*If input is file, make sure the file only contain one column for mutations;
%VarscanIDs2Bed(VarscanID_dsd=VAF.Clean_driver_mutations
                ,Tbl_or_File=1
				,VarName=mut
                ,dsdout=test
                ,outbed_fullpath=D:\F_tmp\NewTCGAAssocRst\VAF_SAS\Clean_driver_mutations.bed
);

*/
