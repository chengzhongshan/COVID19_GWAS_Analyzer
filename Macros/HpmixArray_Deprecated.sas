
/*=======================DEMO or HpmixArray===============================*/
/* Adopted from                                                           */
/* Karine PIOT  --  SEPT 2003                                             */
/* Christelle Hennequet-Antier -- March 2005                              */
/* Demonstration of data analysis with AnovArray                          */
/*                                                                        */
/*========================================================================*/
/* Analysis of Variance of logsign with two factors (tissu and gene), and their 
interaction. We use the global_analysis Macro
Solved the problem of total number of combination of tissue and gene gt 32767
*/

/*Modify the following codes for your analysis;

%CD2CWD;

*Note: Bovine_Tissue.txt is a long format data with columns of tissue, sample, SigMean, and gene;

data BOVINE;
 infile 'Bovine_Tissue.txt' firstobs=2 expandtabs;
 input TISSUE$ SAMPLE SIGNALMEAN GENE$;
 logsign=log2(SIGNALMEAN);
run;

proc print data=BOVINE (OBS=15);run;

%global_analysis (data = BOVINE,
                  outdata = RESULT1,
                  outgraph = global_graphs.ps,
                  stmts=%str(class tissue gene;
                              model logsign = tissue|gene@2;
                              lsmeans tissue));

%cleandata (data=RESULT1,
            outdatakeep=BOVKEEP,
            outdatadrop=BOVDROP,
            outdataoutliers=BOVOUTLIERS,
            limit=3)



%global_analysis (data = BOVKEEP,
                  outdata = RESULT2,
                  outgraph = global_graphs2.ps,
                  stmts=%str(class tissue gene;
                              model logsign = tissue|gene@2;
                              lsmeans tissue));

%differential_analysis(data=RESULT2,
                       outdata=BOVHET ,
                       outgraph='diff_het_graph.ps',
                       signal=logsign,
                       treatment=tissue,
                       FDR=0.05);

*/



/*%%%%%%%%%%%%%%%%%%%%%%%%%%%SAS MACROS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*                                                                     */
/*  Karine PIOT  --  initial coding        10Mar2003                   */
/*                   last modification     29Aou2003                   */
/* Christelle hennequet-Antier -- modification  Mar2005                */
/*                                                                     */
/*                                                                     */
/*                                                                     */
/*  TITLE                                                              */
/*  -----                                                              */
/*                                                                     */
/*  GLOBAL_ANALYSIS: macro for micro/macroarray data analysis          */
/*                                                                     */
/*                                                                     */
/*  DESCRIPTION                                                        */
/*  -----------                                                        */
/*                                                                     */
/*  The macro uses Proc Anova to fit complete analysis of variance     */
/*  models. It enables to calculate residuals, fitted values and to    */
/*  check model assumptions with graphs.                               */
/*                                                                     */
/*                                                                     */
/*  SYNTAX                                                             */
/*  -------                                                            */
/*                                                                     */
/*  Syntax for this macro is similar to that of Proc Anova.            */
/*  However some options of proc Anova are not available here.         */
/*                                                                     */
/*  %global_analysis  (data= ,                                         */
/*                     outdata= ,                                      */
/*                     outgraph= ,                                     */
/*                     procopt= ,                                      */
/*                     stmts= ,                                        */
/*                     options= )                                      */
/*                                                                     */
/*                                                                     */
/*  data        specifies the data set you are using.                  */
/*                                                                     */
/*  outdata     -- OPTIONAL -- by default no data set is created --    */
/*              specifies a name for an output data set. This data     */
/*              set is the original data set specified in the data     */
/*              statement with the following additional variables :    */
/*                                                                     */
/*              the mean and variance of the model response for each   */
/*              effect and cross-effect of the specified model.        */
/*                                                                     */
/*              the fitted values and residuals for the model.         */
/*                                                                     */
/*  outgraph    -- OPTIONAL -- by default no graph file is created --  */
/*              specifies a name for a file that will contain all the  */
/*              graphs produced by the global_analysis macro.          */
/*                                                                     */
/*  procopt     -- OPTIONAL -- by default no Proc Anova option --      */
/*              specifies the options appropriate for PROC ANOVA       */
/*              statement.                                             */
/*                                                                     */
/*  stmts       specifies Proc Anova statements for the analysis,      */
/*              separated by semicolons and listed as a single         */
/*              argument to the %str() macro function. Statement may   */
/*              include any of the following : CLASS, MODEL, MEANS     */
/*              Syntax and options for each statement are exactly as   */
/*              in the Proc Anova documentation.                       */
/*                                                                     */
/*  options     -- OPTIONAL --                                         */
/*              specifies global_analysis macro options separated      */
/*              by spaces:                                             */
/*                                                                     */
/*       NOTES     requests printing of SAS notes, date, and page      */
/*                 numbers during the macro execution. By default, the */
/*                 notes, date and page numbers are turned off during  */
/*                 macro execution and turned back on after completion */
/*                                                                     */
/*                                                                     */
/*  EXAMPLE SYNTAX                                                     */
/*  ---------------                                                    */
/*                                                                     */
/*  1) This example uses procopt, means and options arguments          */
/*                                                                     */
/*  %global_analysis  (data = TAB,                                     */
/*                     procopt = noprint,                              */
/*                     stmts = %str(class tissu ampli gene;            */
/*                                  model signal= ampli|gene@2;        */
/*                                  means ampli),                      */
/*                     options = NOTES )                               */
/*                                                                     */
/*                                                                     */
/*  2) This example uses outgraph (for Unix/Linux) argument            */
/*                                                                     */
/*   %global_analysis  (data = disease,                                */
/*                      outgraph = /home/myrepertory/mygraphs.ps,      */
/*                      stmts = %str(class gene treatment;             */
/*                                   model illness=gene|treatment@2)   */
/*                      )                                              */
/*                                                                     */
/*                                                                     */
/*                                                                     */
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/



/*--------------------------------------------------------------*/
/*                                                              */
/*    %mvarlst                                                  */
/*    Make a variable list from the model                       */
/*                                                              */
/*--------------------------------------------------------------*/

%macro mvarlst;

%let varlst =;
%let mdllst = &mdlspec;

/*---get response variable---*/
%if %index(&response,/) %then
  %let varlst = %scan(&response,1,/) %scan(&response,2,/) &varlst;
%else %let varlst = &response &varlst;

/*---strip out @ signs---*/
%if %index(&mdllst,@) %then %do;
  %let j = 1;
  %let mdl = &mdllst;
  %let mdllst=;
  %do %while(%length(%scan(&mdl,&j,' ')));
    %let var=%scan(&mdl,&j,' ');
    %if %index(&var,@) %then %do;
      %let b = %eval(%index(&var,@)-1);
      %let mdllst = &mdllst %substr(%quote(&var),1,&b);
    %end;
    %else %let mdllst = &mdllst &var;
  %let j = %eval(&j+1);
  %end;
%end;

/*---get fixed effects---*/
%let iv = 1;
%do %while (%length(%scan(&mdllst,&iv,%str( ) | * %( %) )));
  %let varlst = &varlst %scan(&mdllst,&iv,%str( ) | * %( %) );
  %let iv = %eval(&iv + 1);
