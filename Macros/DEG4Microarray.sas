/***********************Important********************************************;
*Note: for typical microarrays with thousands of genes,;
*the simplely running of glimmix will not be computational feasible;
*because of the large size of the X matrix;
*In this situation, we recommend breaking the model into two parts:;
*those terms that involve GENE and these that do not.;
*First, fit the effects that do not involve genes and construct residudes;
*from this fit. This is a kind of "normalization" or centering of the overall
*data set. Then in a second stage, use GENE as a BY variable and fit ;
*separate mixed models to each gene;

*A further improvement is to first run hpmixed (linear models)/hpnlmod (non-linear models);
*to get covariance estimates;
*then import these covariance estimates into glimmix using the command:;
*params /pdata=HPEstimate hold=1,2,3,4,5 noiter;
*Second, run glimmix BY GENE, which will be very efficient!;*/

/*
proc sort data=microarray;
by gene marray dye trt pin dip;
run;

*first run hpmixed to get covariance matrix;
proc hpmixed data=microarray(obs=100);
   class marray dye trt gene pin dip;
   model log2i = dye trt gene dye*gene trt*gene pin;
   random marray marray*gene dip(marray) pin*marray;
   *test trt;
   ods output covparms=HPEstimate;
run;

*prepare HPEstimate for all genes;
proc sql;
create table HPE as 
select a.*,b.gene
from HPEstimate as a,
     (select unique(gene) from microarray) as b;
proc print data=HPE(obs=20);run;


*second run glimmix by gene;

*ods graphics on;
ods select none;
ods output diffs=diffs;
proc glimmix data=microarray;
by gene;
   class marray dye trt gene pin dip;
   model log2i=dye trt gene pin;
   random marray marray*gene dip(marray) pin*marray;
   parms /pdata=HPEstimate hold=1,2,3,4,5 noiter;
   lsmeans trt / pdiff=all adjust=BON;
run;
ods select all;
%ds2csv(data=diffs,csvfile="diffs_glimmix.csv",runmode=b);

*/


**********************Run genmod for RNAseq count data**********************************;

/*
*https://stats.oarc.ucla.edu/sas/dae/negative-binomial-regression/;
*https://stats.oarc.ucla.edu/sas/faq/how-can-i-compute-negative-binomial-models-with-random-intercepts-and-slopes-using-nlmixed/;

*It run out of memory on genome-wide;
*need to run it by gene;
proc sort data=x1;by gene g;run;
ods select none;
ods output diffs=diffs;
proc genmod data=x1;
by gene;
class g;
model rd=g/dist=negbin;
*output out=pred resraw=resraw pred=pred;
*slice g*gene/sliceby=gene pdiff=all adjust=tukey;
lsmeans g/pdiff=all adjust=BON;
run;
ods select all;

*/

**********************Important********************************************;

*This macro might not work as expected;
*Here would be the best open code to perform DEG with hpmixed only;
/*

data a;
input gene $ trt $ rep exp;
cards;
g1 0 1 3
g1 0 2 4
g1 0 3 3.1
g1 0 4 4.5
g1 1 1 30
g1 1 2 44
g1 1 3 31
g1 1 4 45
g2 0 1 5
g2 0 2 6
g2 0 3 5.1
g2 0 4 5.5
g2 1 1 55
g2 1 2 66
g2 1 3 51
g2 1 4 55
g3 0 1 5
g3 0 2 6
g3 0 3 5.1
g3 0 4 5.5
g3 1 1 5
g3 1 2 6.6
g3 1 3 5.1
g3 1 4 5.5
;
proc print;run;

*Use glm to determine DEG;
ods trace on;
ods output diff=diff SlicedANOVA=slices;
proc glm data=a;
class trt gene;
model exp=trt gene trt*gene/ss3;
lsmeans trt*gene/pdiff=all adjust=tukey slice=gene;
run;
ods trace off;

*Use hpmixed;
*The hpmixed generates the same results as that of glm;
ods trace on;
ods output diffs=diffs_hpmixed Slices=slices_hpmixed;
proc hpmixed data=a;
class trt gene;
model exp=trt gene trt*gene/s;
lsmeans trt*gene/pdiff=all cl slice=gene;
run;
ods trace off;

*Use %hpglimmix, which is surposed to be faster than glimmix!;
*However, it is still very slow!;

*Test it with hpglimmix;
*Note: it is necessary to provide slice=gene for hpmixed!;
*first it is necessary to %include "hpglimmix.sas";
*However, it will be very slow compared to hpmixed alone;
*The advantage of %hpglimmix would be its ability to handle nonlinear models;

hpglimmix(data=a,
       stmts=%str(
          class trt gene;
          model exp=trt gene trt*gene;
          lsmeans trt*gene/cl diff slice=gene;
       ),
       error=n
       
);


*/


*Parameters used by the macro need to fulfill the above criteria;
*Some of the original annotations for these parameters;
*are not true, so please use it with cautions;


