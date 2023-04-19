%macro add_symbol4grp_in_dsd(dsdin,grp_var,symbols,dsdout);
proc sql;
create table grp_var as
select unique(&grp_var) 
from &dsdin;
data grp_var;
set grp_var;
symbol_grp=scan("&symbols",_n_,' ');
if symbol_grp="" then symbol_grp='X';
run;
proc sql;
create table &dsdout as
select a.*,b.symbol_grp 
from &dsdin as a,
     grp_var as b
where a.&grp_var=b.&grp_var;

%mend;
/*Demo: the limitation is that specific sas metachar can not be used by macro var symbols;

*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

*Download UMAP gz file;
%let httpfile_url=https://cells.ucsc.edu/covid-hypertension/Seurat_umap.coords.tsv.gz;
*In SAS ondemand, putting data into the temporary work directory will not be limited by the 5GB quota!;
%dwn_http_file(httpfile_url=&httpfile_url,outfile=Seurat_umap.coords.tsv.gz,outdir=%sysfunc(getoption(work)));

*Import UMAP gz file into SAS;
%ImportFileHeadersFromZIP(
zip=%sysfunc(getoption(work))/Seurat_umap.coords.tsv.gz,
filename_rgx=.,
obs=max,
sasdsdout=x,
deleteZIP=0,
infile_command=%str(
obs=max delimiter='09'x truncover;
length seq_ID $200.;
input seq_ID $ x y;)
);

*Download cell type and other meta info;
filename meta url 'https://cells.ucsc.edu/covid-hypertension/meta.tsv';
proc import datafile=meta dbms=tab out=info replace;
getnames=yes;guessingrows=100000;
run;

*Add meta info into UMAP dataset;
proc print data=x(obs=10);
proc print data=info(obs=10);
run;
proc sql;
create table UMAP as 
select a.*,b.*
from x as a,
     info as b
where a.seq_ID=b.cell;

*Draw scatterplot of UMAP;    
proc sgplot data=UMAP;
scatter x=x y=y/group=cluster;
run;

option mprint mlogic symbolgen;

%add_symbol4grp_in_dsd(
dsdin=UMAP,
grp_var=cluster,
symbols=%nrstr(+ * | a b c d e f g h i y z w n h m n r w q),
dsdout=UMAP1);

ods graphics on/width=600 height=1000;
proc sgpanel data=UMAP1;
where cluster contains 'Ciliated';
panelby severity/onepanel columns=1 novarname;
scatter x=x y=y/group=cluster markerchar=symbol_grp;
run;

*Better way is to use datacontrastcolors and datasymbols for sgpanel;
ods graphics on/width=600 height=1000;
proc sgpanel data=UMAP1;
 *Only after the using up the combination of all colors with the 1st datasymbol, it will use the combinations of;
 *colors with 2nd datasymbols, and the same applied to other datasymbols;
 styleattrs datacontrastcolors=(green gold red black blue grey pink)  
            datasymbols=(circlefilled starfilled triangle diamond square circle) ;
where cluster contains 'Ciliated';
panelby severity/onepanel columns=1 novarname;
scatter x=x y=y/group=cluster;
run;

*/






