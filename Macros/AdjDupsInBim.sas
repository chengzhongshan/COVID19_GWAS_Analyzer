*options mprint mlogic symbolgen compress=yes;
%macro AdjDupsInBim(BimFullpath,BimSep);
data _NULL_;
filepath="&BimFullPath";
retain length_SNP_ 0 length_A1_ 1 length_A2_ 1;
infile dummy filevar=filepath length=reclen end=done;
do while (not done);
input;
length_SNP=length(scan(_infile_,2,&BimSep));
length_SNP_=IFC(length_SNP_>length_SNP,length_SNP_,length_SNP);
length_A1=length(scan(_infile_,5,&BimSep));
length_A1_=IFC(length_A1_>length_A1,length_A1_,length_A1);
length_A2=length(scan(_infile_,6,&BimSep));
length_A2_=IFC(length_A2_>length_A2,length_A2_,length_A2);
if done then do;
  call symput("length_A1",length_A1_);
  call symput("length_A2",length_A2_);
  call symput("length_SNP",length_SNP_+2+length_A1_+length_A2_);
end;
end;
run;
%put &length_SNP;
%put &length_A1;
%put &length_A2;


data PLINK;
filepath="&BimFullPath";
infile dummy filevar=filepath length=reclen end=done delimiter=&BimSep dsd missover firstobs=1;
n=1;
do while (not done);
length x2 $&length_SNP. x5 $&length_A1. x6 $&length_A2.;
input x1 x2 $ x3 x4 x5 $ x6 $ ;
output;
n+1;
end;
run;

proc sort data=PLINK;by x2;run;
proc rank data=PLINK out=PLINK_Rank ties=mean;
by x2;
var x4;
ranks x4_rank;
run;
proc sort data=PLINK_Rank;by n;run;
data Plink_Rank(keep=x1-x6);
set Plink_Rank;
if x4_rank>1 or x4=lag(x4) then do;
 x2=strip(x2)||"_"||strip(x5)||"_"||strip(x6);
 x4=-9;
end;
run;

data _NULL_;
retain x1 x2 x3 x4 x5 x6;
set Plink_Rank;
file "&BimFullPath" delimiter=&BimSep;
put x1 x2 x3 x4 x5 x6;
run;

%mend;
/*Demo: BimSeq would be '09'x or '20'x;
 *'20'x is the hexadecimal value for a space in ASCII code.;
 *Note: original bim will be updated;
 
 options mprint mlogic symbolgen;
 %AdjDupsInBim(BimFullpath=C:\Users\ZC254\Desktop\test.bim,BimSep='20'x);

*/

