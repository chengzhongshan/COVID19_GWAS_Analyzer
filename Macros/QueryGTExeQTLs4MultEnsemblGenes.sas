%macro QueryGTExeQTLs4MultEnsemblGenes(
ensembl_gene_ids=ENSG00000128383.12,/*For Apobec3a Apobec3b and others, separated by blank space;*/
outdsd=gene_eqtls
);
%let ngenes=%ntokens(&ensembl_gene_ids);
%do _gi_=1 %to &ngenes;
   %let ensembl_gene_id=%scan(&ensembl_gene_ids,&_gi_,%str( ));
   %let url_link=%bquote(https://gtexportal.org/api/v2/association/singleTissueEqtl?gencodeId=&ensembl_gene_ids)%nrstr(&itemsPerPage=100000);
   filename out temp;
   proc http url="&url_link"
/*   for windows SAS9.4, the default method is get and the method parameter is not available in local windows SAS9.4*/
/*   method=get*/
   out=out ;
   debug level=2;
   run;

   /* data _null_; */
   /* infile out; */
   /* input; */
   /* put _infile_; */
   /* rc=jsonpp('out','log'); */
   /* run; */

   libname eqtl json fileref=out;
   data &outdsd._&_gi_;
   set eqtl.data;
   logP=-log10(pvalue);
   drop ordinal: snpidUpper geneSymbolUpper;
   run;
   filename out clear;
   libname eqtl clear;
%end;
data &outdsd;
set &outdsd._:;
run;
/*
title "First 10 eQTL records for the gene &ensembol_gene_id";
proc print data=&outdsd(obs=10);
%print_nicer;
run;
*/

%mend;

/*Demo:

*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

*For PHYHD1, ENSG00000175287.18, which has >4000 eQTLs;
%QueryGTExeQTLs4MultEnsemblGenes(
ensembl_gene_ids=ENSG00000175287.18,
outdsd=gene_eqtls
);

*For debugging when the above failed if there are too many eQTL records;
filename out temp;
proc http url="%bquote(https://gtexportal.org/api/v2/association/singleTissueEqtl?gencodeId=ENSG00000175287.18)%nrstr(&itemsPerPage=100000)" out=out ;
debug level=2;
run;
libname eqtl json fileref=out;
data test;
set eqtl.data;
logP=-log10(pvalue);
drop ordinal: snpidUpper geneSymbolUpper;
run;
filename out clear;
libname eqtl clear;
 
*For Apobec3a eqtls;
%QueryGTExeQTLs4MultEnsemblGenes(
ensembl_gene_ids=ENSG00000128383.12 ENSG00000179750.15,
outdsd=gene_eqtls
);

*/
