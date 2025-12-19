%macro QueryGTEx4GeneID(
geneids=Apobec3a Apobec3b,/*For Apobec3a*/
genomeBuild=hg38,/*hg38, but hg19 is not supported by GTEx*/
outdsd=gene_info
);
%let genomeBuild=%str(GRCh38/hg38);
%if "&genomeBuild"="hg19" %then %do;
 %let genomeBuild=%str(GRCh37/hg19);
 %put The hg19 query does not work right now;
 %abort 255;
%end;

%let gstot=%ntokens(&geneids);
%do _gsi_=1 %to &gstot;
  %let geneid=%scan(&geneids,&_gsi_,%str( ));
  %let api=https://gtexportal.org/api/v2/reference/geneSearch;
  %let url_link=%str(&api?geneId=&geneid);
  filename out temp;
  proc http url="&url_link"
 /*Local Window SAS dose not have this updated option*/
/*  method=get*/
  out=out;
  debug level=2;
  run;
  data _null_;
  infile out;
  input;
  put _infile_;
  rc=jsonpp('out','log');
  run;

  libname eqtl json fileref=out;
  data &outdsd._info&_gsi_;
  set eqtl.data;
  where geneSymbol=upcase("&geneid");
  run;
  filename out clear;
  libname eqtl clear;
%end;

/*
data &outdsd;
set &outdsd._info:;
run;
*/
%Union_Data_In_Lib_Rgx(lib=work,excluded=,dsd_contain_rgx=&outdsd._info.*,dsdout=&outdsd);

proc datasets nolist;
delete &outdsd._:;
run;

/* title "Info for gene &geneid"; */
/* proc print data=&outdsd(obs=10); */
/* %print_nicer; */
/* run; */

%mend;

/*Demo:

*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

*For Apobec3a eqtls;
%QueryGTEx4GeneID(
geneids=Apobec3a Apobec3h Apobec3b Apobec3c,
genomeBuild=hg38,
outdsd=gene_info
);

*/
