%macro Long_format_muts2ProteinTrack(
/*See the demo code at the end of this macro for how to generate fake gtf and inptu data set based on ncbi gpff file;
Note: several important parameters can adjust the label on the top:
yoffset4max_drawmarkersontop  and Yoffset4textlabels can be used to enlarge the top regions covering the labels;
pct2adj4dencluster is able to increase the distance among these labels.
text_rotate_angle and  pct2adj4dencluster control the rotation of these labels.
*/
longformat_muts=,/*Long format HGI GWAS with association signals in a union by same columns and different gwas dsd names;
Note: the input GWAS data should be in hg38 build if querying by genesymbol!*/
gwas_dsd_var=gwas,/*The gwas variable in the longformat_muts*/
filter4gwas_dsd=,/*Add full sas conditional filter for filtering snps by GWAS dsd, such as the following without adding ;:
%nrbquote(if prxmatch('/DF/',&gwas_dsd_var)); note: superq can not be used here!*/
query_rsid_or_genesymbol=1:1:1000 ,/*Subset the long format GWAS by rsid or genesymbol, rsid should be in the format of chr:st:end*/
dist2snp_or_gene=1,/*in bp; left or right size distant to each target Gene for the Manhattan plot*/
subset_gwas_dsd=subset_gwas_dsd,/*Output subset gwas dataset for further visualization with other sas macro if necessary*/
gwas_chr_var=chr,/*GTF uses numeric chr notation; ensure the type of chr is consistent with input gwas dsd*/
gwas_p_var=p,
gwas_beta_var=beta,
gwas_se_var=se,
gwas_snp_var=rsid,
gwas_pos_var=pos,
GenerateGeneManhattanPlot=1,/*To not generate gene Manhattan plot, provide value 0 here*/
SNPs2label_scatterplot_dots=,/*Add mut ids to label scatter dots at the top of figure; ensure
gwas_snp_var contain these mut ids, otherwise, these muts will not be */
var4label_scatterplot_dots=,/*Use either this var or input SNPs IDs to label vars*/
yoffset4max_drawmarkersontop=0.5,/*Increase the top offset region for snp labels*/
Yoffset4textlabels=3.5, /*Move up the text labels for target SNPs in specific fold; 
the default value 2.5 fold works for most cases*/
text_rotate_angle=90, /*Angle to rotate text labels for these selected dots by users*/
auto_rotate2zero=0, /*supply value 1 when less than 3 text labels, it is good to automatically set the text_rotate_angel=0*/
pct2adj4dencluster=20,/*For SNP labels on the top, please try to use this parameter, which only works when 
there are less than or equal to 3 top SNPs if track_width <= 500, or 5 top SNPs if track_width between 500 and 800, or 6 top SNPs if 
track_width >=800, otherwise, this parameter will be excluded and even step will be used to separate them on the top!
and SNPs within a cluster are overlapped with each other or overlapped with elements from other SNP cluster, so it is feasible to 
avoid this issue by increasing the pct or reducing it, respectively*/
gtf_dsd=LG.GTF_HG38,
Gene_Var_GTF=Genesymbol,
GTF_Chr_Var=chr,
GTF_ST_Var=st,
GTF_End_Var=end,
design_width=1000, 
design_height=5000, 
barthickness=20, /*gene track bar thinkness*/
dotsize=8, 
dist2sep_genes=10,/*Distance to separate close genes into different rows in the gene track; provide negative value
to have all genes in a single row in the final gene track*/
where_cndtn_for_gwasdsd=%str(), /*where condition to filter input gwas_dsd*/
gwas_labels_in_order=,
/*The order will be from down to up in the final tracks*/
outfigfmt=png
);

%let SNP_long_dsd=tgt;

