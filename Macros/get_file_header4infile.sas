%macro get_file_header4infile(filename,rownum4header,dlm,dsdout);
filename H "&filename";
data &dsdout;
  length header $200.;
   infile H obs=&rownum4header length=len firstobs=&rownum4header;
			input;
			n=_n_;
			ndlm=countc(_infile_,&dlm);
   do i=1 to ndlm;
     header=scan(_infile_,i,&dlm);output;
			end;
			drop i ndlm;
run;
proc print data=&dsdout(obs=10);run;
%mend;
/*usage demo:
*This macro will get specific row and transpose it into longformat data;

*x cd "J:\Coorperator_projects\ACE2_2019_nCOV\Covid_GWAS_Manuscrit_Related\MAP3K19_Manuscript\Figures_Tables\covid19_female_vs_male_gwas_results\GTEx_Sex_Diff_Analysis";
*option mprint mlogic symbolgen;

%get_file_header4infile(
filename=GTEx_Analysis_2017-06-05_v8_RNASeQCv1.1.9_gene_tpm.gct,
rownum4header=3,
dlm=%str('09'x),
dsdout=x
);
*/
