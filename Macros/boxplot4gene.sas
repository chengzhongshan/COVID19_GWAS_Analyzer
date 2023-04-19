%macro boxplot4gene(dsdin,gene,grp=grp,genevar=gene);
data gene_exp;
set &dsdin;
/*where _GeneSymbol_="MAP3K19";*/
/*Alias name of MAP3K19 is YSK4*/
where &genevar="&gene";
run;

proc glm data=gene_exp;
class &grp;
model exp=&grp;
/*means grp/duncan;*/
means &grp/t;
run;


ods listing sge=on;

/*control sgplot size*/
ods graphics on / width=3in height=4in
      outputfmt=svg
      imagemap=on
      imagename="MyBoxplot4&gene"
      border=off;

proc sgplot data=gene_exp;
title "&gene expression in lung samples";
/*histogram exp;*/
/*density exp/type=kernel;*/
/*keylegend /location=inside position=topright;*/
vbox exp/category=&grp;
run;
ods listing close;
title;

%mend;
/*Demo:
*Note: input &dsdin is a long format dataset;

%boxplot4gene(dsdin=Normalized_exp_subset_long,gene=IL10,grp=grp);

*/

