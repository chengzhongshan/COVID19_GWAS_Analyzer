%macro fasta2sas(/*It is able to read a fasta file containing multiple fasta records*/
fasta,
outdsd,
fasta_one_line_mode=1
);

filename fasta "&fasta";
%if &fasta_one_line_mode %then %do;
data &outdsd;
infile fasta end=done;
length desc $1000. sequence $32767.;
/*Create number to determin when to output concatenated sequence! */
do _n_=1 by 1 until (done);
/*Holds an input record for the execution of the next input statement with the same iteration of the data step*/
input @;*Be caution about the trailing at;
if char(_infile_,1) eq ">" then do;
 if _n_ ne 1 then output;*This step only output concatenated sequences, restricted by the _n_ condition;
/* The two IF conditions restricted to only output sequences when encountering the fasta > and _n_ ne 1*/
 desc=substr(_infile_,2);
 call missing(sequence);*Only assign missing value for sequence when reading fasta head;
end;
else sequence=cats(sequence,_infile_);*Make sure to use cats but not cat;
/* The next input will STOP the RECORD held by the first input*/
/*Without this input, SAS will hold the record forever and will not stop running*/
input;
end;
/*For the last concatenated sequence,as it is out of the two IF conditions, it needs to be output;*/
output;
run;

%end;

%else %do;

*Input fasta seq into different rows;
data &outdsd;
infile fasta;
length desc $1000. sequence $32767.;
retain desc;
/*Create number to determin when to output concatenated sequence! */
/*Holds an input record for the execution of the next input statement with the same iteration of the data step*/
input @;*Be caution about the trailing at;
if char(_infile_,1) eq ">" then do;
 desc=substr(_infile_,2);
 *call missing(sequence);*Only assign missing value for sequence when reading fasta head;
end;
else do;
input;
 if char(_infile_,1) eq ">" then do;
  desc=substr(_infile_,2);
end;
Sequence=_infile_;
if Sequence^='' then output;*Make sure to use cats but not cat;
end;
run;
%end;
filename fasta clear;

%mend;


/*Demo: output fasta in long format with each fragment in one row;
%fasta2sas(fasta=Toy.fa,outdsd=x,fasta_one_line_mode=0);

*output fasta in one line format with all fragment concatenated;
%fasta2sas(fasta=Toy.fa,outdsd=x,fasta_one_line_mode=1);

%fasta2sas(fasta=H:\F_Queens\360yunpan\SASCodesLibrary\SAS-Useful-Codes\SAS_Sequencing_Analysis\Fasta_Toy.txt,
outdsd=x,
fasta_one_line_mode=0);

*/

