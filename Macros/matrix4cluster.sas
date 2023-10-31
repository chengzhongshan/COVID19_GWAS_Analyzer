%macro matrix4cluster(dsdin,
                      distance_method,
                      dist_matrix_out,
					  dendrogram_out,
                      cluster_method,
					  id_var4cluster,
					  numeric_vars
                      );
*Remove records with id_var4cluster as missing;
data &dsdin;
set &dsdin;
if &id_var4cluster^="";
run;

/*https://support.sas.com/documentation/cdl/en/statug/63033/HTML/default/viewer.htm#statug_distance_sect006.htm*/
%if %scan(&numeric_vars,1,' ') ne  %then %do;
proc distance data=&dsdin out=&dist_matrix_out method=&distance_method;
var interval(&numeric_vars/std=std);
id &id_var4cluster;
run;
%end;
%else %do;
proc distance data=&dsdin out=&dist_matrix_out method=Euclid;
var interval(_numeric_/std=std);
id &id_var4cluster;
run;
%end;

proc cluster data=&dist_matrix_out(type=distance) method=&cluster_method 
     pseudo outtree=&dendrogram_out(keep=_name_ _parent_ _height_);
   id &id_var4cluster;
run;

data &dendrogram_out;
set &dendrogram_out;
rename _name_=&id_var4cluster._name
       _parent_=&id_var4cluster._parent
	   _height_=&id_var4cluster._hgt
	   ;
run;

%mend;

/*Demo: use %longdsd2matlabmatrix to prepare data for %matrix4cluster;

%longdsd2matlabmatrix(dsd=x
                     ,var_row=gwas
                     ,var_col=gene_name
                     ,data_var=logP
                     ,value2asign4missing=0
                     ,dsdout=z
                     ,outdir4matrix=);

*options mprint mlogic symbolgen;

%matrix4cluster(dsdin=z,
                distance_method=Euclid,
                dist_matrix_out=dist,
                dendrogram_out=dendrogram_out,
                cluster_method=average,
				id_var4cluster=gwas,
				numeric_vars=
                      );
*/