%end;

%mend mvarlst;



/*--------------------------------------------------------------*/
/*                                                              */
/*    %trimlst                                                  */
/*    Get rid of repetitions in a list                          */
/*                                                              */
/*--------------------------------------------------------------*/

%macro trimlst(name,lst);

%let i1 = 1;
%let tname =;
%do %while (%length(%scan(&lst,&i1,%str( ))));
  %let first = %scan(&lst,&i1,%str( ));
  %let i2 = %eval(&i1 + 1);

  %do %while (%length(%scan(&lst,&i2,%str( ))));
     %let next = %scan(&lst,&i2,%str( ));
     %if %quote(&first) = %quote(&next) %then %let i2=10000;
     %else %let i2 = %eval(&i2 + 1);
  %end;

  %if (&i2<10000) %then %let tname = &tname &first;
  %let i1 = %eval(&i1 + 1);
  
%end;

%let &name = &tname;

%mend trimlst;



/*--------------------------------------------------------------*/
/*                                                              */
/*    %anova                                                    */
/*    Calculate factors contribution using Proc Anova           */
/*                                                              */
/*--------------------------------------------------------------*/

%macro anova;

title1 "Anova result for the model &model";
title2 "data = &data";
proc anova data=_DS &procopt outstat=_OUTST;
  class &class;
  model &response = %unquote(&mdlspec) %unquote(&mdlopt);
  %if %length(&meanslst) %then %do;
    means &meanslst;
  %end;
run;
quit;

%mend anova;


%macro hpmixed;
title1 "hpmixed result for the model &model";
title2 "data = &data";
ods output OverallANOVA=_outst;
proc hpmixed data=_DS &procopt;
  class &class;
  model &response = %unquote(&mdlspec) %unquote(&mdlopt);
  output out=_OUTST1 pred=p resid=r;
  %if %length(&meanslst) %then %do;
    lsmeans &meanslst;
  %end;
run;
quit;

%mend;


/*---------------------------------------------------------*/
/*                                                         */
/*    %predres                                             */
/*    Calculate means, predicted values and residuals      */
/*    Plots residuals vs predicted values                  */
/*                                                         */
/*---------------------------------------------------------*/

%macro predres(data= );

%let i = 2;
%let effname1 = ;
%let effname2 = ;
%let efflist1 = ;
%let efflist2 = ;

/*---check means for all factors ---*/

data &data;
set &data;
code=1;
mntotale=.;
vartotale = .;
ntotal = .;
drop mntotale vartotale ntotal;
run;

proc means data=&data noprint;
var &response;
by code;
output out=_MNTOTALE mean=mntotale var=vartotale N=ntotal;
run;

data &data(drop= _type_ _freq_ code);
merge &data _MNTOTALE;
by code;
run;

%let i = 2;

%do %while (&i<=&nbvar);
  %let effname1 = %scan(&varlst,&i,%str( ) %( %));
  %let efflist1 = %scan(&varlst,&i,%str( ) %( %));

  data &data;
  set &data;
  mn&effname1 = .;
  var&effname1 = .;
  n&effname1 = .;
  drop mn&effname1 var&effname1 n&effname1;
  run;

  proc sort data=&data;
  by &efflist1;
  run;

  proc means data=&data noprint;
  var &response;
  by &efflist1;
  output out=_MN&effname1 mean=mn&effname1 var=var&effname1 N=n&effname1;
  run;

  data &data;
  merge &data _MN&effname1;
  by &efflist1;
  drop _TYPE_ _FREQ_;
  run;

  proc datasets lib=work nolist;
  delete _MNTOTALE _MN&effname1;
  run;
  quit;

  %let j = %eval(&i+1);
  %let i = %eval(&i+1);

  %do %while(&j<=&nbvar);
    %let effname2 = &effname1.%scan(&varlst,&j,%str( ) %( %));
    %let efflist2 = &efflist1 %scan(&varlst,&j,%str( ) %( %));
    
    data &data;
    set &data;
    mn&effname2 = .;
    var&effname2 = .;
    n&effname2 = .;
    drop mn&effname2 var&effname2 n&effname2;
    run;

    proc sort data=&data;
    by &efflist2;
    run;

    proc means data=&data noprint;
    var &response;
    by &efflist2;
    output out=_MN&effname2 mean=mn&effname2 var=var&effname2 N=n&effname2;
    run;

    data &data;
    merge &data _MN&effname2;
    by &efflist2;
    drop _TYPE_ _FREQ_;
    run;

    proc datasets lib=work nolist;
    delete _MN&effname2;
    run;
    quit;

    %let k = %eval(&j+1);
    %let j = %eval(&j+1);

    %do %while(&k<=&nbvar);
      %let effname2 = &effname2.%scan(&varlst,&k,%str( ) %( %));
      %let efflist2 = &efflist2 %scan(&varlst,&k,%str( ) %( %));

      data &data;
      set &data;
      mn&effname2 = .;
      var&effname2 = .;
      n&effname2 = .;
      drop mn&effname2 var&effname2 n&effname2;
      run;

      proc sort data=&data;
      by &efflist2;
      run;

      proc means data=&data noprint;
      var &response;
      by &efflist2;
      output out=_MN&effname2 mean=mn&effname2 var=var&effname2 N=n&effname2;
      run;

      data &data;
      merge &data _MN&effname2;
      by &efflist2;
      drop _TYPE_ _FREQ_;
      run;

      proc datasets lib=work nolist;
      delete _MN&effname2;
      run;
      quit;

      %let k = %eval(&k+1);

    %end;
  %end;
%end;

/*---check residuals and predicted---*/
%let i = 2;
%let valp = ;

%do %while (%length(%scan(&varlst,&i,%str( ) %( %))));
  %let valp = &valp.%scan(&varlst,&i,%str( ) %( %));
  %let i = %eval(&i+1);
%end; 

data &data;
set &data;
predicted = mn&valp;
residual = &response - predicted;
run;


%mend predres;



/*---------------------------------------------------------*/
/*                                                         */
/*    %hpmixedgraphs                                         */
/*    Plots residuals vs predicted values                  */
/*          residuals vs predicted values for each factor  */
/*          histogram of residuals                         */
/*          QQplot of normal vs residuals                  */
/*          histogram for global gene variance             */
/*                                                         */
/*---------------------------------------------------------*/

%macro hpmixedgraphs;

/*---check the variance for residual standardisation---*/
data _SIG;
set _OUTST;
/*Pay attention to letter case*/
if Source='Error';
sig2 = SS/DF;
call symput ('dferror',trim(left(DF)));
call symput ('sigma2',trim(left(sig2)));
run;


data _DS;
set _DS;
stdresidual = residual/sqrt(&sigma2);
run;

proc datasets library=work nolist;
delete _SIG _OUTST;
run;
quit;
 
/*---graph of standardized residuals vs predicted values---*/
title1 "- Graph of standardized residuals vs predicted values -";
title2 "model  ->   &model";
title3 "data   ->   &data";
proc gplot data=_DS ;
symbol i=none v=plus;
plot stdresidual*predicted /vref=0 ;
run;

