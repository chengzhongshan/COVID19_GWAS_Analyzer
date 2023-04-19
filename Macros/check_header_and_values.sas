%macro check_header_and_values(
input_dsd_or_file_or_url=,
tgt_var_from_dsd=info,
linesep=\t,
dsdout=x,
column_len=500,
header_line=1,
value_line=10,
use_zcat=0,
deleteZIP=0
);

***************************************Prepare dsd from gz, zip, dsd, or url*************;
%if %sysfunc(prxmatch(/^http/,&input_dsd_or_file_or_url)) %then %do;
  %let wkdir=%sysfunc(getoption(work));
  %dwn_http_file(httpfile_url=&input_dsd_or_file_or_url,outfile=gwas_gz_file.gz,outdir=&wkdir);
%end;

%if (%sysfunc(prxmatch(/^http/i,&input_dsd_or_file_or_url)) or 
     %sysfunc(prxmatch(/.(gz|zip)/i,&input_dsd_or_file_or_url))
     ) %then %do;
  %ImportFileHeadersFromZIP(
  zip=&wkdir/gwas_gz_file.gz,
  /*Only provide file with .gz, .zip, or common text file without comporession*/
  filename_rgx=.,
  obs=max,
  sasdsdout=&dsdout,
  deleteZIP=0,
  infile_command=%str(firstobs=&header_line obs=&value_line;input;info=_infile_;),
  use_zcat=0
  );
%end;

%let sep='09'x;
%if (&linesep^='09'x and &linesep^=\t) %then %let sep=&linesep;

%let _old_dsdout=&dsdout;
%if %sysfunc(exist(&input_dsd_or_file_or_url)) %then %do;
 %let dsdout=&input_dsd_or_file_or_url._;
 *Create a temporary var info for later processing;
 data &dsdout;
 set &input_dsd_or_file_or_url;
 info=&tgt_var_from_dsd;
 run;
%end;

*********************Process extracted or existing dsd******************************;

data x_header(keep=Column) x_contents(keep=Value);
set &dsdout;
length Column Value $&column_len..;

if _n_=&header_line then do;
*Make missing value as NaN;
info=prxchange("s/\t(\t|$)/\tNaN$1/",-1,info);
%if &sep^='09'x %then %do;
info=tranwrd(info,"&sep&sep","&sep.NaN&sep");
%end;

do i=1 to 10000;

%if &sep='09'x %then %do;
 *Note: the '09'x does not need to be quoted;
 Column=scan(info,i,&sep);
%end;
%else %do;
 Column=scan(info,i,"&sep");
%end;

 if Column^="" then output x_header;
end;
end;

else if _n_=&value_line then do;
 do i=1 to 10000;

%if &sep='09'x %then %do;
 *Note: the '09'x does not need to be quoted;
 Value=scan(info,i,&sep);
%end;
%else %do;
 Value=scan(info,i,"&sep");
%end;

 if Value^="" then output x_contents;
 end;
end;

else do;
 *skip it;
end;

drop info;
run;

data &_old_dsdout;
set x_header;
set x_contents;
ord=_n_;
run;

proc print data=&_old_dsdout noobs;run;

%mend;

/*Demo:

options mprint mlogic symbolgen;

%let url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/pop_spec/sumstats/COVID19_HGI_B2_ALL_afr_leave23andme_20220403_GRCh37.tsv.gz;

%check_header_and_values(
input_dsd_or_file_or_url=&url,
tgt_var_from_dsd=info,
linesep=\t,
dsdout=xxx,
column_len=500,
header_line=1,
value_line=10,
use_zcat=0,
deleteZIP=0
);

**************************input is from dsd;
%let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/pop_spec/sumstats/COVID19_HGI_B2_ALL_afr_leave23andme_20220403_GRCh37.tsv.gz;

*for debugging;
*Get HGI release GWAS gz file header;
%let wkdir=%sysfunc(getoption(work));
%dwn_http_file(httpfile_url=&gwas_url,outfile=gwas_gz_file.gz,outdir=&wkdir);

%ImportFileHeadersFromZIP(
zip=&wkdir/gwas_gz_file.gz,
filename_rgx=.,
obs=2,
sasdsdout=x,
deleteZIP=0,
infile_command=%str(firstobs=1 obs=10;input;info=_infile_;),
use_zcat=0
);
%check_header_and_values(
input_dsd_or_file_or_url=x,
tgt_var_from_dsd=info,
linesep=\t,
dsdout=x_trans,
column_len=500,
header_line=1,
value_line=10,
use_zcat=0,
deleteZIP=0
);

*/
