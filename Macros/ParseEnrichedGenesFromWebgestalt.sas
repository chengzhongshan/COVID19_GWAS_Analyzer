%macro ParseEnrichedGenesFromWebgestalt(enrichment_file,dsdout);
*typical Webgestalt file: enrichment_results_wg_result1642738253.txt;
proc import datafile="&enrichment_file"
dbms=tab out=&dsdout replace;
getnames=yes;
guessingrows=1000;
run;

data &dsdout (keep=gene description FDR);
*use strict FDR < 0.01;
set &dsdout(where=(FDR<0.01));
i=countc(userid,';')+1;
do while (i>0);
 gene=scan(userid,i,';');output;
	i=i-1;
end;
run;
/*proc sort nodupkeys;by gene description;run;*/
proc sort nodupkeys;by gene;run;

*Only select the top 140 genes based on FDR;
proc sort data=&dsdout;by FDR;run;
data &dsdout;
set &dsdout;
if _n_<=140;
run;
%mend;

/*Demo:
x cd "J:\Coorperator_projects\ACE2_2019_nCOV\Covid_GWAS_Manuscrit_Related\MAP3K19_Manuscript\Figures_Tables\covid19_female_vs_male_gwas_results";

%ParseEnrichedGenesFromWebgestalt(
enrichment_file=NECTIN1_top_downregulated_genes_KEGG_enrichment/enrichment_results_wg_result1643152335.txt,
dsdout=downreggenes);

%ParseEnrichedGenesFromWebgestalt(
enrichment_file=NECTIN1_top_upregulated_genes_KEGG_enrichment/enrichment_results_wg_result1643152493.txt,
dsdout=upreggenes);

*/