%if %length(&outgraph) %then %do;
  goptions gsfmode=append;
%end;

/*---graph of standardized residuals vs predicted values with an identifier--*/
%let iv = 2;

%do %while (%length(%scan(&varlst,&iv,%str( ) %( %))));

  %let identif = %qupcase(%scan(&varlst,&iv,%str( ) %( %)));
  %if not %index(&identif,GENE) %then %do;
    title1 "- Graph of standardized residuals vs predicted values -";
    title2 "model  ->   &model";
    title3 "data   ->   &data";
    title4 "identifier -> &identif";
    proc gplot data=_DS ;
    symbol i=none v=plus;
    plot stdresidual*predicted=&identif /vref=0 ;
    run;
  %end;

  %let iv = %eval(&iv+1);

%end;
  
/*---graph of residuals vs predicted values for each factor---*/
title1"- Graph of standardized residuals vs predicted values for each factor -";
title2 "model  ->   &model";
title3 "data   ->   &data";

%let i = 2;

%let detectgene=0;
%let identkeep = ;

%do %while(%length(%scan(&varlst,&i,%str( ) %( %))));

  %let effname = %qupcase(%scan(&varlst,&i,%str( ) %( %)));
  %let identlist = &identkeep;
  %if not %index(&effname,GENE) %then %do;
    %let j = %eval(&i+1);
    %do %while (%length(%scan(&varlst,&j,%str( ) %( %))));
      %let identajout = %qupcase(%scan(&varlst,&j,%str( ) %( %)));
      %if not %index(&identajout,GENE) %then %do;
        %let identlist = &identlist &identajout; 
      %end;
    %let j = %eval(&j+1); 
    %end; 

    %let k = 1;
    %do %while (%length(%scan(&identlist,&k,%str( ) %( %))));
      %let identif = %scan(&identlist,&k,%str( ) %( %));

      proc sort data=_DS;
      by &effname;
      run;
      proc gplot data=_DS uniform;
      symbol i=none v=plus;
      plot stdresidual*predicted=&identif /vref=0;
      by &effname;
      run;
      %let k = %eval(&k+1);
    %end;
    %if not %length(%scan(&identlist,1,%str( ) %( %))) %then %do;
      proc sort data=_DS;
      by &effname;
      run;
      proc gplot data=_DS uniform;
      symbol i=none v=plus;
      plot stdresidual*predicted /vref=0;
      by &effname;
      run;
    %end;
    %let identkeep = &identkeep &effname; 
  %end;

  %else %if %index(&effname,GENE) %then %do;
    %let detectgene = %eval(&detectgene + 1);
  %end;
  %let i = %eval(&i+1);
  
%end;

quit;

/*---Normality of residuals---*/
title1 "- Normality of standardized residuals -";
title2 "model   ->   &model";
title3 "data    ->   &data"; 
proc univariate data=_DS noprint;
var stdresidual;
symbol i=none v=plus c=blue;
histogram stdresidual / normal(mu=0 sigma=1 color=red) nohlabel
                        vscale=count;
qqplot stdresidual / normal(mu=0 sigma=1 color=red) ;
run;

/*--- no gene in the model -> no graph ---*/
%if (&detectgene=1) %then %do;
  
  %let i = 2;
  %let effname = ;
  %let efflist = ;

  %do %while (%length(%scan(&varlst,&i,%str( ) %( %))));
    %let effname= &effname.%scan(&varlst,&i,%str( ) %( %));
    %let efflist= &efflist %scan(&varlst,&i,%str( ) %( %));
    %let i = %eval(&i+1);
  %end;
  
  %let ntot = n&effname;
  %let vartot=var&effname;
  %let ddlchitot = ;
  %let nchi = ;
  
  data _TOTVAR;
  set _DS;
  sigglob=&sigma2;
  n = &ntot;
  ddl = (n-1)/2;
  call symput ('ddlchitot',trim(left(ddl)));
  chi_obs = (n-1)*&vartot/sigglob;
  run;
 
 
  data _TOTVAR;
  set _TOTVAR;
  keep &efflist chi_obs;
  run;

  proc sort data=_TOTVAR out=_TOTVARTRI nodupkey; 
  by &efflist;
  run;
  
  title1 "- Chi Square Adjustment BY &efflist -";
  title2 "model   ->   &model";
  title3 "data    ->   &data"; 
  proc univariate data=_TOTVARTRI noprint;
  var chi_obs;
  symbol i=none v=plus c=blue;
  histogram chi_obs / gamma(theta=0 scale=2 alpha=&ddlchitot color=red
                            noprint) vscale=count;
  run;


  /*-- check the parameter for chi-square density ---*/
  proc sort data=_DS out=_SORTBYGENE;
  by gene;
  run;

  proc means data=_SORTBYGENE noprint;
  var &response;
  by gene;
  output out=_GENEVAR var=variance;
  run;

  proc anova data=_DS outstat=_VARGENEGLOB noprint;
  class gene;
  model &response=gene;
  run;
  quit;

  data _VARGENEGLOB;
  set _VARGENEGLOB;
  if _source_ = "ERROR";
  varianceglob = SS/DF;
  code=1;
  keep code varianceglob;
  run;

  %let ddlchi = 0;
  
  data _GENEVAR;
  set _GENEVAR;
  code=1;
  run;

  data _GENEVAR;
  merge _GENEVAR _VARGENEGLOB;
  by code;
  chi_obs = (_FREQ_-1)*variance/varianceglob;
  ddl = (_freq_-1)/2;
  call symput ('ddlchi',trim(left(ddl)));
  run;


/*---residuals variance by gene - homoscedasticity ---*/  
  title1 "- Chi Square Adjustment BY GENE -";
  title2 "model   ->   &model";
  title3 "data    ->   &data"; 
  proc univariate data=_GENEVAR noprint;
  var chi_obs;
  symbol i=none v=plus c=blue;
  histogram chi_obs / gamma(theta=0 scale=2 alpha=&ddlchi color=red
                            noprint) vscale=count;
  run;

 * proc datasets library=work nolist;
 * delete _GENEVAR _SORTBYGENE _VARGENEGLOB _TOTVAR _TOTVARTRI;
 * run;
  quit;
%end;

%else %do;
  %put The histogram of genes variance is not produced because the;
  %put variable GENE does not appear in the model statement.;
  %put;
%end;

title;

%mend hpmixedgraphs;



/*--------------------------------------------------------------*/
/*                                                              */
/*    %global_analysis                                          */
/*    Put it all together                                       */
/*                                                              */
/*--------------------------------------------------------------*/

%macro global_analysis(data=,outdata=,outgraph=,procopt=,stmts=,options=);

title;

/*---change to uppercase---*/
%let data     = %qupcase(&data);
%let outdata  = %qupcase(&outdata);
%let procopt  = %qupcase(&procopt);
%let stmts    = %qupcase(&stmts);
%let options  = %qupcase(&options);

/*---graphical options---*/

%if %length(&outgraph) %then %do;
*Use the updated device zpscolor but no pscolor;
*https://support.sas.com/kb/32/976.html;
  filename graphs "&outgraph";
  goptions reset=all colors=(black lime blue red violet salmon green maroon) 
         rotate device=zpscolor gsfname=graphs gsfmode=replace;
