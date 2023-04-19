%macro Query_GTEx_eQTLs4Genesymbol(
ensembl_gene_id=ENSG00000128383.12,/*For Apobec3a*/
outdsd=gene_eqtls
);

*https://gtexportal.org/api/v2/redoc#tag/Static-Association-Endpoints/operation/get_significant_single_tissue_eqtls_api_v2_association_singleTissueEqtl_get;
*for Apobec3a: ENSG00000128383.12;
%let url_link=%str(https://gtexportal.org/api/v2/association/singleTissueEqtl?gencodeId=&ensembl_gene_id);
filename out temp;
proc http url="&url_link"
method=get
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
data &outdsd;
set eqtl.data;
drop ordinal: snpidUpper geneSymbolUpper;
run;
libname eqtl clear;
title "First 10 eQTL records for the gene &ensembol_gene_id";
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
%Query_GTEx_eQTLs4Genesymbol(
ensembl_gene_id=ENSG00000128383.12,
outdsd=gene_eqtls
);

*/
