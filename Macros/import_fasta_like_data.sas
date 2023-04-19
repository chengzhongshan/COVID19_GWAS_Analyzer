/*%macro import_fasta_like_file(fasta_like_file,header_start_char,outdsd);*/
%macro import_fasta_like_data(header_start_char,outdsd,onelinemode=1);
/*clear and create new temp file*/
filename FT15F001 clear;
filename FT15F001 temp;
/*Import data using parmcards*/
data &outdsd(drop=t);
length fa_header $500. seq $32767;
retain fa_header "" seq "" t 0;
infile FT15F001 length=reclen end=eof;
input;
if (t=0 and prxmatch("/^&header_start_char/",_infile_)) then do;
/* fa_header=substr(_infile_,2,reclen-1);*/
 fa_header=substr(_infile_,1,reclen);
end;
else if ( t>0 and prxmatch("/^&header_start_char/",_infile_) )then do;
 output;
 t=0;
 seq="";
/* fa_header=substr(_infile_,2,reclen-1);*/
 fa_header=substr(_infile_,1,reclen);
end;
else do;
 if reclen>0 then do;
 %if &onelinemode %then %do;
  seq=cats(seq,substr(_infile_,1,reclen));
 %end;
 %else %do;
  seq=substr(_infile_,1,reclen);output;
 %end;
  t=t+1;
 end;
end;
/*Need to output the last record using the end of file marker 'eof'*/
%if &onelinemode %then %do;
if eof then output;
%end;

%mend;


/*Demo:

*This macro will generate sas infile codes for the following parmcards command:;
%import_fasta_like_data(header_start_char=>,outdsd=fasta_dsd,onelinemode=1);
*Make sure there are no blank lines after parmcards;

parmcards;
>fasta1 description1
aaaccccccttttt 
gggggggggggggg
>fasta2 description2
aaaaaaaaaaaaaaaaaaaaa 
xxxx
;
run;


*/