%end;

/*---system options---*/
options linesize=75 pagesize=53;
%if not %index(&options,NOTES) %then %do;
  options nocenter nonotes nodate nonumber;
%end;
%else %do;
  options center notes date number;
%end;

/*---local and global variables---*/
%local varlst;
%local effname;


/*---check data set---*/
%if %bquote(&data)= %then %let data=&syslast;

%let exiterr = 0;
%let there = no;

data _DS;
set &data;
call symput('there','yes');
run;
%if ("&there" = "no") %then %do;
  %let exiterr = 1;
  %goto exit;
%end;


/*---loop through statements and extract information---*/
%let class = ;
%let model = ;
%let meanslst= ;
%let iv = 1;

%do %while (%length(%scan(&stmts,&iv,;)));
  %let stmt = %qscan(&stmts,&iv,%str(;));
  %let first = %qscan(&stmt,1);
  %let fn = %eval(%index(&stmt,&first) + %length(&first));

  %if %index(&first,CLASS) %then %do;
    %let class = %qsubstr(&stmt,&fn);
  %end;

  %else %if %index(&first,MODEL) %then %do;
    %let fna = %eval(&fn+1);
    %let model = %qsubstr(&stmt,&fna);
  %end;

  %else %if %index(&first,MEANS) %then %do;
    %let meanslst = %qsubstr(&stmt,&fn);
  %end;

  %let iv = %eval(&iv + 1);
%end;

/*---error if class or model statement is missing---*/
%if (not %length(&class)) | (not %length(&model)) %then %do;
  %let exiterr=1;
  data _DS;
  set _DS;
  %goto exit;
  run;
%end; 

/*---get response, model specification, and model options---*/
%let response = %scan(&model,1,=);
%let eqidx = %eval(%index(&model,=)+1);
%if (&eqidx > %length(&model)) %then %let mdl = %str();
%else %let mdl = %str( ) %qsubstr(&model,&eqidx);

%let mdlspec = %qscan(&mdl,1,/);
%let mdlopt = / %qscan(&mdl,2,/);

/*---get variable list and trim it---*/
%mvarlst;
%trimlst(varlst,&varlst);

/*---count number of variables---*/
%let iv=1;
%do %while(%length(%scan(&varlst,&iv,%str( ) %( %))));
  %let iv = %eval(&iv+1);
%end;

%let nbvar=%eval(&iv-1);

/*---print header---*/
%if %index(&data,.)=0 %then %let data=WORK.&data;
  
%put;
%put;
%put %str(      ) The GLOBAL_ANALYSIS Macro;
%put;
%put Data Set        : &data;
%put Model           : &model;
%put;


/*---final Proc hpmixed run---*/  
%hpmixed;

%put Wait a few minutes, calculs are in progress.....;
%put;


/*---means residuals and fitted---*/
%predres(data=_DS);


/*---graphs for anova---*/
%hpmixedgraphs;

/*---create an output dataset---*/
%if %length(&outdata) %then %do;
  data &outdata;
  set _DS;
  run;
  %put The output Data Set &outdata has been created.;
%end;


%put;
%put End of GLOBAL_ANALYSIS Macro.;
%put;


/*---execution halted--*/
%exit:;
%if (&exiterr = 1) %then %do;
  %if not %index(&options,NOPRINT) %then %do;
    %put ;
    %put GLOBAL_ANALYSIS macro exited due to errors.;
    %put;
  %end;
%end;

/*---delete data sets created during the macro execution---*/
proc datasets lib=work nolist;
delete _DS;
run;
quit;


/*---reset options---*/
title;
options center notes date number;

%if %length(&outgraph) %then %do;
  goptions reset=all;
%end;


%mend global_analysis;


/*************************************************************************/
/*************************************************************************/
/*************************************************************************/


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*                                                                     */
/*  Karine PIOT  --  initial coding        15Apr2003                   */
/*                   last modification     07Jul2003                   */
/*                                                                     */
/*                                                                     */
/*  TITLE                                                              */
/*  -----                                                              */
/*                                                                     */
/*  CLEANDATA : contains data set cleaning facilities to remove        */
/*              suspicious genes.                                      */
/*                                                                     */
/*  DESCRIPTION                                                        */
/*  -----------                                                        */
/*                                                                     */
/*  The macro uses Data steps to remove genes from the data set.       */
/*                                                                     */
/*                                                                     */
/*  SYNTAX                                                             */
/*  -------                                                            */
/*                                                                     */
/*  %cleandata  (data = ,                                              */
/*               outdatakeep = ,                                       */
/*               outdatadrop = ,                                       */
/*               outdataoutliers = ,                                   */
/*               limit = ,                                             */
/*               droplist = ,                                          */
/*               options = )                                           */
/*                                                                     */
/*                                                                     */
/*  data        specifies the data set you are using.                  */
/*                                                                     */
/*  outdatakeep  -- OPTIONAL -- by default no data set is created --   */
/*              specifies a name for an output data set. This data     */
/*              set is the original data set specified in the data     */
/*              statement from which selected genes have been removed. */
/*                                                                     */
/*  outdatadrop  -- OPTIONAL -- by default no data set is created --   */
/*              specifies a name for an output data set which contains */
/*              all observations of removed genes according to the     */
/*              droplist or limit criteria.                            */
/*                                                                     */
/*  outdataoutliers -- OPTIONAL -- by default no data set is created --*/
/*                  specifies a name for an output data set which      */
/*                  only contains observations bringing cleandata to   */
/*                  remove a gene.                                     */
/*                                                                     */
/*  limit       is a real number. Gene which has at least one          */ 
/*              standardized residual observation less than -|limit|   */
/*              or greater than |limit| is removed.                    */
/*                                                                     */
/*  droplist    specifies the identifiers of the genes to remove,      */
/*              listed between parenthesis and separated by a colon.   */
/*              Each identifier must be written with quotation marks.  */
/*                                                                     */
/*  options     -- OPTIONAL --                                         */
/*              specifies global_analysis macro options separated      */
/*              by spaces :                                            */
/*                                                                     */
/*       NOTES     requests printing of SAS notes, date, and page      */
/*                 numbers during the macro execution. By default, the */
/*                 notes, date and page numbers are turned off during  */
/*                 macro execution and turned back on after completion */
/*                                                                     */
/*                                                                     */
/*  EXAMPLE SYNTAX                                                     */
/*  ---------------                                                    */
/*                                                                     */
/*  1) This example uses outdatakeep, outdatadrop and limit arguments  */
/*                                                                     */
/*  %cleandata ( data = tab,                                           */
/*               outdatakeep = tabkeep,                                */
/*               outdatadrop = tabdrop,                                */ 
/*               limit = 2.5 )                                         */
/*                                                                     */
/*  2) This example uses outdatakeep, limit and droplist arguments     */
/*                                                                     */
/*  %cleandata ( data = disease,                                       */ 
/*               outdatakeep = result,                                 */
/*               outdataoutliers = outlierobs,                         */
/*               limit = 3,                                            */
/*               droplist = ('gen1', 'gen5','gen18')                   */
/*              )                                                      */ 
/*                                                                     */
/*                                                                     */
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


