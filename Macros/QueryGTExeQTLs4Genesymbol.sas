%macro QueryGTExeQTLs4Genesymbol(
geneids=Apobec3a Apobec3b,/*For Apobec3a*/
outdsd=gene_eqtls
);
%let gstot=%ntokens(&geneids);
%do _gsi_=1 %to &gstot;
  %let geneid=%scan(&geneids,&_gsi_,%str( ));
  %let api=https://gtexportal.org/api/v2/reference/geneSearch;
  %let url_link=%str(&api?geneId=&geneid);
  filename out temp;
  proc http url="&url_link"
  method=get
  out=out;
  debug level=2;
  run;

  /* data _null_; */
  /* infile out; */
  /* input; */
  /* put _infile_; */
  /* rc=jsonpp('out','log'); */
  /* run; */

  libname eqtl json fileref=out;
  data &outdsd._info&_gsi_;
  set eqtl.data;
  where geneSymbol=upcase("&geneid");
  /* logP=-log10(pvalue); */
  /* drop ordinal: snpidUpper geneSymbolUpper; */
  run;
  filename out clear;
  libname eqtl clear;
/*   title "Info for gene &geneid"; */
/*   proc print data=&outdsd(obs=10); */
/*   %print_nicer; */
/*   run; */
%end;
data &outdsd._info;
set &outdsd._info:;
run;
proc sql noprint;
select  distinct gencodeId into: ensembl_genes separated by ' '
from &outdsd._info;
drop table &outdsd._info;
quit;
proc datasets nolist;
delete &outdsd._info:;
run;
%QueryGTExeQTLs4MultEnsemblGenes(
ensembl_gene_ids=&ensembl_genes,
outdsd=&outdsd
);
proc datasets nolist;
delete &outdsd._:;
run;
title "First 10 eQTL records for the genes: &geneids";
proc print data=&outdsd(obs=10);
%print_nicer;
run;

%mend;

/*Demo:

*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

*For Apobec3a eqtls;
%QueryGTExeQTLs4Genesymbol(
geneids=Apobec3a Apobec3h Apobec3b Apobec3c,
outdsd=gene_eqtls
);

*/
