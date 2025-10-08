%macro geo_sample_info_in_gse_matrix_gz(
gse_matrix_gz_url=https://ftp.ncbi.nlm.nih.gov/geo/series/GSE267nnn/GSE267625/matrix/GSE267625_series_matrix.txt.gz,
outdsd=sample_info,
debug=0
);

%CheckHeader4GZ_URL( 
any_gz_url=&gse_matrix_gz_url, 
infile_cmd=%str(
firstobs=1 obs=max;
input;info=_infile_;
if info="!series_matrix_table_end" then stop;
), 
/*Provide command like the following using the macro str to wrap it; 
Note: ensure there is not infile put before any supplied infile_cmd, as the infile 
statement is hard-coded into the internal macro! 
*/ 
outdsd=exp_info 
); 

title;
%if &debug=1 %then %do;
proc print;run;
%end;

data _null_;
set exp_info end=eof;
if prxmatch("/^\!Sample_title/i",info) then call symputx('ncols',countc(info,'"')/2);
run;
%put There are &ncols samples;
data exp_info1;
if _n_=1 then do;
  ret=prxparse('/\"[^\"]+\"/');
end;
*It is important to retain ret for all lines;
retain ret;
set exp_info end=eof;
*It is necessary to put these filters after establishing the regular expression pattern;
if prxmatch("/^(\!Sample_description|.ID_REF|\!Sample_characteristics_ch1|!Sample_title)/i",info);
*Remove the "ID_REF" element;
if prxmatch('/^.ID_REF/i',info) then info=prxchange("s/.ID_REF.\s+//",1,info);
start=1;
stop=length(info);
call prxnext(ret,start,stop,info,position,length);
*Restrict the length of each element in the X array is <=50;
array X[&ncols] $50.;
do i=1 to &ncols while (position gt 0);
	   *Note: remove the 1st and last character, so the target string length should be length-2;
		X[i]=substr(info,position+1,length-2);
	   call prxnext(ret,start,stop,info,position,length);
end;
drop info i ret start stop position length;
proc transpose data=exp_info1 out=sample_info;
var _character_;
run;
proc print;run;
%mend;
/*Demo codes:

%geo_sample_info_in_gse_matrix_gz(
gse_matrix_gz_url=https://ftp.ncbi.nlm.nih.gov/geo/series/GSE267nnn/GSE267625/matrix/GSE267625_series_matrix.txt.gz,
outdsd=sample_info,
debug=0
);

*/