%macro cleandata (data= ,outdatakeep= ,outdatadrop= ,outdataoutliers= ,
                  limit= ,droplist= ,options= );


/*---system options---*/
options nocenter nodate nonumber nonotes linesize=75 pagesize=53;


/*---change to uppercase---*/
%let data = %qupcase(&data);
%let option = %qupcase(&options);
%let outdataoutliers = %qupcase(&outdataoutliers);

%if not %index(&option,NOTES) %then %do;
  options nodate nonumber nonotes;
%end;
%else %do;
  options date number notes;
%end;


/*---check data set---*/
%if %bquote(&data)= %then %let data=&syslast;
%let exiterr = 0;
%let there = no;

data _MINMAX;
set &data;
call symput('there','yes');
run;

%if ("&there" = "no") %then %do;
  %let exiterr = 1;
  %goto exit;
%end;

data _OUTLIERS;
set &data;
run;

%put ;
%put Wait a few minutes, the macro is running...;
%put ;

/*---drop observation from minvalue and maxvalue---*/
proc sort data=_MINMAX;
by gene;
run;

proc means data=_MINMAX noprint;
var stdresidual;
by gene;
output out=_EXTREM min=mini max=maxi N=nbrep;
run;

%let genenb = ;

data _MINMAX;
merge _MINMAX _EXTREM;
by gene;
call symput('genenb',nbrep);
drop _type_ _freq_ nbrep;
run;


%if %length(&limit) %then %do;
  
  %if (&limit<0) %then %let limit = -&limit;
    
  %if %length(&droplist) %then %do;
      
    data &outdatakeep;
    set _MINMAX;
    if (mini>=-&limit) & (maxi<=&limit) &(gene not in &droplist); 
    run;

    data &outdatadrop;
    set _MINMAX;
    if (mini<-&limit) | (maxi>&limit) | (gene in &droplist); 
    run;

     data _OUTLIERS;
     set _OUTLIERS;
     if (stdresidual<-&limit) | (stdresidual>&limit) | (gene in &droplist);
     run;
      
  %end;

  %else %do;
    
    data &outdatakeep;
    set _MINMAX;
    if (mini>=-&limit) & (maxi<=&limit);
    run;
        
    data &outdatadrop;
    set _MINMAX;
    if (mini<-&limit) | (maxi>&limit);
    run;
 
    data _OUTLIERS;
    set _OUTLIERS;
    if (stdresidual<-&limit) | (stdresidual>&limit);
    run;

  %end;

%end;

%else %if %length(&droplist) %then %do;

  data &outdatakeep;
  set _MINMAX;
  if (gene not in &droplist);
  run;

  data &outdatadrop;
  set _MINMAX;
  if (gene in &droplist);
  run;

  data _OUTLIERS;
  set _OUTLIERS;
  if (gene in &droplist);
  run;

%end;


/*---output for observations keeped---*/
data &outdatakeep;
set &outdatakeep;
totalkp+1;
call symput ('totalkeep',trim(left(totalkp)));
drop totalkp mini maxi;
run;

proc sort data=&outdatakeep out=_AFFICH nodupkey;
by gene;
run;

%let listgenekeep = %eval(&totalkeep/&genenb);

/*
title "List of &listgenekeep genes keeped :";
proc print data=_AFFICH;
var gene;
run;
*/

/*---output for observations dropped---*/
data &outdatadrop;
set &outdatadrop;
totaldp+1;
call symput ('totaldrop',trim(left(totaldp)));
drop totaldp mini maxi;
run;

proc sort data=&outdatadrop out=_AFFICH nodupkey;
by gene;
run;

%let listgenedrop = %eval(&totaldrop/&genenb);

/*---output for observations outliers---*/
proc sort data=_OUTLIERS;
by gene;
run;

%let totaloutlier = ;

data _OUTLIERS;
set _OUTLIERS;
totalout+1;
call symput ('totaloutlier',trim(left(totalout)));
drop totalout;
run;

%if %length(&outdataoutliers) %then %do;
  data &outdataoutliers;
  set _OUTLIERS;
  run;
%end;


title1 "Output of CLEANDATA Macro :";
title2 " ";
title3 "   # &listgenekeep genes are kept";
title4 "   # &listgenedrop genes are dropped (&totaloutlier observations)";
title5 " ";
title6 "List of &listgenedrop genes dropped :";
proc print data=_AFFICH;
var gene;
run;




/*---delete data sets created during the macro execution---*/
proc datasets lib=work nolist;
delete _EXTREM _AFFICH _MINMAX _OUTLIERS;
run;
quit;

%put ;
%put End of CLEANDATA Macro.;
%put ;


/*---execution halted--*/
%exit:;
%if (&exiterr = 1) %then %do;
  %put CLEANDATA macro exited due to errors.;
  %put ;
%end;


/*---reset options---*/
title;
options date number center notes;

%mend cleandata; 


/************************************************************************/
/************************************************************************/
/************************************************************************/


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*                                                                     */
/*  Karine PIOT  --  initial coding        15Apr2003                   */
/*                   last modification     07Jul2003                   */
/*                                                                     */
/*                                                                     */
/*  TITLE                                                              */
/*  -----                                                              */
/*                                                                     */
/*  ADJUST: Normalization step. Adjust for undesirable experimental    */
/*          factors.                                                   */
/*                                                                     */
/*  DESCRIPTION                                                        */
/*  -----------                                                        */
/*                                                                     */
/*  The macro uses Anova procedure to normalize data for one or        */
/*  several factors.                                                   */
/*                                                                     */
/*  SYNTAX                                                             */
/*  -------                                                            */
/*                                                                     */
/*  %adjust  (data = ,                                                 */
/*            outdata = ,                                              */
/*            signal = ,                                               */
/*            list = )                                                 */
/*                                                                     */
/*                                                                     */
/*  data       specifies the data set you are using.                   */
/*                                                                     */
/*  outdata    -- OPTIONAL -- by default no data set is created --     */
/*              specifies a name for an output data set. This data     */
/*              set is the original data set specified in the data     */
/*              statement with an additionnal variable named           */
/*              ADJUSTEDSIGNAL which represent the signal adjusted for */
/*              the effects specified in the list statement.           */ 
/*                                                                     */
/*  signal      specifies the name of the signal to adjust.            */
/*                                                                     */
/*  list        specifies the effects to substract from the signal,    */
/*              listed as a single argument to %str macro function and */
/*              separated by a semi-colon. Cross-effects between A and */
/*              B must be written A*B.                                 */
/*                                                                     */
/*                                                                     */
/*  EXAMPLE SYNTAX                                                     */
/*  ---------------                                                    */
/*                                                                     */
/*  1) This example adjusts for one effect named block                  */
/*                                                                     */
/*  %adjust ( data = tab,                                              */
/*            outdata = tabadjust,                                     */
/*            signal = response,                                       */ 
/*            list = %str(block) )                                     */
/*                                                                     */
/*  2) This example adjusts for two effects block and day, and their    */
/*     interaction                                                     */
/*                                                                     */
/*  %adjust ( data = tab,                                              */
/*            outdata = RESULTS,                                       */
/*            signal = response,                                       */ 
/*            list = %str(block;day;block*day) )                       */
/*                                                                     */
/*                                                                     */
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