%if %sysfunc(prxmatch(/^(rs\d+|\d+:\d+)/,&query_rsid_or_genesymbol)) %then %do;
  %put We are going to get the genomic position and chromosome for the input query SNP &query_rsid_or_genesymbol;

  %if %sysfunc(prxmatch(/^(rs\d+)/,&query_rsid_or_genesymbol)) %then %do;
  proc sql noprint;
  select &gwas_chr_var,&gwas_pos_var into: tgt_chr, : tgt_pos
  from
  &longformat_muts
  where &gwas_snp_var="&query_rsid_or_genesymbol";
  %end;

  %else %do;

  %let tgt_chr=%scan(&query_rsid_or_genesymbol,1,:);
  %let tgt_pos1=%scan(&query_rsid_or_genesymbol,2,:);
  %let tgt_pos2=%scan(&query_rsid_or_genesymbol,3,:);

  %end;

  data tgt;
  set &longformat_muts;
  keep &gwas_snp_var &gwas_pos_var &gwas_chr_var &gwas_dsd_var 
           &gwas_beta_var &gwas_se_var &gwas_p_var &var4label_scatterplot_dots;
  where &gwas_snp_var^="" and &gwas_chr_var=&tgt_chr and 
  (&gwas_pos_var between &tgt_pos1-&dist2snp_or_gene and &tgt_pos2+&dist2snp_or_gene);
  run;

	%if %length(&tgt_chr)=0 %then %do;
	   %put No records related to the query SNP &query_rsid_or_genesymbol in the input GWAS &longformat_muts;
		 %abort 255;
	 %end;
  %put target chr and position for the snp are &tgt_chr and &tgt_pos;


%end;
%else %do;
   %put The macro stopped due to the input data set not containing information for the query var;
   %abort 255;
%end;

%if %length(&query_rsid_or_genesymbol)>0 %then %do;
data &SNP_long_dsd;
set &SNP_long_dsd;
%if %length(&filter4gwas_dsd)>0 %then %do;
 *filter GWAS dsd;
 /*if prxmatch('/DF/',dsd);*/
  %unquote(&filter4gwas_dsd);
%end;
run;
%end;


%if %sysfunc(exist(&SNP_long_dsd))=0 %then %do;
		%put You filtered &SNP_long_dsd dataset does not exist;
		%abort 255;
%end;

%long2wide4multigrpsSameTypeVars(
long_dsd=&SNP_long_dsd,
outwide_dsd=&subset_gwas_dsd,
grp_vars=&gwas_snp_var &gwas_chr_var &gwas_pos_var &var4label_scatterplot_dots,/*If grp_vars and SameTypeVars are overlapped,
the macro will automatically only keep it in the grp_vars; 
grp_vars can be multi vars separated by space, which 
can be numeric and character*/
subgrpvar4wideheader=&gwas_dsd_var,/*This subgrpvar will be used to tag all transposed SameTypeVars 
in the wide table, and the max length of this var can not be >32!*/
dlm4subgrpvar=.,/*string used to split the subgrpvar if it is too long*/
ithelement4subgrpvar=1,/*Keep the nth splitted element of subgrpvar and use it for tag 
in the final wide table*/
SameTypeVars=_numeric_, /*These same type of vars will be added with subgrp tag in the 
final wide table; Make sure they are either numberic or character vars and not 
overlapped with grp_vars and subgrpvar!*/
debug=0 /*print the first 2 records for the final wide format dsd*/
);
/*%abort 255;*/
data &subset_gwas_dsd;
set &subset_gwas_dsd;
drop &gwas_chr_var._: &gwas_pos_var._:;
run;


%Get_All_Var_Info(indsd=&subset_gwas_dsd,outdsd=tgt_vars);
proc sql noprint;
select name into: pvar_list separated by ' '
from tgt_vars 
where prxmatch( "/^&gwas_p_var._/i",name);
select name into: betavar_list separated by ' '
from tgt_vars 
where prxmatch("/^&gwas_beta_var._/i",name);


