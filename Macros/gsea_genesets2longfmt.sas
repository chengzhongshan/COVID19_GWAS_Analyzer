%macro gsea_genesets2longfmt(file=,dsdout=,fileout=);

proc import datafile="&file" dbms=tab out=genes replace;
getnames=no;guessingrows=100000;
run;
proc sort data=genes;by var1;
proc transpose data=genes out=genes_tr;
var var:;
by var1;
run;
data &dsdout(rename=(col1=genesymbol var1=geneset) drop=_name_);
set genes_tr;
if col1="" then delete;
if _name_='VAR1' then delete;
run;
%if "&fileout"^="" %then %do;
proc export data=&dsdout outfile="&fileout" dbms=tab replace;
run;
%end;

%mend;


/*Demo:;

%gsea_genesets2longfmt(file=Z:\ResearchHome\ClusterHome\zcheng\shared\Hallmark_gene_sets.txt,
                       dsdout=x,
                       fileout=Z:\ResearchHome\ClusterHome\zcheng\shared\Hallmark_gene_sets_longformat.txt
);

*/