%macro adjust(data= ,outdata= ,signal= ,list= );

/*---system options---*/
options nocenter nodate nonumber nonotes linesize=75 pagesize=53;


/*---check data set---*/
%let data = %qupcase(&data);
%if %bquote(&data)= %then %let data=&syslast;
%let exiterr = 0;
%let there = no;

data _INIT;
set &data;
call symput('there','yes');
run;
%if ("&there" = "no") %then %do;
  %let exiterr = 1;
  %goto exit;
%end;


/*---check the list of effects and make a variable list---*/
%global modelajust;

%let compt = 1;
%let modelajust = ;
%do %while (%length(%scan(&list,&compt,;)));
  %let varajust = %qscan(&list,&compt,%str(;));
  %let modelajust = &modelajust &varajust;
  %let compt=%eval(&compt+1);
%end;

%let iv = 1;
%let varajustlist= ;
%do %while (%length(%scan(&modelajust,&iv,%str( ) | * %( %) )));
  %let varajustlist = &varajustlist %scan(&modelajust,&iv,%str( ) | * %( %) );
  %let iv = %eval(&iv + 1);
%end;

%trimlst(varajustlist,&varajustlist);


/*---adjust for the specified effects---*/
proc glm data=_INIT noprint;
class &varajustlist;
model &signal = &modelajust;
output out=_RESIDAJUST r=adjustedsignal;
run;


/*---add the adjusted signal to the initial Data Set---*/
/*---and creates an output data set---*/
data _RESIDAJUST;
set _RESIDAJUST;
keep gene adjustedsignal;
run;

proc sort data=_INIT;
by gene;
run;

proc sort data=_RESIDAJUST;
by gene;
run;

data &outdata;
merge _INIT _RESIDAJUST;
by gene;
run;


/*---delete data sets created during the macro execution---*/
proc datasets lib=work nolist;
delete _INIT _RESIDAJUST;
run;
quit;


%put ;
%put End of ADJUST Macro.;
%put ;


/*---execution halted--*/
%exit:;
%if (&exiterr = 1) %then %do;
  %put ADJUST macro exited due to errors.;
  %put;
%end;

/*---reset options---*/
title;
options date center number notes;

%mend adjust;


/***********************************************************************/
/***********************************************************************/
/***********************************************************************/


/*=====================================================================*/
/*                                                                     */
/*  Karine PIOT  --  initial coding        19Mar2003                   */
/*                   last modification     29Jul2003                   */
/*  Christelle Hennequet-Antier modification Mar2005                   */
/*             replace hypothesis variable by variance                 */
/*                                                                     */
/*                                                                     */
/*  TITLE                                                              */
/*  -----                                                              */
/*                                                                     */
/*  DIFFERENTIAL_ANALYSIS:                                             */
/*               a SAS macro for macroarray data anlysis.              */
/*               Requires SAS/STAT version 8                           */
/*                                                                     */
/*                                                                     */
/*  DESCRIPTION                                                        */
/*  -----------                                                        */
/*                                                                     */
/*  The macro allows to identify differentially expressed genes in     */
/*  a treatment, in case of homogeneous variance hypothesis and in     */
/*  case of heterogeneous variance hypothesis.                         */
/*                                                                     */
/*                                                                     */
/*  SYNTAX                                                             */
/*  -------                                                            */
/*                                                                     */
/*  %differential_analysis (data= ,                                    */
/*                          outdata= ,                                 */
/*                          outgraph= ,                                */
/*                          variance= ,                                */
/*                          signal= ,                                  */
/*                          treatment= ,                               */
/*                          fdr= ,                                     */ 
/*                                                                     */
/*  where                                                              */
/*                                                                     */
/*  data        specifies the data set you are using.                  */
/*                                                                     */
/*  outdata     -- OPTIONAL -- by default no data set is created --    */
/*              specifies a name for an output data set. This data     */
/*              set is the original data set specified in the data     */
/*              statement with the following additionnal variables :   */
/*                                                                     */
/*              the mean and variance of the model response for each   */
/*              effect and cross-effect of the specified model         */
/*                                                                     */
/*              the fitted values and residuals for the model          */
/*                                                                     */
/*  outgraph    -- OPTIONAL -- by default no graph file is created --  */
/*              specifies a name for a file that will contain all the  */
/*              graphs produced by the globale_analysis macro          */
/*                                                                     */
/*  variance    specifies homoscedasticity or heteroscedasticity       */
/*              hypothesis :                                           */
/*                                                                     */
/*       HOM      implies homoscedasticity hypothesis which means that */
/*                the variance is the same for all genes.              */
/*                                                                     */
/*       HET      implies heteroscedasticity hypothesis which means    */
/*                that the variance is different for each gene.        */
/*                                                                     */
/*  signal      specifies the variable you want to study (which mesure */
/*              gene's expression level)                               */
/*                                                                     */
/*  treatment   specifies the treatment in which you want to identify  */
/*              differentially expressed genes.                        */
/*                                                                     */
/*  fdr         specifies the False Discovery Rate                     */
/*                                                                     */  
/*                                                                     */
/*  EXAMPLE SYNTAX                                                     */
/*  ---------------                                                    */
/*                                                                     */
/*  1) This example uses variance=hom and outdata options              */
/*                                                                     */
/*  %differential_analysis (data = TAB,                                */
/*                          outdata = RESULTS,                         */
/*                          variance = hom,                            */
/*                          signal = response,                         */
/*                          treatment = tissu,                         */
/*                          fdr=0.05)                                  */ 
/*                                                                     */
/*                                                                     */
/*                                                                     */
/*  3) This example uses variance=het and outgraph (for Windows)       */
/*     options                                                         */
/*                                                                     */
/*  %differential_analysis (data = MYDATA,                             */
/*                          outgraph = c:\myrepertory\mygraph.ps,      */
/*                          variance = Het,                            */
/*                          signal = logsign,                          */
/*                          treatment = ampli,                         */
/*                          fdr=0.1)                                   */
/*                                                                     */
/*=====================================================================*/


%macro differential_analysis(data= ,outdata= , outgraph= ,variance= ,
                             signal= ,treatment= , fdr= );


/*---graphical options---*/

%if %length(&outgraph) %then %do;
  filename graphic "&outgraph";
  goptions reset=all colors=(black lime blue red violet) rotate htitle=1.5 device=zpscolor gsfname=graphic gsfmode=replace;
%end;

/*---system options---*/
options nocenter nodate nonumber nonotes linesize=75 pagesize=53;


/*---change to uppercase---*/
%let data = %qupcase(&data);
%let outdata = %qupcase(&outdata);
%let variance  = %qupcase(&variance);
%let signal = %qupcase(&signal);


/*---check data set---*/
%if %bquote(&data)= %then %let data=&syslast;

%let exiterr = 0;
%let there = no;

data _DATASET;
set &data;
keep gene &treatment &signal;
call symput('there','yes');
run;

