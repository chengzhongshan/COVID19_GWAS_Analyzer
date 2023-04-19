%macro gnomad4proteinpaint(dir4gnomadcsv,gnomadcsv);
x cd "&dir4gnomadcsv";
%let gnomad_file=&gnomadcsv;
proc import datafile="&gnomad_file" dbms=csv out=gnomad replace;
getnames=yes;guessingrows=10000;
run;
data out(keep=chr Protein_st Vtype);
length chr $100.;
set gnomad;
chr=compress(catx(":",catx("","chr",chromosome),position,reference,alternate));
if rsID^="" then chr=rsID;

Protein_st=prxchange('s/\D+(\d+)\D+.*/$1/',-1,Consequence)+0;
Vtype=prxchange('s/_variant//',-1,Annotation);
Vtype=prxchange('s/splice.*/splice/',-1,Vtype);
if Protein_st=. then delete;
run;

data final(keep=Info);
length Info $1000.;
set out;
if Vtype="missense" then Vtype="M";
else if Vtype="frameshift" then Vtype="F";
*stop_lost mutation is actually not nonsense mutation but for simplicity it is included here;
else if Vtype="nonsense" or Vtype="stop_gained" or Vtype="stop_lost" then Vtype="N";
else if Vtype="silent" then Vtype="S";
else if Vtype="splice" then Vtype="L";
else if Vtype="inframe_deletion" then Vytpe="proteindel";
if Vtype="L" then delete;*As splice variant should not be in the protein sequence;
Info=catx(";",chr,Protein_st,Vtype);
run;
proc export data=final dbms=tab outfile="&gnomad_file..txt" replace;
putnames=no;
run;
%mend;




