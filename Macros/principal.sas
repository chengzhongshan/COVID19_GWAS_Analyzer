%macro principal(Input, vars, Method, p, scoreout, outdata);
/* Reducing a set of variables (vars) using PCA, by keeping fraction p (p<=1) of the variance.
The output is stored in outdata and the model is stored in scoreout. */
/* First run PRINCOMP to get All the eigenvalues */

%if "&vars"="" %then %do;
 %let vars=_numeric_;
%end;

proc princomp data=&Input &Method outstat=Temp_eigen noprint;
var &vars;
run;
/* Then select only the top fraction p of the variance */
data Tempcov1;
set temp_Eigen;
if _Type_ ne 'EIGENVAL' then delete;
drop _NAME_;
run;
proc transpose data=Tempcov1 out=TempCovT ;
run;
data TempCov2;
set TempCovT;
retain SumEigen 0;
SumEigen=SumEigen+COl1;
run;
proc sql noprint;
select max(SumEigen) into :SEigen from TempCov2;
quit;
data TempCov3;
set TempCov2;
IEigen=_N_;
PEigen = SumEigen/&SEigen;
run;

/* Count the number of eigenvalues needed to reach p */
proc sql noprint;
select count(*) into :Nh from Tempcov3
where PEigen >= &P;
select count(*) into :NN from TempCov3;
%let N=%eval(&NN-&Nh+1);
quit;

/* Delete from the DSEigen all the rows above the needed N eigenvectors */
data &scoreout;
set Temp_Eigen;
run;
proc sql noprint;
%do i=%eval(&N+1) %to &NN;
delete from &scoreout where _NAME_ = "Prin&i";
%end;
quit;
/* And score */
proc score data=&Input Score=&scoreout Out=&outdata;
Var &vars;
run;
/* Finally, clean workspace */
proc datasets library=work nodetails;
*delete Tempcov1 Tempcov2 Tempcov3 Temp_eigen Tempcovt;
run;
quit;
%mend;

/*Demo:;
*https://www.listendata.com/2015/04/principal-component-analysis-with-sas.html;

*************For traditional data analysis*************;
data iris;
set sashelp.iris;
run;

*Method var can be empty;
%principal(Input=iris, 
           vars=SepalLength SepalWidth PetalLength PetalWidth, 
           Method=, 
           p=1, 
           scoreout=score, 
           outdata=principal)

proc template;
define statgraph sgdesign;
dynamic _PRIN1A _PRIN2A _SPECIES;
begingraph / designwidth=732 designheight=700;
   layout lattice / rowdatarange=data columndatarange=data rowgutter=10 columngutter=10;
      layout overlay / walldisplay=none xaxisopts=( griddisplay=on linearopts=( minorticks=ON)) yaxisopts=( griddisplay=on linearopts=( minorticks=ON));
         scatterplot x=_PRIN1A y=_PRIN2A / group=_SPECIES name='scatter';
         discretelegend 'scatter' / opaque=false border=true halign=center valign=top displayclipped=true down=1 order=columnmajor location=inside;
      endlayout;
   endlayout;
endgraph;
end;
run;

proc sgrender data=WORK.PRINCIPAL template=sgdesign;
dynamic _PRIN1A="PRIN1" _PRIN2A="PRIN2" _SPECIES="SPECIES";
run;




*************For gene expression PCA analysis*************;
*Need to transform typical gene expression into row(samples-pheno)-column(samples);
proc transpose data=Ct_genes_exp out=expr_tr;
var _numeric_;
id genesymbol;*Make genesymbol as column names;
run;

*Method var can be empty;
%principal(Input=expr_tr, 
           vars=, 
           Method=, 
           p=1, 
           scoreout=score, 
           outdata=principal);

**************Make 2D PCA;
proc sgplot data=principal;
scatter x=Prin1 y=prin2/datalabel=_name_;
run;


**************Make 3D PCA;
*Filter data;
data principal;
set principal;
where _name_ contains 'SJMB016877';
run;

*Create text for labeling data points in 3D plots;
data labels1;
length text $15;
retain xsys ysys '2' hsys '3' function 'label' position '2' style '"calibri"';
set principal (rename=( Prin1 = y Prin2=x Prin3 = Z));
*text = left(_N_);
text=_name_;
run;

*Add color and shape vars for separating data points;
data principal;
set principal;
length shape color $8.;
*Add shape and color for specific samples;
shape='diamond';color='green';
if prxmatch('/X(36|37|38)/',_name_) then do;
 shape='cube';color='red';
end;
run;
*Plot 3D PCA; 
proc g3d data=principal anno=labels1;
scatter Prin1*Prin2=Prin3/shape=shape color=color;
run;

*/