%if ("&there" = "no") %then %do;
   %let exiterr = 1;
   %goto exit;
%end;
 
/*---check means with the predres macro---*/
%let nbvar = 3;
%let response = &signal;
%let varlst = &signal &treatment gene;
%let tg = &treatment.gene;

%predres(data=_DATASET);


/*---calculate SS model---*/
data _DATASET;
set _DATASET;
SStot = (mn&tg - mn&treatment - mngene + mntotale)**2;
run;

proc sort data=_DATASET;
by gene;
run;
  
proc means data=_DATASET noprint;
var SStot;
by gene;
output out=_FISHER sum=SStot;
run;

data _FISHER;
set _FISHER;
keep gene SStot;
run;

/*---keep means for plots---*/
data _MNTREATGENE;
set _DATASET;
keep gene &treatment mn&tg;
run;

proc sort data=_MNTREATGENE nodupkey;
by gene &treatment;
run;


/*-----------------------------------------*/
/*              GLM ANALYSIS               */
/*-----------------------------------------*/
  %put;
  %put;
  %put %str(     ) The DIFFERENTIAL_ANALYSIS Macro;
  %put;
  %put Data Set     : &data;
  %put Signal       : &signal;
  %put Treatment    : &treatment;
  %put Variance   : heterogeneous variance;
  %put;
  %put;


 /*---glm gene by gene for the specified treatment---*/
  proc glm data=_DATASET outstat=_SIGMADFGENE noprint;
  class &treatment;
  model &signal=&treatment/SS3;
  by gene;
  run;
  quit;


  /*---check df treatment and df error to calculate Fisher quantile---*/
  %let dferror=0;
  %let dftreat=0;

  data _DFTREAT;
  set _SIGMADFGENE ;
  if _type_ = "SS3";
  call symput ('dftreat',trim(left(DF)));
  run;

  data _VARIANCES(keep=gene sigma2gene DFgene);
  set _SIGMADFGENE ;
  if _source_='ERROR';
  call symput ('dferror',trim(left(DF)));
  sigma2gene = SS/DF;
  rename DF = DFgene;
  run;


  /*---check the variance for each gene---*/

  %let ntotal = 0;

  data _FISHERHET;
  merge _FISHER _VARIANCES;
  by gene;
  Fhet = (SStot/&dftreat)/sigma2gene;
  Phet = 1 - probf(Fhet,&dftreat,&dferror);
  run;
  
  
  /*---calculate adjusted pvalues---*/
  proc sort data=_FISHERHET;
  by Phet;
  run;
  
  data _FISHERHET;
  set _FISHERHET; 
  j+1;
  call symput ('ntotal',trim(left(j)));
  run;

  data _FISHERHET;
  set _FISHERHET;
  n=&ntotal;     
  fdr = &fdr;
  pstar = phet*n/j;
  code=1;
  if (pstar>code) then pstar=code;
  drop code; 
  run;

  proc sort data=_FISHERHET;
  by Fhet;
  run;
 
  data _FISHERHET;
  set _FISHERHET;
  result_het='no diff';
  k+1;
  PhetAdjusted=pstar;
  run;

  %let v1=0;
  %let v2=0;
  %let l=2;

  %do %while(&l<=&ntotal);  

    data _FISHERHET;
    set _FISHERHET;
    if (k=&l) then call symput ('v1',trim(left(PhetAdjusted)));
    if (k=%eval(&l-1)) then call symput ('v2',trim(left(PhetAdjusted)));
    run;

    %if (&v2<&v1) %then %do;
      data _FISHERHET;
      set _FISHERHET;
      if (k=&l) then PhetAdjusted=&v2;
      run;
    %end;

  %let l=%eval(&l+1);
  %end;

  proc sort data=_FISHERHET;
  by phet;
  run;

  data _FISHERHET;
  set _FISHERHET;
  if (PhetAdjusted<fdr) then result_het='diff';
  drop j k n fdr pstar;
  run;

  %let seuil = 0;
  %let genesdiff = 0;

  data _SEUIL;
  set _FISHERHET;
  if result_het='diff';
  gd+1;
  call symput ('genesdiff',trim(left(gd)));
  call symput ('seuil',trim(left(Fhet)));
  run;

  %if not (&genesdiff=0) %then %do;

    /*--- display Fisher statistic and proba for each gene ---*/
    title1 'Number of differentially expressed genes (heterogeneous variance) :';
    title2 ' ';
    title3 "   at &fdr False Discovery Rate => &genesdiff (F-critic = &seuil)";
 
    proc print data = _SEUIL;
    var GENE SStot DFgene sigma2gene Fhet PhetAdjusted;
    run;
 
    /*---plot of Fisher statistic for each gene---*/
    proc sort data=_FISHERHET;
    by gene;
    run;

    data _GRAPH;
    merge _FISHERHET _MNTREATGENE;
    by gene;
    run;
  
    title1 '- Plot of Fisher statistic vs mean of each treatment for each gene -';
    title2 "treatment = &treatment (heterogeneous variance)";
    %if %index(&signal,ADJUSTEDSIGNAL) %then %do;
       title3 "signal adjusted for &modelajust";
    %end;

    proc gplot data=_GRAPH;
    symbol i=none  v=plus;
    axis1 label=none;
    axis2 label=(angle=90 'Fgene (heterogeneous variance)')
                 reflabel=(c=red "F-critic for FDR = &fdr ");
    plot Fhet*mn&tg=&treatment/haxis=axis1 vaxis=axis2 vref=&seuil cvref=red;
    run;
    quit;

  %end;

  %else %do;

    %put There are no differentially expressed genes;

    proc sort data=_FISHERHET;
    by Fhet;
    run;

    data _SEUIL;
    set _FISHERHET;
    compt+1;
    Fhet+1;
    call symput ('seuil',trim(left(Fhet)));
    run;
    
 
    /*---plot of Fisher statistic for each gene---*/
    proc sort data=_FISHERHET;
    by gene;
    run;

    data _GRAPH;
    merge _FISHERHET _MNTREATGENE;
    by gene;
    run;
  
    title1 '- Plot of Fisher statistic vs mean of each treatment for each gene -';
    title2 "treatment = &treatment (heterogeneous variance)";
    %if %index(&signal,ADJUSTEDSIGNAL) %then %do;
       title3 "signal adjusted for &modelajust";
    %end;

    proc gplot data=_GRAPH;
    symbol i=none  v=plus;
    axis1 label=none;
    axis2 label=(angle=90 'Fgene (heterogeneous variance)')
                 reflabel=(c=red "F-critic for FDR = &fdr ");
    plot Fhet*mn&tg=&treatment/haxis=axis1 vaxis=axis2 vref=&seuil cvref=red;
    run;
    quit;

 
  %end;

  /*---creates an output Data Set---*/
  %if %length(&outdata) %then %do;
    %let &outdata = %qupcase(&outdata);
    data &outdata;
    set _FISHERHET;
    run;
    %put The output Data Set &outdata has been created.;
  %end;

  /*---delete data sets created during macro execution---*/  
  
  /*
  proc datasets lib=work nolist;
  delete _DATASET _DFERREUR _DFTREAT _FISHERHET _VARIANCES _AFFICH _INDICE 
         _FISHER _GRAPH _MNTREATGENE _SIGMADFGENE _FISHER _CALC _SEUIL;
  run;
  quit;
  */


  %put;
  %put End of DIFFERENTIAL_ANALYSIS Macro (heterogeneous variance);
  %put;


