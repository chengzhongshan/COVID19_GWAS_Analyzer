%macro StandardizeVarscanIDs(VarscanID_dsd,VarName,outdsd);
data &outdsd;
     length _chr_ $5.;
    /*set &VarscanID_dsd(keep=&VarName);*/
	 set &VarscanID_dsd;

	 &VarName=strip(left(&VarName));
	 _&VarName._=&VarName;
	 if (prxmatch('/[()]/',&VarName)) then do;
      /*For Mut: chr22:19111641 ( G->T )*/
	 &VarName=prxchange('s/^((?:chr)*[\dxyXY]+)\W(\d+)\s+\(\s+([acgtnACGTN]+)->([+-acgtnACGTN]+)\s+\)/$1:$2:$3:$4/',-1,&VarName);
/*	 &VarName=prxchange('s/^((?:chr)*[\dxyXY]+)[:-](\d+)\s+\(\s+([acgtnACGTN]+)->([+-acgtnACGTN]+)\s+\)/$1 $2 $3 $4/',-1,&VarName);*/
/*	 rsID=prxchange('s/\s+/:/',-1,strip(left(&VarName)));*/
/*	 rsID=strip(left(rsID));*/
	 end;
	 else do;
      /*For Mut: chr22:19111641-G|T*/
	 &VarName=prxchange('s/^((?:chr)*[\dxyXY]+)\W(\d+)\W(\S+)[\|:](\S+)/$1:$2:$3:$4/',-1,&VarName);
/*	 &VarName=prxchange('s/^((?:chr)*[\dxyXY]+)[:-](\d+)[-:](\S+)[\|:](\S+)/$1 $2 $3 $4/',-1,&VarName);*/
/*	 rsID=prxchange('s/\s+/:/',-1,strip(left(&VarName)));*/
/*	 rsID=strip(left(rsID));*/
	 end;
/*	 rsID=&VarName;*/
	 _chr_=scan(&VarName,1,':');
	 if _chr_="chrX" then chr=23;
	 else if _chr_="chrY" then chr=24; 
     else Chr=prxchange('s/chr//',-1,_chr_)+0;
     Pos=input(scan(&VarName,2,':'),best12.);
run;
%mend;
/*

data a;
input x $20.;
cards;
chr1:180949131:T:C
;
run;
options mprint mlogic symbolgen;
%StandardizeVarscanIDs(VarscanID_dsd=a,VarName=x,outdsd=have);

proc print;run;


*/
