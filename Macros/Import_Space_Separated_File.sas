
%Macro Import_Space_Separated_File(abs_filename,firstobs,getnames,outdsd);
filename outfile "tempdata.txt";
data _null_;
retain n 0;
infile "&abs_filename" lrecl=32767 firstobs=&firstobs end=end;
file outfile;
input;
_infile_=strip(_infile_);
_infile_=prxchange("s/\bNA\b/./",-1,_infile_);
_infile_=compbl(_infile_);
_infile_=translate(_infile_," ",'09'x);
n+1;
/*Assign the total number of abs for proc import*/
if end then do;
if n>1000000 then n=1000000;
call symput('total',n);
end;
put _infile_;
run;

proc import datafile=outfile
             dbms=dlm out=&outdsd replace;
             getnames=&getnames;
			 guessingrows=&total;
run;

/*
This example generates a fileref for an external file in the variable FNAME. 
Then it calls FDELETE to delete the file and calls the FILENAME function again to deassign the fileref.*/

data _null_;
    fname="tempfile";
    rc=filename(fname,"tempdata.txt");
    if rc = 0 and fexist(fname) then
       rc=fdelete(fname);
    rc=filename(fname);
run;
%mend;
/*
%Import_Space_Separated_File(abs_filename=I:\H1N1_Imputated_with_ASN.assoc,
                             firstobs=1,
							 getnames=yes,
                             outdsd=PLINK);
*/