/*---execution halted if errors--*/
%exit:;
%if (&exiterr = 1) %then %do;
    %put DIFFERENTIAL_ANALYSIS exited due to errors.;
%end;

title;
options date center number notes;

%if %length(&outgraph) %then %do;
   goptions reset=all;
%end;

%mend differential_analysis;


/**********************************************************************/
/**********************************************************************/
/**********************************************************************/


/*=====================================================================*/
/*                                                                     */
/*  Karine PIOT  --  initial coding        24Mar2003                   */
/*                   last modification     29Jul2003                   */
/*                                                                     */
/*                                                                     */
/*  TITLE                                                              */
/*  -----                                                              */
/*                                                                     */
/*  COMPARISON: compares the results of the differential_analysis macro*/
/*              in case of homogeneous variance and heterogeneous      */
/*              variance hypothesis.                                   */
/*                                                                     */
/*                                                                     */
/*  DESCRIPTION                                                        */
/*  -----------                                                        */
/*                                                                     */
/*  The macro allows to compare the results of the macro               */
/*  DIFFERENTIAL_ANALYSIS with homogeneous variance hypothesis to the  */
/*  results of the macro DIFFERENTIAL_ANALYSIS with heterogeneous      */
/*  variance hypothesis.                                               */
/*                                                                     */
/*                                                                     */
/*  SYNTAX                                                             */
/*  -------                                                            */
/*                                                                     */
/*  %comparison ( data1= ,                                             */
/*                data2= ,                                             */
/*                outdata= ,                                           */
/*                outgraph= ,                                          */
/*                fdr= )                                               */ 
/*                                                                     */
/*  where                                                              */
/*                                                                     */
/*  data1       specifies the two data sets created in the outdata     */
/*  data2       option of the DIFFERENTIAL_ANALYSIS macro with         */
/*              homoscedasticity and heteroscedasticity hypothesis     */
/*                                                                     */
/*  outdata     -- OPTIONAL -- by default no data set is created --    */
/*              specifies a name for an output data set. This data     */
/*              merge data1 and data2.                                 */
/*                                                                     */
/*  outgraph    -- OPTIONAL -- by default no graph file is created --  */
/*              specifies a name for a file that will contain the      */
/*              graphs produced by the comparaison macro.              */
/*                                                                     */
/*  fdr         specifies the False Discovery Rate.                    */
/*                                                                     */
/*  EXAMPLE SYNTAX                                                     */
/*  ---------------                                                    */
/*                                                                     */
/*  1) This example uses outdata and outgraph (for Unix/Linux)         */
/*                                                                     */
/*  %comparison  (data1 = TABheterosced,                               */
/*                data2 = TABhomosced,                                 */
/*                outdata = RESULT,                                    */
/*                outgraph = /home/myrepertory/myfile.ps,              */
/*                fdr = 0.05 )                                         */
/*                                                                     */
/*                                                                     */
/*  2) This example uses outdata and outgraph (for Window)             */
/*                                                                     */
/*  %comparison  (data1 = datahom,                                     */
/*                data2 = datahet,                                     */
/*                outdata = bothdata,                                  */
/*                outgraph = c:\myrepertory\myfile.ps,                 */
/*                fdr = 0.05 )                                         */
/*                                                                     */
/*=====================================================================*/


%macro comparison (data1= ,data2= ,fdr= ,outdata= ,outgraph=);

/*---graphical options---*/
goptions reset=all rotate htitle=1.5;

%if %length(&outgraph) %then %do;
  filename mygraph "&outgraph";
  goptions device=pscolor gsfname=mygraph gsfmode=replace;
%end;

/*---system options---*/
options nocenter nodate nonumber nonotes linesize=75 pagesize=53;

/*---merge data1 and data2 by gene---*/
proc sort data=&data1;
by gene;
run;

proc sort data=&data2;
by gene;
run;

data _COMPARE;
merge &data1 &data2;
by gene;
run;


/*---plot global proba vs proba by gene---*/
title 'Graph of Adjusted P-values: Homogeneity versus Heterogeneity';
proc gplot data=_COMPARE;
symbol i=none c=black v=plus;
axis1 label=('Adjusted P-value (heterogeneous variance)') reflabel=(c=blue "FDR = &fdr");
axis2 label=(angle=90 'Adjusted Pvalue (homogeneous variance)' angle=90) 
      reflabel=(c=red "FDR = &fdr");
plot PhomAdjusted*PhetAdjusted/haxis=axis1 vaxis=axis2 href=&fdr vref=&fdr chref=blue cvref=red;
run;

/*---details of common and non-common genes---*/
data _DETAILS;
set _COMPARE;
if (result_het="diff") & (result_hom="diff") then ncd+1;
if (result_het="no diff") & (result_hom="no diff") then ncnd+1;
if (result_het="diff") & (result_hom="no diff") then nci+1;
if (result_het="no diff") & (result_hom="diff") then ncs+1;
call symput ('nbcomdiff',trim(left(ncd)));
call symput ('nbcomnondiff',trim(left(ncnd)));
call symput ('nbnoncomi',trim(left(nci)));
call symput ('nbnoncoms',trim(left(ncs)));
run;

%let tot=%eval(&nbcomdiff + &nbcomnondiff);
%let total=%eval(&nbnoncomi + &nbnoncoms);

/*---display the number and the list of common and non-common genes---*/
title1 "Number of common genes for FDR = &fdr  =>  &tot";
title2 ' ';
title3 "    differentially expressed     =  &nbcomdiff";
title4 "    non-differentially expressed =  &nbcomnondiff";
title5 ' ';
title6 "Number of non-common genes for FDR = &fdr  =>  &total";
title7 "    result_het='diff'    & result_hom='no diff'  =  &nbnoncomi";
title8 "    result_het='no diff' & result_hom='diff'     =  &nbnoncoms";
title9 ' ';


proc sort data=_COMPARE;
by Phom;
run;


data _AFFICH;
set _COMPARE;
if (result_het="diff") & (result_hom="diff");
run;

title10 "List of the &nbcomdiff common differentially expressed genes";
proc print data=_AFFICH;
var gene Fhet Fhom PhetAdjusted PhomAdjusted;
run;



%if %length(&outdata) %then %do;
  %let outdata = %qupcase(&outdata);
  data &outdata;
  set _COMPARE;
  run;
  %put ;
  %put The output Data Set &outdata has been created.;
%end;


/*---delete all the data sets created during the macro execution---*/
proc datasets lib=work nolist;
delete _COMPARE _DETAILS _AFFICH;
run;
quit;


%put;
%put End of COMPARAISON Macro;
%put;

/*---reset options---*/
title;
goptions reset=all;
options center date number notes;

%mend comparison;


/***********************************************************************/
/**************************END OF PACKAGE*******************************/
/***********************************************************************/
*****************/


%mend;

