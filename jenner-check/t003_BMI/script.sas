/* Exercises Macros/BMI.sas — a one-line BMI helper from the
 * COVID19_GWAS_Analyzer toolkit. The macro returns a SAS expression
 * that converts pounds + inches into kg/m^2:
 *   weight_lb * 0.45 / (height_in * 0.025) ** 2
 *
 * Useful as a quick covariate-prep step before running ancestry- or
 * sex-stratified GWAS comparisons in the rest of the package.
 */

%macro BMI(WgtPd_Var,HgtIN_Var);
%if &HgtIN_var= or &WgtPd_var= %then %do;
    .
%end;
%else %do;
&WgtPd_var*0.45/(&HgtIN_Var*0.025)**2
%end;
%mend;

/* Eight subjects with weight in lb and height in inches. */
data subjects;
input subject_id $ Wgt Hgt;
datalines;
SBJ001 150 68
SBJ002 180 70
SBJ003 220 72
SBJ004 130 64
SBJ005 200 71
SBJ006 110 60
SBJ007 165 66
SBJ008 250 74
;
run;

data subjects;
set subjects;
BMI=%BMI(Wgt,Hgt);
run;

proc print data=subjects;
run;
