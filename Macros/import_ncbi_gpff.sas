%macro import_ncbi_gpff(
gpff_url=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.40_GRCh38.p14/GCF_000001405.40_GRCh38.p14_protein.gpff.gz,
outdsd=hg38_gpff
);

%let OldOutDsd=&Outdsd;
*If the outdsd contains lib abbreviation;
*It is necessary to generate a gbff dsd in working directory first.;
%if %index(&OldOutDsd,.) %then %do;
 %let outdsd=%scan(&outdsd,2,.);
%end;


%dwn_http_file(httpfile_url=&gpff_url,outfile=hg38gpff.gz,outdir=%sysfunc(getoption(work)));

filename G zip "%sysfunc(getoption(work))/hg38gpff.gz" gzip;
%let infile_cmd1=%str(
do _n_=1 by 1 until (done);
input @;
if scan(_infile_,1,' ')='LOCUS' then do;
 if _n_ ne 1 then do;
  nitems=countc(info,'|')+1;
  do ii=1 to nitems;
   regionname=scan(info,ii,'|');
   region_st=prxchange('s/^\s*\S+\s+(\d+)(?:\.\.\d+)*(\&\&)*.*/$1/',-1,regionname)+0;
   if prxmatch('/\d+\.\.\d+(\&\&)*/',regionname) then region_end=prxchange('s/.*\s+\d+\.\.(\d+)(\&\&)*.*/$1/',-1,regionname)+0;
   else region_end=region_st;
   type=prxchange('s/^[^\&]+\&\&(.*)/$1/',-1,regionname);
   type=prxchange('s/\/(site_type|region_name|note)=//',-1,type);
   type=prxchange('s/\&\&/; /',-1,type);
   type=prxchange('s/\"//',-1,type);
   regionname=prxchange('s/^([^\&]+)\&\&.*/$1/',-1,regionname);
   if not prxmatch('/^\s*DBSOURCE    REFSEQ:/',regionname)  then output;
  end; 
 end;
 
 Protein=scan(_infile_,2,' ');
 call missing(info);
end;
else do;
 if (prxmatch('/^\s*(DBSOURCE    REFSEQ: accession|CDS|Source|Protein|sig_peptide|Site|Region|\/(note|region_name|site_type|gene)\=)/',_infile_)) then do;
  if (prxmatch('/\s*\/gene\=/',_infile_)) then gene=prxchange('s/\s*\/gene\="([^"]+)"/$1/',-1,_infile_);
  else do;
   if prxmatch('/\s*\/(note|region_name|site_type)\=/',_infile_) then do;
     info=catx('&&',info,_infile_);
   end;
   else info=catx('|',info,_infile_);
  if (prxmatch('/DBSOURCE    REFSEQ: accession/',_infile_)) then Refseq=prxchange('s/DBSOURCE    REFSEQ: accession (\S+).*/$1/',-1,_infile_);
  end;

 end;

end;
input;
end;
output;
drop info ii nitems;
);
%put &infile_cmd1;

*Note: the following codes just read the raw gbff file as a single variable;
%symdel obs;

%ImportFileHeadersFromZIP(
zip=%sysfunc(getoption(work))/hg38gpff.gz,/*Only provide file with .gz, .zip, or common text file without comporession*/
filename_rgx=.,
obs=max,
sasdsdout=&outdsd,
deleteZIP=0,
infile_command=%str(
firstobs=1 obs=max lrecl=32767 end=done;
length Protein $15. info $10000. gene $20. regionname $500. type $500. Refseq $30.;

),
/*Better to use nrbquote to replace str and use unquote within the macro
to get back the input infile_command;*/
extra_infile_macrovar_prefix=infile_cmd,/*To prevent the crash of sas when the length of the macro var infile_command is too long,
it is better to assign different parts of infile commands into multiple global macro vars with similar prefix, such as infile_cmd;
it is better to use bquote or nrbquote to excape each extra infile command!*/
num_infile_macro_vars=1,/*Provide positve number to work with the global macro var of extra_infile_macrovar_prefix*/
use_zcat=0,
var4endlinenum=adj_endlinenum, /*make global var for the endline number but it is
necessary to use syminputx in the infile_command to record the endline number;
call symputx("&var4endlinenum",trim(left(put(_n_,8.))));
It is possible to assign other numeric value generated in the infile_command to
this macro var for other purpose, because this global macro var will be accessible
by other outsite macros!
call symputx('adj_endlinenum',trim(left(put(rowtag,8.))));*/
global_var_prefix4vars2drop=drop_var,/*To handle the issue of trunction of macro var infile_command if there are too many variables to be dropped in the infile procedure;
it is feasible to create global macro variables with the same prefix, such as drop_var, to exclude them*/
num_vars2drop=0 /*Provide postive number to work with the macro var global_var_prefix4vars2drop to resolve these variables to be excluded*/
);

/*print the first 10 records for the imported gwas*/
title "First 10 records in &outdsd derived from the gbff: &gbff_gz_file";
proc print data=&outdsd(obs=10);run;

%if %index(&OldOutDsd,.) and "%scan(&OldOutDsd,1,.)"^="work" %then %do;
proc datasets nolist;
copy in=work out=%scan(&OldOutDsd,1,.) memtype=data move;
select &outdsd;
run;
%end;

%mend;

/*Demo codes:;

filename M url "https://raw.githubusercontent.com/chengzhongshan/COVID19_GWAS_Analyzer/main/Macros/importallmacros_ue.sas";
%include M;
Filename M clear;
%importallmacros_ue(MacroDir=%sysfunc(pathname(HOME))/Macros,fileRgx=.,verbose=0);  

%import_ncbi_gpff(
gpff_url=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.40_GRCh38.p14/GCF_000001405.40_GRCh38.p14_protein.gpff.gz,
outdsd=hg38_gpff
);


*/
