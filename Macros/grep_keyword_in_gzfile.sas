%macro grep_keyword_in_gzfile(
/*If no https in the url, the macro assumes that the input would be a local gz file;
if the input file does not contain .zip or .gz, it still can grep it by treating
the file as a plain text file!*/
gz_url=https://storage.googleapis.com/covid19-hg-public/20210415/results/20210607/COVID19_downloaded_file_ALL_leave_23andme_20210607.b37.txt.gz,
keyword=rs7850484, /*regular expression for prxmatch*/
headerlinenum=1, /*The line number for the header, with default 1 asumming the 1st line is header*/
checkmatchedlinenum=100 /*Note: the linenum 1 is used to represent the header or the 1st line;
When multiple lines matched with the searching keyword(s), apart from the 1st line,
print the target line by number along with the header line in long format; also increase the linenum to all possible matched lines
will keep all potential results in the output data set x for manual evaluation*/
);
%let zip=&gz_url;
%if %sysfunc(prxmatch(/https/,&gz_url)) %then %do;
 %dwn_http_file(httpfile_url=&gz_url,outfile=downloaded_file.gz,outdir=%sysfunc(getoption(work)));
 %let zip=%sysfunc(getoption(work))/downloaded_file.gz;
%end;

%ImportFileHeadersFromZIP(
zip=&zip,
/*Only provide file with .gz, .zip, or common text file without comporession*/
filename_rgx=.,
obs=max,
sasdsdout=x,
deleteZIP=0,
infile_command=%str(
firstobs=1;
retain xi 0;
input;
info=_infile_;
if xi>&checkmatchedlinenum then stop;
if _n_=1 or prxmatch("/&keyword/",_infile_) then do;
xi=xi+1;
output;
end;
),
use_zcat=0
);

proc print;run;
proc sql;
select count(*) into: maxnummatch
from x;

%if &maxnummatch<&checkmatchedlinenum %then %let checkmatchedlinenum=&maxnummatch;

*Transpose the lines into long format for view;
%check_header_and_values(
input_dsd_or_file_or_url=x,
tgt_var_from_dsd=info,
linesep=\t,
dsdout=x1,
column_len=500,
header_line=&headerlinenum,
value_line=&checkmatchedlinenum,
use_zcat=0,
deleteZIP=0
);

%mend;

/*Demo:
*This macro likes the linux function zgrep for gz file;
%let gwas_url=https://storage.googleapis.com/covid19-hg-public/20210415/results/20210607/COVID19_HGI_B2_ALL_leave_23andme_20210607.b37.txt.gz;
%grep_keyword_in_gzfile(
gz_url=&gwas_url,
keyword=rs7850484, 
headerlinenum=1,
checkmatchedlinenum=2
);
*/

