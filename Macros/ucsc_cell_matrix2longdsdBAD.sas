%macro ucsc_cell_matrix2longdsdBAD(
gzfile_or_url,
dsdout
);

%if %eval(%sysfunc(prxmatch(/http.*gz/i,&gzfile_or_url))=1) %then %do;
 *Download exp matrix gz file;
 *In SAS ondemand, putting data into the temporary work directory will not be limited by the 5GB quota!;
 %dwn_http_file(httpfile_url=&gzfile_or_url,outfile=exp.matrix.gz,outdir=%sysfunc(getoption(work)));
 %let file=%sysfunc(getoption(work))/exp.matrix.gz;
%end;
%else %do;
 %if %eval(%sysfunc(prxmatch(/http.*gz/i,&gzfile_or_url))=1) %then %do;
   %let file=&gzfile_or_url;
 %end;
 %else %do;
   %put "Please make sure your input file &gzfile_or_url is gz file!";
   %abort 255;
 %end;
%end;
*Import UMAP gz file into SAS;
%let lengthmax=32767;
*read data records;
*This is not comprehensive;
*If the line length >32767, the colnames would not include all records;
*Ensure the right delimiter used by countc and scan;
%ImportFileHeadersFromZIP(
zip=&file,
filename_rgx=.,
obs=max,
sasdsdout=headers,
deleteZIP=1,
infile_command=%str(
delimiter='09'x firstobs=1 obs=3 truncover;
length rownames colnames $50. headers $32767.;
retain ncols 0 headers '';
if _n_=1 then do;
 input;
 ncols=countc(_infile_,'09'x,'st')+1;
 headers=_infile_; 
end;
else do;
 input rownames :$50. @@;
 do i=1 to ncols-1;
  input values @;
  colnames=scan(headers,i+1,'09'x);
  output;
 end;
end;
drop i ncols headers;
)
);

%mend;
/*Demo:
*https://communities.sas.com/t5/SAS-Procedures/first-row-exceed-32767-lrecl-not-work/td-p/217384

%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

*options mprint mlogic symbolgen;
%ucsc_cell_matrix2longdsdBAD(
gzfile_or_url=https://cells.ucsc.edu/covid-hypertension/exprMatrix.tsv.gz,
dsdout=a
);

*/


 
