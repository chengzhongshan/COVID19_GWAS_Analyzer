%macro Bim2Annovar(bim_fullpath,dsdout,annovar_input,annovar_dir,annovar_outdir);
     data ANNOVAR(drop=A);
	 length A1 A2 $32767.;*This is for avoiding truncation of large deletion;
     infile "&Plink_Bim..Bim" dlm='09'x dsd truncover lrecl=32767 length=linelen firstobs=1;
     input;
     Chr=input(scan(_infile_,1,'09'x),best12.);
     rsID=scan(_infile_,2,'09'x);
     Pos=input(scan(_infile_,4,'09'x),best12.);
     A1=scan(_infile_,5,'09'x);
     if index(A1,"<") then A1="N"; 
     A2=scan(_infile_,6,'09'x);
	 if index(A2,"<") then A2="N"; 
	 end=Pos;
     *Be caution that the start of position in ANNOVAR is equal to the start position -1 of UCSC!;
     if length(A1)-length(A2)<0 then do;
	 end=Pos+length(A2)-length(A1);
	 A=A2;
	 A2=A1;
	 A1=A;
     end;

     if length(A1)-length(A2)>0 then do;
	 end=Pos+length(A1)-length(A2);
     end;

     run;
     
     proc sql;
	 create table &dsdout as 
	 select Chr, Pos, end, A1, A2, rsID  
	 from ANNOVAR;
	 
data _null_;
set &dsdout;
file &annovar_input lrecl=32767;*Avoid trunction of string longer than 256 bytes;
put Chr Pos end A1 A2 rsID;
run;
*Map variants to RefSeq gene;
%let ANNOVAR_CMD1=perl &Annovar_dir/annotate_variation.pl --geneanno &cwd/&outdir/annovar_input.txt 
                 &Annovar_dirhumandb/hg19 -buildver hg19 --outfile &annovar_outdir/Annovar;
%put &ANNOVAR_CMD1;
*X "&ANNOVAR_CMD1";	 
%mend;

*/-AT insertion
ST=varscan st+1
END=varcan st+length(AT)

*/+A deletion
chrY    59009654        59009655 
END=varscan st
ST=varscan st - length (A)