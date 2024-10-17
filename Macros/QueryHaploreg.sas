%macro QueryHaploreg(/*Query Haploreg4 for each input SNP to get genes close to it!*/
rsids=rs2564978 rs17425819,
dsdout=results,
print_html=0 /*Print out the annotations of query SNP(s)*/
);

%do _gi_=1 %to %ntokens(&rsids);
%let rsid=%scan(&rsids,&_gi_,%str( ));
%let query_url=%nrstr(https://pubs.broadinstitute.org/mammals/haploreg/detail_v4.2.php?query=&id=)&rsid;
filename J temp;
proc http url=%str("&query_url") 
out=J;
run;
%if &_gi_=1 %then %do;
data &dsdout(keep=gene rsid info); 
 length gene rsid $25.;
 infile J  truncover end=eof lrecl=32767 ; 
 input;
info=_infile_;
gene="NaN";
rsid="&rsid";
gene=prxchange('s/^.*><a href="http:\/\/www.ncbi.nlm.nih.gov\/gene\?term=[^><]+">[^><]+<\/a><\/td><td>([^><]+)<\/td><.*/$1/',-1,info);
info=prxchange('s/<\/tr><\/table><p>Regulatory chromatin states from.*/<\/table><\/body>/',-1,info);
if eof;
 run; 
/* proc print;run; */
filename J clear;
%end;
%else %do;
data &dsdout&_gi_(keep=gene rsid info); 
 length gene rsid $25.;
 infile J truncover end=eof lrecl=32767; 
 input;
info=_infile_;
gene="NaN";
rsid="&rsid";
gene=prxchange('s/^.*><a href="http:\/\/www.ncbi.nlm.nih.gov\/gene\?term=[^><]+">[^><]+<\/a><\/td><td>([^><]+)<\/td><.*/$1/',-1,info);
info=prxchange('s/<\/tr><\/table><p>Regulatory chromatin states from.*/<\/table><\/body>/',-1,info);
if eof;
 run; 
/* proc print;run; */
filename J clear;
data &dsdout;
set &dsdout &dsdout&_gi_;
run;
proc datasets nolist;
delete &dsdout&_gi_;
run;

%end;

%end;
%if &print_html=1 %then %do;
proc print;run;
%end;
%mend;

/*Demo codes:;

option mprint mlogic symbolgen;

%QueryHaploreg(
rsids= rs17425819 rs2564978,
dsdout=results,
print_html=1
);
*Note: a simple HTML format will be printed based on data from the variable info;

*/