%macro DEG4Microarray(
dsd=,                /*Long format dsd for mixed procedure*/
class_vars2exld_eff=,/*vars for the 1st regression to exclude its as well as its interaction with other vars;
                       so the list contains vars that are targeted for exclusion of effects and other vars 
                       may interact with it and the subsequent interaction effect need to be excluded!
                       If it is empty, then the 1st regression model will not be run!*/
model_vars2exld_eff=, /*vars that included in the class_var22exld_eff but its main effect but not its interaction
                       with other vars targeted for exclusion in the class_vars2exld_eff; this means that the main
                       effect of the vars will NOT be excluded
                       If it is empty, no need to run the 1st regression model to exclude these random effects!*/
resp_var=,          /*response var, such as y*/   
random_cmd=,        /*NB: use random parameters with cautions, as it will complicted the model;
                      provide the commands for the parameter random in the 1st regression model;
                      it should include all the vars targeted for exclusion, as well as the interactions
                      with other vars that are not subject to exclusion of main effects!
                      It can be empty if class_vars2exld_eff is empty!*/
sort_vars4regdsd=,  /*vars in order for sorting the outp dsd, which regressed out the effects of random vars
                      ensure the 1st var is the one subject for differential expression analysis, such as gene id*/
class_vars4mixed=,  /*vars for the class parameter in the mixed procedure*/
model_vars4mixed=,  /*vars for testing fixed effects in the mixed model*/
random_vars4mixed=, /*Make sure the assumption of random vars are reasonable; it is not necessary to have complicated
                      random parameters for the proc mixed procedure;
                      vars as random and subject to exclusion of main effects; Other vars with interactions
                      to these random vars should be included here but added into the fixed effect var list model_vars4mixed
                      It can be empty if no random vars to be excluded for effects!*/
lsmeans_cmd=,       /*provide the command for the parameter lsmeans to test the differential effect;
                     It is usually the same as that of model_vars4mixed*/
outdsd4diff=diffs,  /*dsd name for the output dsd containing differential expression statistics*/ 
outdsd4pred=rfir   /*output dsd for predicted response values*/                                         

);

%if &class_vars2exld_eff ne %then %do;
*this will exclude the global effect of targeted vars as well as its interaction effs with other vars;

/*
proc mixed data=&dsd;
class &class_vars2exld_eff;
model &resp_var = &model_vars2exld_eff / outp=rfi;
*/

*use hpmixed;
proc hpmixed data=&dsd;
class &class_vars2exld_eff;
model &resp_var=&model_vars2exld_eff;

%if &random_cmd ne %then %do;
random &random_cmd;
%end;
%else %do;
%put You need to provide random cmd along with the macro var class_vars2exld_eff;
%abort 255;
%end;

*hpmixed needs to output residue with standard alone command;
output out=rfi;

run;

%let dsd4sort=rfi;
%let dsd4mixed=rfi;
%let y_var=resid;

%end;

%else %do;

%let dsd4sort=&dsd;
%let dsd4mixed=&dsd;
%let y_var=&resp_var;

%end;

proc sort data=&dsd4sort;
by &sort_vars4regdsd;
run;
proc print data=&dsd4sort(obs=10);
run;

ods exclude all;
ods noresults;

*Here glimmix can be used to replace mixed;
*but it is necessary to update the outp data set using glimmix specific command;

*proc mixed data=&dsd4mixed;
proc hpmixed data=&dsd4mixed;

*Note: clone is equivalent of gene;
by %scan(&sort_vars4regdsd,1,%str( ));

class &class_vars4mixed;
*model &y_var = &model_vars4mixed / outp=&outdsd4pred;
model &y_var = &model_vars4mixed;

%if &random_vars4mixed ne %then %do;
random &random_vars4mixed;
%end;

lsmeans &lsmeans_cmd / diff;

output out=&outdsd4pred pred=p resid=r;

*ods output covparms=covparms tests3=tests3 lsmeans=lsms diffs=&outdsd4diff;

run;

ods exclude none;
ods results;

%ds2csv(data=&outdsd4diff,csvfile="&outdsd4diff..csv",runmode=b);
%ds2csv(data=&outdsd4pred,csvfile="&outdsd4pred..csv",runmode=b);

%mend;

/*Demo:

%importallmacros;

*No exclusion of random effects;
data BOVINE;
 infile '/home/zcheng/tmp/Bovine_Tissue.txt' firstobs=2 expandtabs;
 input TISSUE$ SAMPLE SIGNALMEAN GENE$;
 logsign=log2(SIGNALMEAN);
run;

*/

/*
%DEG4Microarray(
dsd=BOVINE,
class_vars2exld_eff= ,
model_vars2exld_eff= , 
resp_var=logsign,          
random_cmd= ,        
sort_vars4regdsd= gene tissue sample,  
class_vars4mixed= gene tissue,  
model_vars4mixed=tissue|gene@2,  
random_vars4mixed= , 
lsmeans_cmd= tissue gene tissue*gene,       
outdsd4diff=diffs,
outdsd4pred=rfir
);
*/

/*
data BOVINE;
set BOVINE;
block=0;
if n>4000 then block=1; 
run;

%DEG4Microarray(
dsd=BOVINE,
class_vars2exld_eff= block tissue,
model_vars2exld_eff= tissue , 
resp_var=logsign,          
random_cmd= block,        
sort_vars4regdsd= gene tissue sample,  
class_vars4mixed= gene tissue,  
model_vars4mixed= tissue|gene@2,  
random_vars4mixed= block, 
lsmeans_cmd= tissue gene tissue*gene,       
outdsd4diff=diffs,
outdsd4pred=rfir
);
*/

