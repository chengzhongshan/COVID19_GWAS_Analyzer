%macro MakeCMapSimilarityScoreBarplot(cmap_similarity_score_file);
/*proc import datafile='/home/cheng.zhong.shan/data/MAP3K19_down_regulated_genes_drug_similarity_scores.txt'*/
proc import datafile="&cmap_similarity_score_file"
dbms=tab out=x replace;
run;
data x;set x;
/* where abs(score)>95 and type="cc" and name not contains ' LOF' and name not contains ' GOF'; */
where ((abs(score)>90 and type="cc") or (abs(score)>99 and type="cp")) and 
      name not contains ' LOF' and name not contains ' GOF';
run;
proc sql;
select unique(type) 
from x;
proc format;
value $ drug_type cc='drug classes'
                  cp='single drug'
;
proc sort data=x;by score;run;
data x;
set x;
n=_n_;
attrib type format=$drug_type.;
run;
proc sql;
select "'"||strip(name)||"'" into: ids4xaxis separated by ' '
from x
order by n;
select max(n) into: tot
from x;
%put &ids4xaxis &tot;
/******Codes for making waterfall chart by coloring grps with different colors*****************/
proc sql;
create table attrmap as
select unique(type) as value
from x;
data attrmap;
length fillcolor $15. id $10.;
set attrmap;
/* array tmp{*} $15 tmp1-tmp4 ('lightseagreen','lightblue','orange','gray'); */
array tmp{*} $15 tmp1-tmp4 ('darkgreen','lightred','orange','gray');
fillcolor=tmp{_n_};
id="myid1";
drop tmp1-tmp4;
run;

*change outpu directory;
/* data _null_; */
/* rc=dlgchdir('/home/cheng.zhong.shan/data'); */
/* run; */

/*options printerpath=svg;*/
/*ods listing close;*/
/*ods printer file="CMap_drug_repositioning_barplots.svg";*/

*change the height and width for the final figure;
ods graphics on/height=1200 width=1200 DISCRETEMAX=2600;
*Make sure to use group=treatment, the value of which will
*be used to match with value column in the dataset attrmap;
/* title1 "Single drugs or drug classes showing similar or opposite"; */
/* title2 "expression profiles to these MAP3K19 downregulated genes (n=140)"; */
/* footnote1 j=l "N (total number of patients) =100"; */
/* footnote2 j=l "Vbar statement in SGPLOT is used to create the chart"; */
proc sgplot data=x dattrmap=attrmap;
format type $drug_type.;
hbar n / nooutline attrid=myid1 response=score group=type transparency=0.3 name="vol";
refline -95 / axis=x label="-95" labelloc=outside labelpos=min
              lineattrs=(color=black pattern=dash);
refline 95 / axis=x label="95" labelloc=outside labelpos=min lineattrs=(color=black pattern=dash);
/* keylegend "vol" / noborder location=inside position=top; */
yaxis label="Single drugs or drug classes" labelattrs=(weight=bold) 
      values=(1 to &tot by 1) valuesdisplay=(&ids4xaxis) fitpolicy=none;
xaxis label="CMap similarity score" labelattrs=(weight=bold) grid;
run;

/*ods listing close;*/
/*ods listing;*/

%mend;


/*Demo:

%MakeCMapSimilarityScoreBarplot(cmap_similarity_score_file=J:\Coorperator_projects\ACE2_2019_nCOV\Covid_GWAS_Manuscrit_Related\MAP3K19_Manuscript\Figures_Tables\Lung_GEO_Dsd4MAP3K19\MAP3K19_down_regulated_genes_drug_similarity_scores.txt)


*/