%if %length(&gwas_labels_in_order)=0 %then 
 %let gwas_labels_in_order=%sysfunc(prxchange(s/&gwas_p_var._//,-1,&pvar_list));


*Need to reorder the input p and beta values according to the order of gwas_labels_in_order;
%idx4list_in_alphabet_ord(
list=&gwas_labels_in_order, 
outdsd=gwaslist_order, 
index_list_var=idx4gwas_list,
sep=%str( )
);

%let _pvar_list_=;
%let _betavar_list_=;
%let _idx_i_=1;
%do %while (%scan(&idx4gwas_list,&_idx_i_,%str( )) ne );
		%let 	_pvar_list_=&_pvar_list_ %scan(&pvar_list,&_idx_i_,%str( ));
		%let _betavar_list_=&_betavar_list_ %scan(&betavar_list,&_idx_i_,%str( ));
		%let _idx_i_=%eval(&_idx_i_+1);
%end;

%SNP_Local_Manhattan_With_GTF(/*As this macro use other sub-macros, it is not uncommon that some global macro
vars would be in the same name, such as macro vars chr and i, thus, to avoid of crash, chr_var is used instead of macro
var chr in this macro*/
gwas_dsd=&subset_gwas_dsd,
chr_var=&gwas_chr_var,
AssocPVars=&_pvar_list_,
SNP_IDs=&query_rsid_or_genesymbol,
/*if providing chr:pos or chr:st:end, it will query by pos;
Please also enlarge the dist2snp to extract the whole gene body and its exons,
altought the final plots will be only restricted by the input st and end positions!*/
dist2snp=&dist2snp_or_gene,
/*in bp; left or right size distant to each target SNP for the Manhattan plot*/
SNP_Var=&gwas_snp_var,
Pos_Var=&gwas_pos_var,
gtf_dsd=&gtf_dsd,
ZscoreVars=&_betavar_list_,/*Can be beta1 beat2 or other numberic vars indicating assoc or other +/- directions*/ 
gwas_labels_in_order=&gwas_labels_in_order,/*If providing _ for labeling each GWAS, 
the _ will be replaced with empty string, which is useful when wanting to remove gwas label 
if only one scatterplot or the label for a gwas containing spaces;
The list will be used to label scatterplots 
by the sub-macro map_grp_assoc2gene4covidsexgwas*/
design_width=&design_width, 
design_height=&design_height, 
barthickness=&barthickness, /*gene track bar thinkness*/
dotsize=&dotsize, 
dist2sep_genes=&dist2sep_genes,/*Distance to separate close genes into different rows in the gene track; provide negative value
to have all genes in a single row in the final gene track*/
where_cndtn_for_gwasdsd=%str(), /*where condition to filter input gwas_dsd*/

shift_text_yval=0.2, /*in terms of gene track labels, add positive or negative vale, ranging from 0 to 1, 
                      to liftup or lower text labels on the y axis; the default value is -0.2 to put gene lable under gene tracks;
                      Change it with the macro var pct4neg_y!*/
fig_fmt=&outfigfmt, /*output figure formats: svg, png, jpg, and others*/
pct4neg_y=4, /*the most often used value is 1;
              compacting the bed track y values by increasing the scatterplot scale, 
              which can reduce the bed trace spaces; It seems that two-fold increasement
              leads to better ticks for different tracks!
              Use value >1 will increase the gene tract, while value < 1 will reduce it!
              Note: when there are only 1 or 2 scatterplots, it is better to provide value = 0.5;
              Modify this parameter with the parameter shift_text_yval to adjust gene label!
              Typically, when there are more scatterplots, it is necessary to increase the value of pct4neg_y accordingly;
              If there are only <4 scatterplots, the value would be usually set as 1 or 2;
              */
adjval4header=2, /*In terms of header of each subscatterplot, provide postive value to move up scatter group header by the input value*/
makedotheatmap=1,/*use colormap to draw dots in scatterplot instead of the discretemap;
Note: if makedotheatmap=1, the scatterplot will not use the discretemap mode based on
the negative and postive values of lattice_subgrp_var to color dots in scatterplot*/

color_resp_var=,/*Use value of the var to draw colormap of dots in scatterplot
if empty, the default var would be the same as that of yval_var;*/

makeheatmapdotintooneline=1,/*This will make all dots have the same yaxis value but have different colors 
based on its real value in the heatmap plot; To keep the original dot y axis value, assign 0 to the macro var
This would be handy when there are multiple subgrps represented by different y-axis values! By modifying
the y-axis values for these subgrps, the macro can plot them separately in each subtrack!
*/
var4label_scatterplot_dots=&var4label_scatterplot_dots,/*Make sure the variable name is not grp, which is a fixed var used by the macro for other purpose;
the variable should contain values of target SNPs and other non-targets are asigned with empty values;
Whenever  makeheatmapdotintooneline=1 or 0, it is possible to use values of the var4label_scatterplot_dots to
label specific scatterplot dots based on the customization of the variable predifined by users for the input data set; 
default is empty; provide a variable that include non-empty strings for specific dots in the 
scatterplots;*/
SNPs2label_scatterplot_dots=&SNPs2label_scatterplot_dots, /*Add multiple SNP rsids to label dots within or at the top of scatterplot
Note: if this parameter is provided, it will replace the parameter var4label_scatterplot_dots!
*/
text_rotate_angle=&text_rotate_angle, /*Angle to rotate text labels for these selected dots by users*/
auto_rotate2zero=&auto_rotate2zero, /*supply value 1 when less than 3 text labels, it is good to automatically set the text_rotate_angel=0*/
pct2adj4dencluster=&pct2adj4dencluster,/*For SNP labels on the top, please try to use this parameter, which only works when 
there are less than or equal to 3 top SNPs if track_width <= 500, or 5 top SNPs if track_width between 500 and 800, or 6 top SNPs if 
track_width >=800, otherwise, this parameter will be excluded and even step will be used to separate them on the top!
and SNPs within a cluster are overlapped with each other or overlapped with elements from other SNP cluster, so it is feasible to 
avoid this issue by increasing the pct or reducing it, respectively*/
yoffset4max_drawmarkersontop=&yoffset4max_drawmarkersontop,
Yoffset4textlabels=&Yoffset4textlabels /*Move up the text labels for target SNPs in specific fold; 
the default value 2.5 fold works for most cases*/

);


%mend;

/*Demo codes:;

*Use the sas macro import_ncbi_gpff to generate hg38 gpff;
*Modify the gpff by manually creating required vars;

libname G "E:\NTU_Testing";
data fake_gtf;
set G.Hg38_gpff;
reganno=type;
chr=1;
st=region_st;
end=region_end;
genesymbol=protein;
protein_coding=1;
if substr(regionname,1,3)="CDS" then delete;
if substr(regionname,1,7)="Protein" then type="gene";
else if (substr(regionname,1,6)="Region") then type="exon";
else type="exon";
where gene="JAK2" ;
run;
proc sort nodupkeys;by genesymbol st end;run;
data fake_gtf;
set fake_gtf;
where genesymbol in ("NP_004963" "NP_001309133" "NP_001309128") ;
run;

data sites;
set fake_gtf;
P=0.1;
beta=0.1;
se=0.01;
if _n_>10 then P=0.01;
pos=mean(of st,end);
reganno=prxchange("s/ +/_/",-1,trim(left(scan(reganno,1,';'))));
where type="exon";
run;
proc sql noprint;
select regionname into: tgt_labels separated by ' '
from sites;

*************The above prepare required vars and data for making protein tracks;

%Long_format_muts2Proteintrack(
longformat_muts=sites,
filter4gwas_dsd=%nrbquote(if prxmatch("/./",&gwas_dsd_var)),
query_rsid_or_genesymbol=1:1:1000,
dist2snp_or_gene=50,
subset_gwas_dsd=subset_gwas_dsd,
gwas_chr_var=chr,
gwas_p_var=p,
gwas_beta_var=beta,
gwas_se_var=se,
gwas_snp_var=regionname,
gwas_pos_var=pos,
GenerateGeneManhattanPlot=1,
SNPs2label_scatterplot_dots=,
var4label_scatterplot_dots=reganno,
yoffset4max_drawmarkersontop=0.25,
Yoffset4textlabels=1.5, 
text_rotate_angle=90, 
auto_rotate2zero=0, 
pct2adj4dencluster=0.01,
gtf_dsd=fake_gtf,
Gene_Var_GTF=Genesymbol,
GTF_Chr_Var=chr,
GTF_ST_Var=st,
GTF_End_Var=end,
design_width=1000, 
design_height=700, 
barthickness=20, 
dotsize=8, 
dist2sep_genes=100000,
where_cndtn_for_gwasdsd=%str(), 
gwas_labels_in_order=Test,
outfigfmt=png
);

*/

