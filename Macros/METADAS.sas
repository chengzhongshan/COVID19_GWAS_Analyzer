/*************************************************************************************************		  										
**																								**
**																								**
** TITLE:		Diagnostic Test Accuracy Meta-analysis - Bivariate and HSROC models				**
**																								**
**																								**
** AUTHOR:		Yemisi Takwoingi																**
**																								**
** ADAPTED FROM: Petra Macaskill																**
**																								**
**																								**
** DATE CREATED:	28/02/08																	**
** VERSION: 		1.3.0																	**
** DATE MODIFIED:	30/07/10																	**
** MODIFICATION:	Add options to enable:														**
**						-allow import of stata data file										**
**						-refined choice of starting values for the models 						**
**																								**
** PURPOSE: 	To automate fitting of bivariate and HSROC models for 							**
**				meta-analysis of diagnostic accuracy studies using PROC NLMIXED.				**
**				Explanatory variables (covariates) can be added to the models to 				**
**				produce separate effects on the summary measures of test accuracy.				**
**				Also, distributional assumptions of the random effects can be checked and 		**
**				predicted values of sensitivity and specificity, based on empirical Bayes 		**
**				estimates of the random effects, can be obtained for each study in the 			**
**				meta-analysis. The output from the analysis is presented in a Word document.	**  
**	  								 															**
*** INPUT PARAMETERS:																			**
**   		%metadas(																			**
**				dtfile='text'	The path and name of the Excel or Stata file to import 			**
**								e.g. 'C:\Documents\DTA\Revman Test Data.xls'. 					**
**								The file extension (.xl, .csv or .dta) must be included. 		**
**				import=y/n		If =n, a data set must be provided with the dsname= option. 	**
**								The default is y.												**
**				dsname=data set	The input data set if no data import is required.				**
**				tech=quanew/newrap/trureg/nrridg/dbldog/congra/nmsimp							**
**								There are several optimization techniques available with 		**
**								Proc NLMIXED. No algorithm for optimizing general nonlinear 	**
**								functions exists that always finds the global optimum for 		**
**								a general nonlinear minimization problem in a reasonable 		**
**								amount of time. This parameter enables the user to select a 	**
**								technique as they would do if they were running NLMIXED 		**
**								directly. The default is tech=QUANEW. 							**
**								With the exception of options START, DF, ALPHA, HESS, COV 		**
**								and ECOV (they are already in use), you can also specify 		**
**								other Proc NLMIXED options by tagging them on to this 			**
**								parameter e.g. tech = newrap gconv=1e-9 qtol=1e-5. For more 	**
**								information and algorithm descriptions, see the SAS user 		**
**								documentation for NLMIXED.										**
**				ident=y/n		A potential problem with numerical maximization of the 			**
**								likelihood function is identifiability of model parameters. 	**
**								When this occurs, the likelihood will equal its maximum 		**
**								value at a set of parameter values instead of at a single 		**
**								point. To detect if there is a problem, you could try 			**
**								different initial values of the parameters and check for 		**
**								changes in parameter estimates or by examining the Hessian 		**
**								matrix at convergence.											**
**								If ident=y the Hessian matrix after optimization is 			**
**								produced and the eigenvalues of the Hessian are calculated 		**
**								(with values saved in _metadas_a_eigenvals_ / 					**
**								_metadas_cv_eigenvals_). At a true minimum, the eigenvalues 	**
**								will all be positive, i.e., positive definite. The default 		**
**								is y. The starting Hessian matrix is also produced because 		**
**								Proc NLMIXED option START is always used by METADAS to 			**
**								output the gradient at the starting values.						**
**				tp=variable		The number of true positives. The default variable name is 		**
**								tp so that RevMan users or those who have named their 			**
**								variables accordingly do not need to specify this input 		**
**								parameter.														**
**				fp=variable		The number of false positives. The default variable name is	fp.	**															**
**				fn=variable		The number of false negatives. The default variable name is fn.	**														**
**				tn=variable		The number of true negatives. The default variable name is tn.	**
**				subject=variable																**	
**								This determines when new realizations of the random effects 	**
**								are assumed to occur. Proc NLMIXED assumes that a new 			**
**								realization occurs whenever the subject= variable changes 		**
**								from the previous observation, so the input data set is 		**
**								clustered according to this variable. The default variable 		**
**								name is study_id (as named in the RevMan 5 data export file)	**
**				cialpha=numeric	Specifies the alpha level for computing z statistics and 		**
**								confidence limits. The default is 0.05.							**
**				byvar=variable	This enables multiple analyses, i.e., consecutive calls 		**
**								to Proc NLMIXED for each test or group of studies in the 		**
**								data file. This may also be used to produce separate models 	**
**								using subsets of the data (subgroup analyses as in 				**
**								traditional meta-analysis) but be aware this is not 			**
**								recommended because you cannot formally test for a 				**
**								difference. A better approach is to use all the data and 		**
**								include the variable as a covariate in the model.				**
**				covariate=variable																**
**								Specifies a covariate for inclusion in the model 				**
**								(meta-regression). Covariates can be included in the model 		**
**								to determine the effect of patient or study characteristics 	**
**								on threshold, accuracy, and the shape of the SROC 				**
**								(individually or in any combination) for the HSROC model or 	**
**								on sensitivity and/or specificity for the bivariate model. 		**
**								For example, to compare multiple tests use test type as a 		**
**								covariate in the model.											**
**				cvref='text'/numeric															**
**								This specifies the reference level of the covariate. If it 		**
**								is not specified, the reference level is selected based on 		**
**								the sort order. Sorting is done in ascending order by 			**
**								default and for descending specify sortcv=d.					**
**				sortcv=d/a		The sort order for the covariate. sortcv=d specifies 			**
**								descending order and a specifies ascending. The default is 		**
**								to sort in ascending order.										**
**				cvtype=cat/con	Type of covariate. Options are cat for categorical or con 		**
**								for continuous. If the parameter is not specified, the 			**
**								covariate is assumed to be categorical.							**
**				cveffect=a/t/b/at/ab/bt/abt/se/sp/sesp											**
**								For the HSROC model t specifies that the effect of the 			**
**								covariate be assessed only on theta, a on alpha only, b on 		**
**								only beta, ab on alpha and beta, at on alpha and theta, bt 		**
**								on beta and theta, and abt on all three parameters. Default 	**
**								is abt.															**
**								For the bivariate model, se specifies that the effect be 		**
**								assessed only on sensitivity while sp on specificity and 		**
**								sesp specifies effect on both sensitivity and specificity. 		**
**								Default is sesp.												**
**				cvsummorder=stat/level															**
**								Specifies the ordering of items in the table of summary 		**
**								estimates for a model with covariate. If level is specified,	**
**								items are listed in the table according to covariate level. 	**
**								If stat is specified, items are listed according to summary 	**
**								statistic such that all levels of the covariate are grouped 	**
**								together for each statistic. The default is stat.				**
**				formatlr=y/n	For formatting the log likelihood difference and p-value 		**
**								obtained for the likelihood ratio test. If =y, then -2logL 		**
**								difference is formatted to 3 decimal places if it is greater	**
**								than or equal to 0.001 otherwise the exact value is 			**
**								reported. The p-value is formatted to 3 d.p. if less than or	**
**								equal to 0.001 and as <0.001 if less than 0.001. The default	**
**								is y.															**
**				test='text'/numeric																**
**								The name of the test to analyse	if the data file contains		**
**								more than one test on which we wish to perform a variety		**
**								of analyses. No need to specify a test if there is only one.	** 	
**				method=h/b		Specifies the type of model to fit. Options are b for 			**
**								bivariate or h for HSROC method. The default is h.				**
**				mtitle=text		Title of the meta-analysis that is placed in the Word 			**
**								document. Default is Meta-analysis of diagnostic test 			**
**								accuracy studies.												**
**								NOTE: no quotation marks allowed unlike some of the other 		**
**								text options.													**
**				tbpe=data set	Use parameters and starting values stored in the named 			**
**								table. The data set can be in either a narrow or wide form. 	**
**								The narrow-form data set contains the variables PARAMETER 		**
**								and ESTIMATE, with parameters and values listed as distinct 	**
**								observations. The wide-form data set has the parameters 		**
**								themselves as variables, and each observation provides a 		**
**								different set of starting values. 								**
**								Note: In this version of METADAS, the data set should only 		**
**								contain the 5 basic parameters for either the HSROC (alpha, 	**
**								theta, beta, s2ua and s2ut) or bivariate model (msens, 			**
**								mspec, s2usens, s2uspec, covsesp). If there is a covariate, 	**
**								the starting values for additional parameters can be 			**
**								specified using cspa1 - cspa5, cset1 - cset5 and/or 			**
**								cpb1 - cpb5.													**
**				p1 - p5			These are the basic parameters and their starting values. 		**
**								There are five such parameters for either model. You can 		**
**								either specify a single number e.g. p1= 2.5 or you can use 		**
**								the TO and BY keywords to specify a number list for a grid 		**
**								search e.g. p1 = -2 to 2 by 0.5. If you specify a grid of 		**
**								points, the objective function value at each grid point is 		**
**								calculated and the best (feasible) grid point is chosen as 		**
**								an initial point for the optimization process.					**
**								For HSROC model:												**
**								p1 = alpha (accuracy parameter), p2 = theta (threshold 			**
**								parameter), p3 = beta (shape parameter), p4 = variance of 		**
**								accuracy, p5= variance of threshold. The default values are:	**
**								p1= -4 to 4 by 1												**
**								p2= -2 to 2 by 1												**
**								p3= -3 to 2 by 0.5												**
**								p4= 0 to 1 by 0.2												**
**								p5= 0 to 1 by 0.2												**
**								For bivariate model:											**
**								p1 = mean logit sensitivity, p2 = mean logit specificity, 		**
**								p3= variance of logit sensitivity, p4 = variance of logit 		**
**								specificity, p5 = covariance of logit sensitivity and 			**
**								specificity. The default values are:							**
**								p1= -2 to 4 by 1												**
**								p2= -2 to 4 by 1												**
**								p3= 0 to 1 by 0.2												**
**								p4= 0 to 1 by 0.2												**
**								p5= -1 to 1 by 0.2												**
**				cspa1 - cspa5	If the HSROC model is required, these specify starting 			**
**								values for additional alpha parameters or if it is the 			**
**								bivariate model then they are for additional specificity 		**
**								parameters e.g. cspa1 = 0 to 2 by 1. cspa1 - cspa5 indicates	**
**								a maximum of 5 parameters, i.e., a covariate with 6 levels. 	**
**								The default is 0 for any of the 5 parameters, i.e., cspa1=0,	**
**								cspa2 = 0 for a covariate with 3 levels.						**
**				cset1 - cset5	Starting values for additional theta or sensitivity 			**
**								parameters. The maximum is 5, i.e., a covariate with 6 			**
**								levels,. The default is 0 for any of the 5 parameters, i.e.,	**
**								cset1 = 0, cset2 = 0 for a covariate with 3 levels.				**
**				cpb1 - cpb5		Starting values for additional beta parameters. Applies to 		**
**								each level of the covariate except the reference level, 		**
**								therefore a maximum of 5 parameters, i.e., a covariate 			**
**								with 6 levels.													**
**				randeffs=y/n	Produce table of empirical Bayes estimates of the random 		**
**								effects if = y. The default is n.								**
**				predict=y/n		If =y, predictions are obtained using the estimated model, 		**
**								parameter estimates and empirical Bayes estimates of the 		**
**								random effects. Standard errors of prediction are computed 		**
**								using the delta method and the predicted values of logitp 		**
**								(stored in data sets prefixed with _logitp_ and _logitp_cv_)	**
**								are transformed to obtain predictions of sensitivity and 		**
**								specificity (stored in data sets prefixed with _predsesp_ 		**
**								and _predsesp_cv_). The default is n.							**
**				checkmod=y/n	If =y, produce histograms and normal probability plots of 		**
**								the empirical Bayes estimates of the random effects to 			**
**								check assumption of normality. The default is n.				**
**				debug=y/n		Debugging tool. If =y, displays the SAS statements that are 	**
**								generated by macro execution. The default is n.					**
**				logfile='text'	Path and file name to save the contents of the SAS log. 		**
**								Must add the .log extension. Contents of the log file are 		**
**								scanned and any errors found are stored in _metadas_errors, 	**
**								warnings in _metadas_warnings, and model failure messages 		**
**								generated by METADAS in _metadas_modfail. The data set for 		**
**								the log contents is _metadas_log.								**
**				outfile='text'	Path and filename to save the contents of the SAS output 		**
**								window. The file name must have the .lst extension. This is 	**
**								especially useful if the analysis is expected to run for 		**
**								awhile because the output window will fill up and user input	**
**								is required before SAS can proceed. However, this is not 		**
**								the case if the output is being saved to a file.				**
**				keepds=all/some/log/none														**
**								Selectively keeps the data sets produced as output from the 	**
**								analyses. Option some is the default. With this option, 		**
**								data sets containing data from the Excel file are kept, 		**
**								including any data sets generated from the log file if a 		**
**								log file was specified. For the option log, only the data 		**
**								sets generated from the log file are kept. If option none is	**
**								specified, all data sets prefixed with _metadas_ are 			**
**								deleted. Option all keeps all output data sets from NLMIXED 	**
**								as well as two summary ones for covariate summary and 			**
**								relative measures of test accuracy. Data sets for 				**
**								predictions, random effects, the Hessian matrix and 			**
**								eigenvalues are also kept with options all and some if 			**
**								parameters have been specified for them.						**
**								METADAS output data sets										**
**								All data from Excel file =_metadas_meta							**
**								Unique values of the BY variable = _metadas_variablename		**
**								Data set for level i of the BY variable = _metadas_dsi			**
**								Unique values of the covariate = _metadas_variablename			**
**								Predicted logitp for model without covariate=_metadas_logitp_i	**
**								Predicted logitp for model with covariate=_metadas_cv_logitp_i	**
**								Predicted sensitivities and specificities for 					**
**								model without covariate = _metadas_predict_i					**
**								Predicted sensitivities and specificities for model with 		**
**								covariate = _metadas_cv_predict_i								**
**								Relative estimates of accuracy measures for 					**
**								covariate = _metadas_cv_relsummary_i							**
**								Summary estimates of accuracy measures for covariate = 			**
**								_metadas_cv_statsummary_i										**
**								Eigenvalues for model without covariate =_metadas_a_eigenvals_	**
**								Eigenvalues for model with covariate =_metadas_cv_eigenvals_	**
**								SAS NLMIXED output data sets are prefixed by metadas as follows:**
**								Model without covariate											**
**								Starting values =_metadas _a_sv_								**
**								Parameters=_metadas_a_parms_									**
**								Parameter estimates=_metadas_a_pe_								**
**								Fit statistics=_metadas_a_fit_									**
**								Additional estimates=_metadas_a_addest_							**
**								Covariance matrix of additional estimates =_metadas_a_covaddest_**
**								Convergence status=_metadas_a_convgstat_						**
**								Final Hessian matrix=_metadas_a_hessian_						**
**								Model with covariate											**
**								Starting values = _metadas_cv_sv_								**
**								Parameters=_metadas_cv_parms_									**
**								Parameter estimates=_metadas_cv_pe_								**
**								Fit statistics=_metadas_cv_fit_									**
**								Additional estimates=_metadas_cv_addest_						**
**								Covariance matrix of additional estimates=_metadas_cv_covaddest_**
**								Convergence status=_metadas_cv_convgstat_						**
**								Contrasts=_metadas_cv_contrasts_								**
**								Final Hessian matrix=_metadas_cv_hessian_						**
**								For the bivariate model there are 2 additonal tables, 			**
**								metadas_cv_covparmest_ and metadas_cv_covparmest_, for the 		**
**								covariance marix of parameter estimates. 						**
**				revman='text'	Launch the specified RevMan 5 file at the end of analysis so 	**
**								that parameters can be copied and pasted into the appropriate 	**
**								cells for the analysis in the external analyses section.		**
**				info=y/n		If =y, include details of some of the input parameters 			**
**								specified for the macro. The default is y.						**
**				bothmodels=y/n	If = y both models are included in the output. For instance, if **
**								the method is HSROC then bivariate parameters are obtained as 	**
**								functions of the HSROC parameters and included in the output. 	**
**								The default is n.												**
**				incbasic=y/n	If = n then the output for the model with no covariate is 		**
**								suppressed. This may be useful where the model with no covariate**
**								has already been investigated and the parameters are no longer 	**
**								of interest for extraction to RevMan or in test comparisons 	**
**								where the covariate is test type. The default is y.				**
**				rfile='text'	Path and name of the Word document to save the result of the 	**
**								analyses. The file name must have the .rtf extension 			**
**								(rich text file).												**
**																								**
**																								**
**	Example: %metadas(dtfile= 'C:\Test\Revman Test Data.xls', covariate=age_group, 				**
**							test='HPV testing', method=b, tech = newrap gconv=1e-9 qtol=1e-5,	**
**							rfile ="c:\Test\hsroc test data output.rtf");						**
**																								**
*************************************************************************************************/


/* Declare global macro variables which will be used in some of the macros below */
%global metadas nlevels bylevels estmuAcv estmuBcv estsenscv estspeccv estDOR 
		estRDOR estRelSens estRelSpec estLRpos estLRneg estAlpha estTheta 
		estBeta estMuAlevels estMuBlevels pms cvparamlist logitp contrasta 
		contrastt contrastb contrastse contrastsp dsprefixpe dsprefixae dsprefixcov sub;


%macro metadas(dtfile=, import=, dsname=, tech=, ident=,
				tp=, fp=, fn=, tn=, subject=, cialpha=, byvar=, 
				covariate=, cvref=, sortcv=, cvtype=, cveffect=, 
				cvsummorder=, formatlr=, test=, method=, mtitle=, tbpe=, 
				p1=, p2=, p3=, p4=, p5=, cspa1=, cspa2=, cspa3=, cspa4=, 
				cset1=, cset2=, cset3=, cset4=, cpb1=, cpb2=, cpb3=, cpb4=,
 				randeffs=, predict=, checkmod=, debug=, logfile=, outfile=, 
				keepds=, revman=, info=, bothmodels=, incbasic=, rfile=);

	%put %str(*******************************************************);
	%put %str(*    		                                            *);
	%put %str(* 	META-ANALYSIS OF DIAGNOSTIC ACCURACY STUDIES 	*);
	%put %str(*											            *);
	%put %str(*******************************************************);


	/* initialise macro variable as zero
	use this macro variable to track execution of macros within metadas.
	return 0 if unsuccessful otherwise 1*/
	%let metadas=0;

	/* prefixes for data sets generated from analysis with covariate */
	%let dsprefixpe=_metadas_cv_pe_cv;
	%let dsprefixae=_metadas_cv_ae_cv;
	%let dsprefixcov=_metadas_cv_cov_cv;
	%let sub=_ds;

	/* If importing data, check if the external data file exists 
	if it exists check the last 4 characters for file extensions .xls or .csv  or .dta
	and set the dbms type */
	%if %upcase(&import)~= N and &dtfile ~= %str() %then %do;
		%if %sysfunc(fileexist(&dtfile)) ~=1 %then %do;
			%put %str(FILE ERROR: File &dtfile not found! Please check the path, file name and extension.);
			%put %str(Execution of metadas terminated.);
			%return;
		%end;
		%else %do;
			%let len=%sysfunc(lengthn(&dtfile));

			%let ext=%sysfunc(substr(&dtfile,&len-4,4));
			%if &ext ~= %str() %then %do;
				%if %upcase("&ext")=".XLS" %then %let dbmstype=excel; 
				%else %if %upcase("&ext")=".CSV" %then %let dbmstype=csv;
				%else %if %upcase("&ext")=".DTA" %then %let dbmstype=dta;
				%else %do;
					%put %str(FILE ERROR: &dtfile extension must be .csv, .xls or .dta. Data import failed!);
					%put %str(Execution of metadas terminated.);
					%return;
				%end;
			%end;
			%else %do;
				%put %str(FILE ERROR: Failed to get the file extension! Please check file name and extension (.csv or .xls depending on the file type).);
				%put %str(Execution of metadas terminated.);
				%return;
			%end;
		%end;
	%end;
	%else %if %upcase(&import)~=N and &dtfile = %str() %then %do;
		%put %str(INPUT ERROR: Excel file (.csv or .xls) not specified.);
		%put %str(If data import is required a file name must be specified otherwise specify option IMPORT=N and provide a data set (DSNAME=).);
		%put %str(Execution of metadas terminated.);
		%return;
	%end;

	/* data set name is required if no import */
	%if %upcase(&import)= N and &dsname = %str() %then %do;
		%put %str(INPUT ERROR: A data set must be specified for option DSNAME if data import from Excel is not required.);
		%put %str(Execution of metadas terminated.);
		%return;
	%end;
	/* if data set is specified check that it exists */
	%else %if &dsname ~= %str() %then %do;
		%if not %sysfunc(exist(&dsname)) %then %do;
			%put %str(DATA SET ERROR: The data set &dsname does not exist.);
			%put %str(Check that you have specified the correct data set name and library.);
			%put %str(Execution of metadas terminated.);
			%return;
		%end;
		%let dbmstype=%str();
	%end;

	/* Check for variables representing the cells of the 2x2 table and study identifier.
	If they are not specified use the RevMan 5 names since the macro is designed mainly for 
	RevMan 5 users anyway 
	If alpha level is not specified use a default of 0.05 to obtain 95% confidence limits */
	%if &tp=%str() %then %let tp=tp;
	%if &fp=%str() %then %let fp=fp;
	%if &fn=%str() %then %let fn=fn;
	%if &tn=%str() %then %let tn=tn;
	%if &subject=%str() %then %let subject=study_id;
	%if &cialpha=%str() %then %let cialpha=0.05;
	
	/* If a log file name is specified, send output that would normally go to the Log Window 
	to the file and if the file already exists replace it.
	Also, check the extension is correctly specified (.log) */
	%if &logfile ~= %str() %then %do;
		%let len=%sysfunc(lengthn(&logfile));
		%let ext=%sysfunc(substr(&logfile,&len-4,4));
		%if %upcase("&ext")=".LOG" %then %do;
			filename logfile &logfile; 		
			proc printto log = logfile new;
		%end;
		%else %do;
			%put %str(FILE ERROR: &logfile extension must be .log!);
			%put %str(Execution of metadas terminated.);
			%return;			
		%end; 
	%end;

	/* If an output file name is specified, send output that would normally go to the Output Window 
	to the file and if the file already exists replace it.
	Also, check the extension is correctly specified (.lst) */
	%if &outfile ~= %str() %then %do;
		%let len=%sysfunc(lengthn(&outfile));
		%let ext=%sysfunc(substr(&outfile,&len-4,4));
		%if %upcase("&ext")=".LST" %then %do;
			filename outfile &outfile; 		
			proc printto print = outfile new;
		%end;
		%else %do;
			%put %str(FILE ERROR: &outfile extension must be .lst!);
			%put %str(Execution of metadas terminated.);
			%return;			
		%end; 
	%end;

	%if &byvar~=%str() %then %do;
		/* need to check that the name of the data set _metadas_&byvar
		will not exceed 32, the maximum length for a sas sata set name*/
		%let bylen= %sysfunc(lengthn(&byvar));
		%let dslen= %eval(&bylen + 9);
		%if &dslen > 32 %then %do;
			%put %str(METADAS ERROR: The length (&dslen) of the name of the metadas generated data set, _metadas_&byvar, exceeds 32 which is the maximum for a SAS data set name!);
			%put %str(Please shorten the name of the BY= variable.);
			%put %str(Execution of metadas terminated.);
			%return;	
		%end;
		%else %if %sysfunc(exist(_metadas_&byvar)) %then %do;
			data _null_;
	   			set _metadas_&byvar nobs = numobs; 
				call symput('numobs',numobs);
			run;
			%let bylevels=&numobs;
		%end;
		%else %let bylevels=0;
	%end;
	%else %let bylevels=1;

	%if &covariate~=%str() %then %do;
		/* need to check that the name of the data set _metadas_&covariate
		will not exceed 32, the maximum length for a sas sata set name*/
		%let cvlen= %sysfunc(lengthn(&covariate));
		%let dslen= %eval(&cvlen + 9);
		%if &dslen > 32 %then %do;
			%put %str(METADAS ERROR: The length (&dslen) of the name of the metadas generated data set, _metadas_&covariate, exceeds 32 which is the maximum for a SAS data set name!);
			%put %str(Please shorten the name of the COVARIATE= variable.);
			%put %str(Execution of metadas terminated.);
			%return;	
		%end;
		%else %if %sysfunc(exist(_metadas_&covariate)) %then %do;
			data _metadas_&covariate;
	   			set _metadas_&covariate nobs=num; 
				call symput('num',num);
			run;
			%let nlevels=%eval(&num-1);	
		%end;
		%else %let nlevels=0;
	%end;

	/* clear output data sets from previous analysis if any */	
	%keepds(mode=none);
	run;

	/* check if macro successfully executed */
	%if &metadas=0 %then %goto continueprog;

	/* if user wishes to debug macro execution, turn on
	  macro debug system options */
	%if %upcase(&debug)=Y %then %do;
		options mprint;
	%end;

	/* add this title for the Word document header if none is provided */
	%if &mtitle=%str() %then %do;
   		%let mtitle=Meta-analysis of diagnostic accuracy studies;
   		run;
  	%end;
	
	/* Import data from Excel file and create appropriate SAS data set */	
	%setupdata(dtfile=&dtfile, import=&import, dsname=&dsname, 
				tp=&tp, fp=&fp, fn=&fn, tn=&tn, dbmstype=&dbmstype, 
				byvar=&byvar, covariate=&covariate, cvref=&cvref,
				sortcv=&sortcv, cvtype=&cvtype, test=&test,
				method=&method);
	run;

	/* check if macro successfully executed */
	%if &metadas=0 %then %goto continueprog;

	/* get the optimisation technique, if none use quanew as default*/
	%if &tech=%str() %then %let tech=%str(tech=quanew);
   	%else %if &tech~=%str() %then %let tech=%str(tech=&tech);

	/* output Hessian matrix at convergence if ident=y*/
	%if %upcase(&ident)= N %then %let hessout= ;
   	%else %if %upcase(&ident) ~=N %then %let hessout=hess;

	/* Call analysis macro depending on whether an HSROC or 
	bivariate model is required. The default is HSROC. */
	%if %upcase(&method) = H or &method = %str() %then %do;
		%metah(subject=&subject, cialpha=&cialpha, tech=&tech, hessout=&hessout,
				byvar=&byvar, covariate =&covariate, cvtype=&cvtype, cveffect=&cveffect, 
				mtitle=&mtitle, tbpe=&tbpe, p1=&p1, p2=&p2, p3=&p3, p4=&p4, p5=&p5, 
				cset1=&cset1, cset2=&cset2, cset3=&cset3, cset4=&cset4, 
				cspa1=&cspa1, cspa2=&cspa2,	cspa3=&cspa3, cspa4=&cspa4, 
				cpb1=&cpb1, cpb2=&cpb2, cpb3=&cpb3, cpb4=&cpb4,
				randeffs=&randeffs, predict=&predict, checkmod=&checkmod);
		run;
	%end; 
	%else %if %upcase(&method) = B %then %do;
		%metab(subject=&subject, cialpha=&cialpha, tech=&tech, hessout=&hessout,
				byvar=&byvar, covariate =&covariate, cvtype=&cvtype, cveffect=&cveffect, 
				mtitle=&mtitle, tbpe=&tbpe, p1=&p1, p2=&p2, p3=&p3, p4=&p4, p5=&p5, 
				cset1=&cset1, cset2=&cset2, cset3=&cset3, cset4=&cset4, 
				cspa1=&cspa1, cspa2=&cspa2,	cspa3=&cspa3, cspa4=&cspa4,
				randeffs=&randeffs, predict=&predict, checkmod=&checkmod);
		run;
	%end;

	/* check if macro successfully executed */
	%if &metadas=0 %then %goto continueprog;

	/* parameter identifiability check using the Hessian matrix*/
	%if %upcase(&ident) ~= N %then %do;

		%do k = 1 %to &bylevels;

			data _metadas_a_hess_&k (drop= Row Parameter);
				set _metadas_a_hessian_&k;
			run;

			proc iml;
				use _metadas_a_hess_&k; /* input data set */
				read all into mx; /* read all observations into matrix mx */
				_m_eg = eigval(mx); /* compute eigenvalues */
				/* create a SAS data set from the resulting matrix */
				create _metadas_a_eigenvals_&k from _m_eg[colname='Eigenvalue']; 
   				append from _m_eg;
			quit;

			proc datasets;
				delete _metadas_a_hess_&k;
			run;
			quit;

			%if &covariate ~=%str() %then %do;
				data _metadas_cv_hess_&k (drop= Row Parameter);
					set _metadas_cv_hessian_&k;
				run;

				proc iml;
					use _metadas_cv_hess_&k;
					read all into mxcv;
					_m_egcv = eigval(mxcv); 
					/* create a SAS data set from the resulting matrix */
					create _metadas_cv_eigenvals_&k from _m_egcv[colname='Eigenvalue']; 
   					append from _m_egcv;
				quit;

				proc datasets;
					delete _metadas_cv_hess_&k;
				run;
				quit;
			%end;
		%end;
	%end;

	/* output results of the analysis to Word */
	%printtodoc(method=&method, covariate=&covariate, cvtype=&cvtype, 
				cveffect=&cveffect,	formatlr=&formatlr, byvar=&byvar, 
				mtitle=&mtitle, info=&info, cialpha=&cialpha,
				subject=&subject, predict=&predict, dtfile=&dtfile, 
				checkmod=&checkmod, bothmodels=&bothmodels, 
				incbasic=&incbasic, rfile=&rfile);
	run;

	/* check if macro successfully executed */
	%if &metadas=0 %then %goto continueprog;

	%if %upcase(&keepds) ~= ALL %then %do;
		%keepds(mode=&keepds, covariate=&covariate, byvar=&byvar, 
				randeffs=&randeffs, checkmod=&checkmod);
		run;
	%end;

	/* resume metadas execution here if any of the other macros
	failed to execute correctly, i.e, returned metadas = 0. */
	%continueprog:;

	/* if debugging options were switched on earlier, turn off
	  macro debug system options at the end*/
	%if %upcase(&debug)=Y %then %do;
		options nomprint;
	%end;


	/* Create tables of errors, warnings and model failure messages 
	based on the log output sent to file */
	%if &logfile ~= %str() %then %do;	

		/*change the destination for the log back to the SAS Log Window */
		proc printto log = log;
		run;

		/* read full log into _tb_log, any errors into _tb_errors, any warnings into _tb_warnings 
		and any programmer generated model failure messages to _tb_modfail. */ 
		data _metadas_log(keep=logline) _metadas_errors _metadas_warnings _metadas_modfail; 
			infile logfile missover; 
	      	length logline $256 code macroname $20 tbloglineref 4; 
	      	retain code macroname; 
	      	input; 
	      	if index(_infile_,'0D'x) then logline=scan(_infile_,1,'0D'x); 
	      	else                          logline=_infile_; 
	      	logline = translate(logline,' ','%'); 
			tbloglineref=_n_;
	      	if index(logline,'MPRINT(') then macroname=scan(logline,2,'()'); 
	      	if index(logline,':') then code=scan(logline,1,':'); 
	      	else if substr(logline,1,5) ne ' ' then code=scan(logline,1,' '); 
	      	output _metadas_log; 
	      	if index(code,'ERROR') =1 and logline ne ' ' then output _metadas_errors; 
			else if index(code,'WARNING') =1 and logline ne ' ' then output _metadas_warnings;
			else if index(code,'MODEL FAILURE') =1 and logline ne ' ' then output _metadas_modfail; 
	   	run; 		
	%end;

	/*change the destination for the output back to the SAS Output Window */
	%if &outfile ~= %str() %then %do;
		proc printto print = print;
		run;
	%end;

	%if &metadas = 0 %then %do;
		%put %str(Error encountered. Execution of metadas terminated.);
		%return;
	%end; 

	/* Open specified revman file */
	%if &revman ~= %str() %then %do;
		%if %sysfunc(fileexist(&revman)) ~=1 %then %do;
			%put %str(FILE ERROR: The RevMan file (&revman) was not found! Please check the path and file name.);
			%put %str(Execution of metadas terminated.);
			%return;
		%end;
		%else %do;
			options noxwait noxsync;
			x &revman;
			run;
		%end;
	%end;

%mend;


/********************************************************************
*																	*
* 		IMPORT DATA	FROM EXCEL FILE	AND MODIFY FOR ANALYSIS			*			
*																	*
********************************************************************/

%macro setupdata(dtfile=, import=, dsname=, method=,
				tp=, fp=, fn=, tn=, dbmstype=, byvar=, 
				covariate=, cvref=, sortcv=, cvtype=, test=);

	/* set global variable metadas to 0 to begin with */
	%let metadas=0;

	/* if import is not NO and we have an Excel file, then import data */
	%if %upcase(&import) ~=N and &dtfile ~= %str() %then %do;
		%put %str(*******************************************************);
		%put %str(IMPORT DATA FROM %upcase(&dbmstype) FILE AND MODIFY FOR ANALYSIS);	
		%put %str(*******************************************************);
		
		%put %str(-----------------------------------------------------------------------------);
		%put %str(DATA STEP 1: Import data from %upcase(&dtfile));
		%put %str(-----------------------------------------------------------------------------);

		/* run proc import to import data from excel/csv file or Stata data file*/	
		%if  %upcase(&dbmstype) = DTA %then %do;	
			proc import 	
				out= _metadas_meta		/* Name of the SAS data to create */
				datafile= &dtfile 		/* Name of Stata file to import */
				dbms=&dbmstype replace;
			run;
		%end;
		%else %do;
			proc import 	
				out= _metadas_meta		/* Name of the SAS data to create */
				datafile= &dtfile 		/* Name of Excel file to import */
				dbms=&dbmstype replace;
				getnames=yes; 			/* Generate variable names from the first row of data in the Excel file */
			run;
		%end;

		%if &syserr ~=0 %then %do;
			%put %str(ERROR: Failed to import data from %upcase(&dtfile). If the file is open, please close and rerun the macro.);
			%put %str(Execution of metadas terminated.);
			%return;
		%end;
		%else %let dsname=_metadas_meta;
	%end;
			
	%put -------------------------------------;
	%put DATA STEP 2: Modify data for analysis;
	%put -------------------------------------;

	/* Modify the data set in order to create 2 records 
	for each study, one for sensitivity and the other for specificity */
	%if %upcase(&method) = B %then %do;
		data &dsname;
			set &dsname;
			if &tp=0 or &fp=0 or &fn=0 or &tn=0 then do;
				zctp=&tp+0.5;
				zcfp=&fp+0.5;
				zcfn=&fn+0.5;
				zctn=&tn+0.5;
			end;
			else do;
				zctp=&tp;
				zcfp=&fp;
				zcfn=&fn;
				zctn=&tn;
			end;
			sensit=zctp/(zctp+zcfn);
			specit=zctn/(zctn+zctp);
			logit_sens=log(sensit/(1-sensit));
			var_logit_sens=1/(sensit*(1-sensit)*(zctp+zcfn));
			logit_spec=log(specit/(1-specit));
			var_logit_spec=1/(specit*(1-specit)*(zctn+zcfp));
		run;
		%if &test=%str() %then %do;
	   		data _metadas_tbmeta;
				set &dsname;
				n=&tp+&fn; 					/* Number with disease, sensitivity */
				sens=1; spec=0; true=&tp; 	/* Set this up for bivariate model */
				logit=logit_sens;
				var_logit=var_logit_sens;
				rec+1;
				output;
				n=&tn+&fp; 					/* Number without disease, specificity */
				sens=0; spec=1; true=&tn; 	/* Set this up for bivariate model */
				logit=logit_spec;
				var_logit=var_logit_spec;
				rec+1;
				output;
			run;
	  	%end;
		%else %if &test~=%str() %then %do;
			data _metadas_tbmeta;
				set &dsname; 
				where test = &test;
				n=&tp+&fn; 					/* Number with disease, sensitivity */
				sens=1; spec=0; true=&tp; 	/* Set this up for bivariate model */
				logit=logit_sens;
				var_logit=var_logit_sens;
				rec+1;
				output;
				n=&tn+&fp; 					/* Number without disease, specificity */
				sens=0; spec=1; true=&tn; 	/* Set this up for bivariate model */
				logit=logit_spec;
				var_logit=var_logit_spec;
				rec+1;
				output;
			run;
		%end;
	%end;
	%else %if %upcase(&method) ~= B %then %do;
		%if &test=%str() %then %do;
	   		data _metadas_tbmeta;
				set &dsname;
				n=&tp+&fn; 					/* Number with disease, sensitivity */
				dis=0.5; pos=&tp;         	/* Set this up for HSROC model */
				sens=1; spec=0;  			/* Set this up for computing predictions in printtodoc */
				output;
				n=&tn+&fp; 					/* Number without disease, specificity */
				dis=-0.5; pos=&fp;         	/* Set this up for HSROC model */
				sens=0; spec=1;
				output;
			run;
	  	%end;
		%else %if &test~=%str() %then %do;
			data _metadas_tbmeta;
				set &dsname; 
				where test = &test;
				n=&tp+&fn; 					/* Number with disease, sensitivity */
				dis=0.5; pos=&tp;         	/* Set this up for HSROC model */
				sens=1; spec=0; 
				output;
				n=&tn+&fp; 					/* Number without disease, specificity */
				dis=-0.5; pos=&fp;         	/* Set this up for HSROC model */
				sens=0; spec=1;
				output;
			run;
		%end;
	%end;

	/* Create dummy variables for the specified categorical covariate */
	%if &covariate~=%str() and %upcase(&cvtype)~= CON %then %do;

		%put %str(Create dummy variables for covariate %upcase(&covariate));

		/* A: 
		Get unique values of the covariate into the data set tbmeta_covariatename
		Sort covariate - A for ascending, D for descending */
		%if %upcase(&sortcv) = D %then %let sortdesc = descending;
		%else %let sortdesc = ;
		proc sort data=_metadas_tbmeta out= _metadas_&covariate nodupkey; 
			by &sortdesc &covariate;
		run;

		/* B: 
		The macro variable nlevels will contain the number of levels of 
		the covariate. If a reference level is given for the covariate 
		then set cvlevels value to 0 otherwise use only the sort order to 
		generate all values.*/
		%if &cvref=%str() %then %do;
			data _metadas_&covariate;
	   			set _metadas_&covariate end = maxn;			
				cvlevels =_n_-1;
				if maxn then call symput('nlevels', put(cvlevels, 3.)); 
			run;
		%end;
		%else %do;

			/* check the given reference level exists in the data set */
			%let numobs=0;

			data _tmp_;
	   			set _metadas_&covariate;			
				where &covariate=&cvref; 
			run;
			data _null_;
				set _tmp_ nobs=numobs;
				call symput('numobs',numobs);
			run;

			%if %sysfunc(exist(_tmp_)) %then %do;			
				proc datasets memtype=data nodetails nolist; 
					delete _tmp_; 
				run;				
			%end;

			%if &numobs > 0 %then %do;
				data _metadas_&covariate;
		   			set _metadas_&covariate;
					if &covariate=&cvref then _cv_reference_=1;
					else _cv_reference_ = 0;
				run;

				proc sort data=_metadas_&covariate;
					by descending _cv_reference_;
				run;

				data _metadas_&covariate;
		   			set _metadas_&covariate end=maxn;
					if _cv_reference_ =1 then cvlevels=0;
					else cvlevels =_n_-1;
					if maxn then call symput('nlevels', put(cvlevels, 3.)); 
				run;
			%end;
			%else %do;
				%put %str(ERROR: The reference level &cvref specified for option CVREF does not exist in the data set.);
				%let metadas=0;
				%return;
			%end;
		%end;

		/* C:
		Finally create the dummy variables for the covariate 
		Sort each data set then merge them and generate values 
		for each dummy variable */
		proc sort data = _metadas_tbmeta;
			by &sortdesc &covariate;
		run;

		proc sort data = _metadas_&covariate;
			by &sortdesc &covariate;
		run;

		data _metadas_tbmeta;
   			merge _metadas_tbmeta _metadas_&covariate;
   			by &sortdesc &covariate;
   		run;

		%do I = 0 %to &nlevels;
			%let cv=%str(cv&I);
			data _metadas_tbmeta;
				set _metadas_tbmeta;
				if cvlevels = &I then &cv=1;
				else &cv=0;
			run;
		%end;
	%end;
	%else %if %upcase(&cvtype) = CON %then %do;
		/* For continuous covariate, treat as a categorical variable with 2 levels 
		for the purpose of producing statements */
		%let nlevels = 1;
		data _metadas_tbmeta;
			set _metadas_tbmeta;
			cv1 = &covariate;
		run;
	%end;

	/* For multiple/subgroup analyses using subsets of the data, 
	separate models are required so create separate data sets. 
	The BY statement of PROC NLMIXED could have been used instead 
	thereby eliminating the need to do this. However, doing 
	it this way means in future we can have separate starting values 
	and/or covariate for each analysis which would not otherwise be  
	possible. */
	%if &byvar ~=%str() %then %do;
		%put ----------------------------------------------;
		%put DATA STEP 3: Modify data for multiple analyses;
		%put ----------------------------------------------;

		/* A: 
		Create a duplicate of tbmeta as tbmeta_by */
		data tbmeta_by;
   			set _metadas_tbmeta;			
		run;

		/* B: 
		Get unique values of the by variable */
		proc sort data=tbmeta_by out= _metadas_&byvar nodupkey; 
			by &byvar;
		run;

		/* C: 
		The macro variable bylevels will contain the number of levels of 
		the by variable */
		data _metadas_&byvar;
   			set _metadas_&byvar end = maxn;			
			bylevels =_n_;
			if maxn then call symput('bylevels', put(bylevels, 3.)); 
		run;

		/* D: 
		Create a data set for each level of the by variable */
		proc sort data = tbmeta_by;
			by &byvar;
		run;

		proc sort data = _metadas_&byvar;
			by &byvar;
		run;

		data tbmeta_by;
   			merge tbmeta_by _metadas_&byvar;
   			by &byvar;
   		run;

		%do I = 1 %to &bylevels;
			data _metadas_ds&I;
				set tbmeta_by;
				where bylevels = &I;
			run;
		%end;
	%end;
	/* if no BY variable set bylevels as 1 so that only a set of 
	analyses is run. Also create a copy of the _metadas_tbmeta data set 
	as _metadas_ds1. Doing this just so that it fits in with the loop 
	for running the analyses */
	%else %if &byvar=%str() %then %do;
		%let bylevels = 1;
		data _metadas_ds1;
			set _metadas_tbmeta;
		run;
	%end;

	%if %sysfunc(exist(_metadas_tbmeta)) %then %do;
		proc datasets memtype=data nodetails nolist; 
			delete _metadas_tbmeta; 
		run;
	%end;

	%if %sysfunc(exist(tbmeta_by)) %then %do;
		proc datasets memtype=data nodetails nolist; 
			delete tbmeta_by; 
		run;
	%end;

	quit;

	/* if macro execution is not terminated prematurely due to an error of 
	some sort then set global variable metadas to 1, i.e., successful execution so far */
	%let metadas=1;
	
%mend;


/********************************************************
*														*
* 				PERFORM META-ANALYSIS: HSROC Model		*			
*														*
********************************************************/

%macro metah(tech=, subject=, cialpha=, byvar=, covariate=, hessout=,
			cvtype=, cveffect=, mtitle=, tbpe=, p1=, p2=, p3=, p4=, p5=, 
			cset1=, cset2=, cset3=, cset4=, cspa1=, cspa2=,	cspa3=, cspa4=, 
			cpb1=, cpb2=, cpb3=, cpb4=, randeffs=, predict=, checkmod=);

	/* set global variable metadas to 0 to begin with */
	%let metadas=0;

	%put %str(***************);
	%put %str(FIT HSROC MODEL);
	%put %str(***************);

	%if &byvar ~=%str() %then %do;
		%put %str(*************************************************);
		%put SEPARATE ANALYSES FOR EACH LEVEL OF %upcase(&byvar);
		%put %str(*************************************************);
	%end;

	/* create an indicator variable to be used later */
	%let modfailed = 0;

	/* if performing several analyses using the BY variable then repeat 
	the analysis for each level of the BY variable ,i.e., 
	produce as many models as levels of the variable otherwise run one
	set of analyses*/
	%do k=1 %to &bylevels;

		%if &bylevels > 1 %then %do;
			data _null_;
			   	set _metadas_&byvar;
				if bylevels=&k then call symput('byname', &byvar);
			run;
		%end;
		%else %if &bylevels =1 and &test ~= %str() %then %let byname = &test;
		%else %if &bylevels =1 and &test = %str() %then %let byname= test;

		/* if the empirical Bayes estimates of the random effects are required or model
		checking is yes, _metadas_a_randeffs will be created when Proc Nlmixed runs*/
		%if %upcase(&randeffs)=Y or %upcase(&checkmod) = Y %then %let outreffs= %str(out = _metadas_a_randeffs_&k);
		%else %let outreffs= ;
				 	
		%put %str(****************************************************************************************);
		%put %str(ANALYSIS: Fitting HSROC model with no covariate for %upcase(&byname));
		%put %str(****************************************************************************************);
		
		/* STARTING VALUES FOR NO COVARIATE MODEL */
		/*if user does not provide starting values for parameters
		 then use the following  */
		/* theta is the threshold parameter */
		/* alpha is the accuracy parameter */
		/* beta is the shape parameter */
		/* s2ut and s2ua are variances of threshold 
		and accuracy respectively*/

		%put ------------------------------------------------------;
		%put ANALYSIS STEP 1: Set up parameters and starting values;
		%put ------------------------------------------------------;

		/* for now only set this up once - will modify in next version 
		to allow multiple tables of starting values */
		%if &k = 1 %then %do;

			/* if we are not using a table of parameters */
			%if &tbpe=%str() %then %do;
				/* use these values as default to create a grid of values
				if user doesn't provide starting values for parameters */
				%if &p1=%str() %then %let p1= 0 to 4 by 1;
				%if &p2=%str() %then %let p2= -1 to 2 by 1; 
				%if &p3=%str() %then %let p3= 0 to 2 by 0.5; 
				%if &p4=%str() %then %let p4= 0 to 1 by 0.2; 
				%if &p5=%str() %then %let p5= 0 to 1 by 0.2;		
				
				/*PARAMETERS FOR THE MODEL */
				/*Build list of parameters and their starting values */
				%let pms = %str(alpha=&p1 theta=&p2 beta=&p3 s2ua=&p4 s2ut=&p5);
			%end;
			%else %let pms= %str( / data=&tbpe);
		%end;

		
		/*RUN PROC NLMIXED: MODEL WITH NO COVARIATE */
		/*HSROC model without covariate*/
		%put ---------------------------------------------------------------------;
		%put %str(ANALYSIS STEP 2: Run PROC NLMIXED for _metadas_ds&k);
		%put ---------------------------------------------------------------------;

		proc sort data=_metadas_ds&k;
			by &subject &covariate dis;
		run;

		%hsrocnocv(data=_metadas_ds&k, tech=&tech, cialpha=&cialpha, subject=&subject, 
					outreffs=&outreffs, pms=&pms, byname=&byname, 
					modelnum=&k, predict=&predict, hessout=&hessout);
		run;

		/* if above model doesn't converge or the final Hessian matrix is not positive definite, then
		additional estimates will not be produced so try fitting model without random effects 
		to obtain new starting values and then repeat analysis */
		%if %sysfunc(exist(_metadas_a_addest_&k)) %then 
			%put %str(HSROC modelling without covariate successfully completed for &byname);
		%else %do;
			%put %str(-----------------------------------------------------------------------------------);
			%put %str(ANALYSIS INFORMATION: HSROC analysis for &byname failed.);
			%put %str(Running Proc NLMIXED for _metadas_ds&k without random effects);
			%put %str(to obtain new starting values for alpha, theta and beta.);
			%put %str(-----------------------------------------------------------------------------------);

			ods output ParameterEstimates=_temp_nore_pe
				AdditionalEstimates=_temp_nore_addest
				ConvergenceStatus=_temp_nore_convgstat;
		
			proc nlmixed data=_metadas_ds&k cov ecov df=1000 start alpha=&cialpha &tech;
				title "HSROC analysis without covariate and random effects";
				parms alpha=&p1 theta=&p2 beta=&p3;/*initial values for analysis*/
				logitp= (theta + (alpha) * dis) * exp(-(beta)*dis);
				p = exp(logitp)/(1+exp(logitp));
				model pos ~ binomial(n,p);						
				/* estimates of average operating point */
				/* To some extent the order of the estimate statements is important in 
				extracting data for output so if you change it check 
				that the tables are still ok - any changes necessary should 
				be done to hsrocout */
				estimate 'sensitivity' exp(exp(-beta/2) * (theta + 0.5 * alpha))/(1+exp(exp(-beta/2) * (theta + 0.5 * alpha)));
				estimate 'specificity' exp(-exp(beta/2) * (theta - 0.5 * alpha))/(1+exp(-exp(beta/2) * (theta - 0.5 * alpha)));
				estimate 'logDOR' log(((exp(exp(-beta/2) * (theta + 0.5 * alpha))/(1+exp(exp(-beta/2) * (theta + 0.5 * alpha))))
						/(1-(exp(exp(-beta/2) * (theta + 0.5 * alpha))/(1+exp(exp(-beta/2) * (theta + 0.5 * alpha))))))
				/((1-(exp(-exp(beta/2) * (theta - 0.5 * alpha))/(1+exp(-exp(beta/2) * (theta - 0.5 * alpha)))))
				/(exp(-exp(beta/2) * (theta - 0.5 * alpha))/(1+exp(-exp(beta/2) * (theta - 0.5 * alpha))))));
				estimate 'logLR+' log((exp(exp(-beta/2) * (theta + 0.5 * alpha))/(1+exp(exp(-beta/2) * (theta + 0.5 * alpha))))
					/(1-(exp(-exp(beta/2) * (theta - 0.5 * alpha))/(1+exp(-exp(beta/2) * (theta - 0.5 * alpha))))));
				estimate 'logLR-' log((1-(exp(exp(-beta/2) * (theta + 0.5 * alpha))/(1+exp(exp(-beta/2) * (theta + 0.5 * alpha)))))
					/(exp(-exp(beta/2) * (theta - 0.5 * alpha))/(1+exp(-exp(beta/2) * (theta - 0.5 * alpha))))) ;
				
			run;
			quit;

			/* successful convergence and production of additional estimates then 
			refit model using these as starting values instead*/
			%if %sysfunc(exist(_temp_nore_addest)) %then %do;
				%createhpars(tbpe=_temp_nore_pe, reffs=n);
				run;

				/* delete the temporary data sets */
				proc datasets memtype=data nodetails nolist; 
					delete _temp_nore_:; 
				run;
				quit;

				%hsrocnocv(data=_metadas_ds&k, tech=&tech, cialpha=&cialpha, subject=&subject, 
						outreffs=&outreffs, pms=&pms, byname=&byname, modelnum=&k,
						predict=&predict, hessout=&hessout);
				run;
				%if %sysfunc(exist(_metadas_a_addest_&k)) %then %do;
					%put %str(HSROC modelling without covariate successfully completed for &byname);
					%let modfailed=0;
				%end;
				%else %do;
					%put %str(MODEL FAILURE: HSROC modelling without covariate was not successfully completed for &byname);
					%let modfailed =1;
				%end;
			%end;
			/*if model without random effects failed and we are only running a set of 
			analyses then terminate the macro otherwise carry on with other levels of the
			BY variable */
			%else %if &byar = %str() %then %do;
				%put %str(----------------------------------------------------------------------------------------------------------------);
				%put %str(ANALYSIS INFORMATION: metadas terminated.);
				%put %str(Model without random effects failed to produce suitable starting values for analysis of &byname);
				%put %str(----------------------------------------------------------------------------------------------------------------);
				%let metadas=0;
				%return;
			%end;
		%end;

		/****************************************************
		*													*
		* Fit model with covariate if covariate is given &	*
		* the no covariate model converged and produced		*
		* additional estimates								*
		*													*
		****************************************************/
		
		%if &covariate~=%str() and %sysfunc(exist(_metadas_a_pe_&k)) and %sysfunc(exist(_metadas_a_addest_&k)) %then %do;		
			
			%let numobs=0;
			%let nstudies=0;
			
			/* check that we have data for the reference level of the covariate otherwise
			skip the analysis */
			%if %upcase(&cvtype)~= CON %then %do;	
				data _tmp_;
		   			set _metadas_ds&k;
					where cvlevels=0;	
				run;
				data _null_;
					set _tmp_ nobs=numobs;
					call symput('numobs',numobs);
				run;			
				%let nstudies = %eval(&numobs/2); /* get number of studies for the covariate level */
			%end;

			%if &nstudies = 0 and %upcase(&cvtype) ~= CON %then %do;
				%put %str(-------------------------------------------------------------------------------------------);
				%put %str(ANALYSIS INFORMATION: Unable to perform HSROC analysis with covariate.);
				%put %str(There are no observations for the reference level of %upcase(&covariate) for this data set.);
				%put %str(-------------------------------------------------------------------------------------------);
				%goto endcvanalysis;
				run;
			%end;
			
			/* if the empirical Bayes estimates of the random effects are required or model
			checking is yes, _metadas_cv_randeffs will be created when proc nlmixed runs*/
			%if %upcase(&randeffs)=Y or %upcase(&checkmod) = Y %then %let outreffs= %str(out = _metadas_cv_randeffs_&k);
			%else %let outreffs= ;
						
			/* PARAMETERS AND ESTIMATE STATEMENTS FOR MODEL WITH COVARIATE*/

			%put %str(*********************************************************************);
			%put ANALYSIS: Fitting HSROC model with %upcase(&covariate) as a covariate;
			%put %str(*********************************************************************);

			%put ---------------------------------------------------------------------------;
			%put ANALYSIS STEP 1: Set up parameters, starting values and estimate statements;
			%put ---------------------------------------------------------------------------;
			
			/* just need to do this once but in future will do k times if different pe tables 
			are given for each analysis of the BY variable */
			%if &k=1 or &modfailed=1 %then %do;
				/*Build additional parameters and estimate statements */
				%cvparshsroc(covariate=&covariate, cvtype=&cvtype, cveffect=&cveffect, 
						cset1=&cset1, cset2=&cset2, cset3=&cset3, cset4=&cset4, 
						cspa1=&cspa1, cspa2=&cspa2, cspa3=&cspa3, cspa4=&cspa4,
						cpb1=&cpb1, cpb2=&cpb2, cpb3=&cpb3, cpb4=&cpb4);
				run;
			%end;

			/* create starting values for the parameeters alpha, beta, theta, 
			s2ua and s2ut from the parameter estimates table */
			%createhpars(tbpe=_metadas_a_pe_&k, reffs=y);
			run;

			ods output StartingValues=_metadas_cv_sv_&k
				Parameters=_metadas_cv_parms_&k
				ParameterEstimates=_metadas_cv_pe_&k
				FitStatistics=_metadas_cv_fit_&k
				AdditionalEstimates=_metadas_cv_addest_&k
				CovMatAddEst=_metadas_cv_covaddest_&k
				ConvergenceStatus=_metadas_cv_convgstat_&k
				Contrasts=_metadas_cv_contrasts_&k;

			%if &hessout ~=%str() %then %do;
				ods output Hessian=_metadas_cv_hessian_&k;
			%end;

			/* RUN PROC NLMIXED: MODEL WITH A COVARIATE */

			%put ------------------------------------------------------------------------------;
			%put %str(ANALYSIS STEP 2: Run Proc NLMIXED for _metadas_ds&k with covariate %upcase(&covariate));
			%put ------------------------------------------------------------------------------;

			%if %upcase(&predict) = Y %then %let predictlogit= %str(predict logitp out=_metadas_cv_logitp_&k);
			%else %let predictlogit= ;

			%if &bylevels > 1 %then %let
				proctitle = %str("HSROC analysis &k with covariate %upcase(&covariate)");
			%else %let proctitle = %str("HSROC analysis with covariate %upcase(&covariate)");

			proc nlmixed data=_metadas_ds&k cov ecov df=1000 start alpha=&cialpha &hessout &tech;
				title &proctitle;
				/* theta is the threshold parameter,alpha is the accuracy parameter*/
				/* theta_cv&I is the change in threshold for covariate level=I */
				/* alpha_cv&I is the change in accuracy for covariate level=I */
				/* beta is the shape parameter*/
				/* beta_cv&I is the change in accuracy for covariate level=I */
				/* s2ut and s2ua are variances of threshold and accuracy */
				/* subject is usually study ID*/
				parms &pms &cvparamlist; /*reset initial value for new analysis*/
				bounds s2ua >= 0; /* set boundary constraint so variance is not negative*/
				bounds s2ut >= 0;
				logitp= &logitp;
				p = exp(logitp)/(1+exp(logitp));
				model pos ~ binomial(n,p);
				random ut ua ~ normal([0,0],[s2ut,0,s2ua]) subject=&subject &outreffs;

				&predictlogit;

				/*convert to bivariate parameterisation */
				/* E(logitSe) is the mean logit sensitivity */
				/* E(logitSp) is the mean logit specificity */
				/* mu_Acv&I is the sensitivity log odds ratio for covariate level=1 */
				/* mu_Bcv&I is the specificity log odds ratio for covariate level=1 */
				/* Var(logitSe), Var(logitSp) are the variances of logit sensitivity and specifcity */
				/* Cov(logits) is the covariance of logit sensitivity and specificity */
				/* To some extent the order of the estimate statements is important in 
				extracting data for output so if you change it check 
				that the tables are still ok - any changes necessary should 
				be done to hsrocout */
				estimate 'E(logitSe)'   	exp(-beta/2) * (theta + 0.5 * alpha);
				estimate 'E(logitSp)'		-exp(beta/2) * (theta - 0.5 * alpha);
				estimate 'Var(logitSe)'		exp(-beta) * (s2ut + 0.25 * s2ua);/*variance of logit(sens) for covariate level=0*/
				estimate 'Var(logitSp)'		exp(beta) * (s2ut + 0.25 * s2ua);/*variance of logit(spec) for covariate level=0*/
				estimate 'Cov(logits)'	- (s2ut - 0.25 * s2ua); 
				estimate 'Corr(logits)'(- (s2ut - 0.25 * s2ua))/(sqrt(exp(-beta) * (s2ut + 0.25 * s2ua))*sqrt(exp(beta) * (s2ut + 0.25 * s2ua)));

				&estmuAcv; /* logit(sens) change for covariate levels*/
				&estmuBcv; /* logit(spec) change for covariate levels*/
				
				/* estimates of average operating points */
				&estMuAlevels; /* elogit(sens) for each level of the covariate */ 
				&estMuBlevels; /* elogit(spec) for each level of the covariate */
				/* &estsenscv;  sensitivity for each level of the covariate 
				&estspeccv; specificity for each level of the covariate */
				&estDOR; /* diagnostic odds ratio for each level of the covariate */ 
				&estRelSens; /* relative sensitivity for each level of the covariate */ 
				&estRelSpec; /* relative specificity for each level of the covariate */ 
				&estRDOR; /* relative diagnostic odds ratio for each level of the covariate */ 
				&estLRpos; /* positive likelihood ratio for each level of the covariate */ 
				&estLRneg; /* negative likelihood ratio for each level of the covariate */ 
				&estAlpha; /* alpha for each level of the covariate except the reference category*/ 
				&estTheta; /* theta for each level of the covariate except the reference category*/
				&estBeta; /* beta for each level of the covariate except the reference category*/ 
				&contrasta;
				&contrastt;
				&contrastb;
			run;
			quit;

			%endcvanalysis:;

		%end;

	%end;

	/* create data sets in the format required from results of the analysis */
	%hsrocout(covariate=&covariate, cvtype=&cvtype, cveffect=&cveffect, 
			cvsummorder=&cvsummorder, byvar=&byvar);
	run;

	/* if macro execution is not terminated prematurely due to an error of 
	some sort then set global variable metadas to 1, i.e., successful execution so far */
	%let metadas=1;
	
%mend;


/********************************************************************
*																	*
* 		CREATE PARAMETER AND ESTIMATE STATEMENTS 					*
*		FOR A COVARIATE	FOR THE HSROC MODEL							*
*																	*
********************************************************************/

%macro cvparshsroc(covariate=, cvtype=, cveffect=,
				cset1=, cset2=, cset3=, cset4=, 
				cspa1=, cspa2=, cspa3=, cspa4=, 
				cpb1=, cpb2=, cpb3=, cpb4=);

	/* set global variable metadas to 0 to begin with */
	%let metadas=0;

	/* A:
	INITIALISE MACRO  VARIABLES */
	/* initialise these macro variables as null or with the appropriate 
	estimate statement for the reference category if categorical covariate
	otherwise if continuous nlevels= 1 */

	%let calist0 = ;
	%let ctlist0 = ;
	%let cblist0 = ;
	%let plist0 = ;
	%let acv0 = ;
	%let tcv0 = ;
	%let bcv0= ;
	%let estmuA0= ;
	%let estmuB0= ;
	/*%let estsens0= estimate 'sensitivity cv level 0' exp(exp(-beta/2) * (theta + 0.5 * alpha))/(1+exp(exp(-beta/2) * (theta + 0.5 * alpha)))%str(;);
	%let estspec0= estimate 'specificity cv level 0' exp(-exp(beta/2) * (theta - 0.5 * alpha))/(1+exp(-exp(beta/2) * (theta - 0.5 * alpha)))%str(;); */
	%let lnSens0= log(exp(exp(-beta/2) * (theta + 0.5 * alpha))/(1+exp(exp(-beta/2) * (theta + 0.5 * alpha))))%str(;);
	%let lnSpec0= log(exp(-exp(beta/2) * (theta - 0.5 * alpha))/(1+exp(-exp(beta/2) * (theta - 0.5 * alpha))))%str(;);
	%let lnDOR0= log(((exp(exp(-beta/2) * (theta + 0.5 * alpha))/(1+exp(exp(-beta/2) * (theta + 0.5 * alpha))))
						/(1-(exp(exp(-beta/2) * (theta + 0.5 * alpha))/(1+exp(exp(-beta/2) * (theta + 0.5 * alpha))))))
						/((1-(exp(-exp(beta/2) * (theta - 0.5 * alpha))/(1+exp(-exp(beta/2) * (theta - 0.5 * alpha)))))
						/(exp(-exp(beta/2) * (theta - 0.5 * alpha))/(1+exp(-exp(beta/2) * (theta - 0.5 * alpha))))))%str(;);
	%let estDOR0 = estimate 'logDOR_0' &lnDOR0;
	%let estLRp0= estimate 'logLR+_0' log((exp(exp(-beta/2) * (theta + 0.5 * alpha))/(1+exp(exp(-beta/2) * (theta + 0.5 * alpha))))
						/(1-(exp(-exp(beta/2) * (theta - 0.5 * alpha))/(1+exp(-exp(beta/2) * (theta - 0.5 * alpha))))))%str(;);
	%let estLRn0= estimate 'logLR-_0' log((1-(exp(exp(-beta/2) * (theta + 0.5 * alpha))/(1+exp(exp(-beta/2) * (theta + 0.5 * alpha)))))
						/(exp(-exp(beta/2) * (theta - 0.5 * alpha))/(1+exp(-exp(beta/2) * (theta - 0.5 * alpha)))))%str(;);
	%let estAlphaCvL0= ;
	%let estThetaCvL0= ;
	%let estBetaCvL0= ;
	%let estMuACvL0= ;
	%let estMuBCvL0= ;
	%let estRDOR0 = ;
	%let estRelSens0 = ;
	%let estRelSpec0 = ;

	
	/* B:
	CREATE PARAMETERS AND ESTIMATE STATEMENTS AND REGRESSION EQUATION*/
	/* For each level of the covariate (except the reference level) create parameters for 
	theta and/or alpha */
	%do I = 1 %to &nlevels;
		%let j = %eval(&I - 1);
	
		/* alpha */
		%let alpha=%str(alpha_cv&I);
		%if %superq(cspa&I) = %str() %then %let pa=&alpha=0; /* simply use zero as starting value for
																the additional parameter if none is given */
		%else %let pa=&alpha=%superq(cspa&I);
	
		/* theta */
		%let theta=%str(theta_cv&I);
		%if %superq(cset&I)=%str() %then %let pt=&theta=0; /* simply use zero as starting value for
																the additional parameter if none is given */
		%else %let pt=&theta=%superq(cset&I) ;
	
		/* beta */
		%let beta=%str(beta_cv&I);
		%if %superq(cpb&I)=%str() %then %let pb=&beta=0; /* simply use zero as starting value for
																the additional parameter if none is given */
		%else %let pb=&beta=%superq(cpb&I) ;

		/*create string of parameters with their starting values 
		also create lists for contrasts statements*/ 
		%if %upcase(&cveffect)=ABT or &cveffect=%str() %then %do; /*effect on the 3 parameters */
			%let plist= &pa &pt &pb;
			%let ca = &alpha;
			%let ct = &theta;
			%let cb = &beta;
		%end;
		%else %if %upcase(&cveffect)=AB %then %do; /* covariate effect on alpha & beta */
			%let plist=&pa &pb;
			%let theta=0; 
			%let ca = &alpha;
			%let cb = &beta;
			%let ct= ;
		%end;
		%else %if %upcase(&cveffect)=AT %then %do; /* covariate effect on alpha & theta */
			%let plist=&pa &pt;
			%let beta=0; 
			%let ca = &alpha;
			%let ct = &theta;
			%let cb= ;
		%end;
		%else %if %upcase(&cveffect)=BT %then %do; /* covariate effect on beta & theta*/
			%let plist=&pb &pt;
			%let alpha=0; 
			%let cb = &beta;
			%let ct = &theta;
			%let ca = ;
		%end;
		%else %if %upcase(&cveffect)=A %then %do; /* covariate effect on alpha only */
			%let plist=&pa;
			%let theta=0; 
			%let beta = 0;
			%let ca = &alpha;
			%let cb= ;
			%let ct= ;
		%end;
		%else %if %upcase(&cveffect)=T %then %do; /* covariate effect on theta only */
			%let plist=&pt;
			%let alpha=0; 
			%let beta=0;			
			%let ct = &theta;
			%let ca= ;
			%let cb= ;
		%end;
		%else %if %upcase(&cveffect)=B %then %do; /* covariate effect on theta only */
			%let plist=&pb;
			%let alpha=0; 
			%let theta=0;			
			%let cb = &beta;
			%let ca= ;
			%let ct= ;
		%end;

		%let %str(plist&I)= %superq(plist&j) &plist; /* build string of parameters and their 
													 starting values */

	
		%if &I ~= &nlevels %then %do;
			%let %str(calist&I)= %superq(calist&j) alpha+&ca,; /* for use with contrast statement build string 
													of parameters without their starting values */
			%let %str(ctlist&I)= %superq(ctlist&j) theta+&ct,;
			%let %str(cblist&I)= %superq(cblist&j) beta+&cb,;
		%end;
		%else %do;
			%let %str(calist&I)= %superq(calist&j) alpha+&ca;
			%let %str(ctlist&I)= %superq(ctlist&j) theta+&ct;
			%let %str(cblist&I)= %superq(cblist&j) beta+&cb;
		%end;
		
		/* Now to create estimate statements for the additional parameters */
		%if %upcase(&cvtype)=CON %then %do;
			/*%let lname3 = %str(sensitivity for a unit change in cv1);
			%let lname4 = %str(specificity for a unit change in cv1);*/
			%let trueposORTitle = %str(True positive log odds ratio  1);
			%let truenegORTitle = %str(True negative log odds ratio  1);
			%let RDORTitle = %str(logRDOR 1);
			%let RSensTitle = %str(logRelative sensitivity 1);
			%let RSpecTitle = %str(logRelative specificity 1);		
		%end;
		%else %do;
			/*%let lname3 = %str(sensitivity cv level &I);
			%let lname4 = %str(specificity cv level &I); */
			%let trueposORTitle = %str(True positive log odds ratio  cv level &I vs 0);
			%let truenegORTitle = %str(True negative log odds ratio  cv level &I vs 0);
			%let RDORTitle = %str(logRDOR cv level &I vs 0);
			%let RSensTitle = %str(logRelative sensitivity cv level &I vs 0);
			%let RSpecTitle = %str(logRelative specificity cv level &I vs 0);
		%end;
		%let compa = %str(Pooled test for alpha);
		%let compt = %str(Pooled test for theta);
		%let compb = %str(Pooled test for beta);
		%let DORTitle = %str(logDOR_&I);
		%let LRposTitle = %str(logLR+_&I);
		%let LRnegTitle = %str(logLR-_&I);
		%let alphaTitle = %str(alpha_&I);
		%let thetaTitle = %str(theta_&I);	
		%let betatitle = %str(beta_&I);
		%let ElogitSeTitle = %str(E(logitSe)_&I);
		%let ElogitSpTitle = %str(E(logitSp)_&I);

		%let estA = estimate "&trueposORTitle" exp(-(beta+&beta)*0.5) * (theta + &theta + 0.5 * (alpha + &alpha))-(exp(-beta*0.5) * (theta + 0.5 * alpha));

		%let estB = estimate "&truenegORTitle" -exp((beta+&beta)*0.5) * (theta + &theta - 0.5 * (alpha + &alpha))+ (exp(beta*0.5) * (theta - 0.5 * alpha));

		/* estimates of average operating points and relative measures */
		/* The statements preceded by log could be simplified but leaving them so that it is 
		obvious to anyone inspecting or modifying the macro what the function is and that the 
		estimates have been obtained on the log scale */

		/*%let ests1 = estimate "&lname3" exp(exp(-(beta+&beta)*0.5) * (theta + &theta + 0.5 * (alpha + &alpha)))/(1+exp(exp(-(beta+&beta)*0.5) * (theta + &theta + 0.5 * (alpha + &alpha))));

		%let ests2 = estimate "&lname4" exp(-exp((beta+&beta)*0.5) * (theta + &theta - 0.5 * (alpha + &alpha)))/(1+exp(-exp((beta+&beta)*0.5) * (theta + &theta - 0.5 * (alpha + &alpha))));*/

		%let estlnD = log(((exp(exp(-(beta+&beta)*0.5) * (theta + &theta + 0.5 * (alpha + &alpha)))/(1+exp(exp(-(beta+&beta)*0.5) * (theta + &theta + 0.5 * (alpha + &alpha)))))
						/(1-(exp(exp(-(beta+&beta)*0.5) * (theta + &theta + 0.5 * (alpha + &alpha)))/(1+exp(exp(-(beta+&beta)*0.5) * (theta + &theta + 0.5 * (alpha + &alpha)))))))
						/((1-(exp(-exp((beta+&beta)*0.5) * (theta + &theta - 0.5 * (alpha + &alpha)))/(1+exp(-exp((beta+&beta)*0.5) * (theta + &theta - 0.5 * (alpha + &alpha))))))
						/(exp(-exp((beta+&beta)*0.5) * (theta + &theta - 0.5 * (alpha + &alpha)))/(1+exp(-exp((beta+&beta)*0.5) * (theta + &theta - 0.5 * (alpha + &alpha)))))));

		%let estD = estimate "&DORTitle" &estlnD;

		%let estRD = estimate "&RDORTitle" &estlnD - &lnDOR0;

		%let estLnSens = log(exp(exp(-(beta+&beta)/2) * (theta + &theta + 0.5 * (alpha+&alpha)))/(1+exp(exp(-(beta+&beta)/2) * (theta + &theta + 0.5 * (alpha+&alpha)))));

		%let estRSens = estimate "&RSensTitle" &estLnSens - &lnSens0;

		%let estLnSpec = log(exp(-exp((beta+&beta)/2) * (theta + &theta - 0.5 * (alpha +&alpha)))/(1+exp(-exp((beta+&beta)/2) * (theta + &theta - 0.5 * (alpha+&alpha)))));

		%let estRSpec = estimate "&RSpecTitle" &estLnSpec - &lnSpec0;

		%let estLp = estimate "&LRposTitle" log((exp(exp(-(beta+&beta)*0.5) * (theta + &theta + 0.5 * (alpha + &alpha)))/(1+exp(exp(-(beta+&beta)*0.5) * (theta + &theta + 0.5 * (alpha + &alpha)))))
						/(1-(exp(-exp((beta+&beta)*0.5) * (theta + &theta - 0.5 * (alpha + &alpha)))/(1+exp(-exp((beta+&beta)*0.5) * (theta + &theta - 0.5 * (alpha + &alpha)))))));

		%let estLn = estimate "&LRnegTitle" log((1-(exp(exp(-(beta+&beta)*0.5) * (theta + &theta + 0.5 * (alpha + &alpha)))/(1+exp(exp(-(beta+&beta)*0.5) * (theta + &theta + 0.5 * (alpha + &alpha))))))
						/(exp(-exp((beta+&beta)*0.5) * (theta + &theta - 0.5 * (alpha + &alpha)))/(1+exp(-exp(beta/2) * (theta + &theta - 0.5 * (alpha + &alpha))))));

		%let estAlphaL = estimate "&alphaTitle" alpha+&alpha; /* compute alpha for a covariate level other than the reference */
		
		%let estThetaL = estimate "&thetaTitle" theta+&theta; /* compute theta for a covariate level other than the reference */
		
		%let estBetaL = estimate "&betatitle" beta+&beta; /* compute beta for a covariate level other than the reference */
		
		%let estMuAL = estimate "&ElogitSeTitle" exp(-(beta+&beta)*0.5) * (theta + 0.5 * alpha)+exp(-(beta+&beta)*0.5) * (theta + &theta + 0.5 * (alpha + &alpha))
							- (exp(-(beta+&beta)*0.5) * (theta + 0.5 * alpha)); /* change in Elogit(sens) for a covariate level compared to the reference */

		%let estMuBL = estimate "&ElogitSpTitle" -exp((beta+&beta)*0.5) * (theta - 0.5 * alpha)+-exp((beta+&beta)*0.5) * (theta + &theta - 0.5 * (alpha + &alpha))
							+ (exp((beta+&beta)*0.5) * (theta - 0.5 * alpha)); /* change in Elogit(spec) for a covariate level compared to the reference */
		
		
		/* Now need to build expressions used in the regression equation and estimate statements*/
		%if %eval(&I < &nlevels) %then %do; 
			%let tcv= (&theta * %str(cv&I)) +; /* for expression involving theta */
			%let acv= (&alpha * %str(cv&I)) +; /* for expression involving alpha */
			%let bcv= (&beta * %str(cv&I)) +; /* for expression involving beta */
			%let estmuA = %str(&estA) %str(;);
			%let estmuB = %str(&estB) %str(;);	
			/* %let estsens = %str(&ests1) %str(;);
			%let estspec = %str(&ests2) %str(;); */
			%let estDOR = %str(&estD) %str(;);
			%let estRDOR = %str(&estRD) %str(;);
			%let estRelSens = &estRSens %str(;);			
			%let estRelSpec = &estRSpec %str(;);
			%let estLRp = %str(&estLp) %str(;);
			%let estLRn = %str(&estLn) %str(;);
			%let estAlphaCvL = %str(&estAlphaL) %str(;);
			%let estThetaCvL = %str(&estThetaL) %str(;);
			%let estBetaCvL = %str(&estBetaL) %str(;);
			%let estMuACvL = %str(&estMuAL) %str(;);
			%let estMuBCvL = %str(&estMuBL) %str(;);
		%end;
		%else %do;
			%let tcv=(&theta * %str(cv&I));			
			%let acv=(&alpha * %str(cv&I));
			%let bcv=(&beta * %str(cv&I));
			%let estmuA = &estA;
			%let estmuB = &estB;
			/* %let estsens = &ests1;
			%let estspec = &ests2; */
			%let estDOR = &estD;
			%let estRDOR = &estRD;
			%let estRelSens = &estRSens;			
			%let estRelSpec = &estRSpec;
			%let estLRp = &estLp;
			%let estLRn = &estLn;
			%let estAlphaCvL = &estAlphaL;
			%let estThetaCvL = &estThetaL;
			%let estBetaCvL = &estBetaL;
			%let estMuACvL = &estMuAL;
			%let estMuBCvL = &estMuBL;
		%end;

		%let %str(tcv&I) = &&tcv&j &tcv; /* concatenate expressions */
		%let %str(acv&I) = &&acv&j &acv;
		%let %str(bcv&I) = &&bcv&j &bcv;	
		%let %str(estmuA&I) = &&estmuA&j  &estmuA;
		%let %str(estmuB&I) = &&estmuB&j  &estmuB;
		/* %let %str(estsens&I) = &&estsens&j  &estsens;
		%let %str(estspec&I) = &&estspec&j  &estspec; */
		%let %str(estDOR&I)= &&estDOR&j  &estDOR;
		%let %str(estRDOR&I)= &&estRDOR&j  &estRDOR;
		%let %str(estRelSens&I)= &&estRelSens&j  &estRelSens;
		%let %str(estRelSpec&I)= &&estRelSpec&j  &estRelSpec;
		%let %str(estLRp&I)= &&estLRp&j  &estLRp;
		%let %str(estLRn&I) = &&estLRn&j  &estLRn;
		%let %str(estAlphaCvL&I)= &&estAlphaCvL&j  &estAlphaCvL;
		%let %str(estThetaCvL&I)= &&estThetaCvL&j  &estThetaCvL;
		%let %str(estBetaCvL&I)= &&estBetaCvL&j  &estBetaCvL;
		%let %str(estMuACvL&I)= &&estMuACvL&j  &estMuACvL;
		%let %str(estMuBCvL&I)= &&estMuBCvL&j  &estMuBCvL;
		run;
	%end;

	/* Put parameter list together and the equation and contrast statements*/
	%let j = %eval(&I - 1);
	%let cvparamlist = %superq(plist&j);

	%if %upcase(&cveffect)=ABT or &cveffect=%str() %then %do;
		%let logitp = (theta + ut + (%superq(tcv&j)) +(alpha + ua + %superq(acv&j)) * dis) * exp(-(beta+(%superq(bcv&j)))*dis);
		%let contrasta = contrast "&compa" alpha, %superq(calist&j);
		%let contrastt = contrast "&compt" theta, %superq(ctlist&j);
		%let contrastb = contrast "&compb" beta, %superq(cblist&j);	
	%end;
	%else %if %upcase(&cveffect)=AB %then %do;
		%let logitp = (theta + ut +(alpha + ua + %superq(acv&j)) * dis) * exp(-(beta+(%superq(bcv&j)))*dis);
		%let contrasta = contrast "&compa" alpha, %superq(calist&j);
		%let contrastb = contrast "&compb" beta, %superq(cblist&j);
		%let contrastt= ;
	%end;
	%else %if %upcase(&cveffect)=AT %then %do;
		%let logitp = (theta + ut + (%superq(tcv&j)) +(alpha + ua + %superq(acv&j)) * dis) * exp(-(beta)*dis);
		%let contrasta = contrast "&compa" alpha, %superq(calist&j);
		%let contrastt = contrast "&compt" theta, %superq(ctlist&j);
		%let contrastb= ;
	%end;
	%else %if %upcase(&cveffect)=BT %then %do;
		%let logitp = (theta + ut + (%superq(tcv&j)) +(alpha + ua) * dis) * exp(-(beta+(%superq(bcv&j)))*dis);
		%let contrastb = contrast "&compb" beta, %superq(cblist&j);
		%let contrastt = contrast "&compt" theta, %superq(ctlist&j);
		%let contrasta= ;	
	%end;
	%else %if %upcase(&cveffect)=A %then %do;
		%let logitp = (theta + ut +(alpha + ua + %superq(acv&j)) * dis) * exp(-(beta)*dis);
		%let contrasta = contrast "&compa" alpha, %superq(calist&j);
		%let contrastb= ;
		%let contrastt= ;
	%end;
	%else %if %upcase(&cveffect)=T %then %do;
		%let logitp = (theta + ut +(%superq(tcv&j)) +(alpha + ua) * dis) * exp(-(beta)*dis);
		%let contrastt = contrast "&compt" theta, %superq(ctlist&j);
		%let contrasta= ;
		%let contrastb= ;	
	%end;
	%else %if %upcase(&cveffect)=B %then %do;
		%let logitp = (theta + ut +(alpha + ua) * dis) * exp(-(beta+(%superq(bcv&j)))*dis);
		%let contrastb = contrast "&compb" beta, %superq(cblist&j);
		%let contrasta = ;
		%let contrastt= ;
	%end;

	/* no contrast statements if covariate is continuous  */
	/*%if %upcase(&cvtype)= CON %then %do;		
		%let contrasta= ;
		%let contrastb= ;
		%let contrastt= ;
	%end;*/

	%let estmuAcv = &&estmuA&j;
	%let estmuBcv = &&estmuB&j;	
	/* %let estsenscv = &&estsens&j;
	%let estspeccv = &&estspec&j; */
	%let estDOR = &&estDOR&j;
	%let estRDOR = &&estRDOR&j;
	%let estRelSens = &&estRelSens&j;
	%let estRelSpec = &&estRelSpec&j;
	%let estLRpos = &&estLRp&j;
	%let estLRneg = &&estLRn&j;
	%let estAlpha = &&estAlphaCvL&j;
	%let estTheta = &&estThetaCvL&j;
	%let estBeta = &&estBetaCvL&j;
	%let estMuAlevels= &&estMuACvL&j;
	%let estMuBlevels= &&estMuBCvL&j;
	
	run;

	/* if macro execution is not terminated prematurely due to an error of 
	some sort then set global variable metadas to 1, i.e., successful execution so far */
	%let metadas=1;

%mend;


/********************************************************************
*																	*
* 		CREATE DATA SETS FOR OUTPUT OF HSROC MODEL RESULTS			*							
*																	*
********************************************************************/

%macro hsrocout(covariate=, cvtype=, cveffect=, cvsummorder=, byvar=);

	/* set global variable metadas to 0 to begin with */
	%let metadas=0;

	%put %str(************************);
	%put %str(CREATE TABLES OF RESULTS);
	%put %str(************************); 

	/* create blank data set for storing SeElogitSe, SeElogitSp, CovEs and 
	number of studies */
	%createds();
	run;

	%do k=1 %to &bylevels;

		/* if there is a BY variable get the name of the current test or by category. 
		If no BY variable but test is specified then use the name of the test */ 
		%if &byvar ~= %str() %then %do;
			data _null_;
			   	set _metadas_&byvar;
				if bylevels=&k then call symput('bylevelname', &byvar);
			run;
		%end;
		%else %if &byvar=%str() and &test ~= %str() %then %do;
			%let bylevelname=&test;
		%end;
		%else %if &byvar=%str() and &test = %str() %then %do;
			%let bylevelname=%str(test);
		%end;

		%if %sysfunc(exist(_metadas_ds&k)) %then %do;
			data _null_;
				set _metadas_ds&k nobs=numobs;
				call symput('numobs',numobs);
			run;
			%let nstudies = %eval(&numobs/2);
		%end;

		/* Give each estimate in the additional estimates table 
		a unique identifier if the table exists*/
		%if %sysfunc(exist(_metadas_a_addest_&k)) and %sysfunc(exist(_tb_se)) %then %do;

			/* get exponents of logDOR, logLR- and logLR+.
			Append to additional estimates table (_a_addest_&k) */
			data _metadas_a_addest_temp (drop=Label);
				set _metadas_a_addest_&k;
				substr(label,1,3)='';
				newlabel=left(trim(label));
				expestimate=exp(estimate);
				explower=exp(lower);
				expupper=exp(upper);
				where label contains 'logL' or label contains 'logD';
				rename Estimate = LogEstimate
						lower = LogLower
						upper = LogUpper;
				StandardError=.;
				tValue=.;
				Probt=.;
				output;
			run;

			data _metadas_a_addest_temp (drop=LogEstimate LogLower LogUpper);
				set _metadas_a_addest_temp;
				rename newlabel=Label
						expestimate = Estimate
						explower = Lower
						expupper = Upper;
			run;

			/* get the inverse transformation of logit sensitivity and specificity */
			data _metadas_a_addest_sesp (drop=Label);
				set _metadas_a_addest_&k;
				invlogitestimate=exp(estimate)/(1 + exp(estimate));
				invlogitlower=exp(lower)/(1 + exp(lower));
				invlogitupper=exp(upper)/(1 + exp(upper));
				where label contains 'E(logitS';
				rename Estimate = LogitEstimate
						Lower = LogitLower
						Upper = LogitUpper;
				StandardError=.;
				tValue=.;
				Probt=.;
				if label = 'E(logitSe)' then name = 'Sensitivity';
				else if label = 'E(logitSp)' then name = 'Specificity';
				output;
			run;

			data _metadas_a_addest_sesp (drop=LogitEstimate LogitLower LogitUpper);
				set _metadas_a_addest_sesp;
				rename 	invlogitestimate = Estimate
						invlogitlower = Lower
						invlogitupper = Upper
						name = Label;
			run;

			data _metadas_a_addest_&k;
				set _metadas_a_addest_&k _metadas_a_addest_sesp _metadas_a_addest_temp;
			run;
			
			%if %sysfunc(exist(_metadas_a_addest_temp)) %then %do;
				proc datasets memtype=data nodetails nolist; 
					delete _metadas_a_addest_temp; 
				run;
				quit;
			%end;

			%if %sysfunc(exist(_metadas_a_addest_sesp)) %then %do;
				proc datasets memtype=data nodetails nolist; 
					delete _metadas_a_addest_sesp; 
				run;
				quit;
			%end;

			data _metadas_a_summary_&k(drop=Alpha DF);
				set _metadas_a_addest_&k;
				id=_n_;	
				rename Label=Parameter
						tValue=z
						Probt=Probz;
			run;

			/* Get the standard error for E(logitSe) and E(logitSp).
		     They should be in the first 2 rows of the table */
		    data _null_;
			   	set _metadas_a_summary_&k;
				if id=1 then call symput('SeELogitSe', StandardError);
				else if id=2 then call symput('SeELogitSp', StandardError);
			run;

			data _metadas_a_tmp_se_&k;
			   	set _tb_se;
				SeELogitSe=symget('SeElogitSe');
				SeELogitSp=symget('SeElogitSp');
				Studies=resolve('&nstudies');
			run;

			/*Get the covariance CovEs */
			data _null_;
			   	set _metadas_a_covaddest_&k;
				if row=1 then call symput('CovEs', Cov2);
				stop;
			run;

			data _metadas_a_tmp_se_&k;
			   	set _metadas_a_tmp_se_&k;
				CovEs=symget('CovEs');
			run;

			/* _tb_nocvse_&k is a wide format so transpose */
			proc transpose data=_metadas_a_tmp_se_&k out=_metadas_a_tmp_se_&k;
			run;

			data _metadas_a_tmp_se_&k(drop = _NAME_);
				set _metadas_a_tmp_se_&k;
				label _LABEL_= 'Parameter'
						COL1= 'Estimate';
			run;

			/* Create data set of measures of test accuracy */
			data _metadas_a_tmp_summst_&k(keep=parameter estimate lower upper);
			   	set _metadas_a_summary_&k;
				where id > 9; /* note that this ID number depends on the ordering of  
								the estimate statements in Proc NLMixed so if it 
								changes then check this contains the right records
								otherwise modify as appropriate*/
			run;

			/* Create data set of alternative model parameters, i.e., if method is 
			HSROC then obtain data set of bivariate model parameters */
			data _metadas_a_tmp_statpms_&k(drop=id);
			   	set _metadas_a_summary_&k;
				label z = 'z'
					Probz = 'Pr > |z|';
				where id < 7; 
			run;

			data _metadas_a_pe_&k(drop=Alpha DF );
			   	set _metadas_a_pe_&k;
				format RM_Name $char14.;
				rename tValue = z
						Probt = Probz;
				label tValue = 'z'
						Probt = 'Pr > |z|';
				RM_Name=Parameter;
				select (Parameter);
						when ('alpha')
							do;
							RM_Name='Lambda';
							end;
						when ('theta')
							do;
							RM_Name='Theta';
							end;
						when ('s2ua')
							do;
							RM_Name='Var(accuracy)';
							end;
						when ('s2ut')
							do;
							RM_Name='Var(threshold)';
							end;
						otherwise
							do;	
							end;
						end;
			run;
		%end;
		%else %do;
			%put The data set _metadas_a_addest_&k and/or _tb_se does not exist.;
		%end;
		
		/* if we have a covariate create a table with the estimates we need for the bivariate model
		in Revman */
		%if &covariate ~= %str() %then %do;
					
			/* Get parameter estimates */
			%if %sysfunc(exist(_metadas_cv_pe_&k)) %then %do;
				data _metadas_cv_pe_all_ds&k(drop=Alpha DF);
					set _metadas_cv_pe_&k;
					id=_n_;	
					rename tValue=z
							Probt=Probz;
					label tValue = 'z'
						Probt = 'Pr > |z|';
				run;

				/* Get parameter estimates for level 0*/
				data _metadas_cv_pe_cv0_ds&k (drop=Gradient);
		   			set _metadas_cv_pe_all_ds&k;
					where id between 1 and 5;	
				run;

				/* Get s2ut and s2ua as we are not estimating this for each level */
				data _tb_s2u_&k (drop=Gradient);
		   			set _metadas_cv_pe_all_ds&k;
					where id between 4 and 5;	
				run;
			%end;
			%else %do;
				%put %str(MODEL FAILURE: Parameter estimates for &bylevelname with covariate &covariate were not produced.
						This may be due to failure to converge or other issues with the model and/or data.);
			%end;

			%if %sysfunc(exist(_metadas_cv_addest_&k)) %then %do;

					data _metadas_cv_ae_all_ds&k(drop=Alpha DF);
						set _metadas_cv_addest_&k;
						id=_n_;	
						relativestat=.;
						rename tValue=z
							Probt=Probz;
						label tValue = 'z'
							Probt = 'Pr > |z|';
					run;
				
					/* create a variable to identify relative values such as RDOR, relative sens and spec
					and change in sens and spec */
					data _metadas_cv_ae_rel_ds&k;
						set _metadas_cv_ae_all_ds&k;
						relativestat=1;	
						where label contains "True" or label contains "RDOR" or label contains "Relative";
					run;

					/* now merge with the data set containing all the additional parameters */
					proc sort data = _metadas_cv_ae_rel_ds&k;
						by id;
					run;

					proc sort data = _metadas_cv_ae_all_ds&k;
						by id;
					run;

					data _metadas_cv_ae_all_ds&k;
	   					merge _metadas_cv_ae_all_ds&k _metadas_cv_ae_rel_ds&k;
	   					by id;
	   				run;	

					data _metadas_cv_ae_cv0_ds&k;
		   				set _metadas_cv_ae_all_ds&k;
						where (label contains "0" or label contains 'Corr' or id between 1 and 5)
								and relativestat ~=1;	
					run;
			%end;
			%else %do;
				%put %str(MODEL FAILURE: Additional estimates for &bylevelname with covariate &covariate were not produced. 
						This may be due to failure to converge or other issues with the model and/or data.);
			%end;

			%do j=0 %to &nlevels;

				/* reset these macro variables to zero */
				%let numobs = 0;
				%let nstudies =0;

				/* get the number of studies for the level of the covariate */
				%if %upcase(&cvtype)~=CON %then %do;	
					data _tmp_;
			   			set _metadas_ds&k;
						where cvlevels=&j;	
					run;
					data _null_;
						set _tmp_ nobs=numobs;
						call symput('numobs',numobs);
					run;
					%let nstudies = %eval(&numobs/2); /* get number of studies for the covariate level */			
				%end;

				/* only do this if there's at least one study with the level 
				or it is a continuous covariate */
				%if &nstudies > 0 or %upcase(&cvtype) = CON %then %do; 

					/* Get additional estimates for each level of the covariate */
					%if %sysfunc(exist(_metadas_cv_ae_all_ds&k)) %then %do;
						
						%if &j > 0 %then %do;
							data &dsprefixae&j&sub&k;
				   				set _metadas_cv_ae_all_ds&k;
								where label contains "&j" or label contains 'Corr' 
									 or id between 3 and 5;	
							run;
							
							data &dsprefixpe&j&sub&k;
								set _metadas_cv_ae_all_ds&k ;
								rename Label= Parameter;
								where Label contains "alpha_&j" or Label contains "theta_&j" 
										or Label contains "beta_&j";
							run;

							/* append the data set above to the one containing the variances */
							data &dsprefixpe&j&sub&k;
								set &dsprefixpe&j&sub&k _tb_s2u_&k;
							run;
							
							data _temp_Elogits;
				   				set &dsprefixae&j&sub&k;
								where label contains "E(logitS";	
							run;

							data &dsprefixae&j&sub&k;
				   				set &dsprefixae&j&sub&k;
								if Label = "E(logitSe)_&j" or Label = "E(logitSp)_&j" then delete;
							run;

							data _temp_Elogits;
								set _temp_Elogits &dsprefixae&j&sub&k;
							run;
							
							/* Generate row number and rename data set */
							data &dsprefixae&j&sub&k;
				   				set _temp_Elogits;
								row = _n_;
							run;
						%end;
						%else %do;
							data &dsprefixae&j&sub&k;
				   				set &dsprefixae&j&sub&k;
								row = _n_;
							run;
						%end;

						/*Get the SE and covariance CovEs for ElogitSe and ElogitSp
						first get the id from _tb_ae_cv&j_&k which should match 
						the row number in the covariance matrix table. The standard
						error should be from row 1 and 2 of the data set.
						To get the covariance use the id for ElogitSe as the row
						and the id of ElogitSp as the column */
						
						data _null_;
						   	set &dsprefixae&j&sub&k;
							if row=1 then do;
								call symput('SeELogitSe', StandardError);
								call symput('sensid', id);
							end;
							else if row=2 then do;
								call symput('SeELogitSp', StandardError);
								call symput('specid', left(id));
							end;
						run;

						data &dsprefixcov&j&sub&k;
						   	set _tb_se;
							SeELogitSe=symget('SeElogitSe');
							SeELogitSp=symget('SeElogitSp');
							Studies=resolve('&nstudies');
						run;

						%let covcol = Cov&specid;

						data _null_;
						   	set _metadas_cv_covaddest_&k;
							if row=resolve('&sensid') then call symput('CovEs', resolve(&covcol));
						run;

						data &dsprefixcov&j&sub&k;
						   	set &dsprefixcov&j&sub&k;
							CovEs=symget('CovEs');
						run;

						/* _tb_cov_cv&j_ds&k is a wide format so transpose */
						proc transpose data=&dsprefixcov&j&sub&k out=&dsprefixcov&j&sub&k;
						run;

						data &dsprefixcov&j&sub&k(drop = _NAME_);
							set &dsprefixcov&j&sub&k;
							label _LABEL_= 'Parameter'
									COL1= 'Estimate';
						run;
						/*%end; *******************/

						/* just some tidying up of data sets */
						%if &j > 0 %then %do;
							data _null_;
								set &dsprefixae&j&sub&k nobs=numobs;
								call symput('numobs',numobs);
							run;

							data &dsprefixae&j&sub&k (drop=row);
				   				set &dsprefixae&j&sub&k;							
								orderno=_n_;
								cvgroup=&j;
								where row <= &numobs-3; 
								rename Label=Parameter;
							run;
						%end;
						%else %do;
							data &dsprefixae&j&sub&k (drop=row);
				   				set &dsprefixae&j&sub&k;							
								orderno=_n_;
								cvgroup=&j;
								rename Label=Parameter;
							run;
						%end;

						data &dsprefixpe&j&sub&k (keep=parameter estimate standarderror z probz lower upper);
			   				set &dsprefixpe&j&sub&k;
						run;	

						/* Create one table for estimates of summary statistics for all the levels of the covariate */
						%if &j = 0 %then %do;
							data _metadas_cv_summary_&k;
								set _metadas_cv_ae_cv0_ds&k;
							run;
						%end;
						%else %if &j > 0 %then %do;
							data _metadas_cv_summary_&k ;
								set _metadas_cv_summary_&k &dsprefixae&j&sub&k;
							run;
						%end;

						/* only keep the first 6 observations in this data set, 
						i.e., the bivariate model parameters */
						data &dsprefixae&j&sub&k (keep=parameter estimate standarderror z probz lower upper); 
			   				set &dsprefixae&j&sub&k;
							where orderno < 7;
						run;		
					%end;
					%else %do;
						%put %str(MODEL FAILURE: Additional estimates for &bylevelname with covariate &covariate 
							were not produced. This may be due to failure to converge or other issues with the model and/or data.);
					%end;
				%end;
			%END;

			/* delete these intermediate tables */
			%if %sysfunc(exist(_metadas_cv_ae_rel_ds&k)) %then %do;
				proc datasets memtype=data nodetails nolist; 
					delete _metadas_cv_ae_rel_ds&k; 
				run;
				quit;
			%end;
			%if %sysfunc(exist(_metadas_cv_ae_all_ds&k)) %then %do;
				proc datasets memtype=data nodetails nolist; 
					delete _metadas_cv_ae_all_ds&k; 
				run;
				quit;
			%end;
			%if %sysfunc(exist(_metadas_cv_pe_all_ds&k)) %then %do;
				proc datasets memtype=data nodetails nolist; 
					delete _metadas_cv_pe_all_ds&k; 
				run;
				quit;
			%end;

			/* order the summary table as requested by the user 
			STAT (the default) will order by the summary statistic while level 
			just orders by the level of the covariate so all stats
			grouped together for each level */
			%if %sysfunc(exist(_metadas_cv_summary_&k)) %then %do;

				/* get exponents of the true positve and true negative log odds ratios 
				logDOR, logRDOR, log relative sensitivity and specificity, logLR- and logLR+ 
				and rename them by searching for log and replacing with nothing. */
				data _tb_cvsummary_temp;
					set _metadas_cv_summary_&k;
					RegularExpressionId = prxparse('s/log |log//');
					call prxchange(RegularExpressionId, -1, parameter);
					expestimate=exp(estimate);
					explower=exp(lower);
					expupper=exp(upper);
					where parameter contains 'True' or parameter contains 'logL' or parameter contains 'logD' or parameter contains 'logR';
					rename Estimate = LogEstimate;
					rename lower = LogLower;
					rename upper = LogUpper;					
					output;
				run;

				data _tb_cvsummary_temp (drop=LogEstimate LogLower LogUpper);
					set _tb_cvsummary_temp;
					rename 	expestimate = Estimate
							explower = Lower
							expupper = Upper;
				run;

				data _metadas_cv_summary_&k;
					set _metadas_cv_summary_&k;				
					if parameter='E(logitSe)_1' then call symput('SeID', id);
				run;

				%let idsens = %eval(&SeID -1); /* redo id for sens level 0 for ordering later */			
				%let idspec = %eval(&SeID + &nlevels); /* redo id for spec level 0 for ordering later */			

				data _metadas_cv_summary_&k;
					set _metadas_cv_summary_&k;				
					if parameter='E(logitSe)' then id = resolve('&idsens');
					else if parameter='E(logitSp)' then id = resolve('&idspec');
				run;

				/* get the inverse transformation of logit sensitivity and specificity */
				%if %upcase(&cvtype)= CON %then %do;
					data _tb_cvsummary_temp2;
						set _metadas_cv_summary_&k;
						RegularExpressionId1 = prxparse("s/E\WlogitSe\W_1/Sensitivity for unit change in covariate/");
						RegularExpressionId2 = prxparse("s/E\WlogitSp\W_1/Specificity for unit change in covariate/");
						RegularExpressionId3 = prxparse("s/E\WlogitSe\W/Sensitivity for cv = 0/");
						RegularExpressionId4 = prxparse("s/E\WlogitSp\W/Specificity for cv = 0/");
						call prxchange(RegularExpressionId1, -1, parameter);
						call prxchange(RegularExpressionId2, -1, parameter);
						call prxchange(RegularExpressionId3, -1, parameter);
						call prxchange(RegularExpressionId4, -1, parameter);
						invlogitestimate=exp(estimate)/(1 + exp(estimate));
						invlogitlower=exp(lower)/(1 + exp(lower));
						invlogitupper=exp(upper)/(1 + exp(upper));
						where parameter contains 'E(logitS';
						sensspec=1;
						rename Estimate = LogitEstimate;
						rename Lower = LogitLower;
						rename Upper = LogitUpper;
						output;
					run;
				%end;
				%else %do;
					data _tb_cvsummary_temp2;
						set _metadas_cv_summary_&k;
						RegularExpressionId1 = prxparse("s/E\WlogitSe\W_/Sensitivity for cv level /");
						RegularExpressionId2 = prxparse("s/E\WlogitSp\W_/Specificity for cv level /");
						RegularExpressionId3 = prxparse("s/E\WlogitSe\W/Sensitivity for cv level 0/");
						RegularExpressionId4 = prxparse("s/E\WlogitSp\W/Specificity for cv level 0/");
						call prxchange(RegularExpressionId1, -1, parameter);
						call prxchange(RegularExpressionId2, -1, parameter);
						call prxchange(RegularExpressionId3, -1, parameter);
						call prxchange(RegularExpressionId4, -1, parameter);
						invlogitestimate=exp(estimate)/(1 + exp(estimate));
						invlogitlower=exp(lower)/(1 + exp(lower));
						invlogitupper=exp(upper)/(1 + exp(upper));
						where parameter contains 'E(logitS';
						sensspec=1;
						rename Estimate = LogitEstimate;
						rename Lower = LogitLower;
						rename Upper = LogitUpper;
						output;
					run;
				%end;

				data  _tb_cvsummary_temp2 (drop=LogitEstimate LogitLower LogitUpper);
					set  _tb_cvsummary_temp2;
					rename 	invlogitestimate = Estimate
							invlogitlower = Lower
							invlogitupper = Upper;
				run;

				/* mark the log estimates so they can be deleted from the data set eventually 
				need to do it this way because can't use contains with if statement so create a temporary 
				data set and variable for the records to be deleted and then merge with the summary data set */
				data _tb_temp_&k;
					set _metadas_cv_summary_&k;
					fordelete=1;
					where parameter contains 'True' or parameter contains 'logL' or parameter contains 'logD' or parameter contains 'logR';
				run;

				proc sort data = _tb_temp_&k;
					by id;
				run;

				proc sort data = _metadas_cv_summary_&k;
					by id;
				run;

				data _metadas_cv_summary_&k;
   					merge _metadas_cv_summary_&k _tb_temp_&k;
   					by id;
   				run;

				/* delete the temporary data set */
				%if %sysfunc(exist(_tb_temp_&k)) %then %do;
					proc datasets memtype=data nodetails nolist; 
						delete _tb_temp_&k; 
					run;
					quit;
				%end;

				/* delete log estimates of parameters */
				data _metadas_cv_summary_&k;
					set _metadas_cv_summary_&k;
					if fordelete=1 then delete;
				run;

				/* append the transformed estimates to the rest of the summary data set */
				data _metadas_cv_summary_&k;
					set _metadas_cv_summary_&k _tb_cvsummary_temp2 _tb_cvsummary_temp;
				run;
				
				/* delete temporary data sets */
				%if %sysfunc(exist(_tb_cvsummary_temp)) %then %do;
					proc datasets memtype=data nodetails nolist; 
						delete _tb_cvsummary_temp; 
					run;
					quit;
				%end;

				%if %sysfunc(exist(_tb_cvsummary_temp2)) %then %do;
					proc datasets memtype=data nodetails nolist; 
						delete _tb_cvsummary_temp2; 
					run;
					quit;
				%end;

				/* If group is specified, items are listed in the table according 
				to covariate level. If stat is specified, items are listed 
				according to summary statistic such that all levels of the 
				covariate are grouped together for the statistic. */
				%if %upcase(&cvsummorder)= STAT or &cvsummorder = %str() %then %do;
					proc sort data = _metadas_cv_summary_&k;
						by id parameter;
					run;
				%end;
				%else %if %upcase(&cvsummorder)= LEVEL %then %do;
					proc sort data = _metadas_cv_summary_&k;
						by cvgroup;
					run;
				%end;

				/* create data set for summary statistics  */
				data _metadas_cv_statsummary_&k (keep=Parameter Estimate Lower Upper);
					set _metadas_cv_summary_&k;
					where (orderno > 6 and relativestat=.) or sensspec=1;		
				run;

				/* create data set for relative statistics*/
				data _metadas_cv_relsummary_&k (keep=Parameter Estimate Lower Upper Probz);
					set _metadas_cv_summary_&k;
					where relativestat=1;		
				run;

				%if %upcase(&cvtype)= CON %then %do;
					data _metadas_cv_relsummary_&k (drop=RegularExpressionId1);
						set _metadas_cv_relsummary_&k;
						RegularExpressionId1 = prxparse("s/ 1//");
						call prxchange(RegularExpressionId1, -1, parameter);
					run;
				%end;

				%if %sysfunc(exist(_metadas_cv_summary_&k)) %then %do;
					proc datasets memtype=data nodetails nolist; 
						delete _metadas_cv_summary_&k; 
					run;
					quit;
				%end;

			%end;
		%end;
	%end;

	/* if macro execution is not terminated prematurely due to an error of 
	some sort then set global variable metadas to 1, i.e., successful execution so far */
	%let metadas=1;

%mend;


/********************************************************************
*																	*
* 		CREATE STRING OF PARAMETERS AND THEIR STARTING VALUES 		*
*		FOR HSROC MODEL FROM A PARAMETER ESTIMATES TABLE			*							
*																	*
********************************************************************/

%macro createhpars (tbpe=, reffs=);

	/* set global variable metadas to 0 to begin with */
	%let metadas=0;

	%if %sysfunc(exist(&tbpe)) %then %do;

		/* if we do not have parameter estimates for the random effects then do this */
		%if %upcase(&reffs) = N %then %do;
			data _null_;
			   	set &tbpe;
				if parameter='alpha' then call symput('alpha', put(Estimate, 3.));
				if parameter='theta' then call symput('theta', put(Estimate, 3.));
				if parameter='beta' then call symput('beta', put(Estimate, 3.));		
			run;

			%let num = 5; /* number of steps */
			%let randeffsvar= %str(s2ua=0 to 1 by 0.2 s2ut=0 to 1 by 0.2);
		%end;

		/* we have already fitted random effects model and now fitting
		model with covariate so use the parameter values from the model without 
		covariate as starting values using a grid search of these values within
		the range +/- 1 */
		%else %if %upcase(&reffs) = Y %then %do;
			data _null_;
			   	set &tbpe;
				if parameter='alpha' then call symput('alpha', put(Estimate, 3.));
				if parameter='theta' then call symput('theta', put(Estimate, 3.));
				if parameter='beta' then call symput('beta', put(Estimate, 3.));
				if parameter='s2ua' then call symput('s2ua', put(Estimate, 5.2));
				if parameter='s2ut' then call symput('s2ut', put(Estimate, 5.2));
			run;

			%let num=2; /* using this number of steps so nlmixed doesn't take forever */

			/* create range of values for the variance terms 0 to +1 */
			%let ubs2ua = %sysevalf(&s2ua+1);
			%let s2uabynum = %sysevalf(&ubs2ua/&num);
			%let s2uasv = %str(s2ua = 0 to &ubs2ua by &s2uabynum); /* must remember to check this range */
			
			%let ubs2ut = %sysevalf(&s2ut+1);
			%let s2utbynum = %sysevalf(&ubs2ut/&num);
			%let s2utsv = %str(s2ut = 0 to &ubs2ut by &s2utbynum); /* must remember to check this range */

			%let randeffsvar = %str(&s2uasv &s2utsv);
		%end;

		/* create range of values (lower bound is -1 of the value and upper bound
		is +1 of the value) for alpha, beta and theta and use the number of steps 
		depending on whether or not we have the random effects */
		%let lbalpha = %sysevalf(&alpha-1);
		%let ubalpha = %sysevalf(&alpha+1);
		%let alphabynum= %sysevalf((&ubalpha-&lbalpha)/&num); 
		%let alphasv= %str(alpha = &lbalpha to &ubalpha by &alphabynum);

		%let lbtheta = %sysevalf(&theta-1);
		%let ubtheta = %sysevalf(&theta+1);		
		%let thetabynum= %sysevalf((&ubtheta-&lbtheta)/&num); 
		%let thetasv = %str(theta = &lbtheta to &ubtheta by &thetabynum);

		%let lbbeta = %sysevalf(&beta-1);
		%let ubbeta = %sysevalf(&beta+1);
		%let betabynum= %sysevalf((&ubbeta-&lbbeta)/&num); 
		%let betasv = %str(beta = &lbbeta to &ubbeta by &betabynum);

		%let pms = %str(&alphasv &thetasv &betasv) &randeffsvar;

	%end;

	%else %put The dataset &tbpe does not exist;

	/* if macro execution is not terminated prematurely due to an error of 
	some sort then set global variable metadas to 1, i.e., successful execution so far */
	%let metadas=1;

%mend;

/********************************************************************
*																	*
* 				HSROC ANALYSIS WITH NO COVARIATE					*
*																	*
********************************************************************/

%macro hsrocnocv(data=, tech=, hessout=, cialpha=, subject=, outreffs=, pms=, byname=, modelnum=, predict=);

	/* set global variable metadas to 0 to begin with */
	%let metadas=0;

	%if %upcase(&predict) = Y %then %let predictlogit= %str(predict logitp out=_metadas_a_logitp_&modelnum);
	%else %let predictlogit= ;

	%if &bylevels > 1 %then %let
		proctitle = %str("HSROC analysis &modelnum without covariate - &byname");
	%else %let proctitle = %str("HSROC analysis without covariate - &byname");

	/*ODS OUTPUT */
	ods output StartingValues=_metadas_a_sv_&modelnum
		Parameters=_metadas_a_parms_&modelnum
		ParameterEstimates=_metadas_a_pe_&modelnum
		FitStatistics=_metadas_a_fit_&modelnum
		AdditionalEstimates=_metadas_a_addest_&modelnum
		CovMatAddEst=_metadas_a_covaddest_&modelnum
		ConvergenceStatus=_metadas_a_convgstat_&modelnum;

	%if &hessout ~=%str() %then %do;
		ods output Hessian=_metadas_a_hessian_&modelnum;
	%end;

	proc nlmixed data=&data cov ecov df=1000 start alpha=&cialpha &hessout &tech;
		title &proctitle;
		parms &pms;/*initial values for analysis*/
		bounds s2ua >= 0; /* set boundary constraint so variance is not negative */
		bounds s2ut >= 0;
		logitp= (theta + ut + (alpha + ua) * dis) * exp(-(beta)*dis);
		p = exp(logitp)/(1+exp(logitp));
		model pos ~ binomial(n,p);
		random ut ua ~ normal([0,0],[s2ut,0,s2ua]) subject=&subject &outreffs;/* */

		&predictlogit;

		/* convert to bivariate parameterisation */
		/* E(logitSe) is the mean logit sensitivity */
		/* E(logitSp) is the mean logit specificity */
		/* Var(logitSe), Var(logitSp) are the variances of logit sensitivity and specifcity */
		/* Cov(logits) is the covariance of logit sensitivity and specificity */
		/* To some extent the order of the estimate statements is important in 
		extracting data for output so if you change it check 
		that the tables are still ok - any changes necessary should 
		be done to hsrocout */
		estimate 'E(logitSe)'   	exp(-beta/2) * (theta + 0.5 * alpha);
		estimate 'E(logitSp)'		-exp(beta/2) * (theta - 0.5 * alpha);
		estimate 'Var(logitSe)'		exp(-beta) * (s2ut + 0.25 * s2ua);
		estimate 'Var(logitSp)'		exp(beta) * (s2ut + 0.25 * s2ua);
		estimate 'Cov(logits)'	- (s2ut - 0.25 * s2ua);

		/*Estimate of correlation of expected logit(sensitivity)
		and logit(specificity)*/
		estimate 'Corr(logits)'(- (s2ut - 0.25 * s2ua))/(sqrt(exp(-beta) * (s2ut + 0.25 * s2ua))*sqrt(exp(beta) * (s2ut + 0.25 * s2ua)));

		/* estimates of average operating point */
		/* estimate 'sensitivity' exp(exp(-beta/2) * (theta + 0.5 * alpha))/(1+exp(exp(-beta/2) * (theta + 0.5 * alpha)));
		estimate 'specificity' exp(-exp(beta/2) * (theta - 0.5 * alpha))/(1+exp(-exp(beta/2) * (theta - 0.5 * alpha)));*/
		estimate 'logDOR' log(((exp(exp(-beta/2) * (theta + 0.5 * alpha))/(1+exp(exp(-beta/2) * (theta + 0.5 * alpha))))
				/(1-(exp(exp(-beta/2) * (theta + 0.5 * alpha))/(1+exp(exp(-beta/2) * (theta + 0.5 * alpha))))))
		/((1-(exp(-exp(beta/2) * (theta - 0.5 * alpha))/(1+exp(-exp(beta/2) * (theta - 0.5 * alpha)))))
		/(exp(-exp(beta/2) * (theta - 0.5 * alpha))/(1+exp(-exp(beta/2) * (theta - 0.5 * alpha))))));
		estimate 'logLR+' log((exp(exp(-beta/2) * (theta + 0.5 * alpha))/(1+exp(exp(-beta/2) * (theta + 0.5 * alpha))))
			/(1-(exp(-exp(beta/2) * (theta - 0.5 * alpha))/(1+exp(-exp(beta/2) * (theta - 0.5 * alpha))))));
		estimate 'logLR-' log((1-(exp(exp(-beta/2) * (theta + 0.5 * alpha))/(1+exp(exp(-beta/2) * (theta + 0.5 * alpha)))))
			/(exp(-exp(beta/2) * (theta - 0.5 * alpha))/(1+exp(-exp(beta/2) * (theta - 0.5 * alpha))))) ;
		
	run;
	quit;

	/* if macro execution is not terminated prematurely due to an error of 
	some sort then set global variable metadas to 1, i.e., successful execution so far */
	%let metadas=1;

%mend;

/********************************************************************
*																	*
* 						CREATE WORD OUTPUT							*							
*																	*
********************************************************************/

	
%macro printtodoc(method=, covariate=, cvtype=, cveffect=, 
					formatlr=, byvar=, mtitle=, subject=, 
					info=, dtfile=, cialpha=, checkmod=, 
					predict=, bothmodels=, incbasic=, rfile=);

	/* set global variable metadas to 0 to begin with */
	%let metadas=0;
	
	%put %str(******************************);
	%put %str(CREATE WORD OUTPUT FOR RESULTS);
	%put %str(******************************); 

	/* want no title in the document header */
	title ' ';

	/* set up model type and alternative model for use with headers 
	and info */
	%if %upcase(&method)= B %then %do;
		%let modelname = %str(Bivariate);
		%let altmodelname = %str(HSROC);
	%end;
	%else %if %upcase(&method) ~= B %then %do;
		%let modelname = %str(HSROC);
		%let altmodelname =%str(Bivariate);		
	%end;

	ods noresults; /* prevents results from appearing within SAS viewer */

	/* use the SAS output delivery system to output results */
	options orientation=portrait pageno = 1;
	ods listing close;
	ods rtf file=&rfile startpage=no;
	ods escapechar = '^';
	ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=5} %upcase(&mtitle)";
	ods rtf text="^S={outputwidth=100%} ";
	ods rtf text="^S={outputwidth=100%} ";
 
	/* create template for the document */
	proc template;
		define style rtfmargins;
			parent = styles.rtf;
			style body from body/
				bottommargin  = 2 cm
				topmargin = 2 cm
				rightmargin = 2 cm
				leftmargin = 2 cm;
		end;
	run;

	ods rtf style = rtfmargins;
		
	/* put all information at beginining so that it is not repeated k times */
	%if %upcase(info) ~= N %then %do;
		
		ods rtf text="^S={outputwidth=100%} ";
		ods rtf text="^S={outputwidth=100% just=l font_weight=bold font_size=4} Analysis Information";
		%if &dtfile ~=%str() and %upcase(&import) ~= N %then %do;
			ods rtf text="^S={outputwidth=100% just=l font_size=3} Data: &dtfile";
		%end;
		%else %if &dsname ~=%str() and %upcase(&import) = N %then %do;
			ods rtf text="^S={outputwidth=100% just=l font_size=3} Input data set: &dsname";
		%end;

		%if &test ~=%str() and &byvar = %str() %then %do;
			ods rtf text="^S={outputwidth=100% just=l font_size=3} Test: &test";
		%end;
		%else %if &byvar ~=%str() %then %do;
			ods rtf text="^S={outputwidth=100% just=l font_size=3} BY variable: &byvar";
		%end;
	
		%let cinterval= %sysevalf((1-&cialpha) * 100);
		ods rtf text="^S={outputwidth=100% just=l font_size=3} Confidence Interval: &cinterval%";
		
		%if %sysfunc(exist(_metadas_&covariate)) and %upcase(&cvtype)~= CON %then %do;

			data _metadas_&covariate (keep=&covariate cvlevels);
				set _metadas_&covariate;
				label cvlevels = 'Level';
			run;

			proc sort data=_metadas_&covariate;
				by cvlevels;
			run;

			ods rtf text="^S={outputwidth=100% just=c font_size=3} Covariate Information";
			proc print data= _metadas_&covariate noobs label;
			run;

		%end;
		%else %if %upcase(&cvtype)= CON and &covariate ~= %str() %then %do;
			ods rtf text="^S={outputwidth=100% just=l font_size=3} Covariate: &covariate";
		%end;

		ods rtf text="^S={outputwidth=100%} ";
		ods rtf text="^S={outputwidth=100%} ";
		ods rtf text="^S={outputwidth=100%} ";
		ods rtf text="^S={outputwidth=100%} ";
	%end;

	%do k=1 %to &bylevels;

		/* if there is a BY variable get the name of the current test or by category. 
		If no BY variable but test is specified then use the name of the test */ 
		%if &byvar ~= %str() %then %do;
			data _null_;
			   	set _metadas_&byvar;
				if bylevels=&k then call symput('bylevelname', &byvar);
			run;
		%end;
		%else %if &byvar=%str() and &test ~= %str() %then %let bylevelname=&test;
		%else %if &byvar=%str() and &test = %str() %then %let bylevelname= %str(test);
		

		%if &k > 1 %then %do;
			/* force a page break after each level of the BY variable*/
			ods rtf startpage=now;
		%end;

		%if &k = 1 %then %do;
			ods rtf text="^S={outputwidth=100%} ";
			ods rtf text="^S={outputwidth=100%} ";
		%end;

		/* output the model with no covariate only if incbasic is not equal to no (n) */
		%if %upcase(&incbasic)~= N %then %do;

			ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=5} &modelname model basic analysis for &bylevelname";
		
			/* Starting printing tables to output file */
			%if %sysfunc(exist(_metadas_a_sv_&k)) %then %do;
				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} Starting values";
				proc print data=_metadas_a_sv_&k noobs;
				run;
			%end;
			
			%if %sysfunc(exist(_metadas_a_convgstat_&k)) %then %do;
				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} Convergence status";
				proc print data=_metadas_a_convgstat_&k noobs;
				run;
			%end;

			%if %sysfunc(exist(_metadas_a_fit_&k)) %then %do;
				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} Model fit";
				proc print data=_metadas_a_fit_&k noobs label;
				run;
			%end;
			%else %do;
				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} The fit table was not created. This may be due to failure to converge.";
				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100%} ";
			%end;

			%if %sysfunc(exist(_metadas_a_pe_&k)) %then %do;
				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} &modelname model parameter estimates";
				proc print data=_metadas_a_pe_&k noobs label;
				run;

				data _nostderr_;
					set _metadas_a_pe_&k;
					where standarderror=.;
				run;

				%let numobs=0;
				%if %sysfunc(exist(_nostderr_)) %then %do;
					data _null_;
			   			set _nostderr_ nobs = numobs; 
						call symput('numobs',numobs);
					run;
				%end;
				%let nostderr=&numobs;

				proc datasets memtype=data nodetails nolist; 
					delete 	_nostderr_; 
				run;

				/* checking for correlation of +1 or -1 for bivariate model */
				%if %upcase(&method)= B %then %do;
					%let corr = 0;
					data _null_;
					   	set _metadas_a_pe_&k;
						if parameter='Corr(logits)' then call symput('corr', put(Estimate, best12.));
					run;	
					
					/* notify user of missing standard errors and that model may be unreliable */			
					%if %sysfunc(abs(&corr)) = 1 %then %do;
						ods rtf text="^S={outputwidth=100% just=l font_weight=bold font_size=3} NOTE: Between study correlation of +1 or -1.";
						ods rtf text="^S={outputwidth=100% just=l font_weight=bold font_size=3} There may be insufficient information to estimate the correlation and pooled estimates may be unstable.";
						ods rtf text="^S={outputwidth=100%} ";
					%end;
				%end;

				/* notify user of missing standard errors and that model may be unreliable */
				%if &nostderr > 0 %then %do;
					ods rtf text="^S={outputwidth=100% just=l font_weight=bold font_size=3} WARNING: Standard error missing (.) for &nostderr estimate(s) in the table. Pooled estimates may be unstable.";
					ods rtf text="^S={outputwidth=100%} ";
					ods rtf text="^S={outputwidth=100%} ";
				%end;
			%end;
			%else %do;
				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} Parameters were not estimated. This may be due to failure to converge or other issues with the model and/or data.";
				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100%} ";
			%end;

			%if %sysfunc(exist(_metadas_a_tmp_statpms_&k)) %then %do;
				%if %upcase(&bothmodels)= Y  %then %do;
					ods rtf text="^S={outputwidth=100%} ";
					ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} &altmodelname model parameter estimates";
					proc print data=_metadas_a_tmp_statpms_&k noobs label;
					run;

					/* checking for missing standard errors */
					data _nostderr_;
						set _metadas_a_tmp_statpms_&k;
						where standarderror=. and (lower=. or upper=.); 
					run;

					%let numobs=0;
					%if %sysfunc(exist(_nostderr_)) %then %do;
						data _null_;
				   			set _nostderr_ nobs = numobs; 
							call symput('numobs',numobs);
						run;
					%end;
					%let nostderr=&numobs;

					proc datasets memtype=data nodetails nolist; 
						delete 	_nostderr_; 
					run;
					quit;

					
					/* checking for correlation of +1 or -1 for bivariate model */
					%if %upcase(&method) ~= B %then %do;
						%let corr = 0;
						data _null_;
						   	set _metadas_a_tmp_statpms_&k;
							if parameter='Corr(logits)' then call symput('corr', put(Estimate, best12.));
						run;	
						
						/* notify user of missing standard errors and that model may be unreliable */			
						%if %sysfunc(abs(&corr)) = 1 %then %do;
							ods rtf text="^S={outputwidth=100% just=l font_weight=bold font_size=3} NOTE: Between study correlation of +1 or -1.";
							ods rtf text="^S={outputwidth=100% just=l font_weight=bold font_size=3} There may be insufficient information to estimate the correlation and pooled estimates may be unstable.";
							ods rtf text="^S={outputwidth=100%} ";
						%end;
					%end;

					%if &nostderr > 0 %then %do;
						ods rtf text="^S={outputwidth=100% just=l font_weight=bold font_size=3} WARNING: Standard error missing (.) for &nostderr estimate(s) in the table. Pooled estimates may be unstable.";
						ods rtf text="^S={outputwidth=100%} ";
						ods rtf text="^S={outputwidth=100%} ";
					%end;
				%end;
			%end;
			%else %do;
				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} &altmodelname model parameters were not estimated. This may be due to failure to converge or other issues with the model and/or data.";
				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100%} ";
			%end;

			%if %sysfunc(exist(_metadas_a_tmp_se_&k)) %then %do;
				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} Confidence and prediction region parameters";
				proc print data=_metadas_a_tmp_se_&k noobs label;
				run;
				quit;
			%end;

			%if %sysfunc(exist(_metadas_a_tmp_summst_&k)) %then %do;
				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} Summary estimates of test accuracy measures";
				proc print data=_metadas_a_tmp_summst_&k noobs label;
				run;
				data _nostderr_;
					set _metadas_a_tmp_summst_&k;
					where lower=. or upper=.; 
				run;

				%let numobs=0;
				%if %sysfunc(exist(_nostderr_)) %then %do;
					data _null_;
			   			set _nostderr_ nobs = numobs; 
						call symput('numobs',numobs);
					run;
				%end;
				%let nostderr=&numobs;

				proc datasets memtype=data nodetails nolist; 
					delete 	_nostderr_; 
				run;
				quit;

				/* notify user of missing standard errors and that model may be unreliable */
				%if &nostderr > 0 %then %do;
					ods rtf text="^S={outputwidth=100% just=l font_weight=bold font_size=3} WARNING: Standard error missing (.) for &nostderr estimate(s) in the table. Pooled estimates may be unstable.";
					ods rtf text="^S={outputwidth=100%} ";
					ods rtf text="^S={outputwidth=100%} ";
				%end;
			%end; 
			%else %do;
				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} Summary estimates of test accuracy measures were not produced. This may be due to failure to converge or other issues with the model and/or data.";
				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100%} ";
			%end;

			/* modify table of predicted value if prediction was requested and model ok*/
			%if %sysfunc(exist(_metadas_a_logitp_&k)) and %upcase(&predict) ~= N and %sysfunc(exist(_metadas_a_addest_&k)) %then %do;

				%if %upcase(&method)~=B %then %do;
					data _predsens_ds&k(keep= &subject &covariate sensobs senspred lowerse upperse);
						set _metadas_a_logitp_&k;
						sensobs=pos/n;	
						senspred=exp(pred)/(1+exp(pred));
						lowerse=exp(lower)/(1+exp(lower));
						upperse=exp(upper)/(1+exp(upper));
						where sens=1;
					run;
					data _predspec_ds&k(keep= &subject &covariate specobs specpred lowersp uppersp);
						set _metadas_a_logitp_&k;
						specobs=1-(pos/n);
						specpred=1-(exp(pred)/(1+exp(pred)));
						lowersp=1-(exp(upper)/(1+exp(upper))); /* switch limit since it is now taken away from 1 */
						uppersp=1-(exp(lower)/(1+exp(lower)));
						where spec=1;
					run;
				%end;
				%else %if %upcase(&method)=B %then %do;
					data _predsens_ds&k(keep= &subject &covariate sensobs senspred lowerse upperse);
						set _metadas_a_logitp_&k;
						sensobs=true/n;	
						senspred=exp(pred)/(1+exp(pred));
						lowerse=exp(lower)/(1+exp(lower));
						upperse=exp(upper)/(1+exp(upper));
						where sens=1;
					run;
					data _predspec_ds&k(keep= &subject &covariate specobs specpred lowersp uppersp);
						set _metadas_a_logitp_&k;
						specobs=true/n;
						specpred=exp(pred)/(1+exp(pred));
						lowersp=exp(lower)/(1+exp(lower));
						uppersp=exp(upper)/(1+exp(upper));
						where spec=1;
					run;
				%end;
				proc sort data = _predsens_ds&k;
					by &subject;
				run;

				proc sort data = _predspec_ds&k;
					by &subject;
				run;

				data _metadas_a_predict_&k;
		   			merge _predsens_ds&k _predspec_ds&k;
		   			by &subject;
		   		run;
				
				data _metadas_a_predict_&k;
					set _metadas_a_predict_&k;
					label sensobs = 'Observed sensitivity'
						specobs = 'Observed specificity'
						senspred = 'Predicted sensitivity'
						specpred = 'Predicted specificity'
						lowerse = 'Lower confidence limit for predicted sensitivity'
						upperse = 'Upper confidence limit for predicted sensitivity'
						lowersp = 'Lower confidence limit for predicted specificity'
						uppersp = 'Upper confidence limit for predicted specificity';
				run;
				
				%if %sysfunc(exist(_predsens_ds&k)) %then %do;
					proc datasets memtype=data nodetails nolist; 
						delete _predsens_ds&k; 
					run;
				%end;

				%if %sysfunc(exist(_predspec_ds&k)) %then %do;
					proc datasets memtype=data nodetails nolist; 
						delete _predspec_ds&k; 
					run;
				%end;

				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} Predicted values of sensitivity and specificity based on parameter and empirical Bayes estimates";
				proc print data=_metadas_a_predict_&k noobs label;
				run;
			%end;


			/* if model	checking is yes, produce histogram and normal probability plot
				of the empirical Bayes estimates of the random effects */
			%if %sysfunc(exist(_metadas_a_addest_&k)) and %upcase(&checkmod) = Y %then %do;

				goptions goutmode=replace noborder;
				
				/*ods noptitle;*/
				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} Model checking - distribution of random effects";			
				ods rtf text="^S={outputwidth=100% just=c font_size=4} Histograms and normal probability plots of the empirical Bayes estimates of the random effects (ua and ut, level two residuals)";
				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100%} ";

				proc sort data=_metadas_a_randeffs_&k;
					by effect;
				run;

				ods select HistRE HistRE1;
				proc univariate data=_metadas_a_randeffs_&k noprint;
					title1 " ";
					title3 "Histogram of random effects for &bylevelname";
				  	by effect;
				  	histogram estimate /normal 
										cfill=ltgray 
										nrows=1 
										name = 'HistRE'
										noframe;
				run;

				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100%} ";

				ods select QQNRE QQNRE1;
				proc univariate data=_metadas_a_randeffs_&k noprint;
					title1 " ";
					title3 "Normal probability plot of random effects for &bylevelname";
				  	by effect;
				  	probplot estimate/normal 
									square 
									noframe
									name= 'QQNRE';
				run;
			%end;
		%end;

		title ' ';

		%if %sysfunc(exist(_metadas_a_summary_&k)) %then %do;
			proc datasets memtype=data nodetails nolist; 
				delete _metadas_a_summary_&k; 
			run;
			quit;
		%end;
		
		%if &covariate ~= %str() and %sysfunc(exist(_metadas_cv_addest_&k)) %then %do;

			%if %upcase(&incbasic) ~= N %then %do;

				/* want the output for model with covariate on a new page
				so force a page break now if there is output for basic model */
				ods rtf startpage=now;

			%end;

			ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=5} &modelname model analysis with covariate = &covariate";

			%if %sysfunc(exist(_metadas_cv_sv_&k)) %then %do;
				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} Starting values";
				proc print data=_metadas_cv_sv_&k noobs;
				run;
			%end;			

			%if %sysfunc(exist(_metadas_cv_convgstat_&k)) %then %do;
				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} Convergence status";
				proc print data=_metadas_cv_convgstat_&k noobs;
				run;
			%end;

			%if %sysfunc(exist(_metadas_cv_fit_&k)) %then %do;
				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} Model fit";
				proc print data=_metadas_cv_fit_&k noobs label;
				run;

				/* get number of parameters so we can work out df for likelihood ratio test */
				%if &cveffect=%str() %then %let plen = 3;
				%else %let plen=%sysfunc(lengthn(&cveffect));
				%let numpars = %eval(&plen * &nlevels);

				/* get difference in -2LogL and compare with Chi-square distribution */
				%if %sysfunc(exist(_metadas_a_fit_&k)) and %sysfunc(exist(_metadas_cv_addest_&k)) %then %do;
					data _null_;
					   	set _metadas_a_fit_&k;
						if descr='-2 Log Likelihood' then call symput('_2logL1', Value);
						stop;
					run;
					data _null_;
					   	set _metadas_cv_fit_&k;
						if descr='-2 Log Likelihood' then call symput('_2logL2', Value);
						stop;
					run;
					%let _2logLDiff = %sysfunc(abs(&_2logL1 - &_2logL2));
					%let upval= %sysfunc(probchi(&_2logLDiff, &numpars));
					%let pval=%sysevalf(1 - &upval);

					
					ods rtf text="^S={outputwidth=100% just=l font_weight=bold font_size=4} Likelihood ratio test for model with and without &covariate: ";
					/* format the -2log difference and p-value */
					%if %upcase(&formatlr)=N %then %do;
						ods rtf text="^S={outputwidth=100% just=l font_size=3} -2 log likelihood difference is &_2logLDiff on &numpars degrees of freedom, p = &pval";
					%end;
					%else %do;
						%if &_2logLDiff >= 0.001 %then %let _2logld = %sysfunc(putn(&_2logLDiff, 6.3));
						%else %if &_2logLDiff < 0.001 %then %let _2logld =&_2logLDiff;
						%if %sysfunc(putn(&pval, 5.3)) >= 0.001 %then %do;
							%let pv= %sysfunc(putn(&pval, 5.3));
							%let fpval=%str(= &pv);
						%end;
						%else %if %sysfunc(putn(&pval, 5.3)) < 0.001 %then %let fpval= %str(<0.001);
						ods rtf text="^S={outputwidth=100% just=l font_size=3} -2 log likelihood difference is &_2logld on &numpars degrees of freedom, p &fpval";
					%end;
					ods rtf text="^S={outputwidth=100%} ";
					ods rtf text="^S={outputwidth=100%} ";
				%end;
				%else %do;
					ods rtf text="^S={outputwidth=100%} ";
					ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} No likelihood ratio test because of failure to converge or other issues with one or both models.";
					ods rtf text="^S={outputwidth=100%} ";
					ods rtf text="^S={outputwidth=100%} ";
				%end;	
			%end;
			%else %do;
				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} The fit table was not created. This may be due to failure to converge.";
				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100%} ";
			%end;

			/* modify table of predicted value if prediction was requested */
			%if %sysfunc(exist(_metadas_cv_logitp_&k)) and %upcase(&predict) ~= N %then %do;
				%if %upcase(&method)~=B %then %do;
					data _predsens_cv_ds&k(keep= &subject &covariate sensobs senspred lowerse upperse);
						set _metadas_cv_logitp_&k;
						sensobs=pos/n;	
						senspred=exp(pred)/(1+exp(pred));
						lowerse=exp(lower)/(1+exp(lower));
						upperse=exp(upper)/(1+exp(upper));
						where sens=1;
					run;
					data _predspec_cv_ds&k(keep= &subject &covariate specobs specpred lowersp uppersp);
						set _metadas_cv_logitp_&k;
						specobs=1-(pos/n);
						specpred=1-(exp(pred)/(1+exp(pred)));
						lowersp=1-(exp(upper)/(1+exp(upper))); /* switch limit since it is now taken away from 1 */
						uppersp=1-(exp(lower)/(1+exp(lower)));
						where spec=1;
					run;
				%end;
				%else %if %upcase(&method)=B %then %do;
					data _predsens_cv_ds&k(keep= &subject &covariate sensobs senspred lowerse upperse);
						set _metadas_cv_logitp_&k;
						sensobs=true/n;	
						senspred=exp(pred)/(1+exp(pred));
						lowerse=exp(lower)/(1+exp(lower));
						upperse=exp(upper)/(1+exp(upper));
						where sens=1;
					run;
					data _predspec_cv_ds&k(keep= &subject &covariate specobs specpred lowersp uppersp);
						set _metadas_cv_logitp_&k;
						specobs=true/n;
						specpred=exp(pred)/(1+exp(pred));
						lowersp=exp(lower)/(1+exp(lower));
						uppersp=exp(upper)/(1+exp(upper));
						where spec=1;
					run;
				%end;

				proc sort data = _predsens_cv_ds&k;
					by &subject;
				run;

				proc sort data = _predspec_cv_ds&k;
					by &subject;
				run;

				data _metadas_cv_predict_&k;
		   			merge _predsens_cv_ds&k _predspec_cv_ds&k;
		   			by &subject;
		   		run;
				
				data _metadas_cv_predict_&k;
					set _metadas_cv_predict_&k;
					label sensobs = 'Observed sensitivity'
						specobs = 'Observed specificity'
						senspred = 'Predicted sensitivity'
						specpred = 'Predicted specificity'
						lowerse = 'Lower confidence limit for predicted sensitivity'
						upperse = 'Upper confidence limit for predicted sensitivity'
						lowersp = 'Lower confidence limit for predicted specificity'
						uppersp = 'Upper confidence limit for predicted specificity';
				run;

				%if %sysfunc(exist(_predsens_cv_ds&k)) %then %do;
					proc datasets memtype=data nodetails nolist; 
						delete _predsens_cv_ds&k; 
					run;
				%end;

				%if %sysfunc(exist(_predspec_cv_ds&k)) %then %do;
					proc datasets memtype=data nodetails nolist; 
						delete _predspec_cv_ds&k; 
					run;
				%end;

				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} Predicted values of sensitivity and specificity based on parameter and empirical Bayes estimates";
				proc print data=_metadas_cv_predict_&k noobs label;
				run;
			%end;


			%do j = 0 %to &nlevels;

				%if %upcase(&cvtype)~= CON %then %do;
					data _null_;
					   	set _metadas_&covariate;
						if cvlevels=&j then call symput('cvlevelname', &covariate);
					run;
					%let name= %str(for &covariate = &cvlevelname);
				%end;
				%else %let name= %str(for &covariate);

				%if %sysfunc(exist(&dsprefixcov&j&sub&k)) %then %do;
					%if %sysfunc(exist(&dsprefixpe&j&sub&k)) %then %do;
						ods rtf text="^S={outputwidth=100%} ";
						ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} &modelname model parameter estimates &name";
						proc print data=&dsprefixpe&j&sub&k noobs label;
						run;

						data _nostderr_;
							set &dsprefixpe&j&sub&k;
							where standarderror=.;
						run;

						%let numobs=0;
						%if %sysfunc(exist(_nostderr_)) %then %do;
							data _null_;
					   			set _nostderr_ nobs = numobs; 
								call symput('numobs',numobs);
							run;
						%end;
						%let nostderr=&numobs;
						
						proc datasets memtype=data nodetails nolist; 
							delete 	_nostderr_; 
						run;

						/* notify user of missing standard errors and that model may be unreliable */
						%if &nostderr > 0 %then %do;
							ods rtf text="^S={outputwidth=100% just=l font_weight=bold font_size=3} WARNING: Standard error missing (.) for &nostderr estimate(s) in the table. Pooled estimates may be unstable.";
							ods rtf text="^S={outputwidth=100%} ";
							ods rtf text="^S={outputwidth=100%} ";
						%end;
					%end;

					%if %sysfunc(exist(&dsprefixae&j&sub&k)) %then %do;
						%if %upcase(&bothmodels)= Y %then %do;
							ods rtf text="^S={outputwidth=100%} ";
							ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} &altmodelname model parameter estimates &name";
							proc print data=&dsprefixae&j&sub&k noobs label;
							run;

							data _nostderr_;
								set &dsprefixae&j&sub&k;
								where standarderror=.;
							run;

							%let numobs=0;
							%if %sysfunc(exist(_nostderr_)) %then %do;
								data _null_;
						   			set _nostderr_ nobs = numobs; 
									call symput('numobs',numobs);
								run;
							%end;
							%let nostderr=&numobs;
							
							proc datasets memtype=data nodetails nolist; 
								delete 	_nostderr_; 
							run;

							/* notify user of missing standard errors and that model may be unreliable */
							%if &nostderr > 0 %then %do;
								ods rtf text="^S={outputwidth=100% just=l font_weight=bold font_size=3} WARNING: Standard error missing (.) for &nostderr estimate(s) in the table. Pooled estimates may be unstable.";
								ods rtf text="^S={outputwidth=100%} ";
								ods rtf text="^S={outputwidth=100%} ";
							%end;

							/* don't want to repeat this info for all levels of the 
							covariate so just do this once after the last level */
							%if &j = &nlevels %then %do;
								%let corr = 0;
								%if %upcase(&method) = B %then %do;
									data _null_;
									   	set &dsprefixpe&j&sub&k;
										if parameter='Corr(logits)' then call symput('corr', put(Estimate, best12.));
									run;
								%end;
								%else %if %upcase(&method) ~= B %then %do;
									data _null_;
									   	set &dsprefixae&j&sub&k;
										if parameter='Corr(logits)' then call symput('corr', put(Estimate, best12.));
									run;
								%end;
								%if %sysfunc(abs(&corr)) = 1 %then %do;
									ods rtf text="^S={outputwidth=100% just=l font_weight=bold font_size=3} NOTE: Between study correlation of +1 or -1.";
									ods rtf text="^S={outputwidth=100% just=l font_weight=bold font_size=3} There may be insufficient information to estimate the correlation and pooled estimates may be unstable.";
									ods rtf text="^S={outputwidth=100%} ";
									ods rtf text="^S={outputwidth=100%} ";
								%end;
							%end;	
						%end;

						proc datasets memtype=data nodetails nolist; 
							delete 	&dsprefixpe&j&sub&k; 
						run;

						proc datasets memtype=data nodetails nolist; 
							delete &dsprefixae&j&sub&k; 
						run;
						quit;

					%end;

					%if %sysfunc(exist(&dsprefixcov&j&sub&k)) %then %do;
						ods rtf text="^S={outputwidth=100%} ";
						ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} Confidence and prediction region parameters &name";
						proc print data=&dsprefixcov&j&sub&k noobs label;
						run;
						proc datasets memtype=data nodetails nolist; 
							delete &dsprefixcov&j&sub&k; 
						run;
						quit;
					%end;
				%end;
				%else %do;
					ods rtf text="^S={outputwidth=100%} ";
					ods rtf text="^S={outputwidth=100% just=l font_weight=bold font_size=4} WARNING: This data set has no data &name";
					ods rtf text="^S={outputwidth=100%} ";
				%end;

			%end;			

			%if %sysfunc(exist(_metadas_cv_statsummary_&k)) %then %do;
				ods rtf text="^S={outputwidth=100%} ";
				ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} Summary estimates of test accuracy measures for &covariate ";
				proc print data=_metadas_cv_statsummary_&k noobs label;
				run;

				data _nostderr_;
					set _metadas_cv_statsummary_&k;
					where lower=. or upper=.; 
				run;

				%let numobs=0;
				%if %sysfunc(exist(_nostderr_)) %then %do;
					data _null_;
			   			set _nostderr_ nobs = numobs; 
						call symput('numobs',numobs);
					run;
				%end;
				%let nostderr=&numobs;
						
				proc datasets memtype=data nodetails nolist; 
					delete 	_nostderr_; 
				run;

				/* notify user of missing standard errors and that model may be unreliable */
				%if &nostderr > 0 %then %do;
					ods rtf text="^S={outputwidth=100% just=l font_weight=bold font_size=3} WARNING: Standard error missing (.) for &nostderr estimate(s) in the table. Pooled estimates may be unstable.";
					ods rtf text="^S={outputwidth=100%} ";
					ods rtf text="^S={outputwidth=100%} ";
				%end;
			%end;

			%if %sysfunc(exist(_metadas_cv_relsummary_&k)) %then %do;
				ods rtf text="^S={outputwidth=100%} ";
				%if %upcase(&cvtype)~=CON %then %do;
					ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} Estimates of relative measures of test accuracy for &covariate";
				%end;
				%else %if %upcase(&cvtype)=CON %then %do;
					ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4} Estimates of relative measures of test accuracy for unit change in &covariate";
				%end;
				proc print data= _metadas_cv_relsummary_&k noobs label;
				run;

				data _nostderr_;
					set _metadas_cv_relsummary_&k;
					where lower=. or upper=.; 
				run;

				%let numobs=0;
				%if %sysfunc(exist(_nostderr_)) %then %do;
					data _null_;
			   			set _nostderr_ nobs = numobs; 
						call symput('numobs',numobs);
					run;
				%end;
				%let nostderr=&numobs;
						
				proc datasets memtype=data nodetails nolist; 
					delete 	_nostderr_; 
				run;

				/* notify user of missing standard errors and that model may be unreliable */
				%if &nostderr > 0 %then %do;
					ods rtf text="^S={outputwidth=100% just=l font_weight=bold font_size=3} WARNING: Standard error missing (.) for &nostderr estimate(s) in the table. Pooled estimates may be unstable.";
					ods rtf text="^S={outputwidth=100%} ";
					ods rtf text="^S={outputwidth=100%} ";
				%end;
			%end;

			/* commented out on 8th july 2009 
			%if %sysfunc(exist(_metadas_cv_contrasts_&k)) %then %do;
				data _metadas_cv_contrasts_&k;
				   	set _metadas_cv_contrasts_&k;
					label Label='Test';
				run;
				ods rtf text="^S={outputwidth=100%} ";
				%if %upcase(&cvtype)~=CON %then %do;
					ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4}  Test of difference between levels of &covariate";
				%end;
				%else %if %upcase(&cvtype)=CON %then %do;
					ods rtf text="^S={outputwidth=100% just=c font_weight=bold font_size=4}  Test of difference for &covariate";
				%end;
				proc print data=_metadas_cv_contrasts_&k noobs label;
				run;
			%end; */

		%end;

		/* delete unnecessary data sets */
		proc datasets memtype=data nodetails nolist; 
			delete 	_tb_s2u_&k;
		run;

		proc datasets memtype=data nodetails nolist; 
			delete 	_temp_elogits 
					_tmp_; 
		run;	

	%end;

	/* delete temporary data sets no longer reuired for output */
	proc datasets memtype=data nodetails nolist; 
		delete _metadas_a_tmp_:; 
	run;

	proc datasets memtype=data nodetails nolist; 
		delete _tb_se; 
	run;

	quit;

	ods results;
	ods rtf close;
	ods listing;

	%put *****************;
	%put  End of Analysis ;
	%put *****************;

	/* if macro execution is not terminated prematurely due to an error of 
	some sort then set global variable metadas to 1, i.e., successful execution so far */
	%let metadas=1;

%mend;



/********************************************************************
*																	*
* 			CREATE EMPTY DATA SET FOR STORING SeElogitSe, 			*
*			SeElogitSp, CovES and studies							*
*																	*
********************************************************************/

%macro createds();

	/* set global variable metadas to 0 to begin with */
	%let metadas=0;

	/* create a data set so we can add the values required for the confidence and
	prediction regions in Revman. Datalines not allowed in macros so let's find a 
	way round it using a temporary file with infile */

	filename temp temp; 

    data _null_; 
		file temp; 
		put; 
	run; 

    data _tb_se; 
      	infile temp; 
      	input @; 
      	do _infile_ = 
			'. . . .' ;
         	input SeELogitSe @1 SeELogitSp @1 CovEs @1 Studies @1 @; 
         	output; 
    	end; 
  	run; 

    filename temp clear; 

	%if %sysfunc(exist(_tb_se)) %then %do;
		data _tb_se;
			set _tb_se;
			label SeELogitSe ='SE(E(logitSe))'
					SeELogitSp = 'SE(E(logitSp))'
					CovEs = 'Cov(Es)'
					Studies = 'Studies';
		run;
	%end;

	/* if macro execution is not terminated prematurely due to an error of 
	some sort then set global variable metadas to 1, i.e., successful execution so far */
	%let metadas=1;

%mend;

/********************************************************************
*																	*
* 						DELETE DATA SETS							*							
*																	*
********************************************************************/

%macro keepds(mode=, covariate=, byvar=, randeffs=, checkmod=);

	/* set global variable metadas to 0 to begin with */
	%let metadas=0;

	/* don't wish to keep any of the generated data sets */
	%if %upcase(&mode) = NONE %then %do;
		proc datasets;
			delete _metadas_: ;
		run;
		quit;
		%let metadas = 1;
		%return;
	%end;

	/* wish to keep only data sets generated from the log file */
	%if %upcase(&mode) = LOG %then %do;
		proc datasets;
			delete _metadas_meta 
			delete _metadas_&byvar
			delete _metadas_&covariate
			delete _metadas_a_: 
			delete _metadas_cv_: 
			delete _metadas_ds:;
		run;
		quit;
		%let metadas = 1;
		%return;
	%end;

	%do k=1 %to &bylevels;

		%if %upcase(&randeffs) ~= Y  %then %do;
			%if %sysfunc(exist(_metadas_a_randeffs_&k)) %then %do;
				proc datasets memtype=data nodetails nolist; 
					delete _metadas_a_randeffs_&k; 
				run;
			%end;
		%end;

		%if %upcase(&predict) ~= Y  %then %do;
			%if %sysfunc(exist(_metadas_a_logitp_&k)) %then %do;
				proc datasets memtype=data nodetails nolist; 
					delete _metadas_a_logitp_&k
							_metadas_a_predict_&k; 
				run;
			%end;
		%end;
		
		%if %sysfunc(exist(_metadas_a_addest_&k)) and %upcase(&mode) ~= ALL %then %do;
			proc datasets memtype=data nodetails nolist; 
				delete _metadas_a_addest_&k
						_metadas_a_covaddest_&k; 
			run;
		%end;


		%if %sysfunc(exist(_metadas_a_covparmest_&k)) and %upcase(&mode) ~= ALL %then %do;
			proc datasets memtype=data nodetails nolist; 
				delete _metadas_a_covparmest_&k; 
			run;
		%end;		

		%if %sysfunc(exist(_metadas_a_convgstat_&k)) and %upcase(&mode) ~= ALL %then %do;
			proc datasets memtype=data nodetails nolist; 
				delete 	_metadas_a_convgstat_&k
						_metadas_a_fit_&k
						_metadas_a_parms_&k
						_metadas_a_pe_&k
						_metadas_a_sv_&k; 
			run;
		%end;	
		
		
		%if &covariate ~=%str() %then %do;
			
			%if %sysfunc(exist(_metadas_cv_addest_&k)) and %upcase(&mode) ~= ALL %then %do;
				proc datasets memtype=data nodetails nolist; 
					delete _metadas_cv_addest_&k
							_metadas_cv_covaddest_&k
							_metadas_cv_contrasts_&k
							_metadas_cv_statsummary_&k
							_metadas_cv_relsummary_&k;
				run;
			%end;

			%if %sysfunc(exist(_metadas_cv_covparmest_&k)) and %upcase(&mode) ~= ALL %then %do;
				proc datasets memtype=data nodetails nolist; 
					delete _metadas_cv_covparmest_&k; 
				run;
			%end;

			%if %sysfunc(exist(_metadas_cv_convgstat_&k)) and %upcase(&mode) ~= ALL %then %do;
				proc datasets memtype=data nodetails nolist; 
					delete _metadas_cv_convgstat_&k
							_metadas_cv_fit_&k
							_metadas_cv_parms_&k
							_metadas_cv_pe_&k
							_metadas_cv_sv_&k; 
				run;
			%end;

			%if %upcase(&randeffs) ~= Y  %then %do;
				%if %sysfunc(exist(_metadas_cv_randeffs_&k)) %then %do;
					proc datasets memtype=data nodetails nolist; 
						delete _metadas_cv_randeffs_&k; 
					run;
				%end;
			%end;

			%if %upcase(&predict) ~= Y %then %do;
				%if %sysfunc(exist(_metadas_cv_logitp_&k)) %then %do;
					proc datasets memtype=data nodetails nolist; 
						delete _metadas_cv_logitp_&k
								_metadas_cv_predict_&k; 
					run;
				%end;
			%end;

		%end;
		
	%end;

	quit;

	/* if macro execution is not terminated prematurely due to an error of 
	some sort then set global variable metadas to 1, i.e., successful execution so far */
	%let metadas=1;

%mend;



/********************************************************
*														*
* 			PERFORM META-ANALYSIS: Bivariate Model		*			
*														*
********************************************************/

%macro metab(tech=, subject=, cialpha=, byvar=, covariate=, 
			cvtype=, cveffect=, mtitle=, tbpe=, p1=, p2=, p3=, p4=, p5=, 
			cset1=, cset2=, cset3=, cset4=, cspa1=, cspa2=,	cspa3=, cspa4=, 
			randeffs=, predict=, checkmod=, hessout=);

	/* set global variable metadas to 0 to begin with */
	%let metadas=0;

	%put %str(*******************);
	%put %str(FIT BIVARIATE MODEL);
	%put %str(*******************);

	%if &byvar ~=%str() %then %do;
		%put %str(*************************************************);
		%put SEPARATE ANALYSES FOR EACH LEVEL OF %upcase(&byvar);
		%put %str(*************************************************);
	%end;

	/* create an indicator variable to be used later */
	%let modfailed = 0;

	/* if performing several analyses using the BY variable then repeat 
	the analysis for each level of the BY variable ,i.e., 
	produce as many models as levels of the variable otherwise run one
	set of analyses*/
	%do k=1 %to &bylevels;

		%if &bylevels > 1 %then %do;
			data _null_;
			   	set _metadas_&byvar;
				if bylevels=&k then call symput('byname', &byvar);
			run;
		%end;
		%else %if &bylevels =1 and &test ~= %str() %then %let byname = &test;
		%else %if &bylevels =1 and &test = %str() %then %let byname= test;

		/* if the empirical Bayes estimates of the random effects are required or model
		checking is yes, _metadas_a_randeffs will be created when Proc Nlmixed runs*/
		%if %upcase(&randeffs)=Y or %upcase(&checkmod) = Y %then %let outreffs= %str(out = _metadas_a_randeffs_&k);
		%else %let outreffs= ;
				 	
		%put %str(****************************************************************************************);
		%put %str(ANALYSIS: Fitting bivariate model with no covariate for %upcase(&byname));
		%put %str(****************************************************************************************);
		
		/* STARTING VALUES FOR NO COVARIATE MODEL */
		/*if user does not provide starting values for parameters
		 then use the following  */
		/* mu_A is the mean logit sensitivity */
		/* mu_B is the mean logit specificity */
		/* s2_A, s2_B are the variances of logit sensitivity and specifcity */
		/* s2_AB is the covariance of logit sensitivity and specificity */

		%put ------------------------------------------------------;
		%put ANALYSIS STEP 1: Set up parameters and starting values;
		%put ------------------------------------------------------;

		/* for now only set this up once - will modify in next version 
		to allow multiple tables of starting values */
		%if &k = 1 %then %do;

			/* if we are not using a table of parameters */
			%if &tbpe=%str() %then %do;
				/* use these values as default to create a grid of values
				if user doesn't provide starting values for parameters */
				%if &p1=%str() %then %let p1= -2 to 4 by 1;
				%if &p2=%str() %then %let p2= -2 to 4 by 1; 
				%if &p3=%str() %then %let p3= 0 to 2 by 0.25; 
				%if &p4=%str() %then %let p4= 0 to 2 by 0.25; 
				%if &p5=%str() %then %let p5= 0 to 1 by 0.2;		
				
				/*PARAMETERS FOR THE MODEL */
				/*Build list of parameters and their starting values */
				%let pms = %str(msens=&p1 mspec=&p2 s2usens=&p3 s2uspec=&p4 covsesp=&p5);
			%end;
			%else %let pms= %str( / data=&tbpe);
		%end;

		proc sort data=_metadas_ds&k;
			by &subject &covariate;
		run;

		/*RUN PROC NLMIXED: MODEL WITH NO COVARIATE */
		/*Bivariate model without covariate*/
		%put ---------------------------------------------------------------------;
		%put %str(ANALYSIS STEP 2: Run PROC NLMIXED for _metadas_ds&k);
		%put ---------------------------------------------------------------------;

		%bivarnocv(data=_metadas_ds&k, tech=&tech, cialpha=&cialpha, subject=&subject, 
					outreffs=&outreffs, pms=&pms, byname=&byname, 
					modelnum=&k, predict=&predict, hessout=&hessout);
		run;

		/* if above model doesn't converge or the final Hessian matrix is not positive definite, then
		additional estimates will not be produced so try fitting model using Proc MIXED 
		to obtain new starting values and then repeat analysis */
		%if %sysfunc(exist(_metadas_a_addest_&k)) %then 
			%put %str(Bivariate model without covariate successful for &byname);
		%else %do;
			%put %str(----------------------------------------------------------------------------------------);
			%put %str(ANALYSIS INFORMATION: Bivariate analysis using Proc NLMIXED for &byname failed.);
			%put %str(Running Proc MIXED for _metadas_ds&k to obtain new);
			%put %str(starting values for logit sensitivity, logit specificity);
			%put %str(their variances and covariance.);
			%put %str(----------------------------------------------------------------------------------------);

			ods output SolutionF=_m_temp_solfixed
				CovParms= _m_temp_covparms
				ConvergenceStatus=_m_temp_convgstat;

			/* run proc mixed for the data so the model estimates can be used as 
			starting values for Proc NLMIXED */			
			proc mixed data=_metadas_ds&k;
				class &subject; 
				model logit=sens spec/solution noint; /* produce fixed effects solution and no intercept */
				random sens spec /subject=&subject type=un; /* want unstructured covariance structure. This 
														is useful for correlated random coefficient models */
			run ;

			/* modify this data set to keep only effect and estimate 
			and give the effect the parameter names */
			%if %sysfunc(exist(_m_temp_solfixed)) %then %do;
				data _m_temp_solfixed (keep= Parameter Estimate);
					set _m_temp_solfixed;
					if Effect = 'sens' then Parameter='msens';
					else if Effect ='spec' then Parameter = 'mspec';
				run;
			%end;

			/* modify and keep only the required variables */
			%if %sysfunc(exist(_m_temp_covparms)) %then %do;
				data _m_temp_covparms (keep= Parameter Estimate);
					set _m_temp_covparms;
					Parameter = CovParm;
					label CovParm = 'Effect';
					select (CovParm);
						when ('UN(1,1)')
							do;
							Parameter='s2usens';
							end;
						when ('UN(2,2)')
							do;
							Parameter='s2uspec';
							end;
						when ('UN(2,1)')
							do;
							Parameter='covsesp';
							end;
						when ('Residual')
							do;
							delete;
							end;
						otherwise
							do;	
							end;
						end;
				run;

				/* append the data sets into a parameter estimates table */
				%if %sysfunc(exist(_m_temp_solfixed)) %then %do;
					data _m_temp_pe;
						set _m_temp_covparms _m_temp_solfixed;
					run;
				%end;
			%end;


			/* successful convergence and production of additional estimates then 
			refit model using these as starting values instead*/
			%if %sysfunc(exist(_m_temp_pe)) %then %do;
				%createbpars(tbpe=_m_temp_pe, reffs=y);
				run;
				%bivarnocv(data=_metadas_ds&k, tech=&tech, cialpha=&cialpha, subject=&subject, 
						outreffs=&outreffs, pms=&pms, byname=&byname, modelnum=&k,
						predict=&predict, hessout=&hessout);
				run;
				%if %sysfunc(exist(_metadas_a_addest_&k)) %then %do;
					%put %str(Bivariate modelling without covariate successfully completed for &byname);
					%let modfailed=0;
				%end;
				%else %do;
					%put %str(MODEL FAILURE: Bivariate modelling without covariate was not successfully completed for &byname);
					%let modfailed =1;
				%end;
			%end;
			/*if model without random effects failed and we are only running a set of 
			analyses then terminate the macro otherwise carry on with other levels of the
			BY variable */
			%else %if &byar = %str() %then %do;
				%put %str(----------------------------------------------------------------------------------------------------------------);
				%put %str(ANALYSIS INFORMATION: metadas terminated.);
				%put %str(Modelling with Proc MIXED failed to produce suitable starting values for analysis of &byname);
				%put %str(----------------------------------------------------------------------------------------------------------------);
				%let metadas=0;
				%return;
			%end;
		%end;

		/* delete these temporary data sets */
		proc datasets memtype=data nodetails nolist; 
			delete _m_temp_:; 
		run;
		quit;


		/****************************************************
		*													*
		* Fit model with covariate if covariate is given &	*
		* the no covariate model converged and produced		*
		* additional estimates								*
		*													*
		****************************************************/
		
		%if &covariate~=%str() and %sysfunc(exist(_metadas_a_pe_&k)) and %sysfunc(exist(_metadas_a_addest_&k)) %then %do;		
			
			%let numobs=0;
			%let nstudies=0;
			
			/* check that we have data for the reference level of the covariate otherwise
			skip the analysis */
			%if %upcase(&cvtype) ~= CON %then %do;	
				data _tmp_;
		   			set _metadas_ds&k;
					where cvlevels=0;	
				run;
				data _null_;
					set _tmp_ nobs=numobs;
					call symput('numobs',numobs);
				run;
				%let nstudies = %eval(&numobs/2); /* get number of studies for the covariate level */
			%end;

			%if &nstudies = 0 and %upcase(&cvtype) ~= CON %then %do;
				%put %str(-------------------------------------------------------------------------------------------);
				%put %str(ANALYSIS INFORMATION: Unable to perform bivariate analysis with covariate.);
				%put %str(There are no observations for the reference level of %upcase(&covariate) for this data set.);
				%put %str(-------------------------------------------------------------------------------------------);
				%goto endcvanalysis;
				run;
			%end;
			
			/* if the empirical Bayes estimates of the random effects are required or model
			checking is yes, _metadas_cv_randeffs will be created when proc nlmixed runs*/
			%if %upcase(&randeffs)=Y or %upcase(&checkmod) = Y %then %let outreffs= %str(out = _metadas_cv_randeffs_&k);
			%else %let outreffs= ;
						
			/* PARAMETERS AND ESTIMATE STATEMENTS FOR MODEL WITH COVARIATE*/

			%put %str(*********************************************************************);
			%put ANALYSIS: Fitting bivariate model with %upcase(&covariate) as a covariate;
			%put %str(*********************************************************************);

			%put ---------------------------------------------------------------------------;
			%put ANALYSIS STEP 1: Set up parameters, starting values and estimate statements;
			%put ---------------------------------------------------------------------------;
			
			/* just need to do this once but in future will do k times if different pe tables 
			are given for each analysis of the BY variable */
			%if &k=1 or &modfailed=1 %then %do;
				/*Build additional parameters and estimate statements */
				%cvparsbivar(covariate=&covariate, cvtype=&cvtype, cveffect=&cveffect, 
						cset1=&cset1, cset2=&cset2, cset3=&cset3, cset4=&cset4, 
						cspa1=&cspa1, cspa2=&cspa2, cspa3=&cspa3, cspa4=&cspa4);
				run;
			%end;

			/* create starting values for the parameters msens, mspec 
			s2usens, s2uspec and covsesp from the parameter estimates table */
			%createbpars(tbpe=_metadas_a_pe_&k, reffs=y);
			run;

			ods output StartingValues=_metadas_cv_sv_&k
				Parameters=_metadas_cv_parms_&k
				ParameterEstimates=_metadas_cv_pe_&k
				FitStatistics=_metadas_cv_fit_&k
				AdditionalEstimates=_metadas_cv_addest_&k
				CovMatAddEst=_metadas_cv_covaddest_&k
				CovMatParmEst=_metadas_cv_covparmest_&k
				ConvergenceStatus=_metadas_cv_convgstat_&k
				Contrasts=_metadas_cv_contrasts_&k;

			%if &hessout ~=%str() %then %do;
				ods output Hessian=_metadas_cv_hessian_&k;
			%end;

			/* RUN PROC NLMIXED: MODEL WITH A COVARIATE */

			%put ------------------------------------------------------------------------------;
			%put %str(ANALYSIS STEP 2: Run Proc NLMIXED for _metadas_ds&k with covariate %upcase(&covariate));
			%put ------------------------------------------------------------------------------;

			%if %upcase(&predict) = Y %then %let predictlogit= %str(predict logitp out=_metadas_cv_logitp_&k);
			%else %let predictlogit= ;

			%if &bylevels > 1 %then %let
				proctitle = %str("Bivariate analysis &k with covariate %upcase(&covariate)");
			%else %let proctitle = %str("Bivariate analysis with covariate %upcase(&covariate)");

			proc nlmixed data=_metadas_ds&k cov ecov df=1000 start alpha=&cialpha &hessout &tech;
				title &proctitle;
				/* msens is the mean logit sensitivity */
				/* msens_cv1 is the change in mean logit sensitivity for covariate level =1*/
				/* mspec is the mean logit specificity */
				/* mspec_cv1 is the change in mean logit specificity for covariate level =1*/				
				/* s2usens, s2uspec are the variances of logit sensitivity and specifcity */
				/* covsesp is the covariance of logit sensitivity and specificity */
				/* subject is usually study ID*/
				/* To some extent the order of the estimate statements are important in 
				extracting data for output so if you change it check 
				that the tables are still ok - any changes necessary should 
				be done to bivarout */
				parms &pms &cvparamlist; /*reset initial value for new analysis*/
				bounds s2usens >= 0; /* set boundary constraint so variance is not less than zero */
				bounds s2uspec >= 0;
				logitp= &logitp;
				p = exp(logitp)/(1+exp(logitp));
				model true ~ binomial(n,p);
				random usens uspec ~ normal([0,0],[s2usens,covsesp,s2uspec]) subject=&subject &outreffs;

				&predictlogit;

				/*Estimate correlation of expected 
				logit(sensitivity)and logit(specificity)*/
				estimate 'Corr(logits)' covsesp/(SQRT(s2usens)*(SQRT(s2uspec))) ;

				/* convert to HSROC parameterisation */				
				/* theta is the threshold parameter, lambda is the accuracy parameter*/				
				/* beta is the shape parameter*/
				estimate 'Lambda' (s2uspec/s2usens)**0.25 * msens  + (s2usens/s2uspec)**0.25 * mspec ;
				estimate 'Theta' 0.5* ( (s2uspec/s2usens)**0.25 * msens - (s2usens/s2uspec)**0.25 * mspec ) ;
				estimate 'beta' log( sqrt(s2uspec/s2usens) ) ;
				estimate 'Var(accuracy)'   2*( sqrt(s2usens*s2uspec) + covsesp) ;
				estimate 'Var(threshold)' 0.5*( sqrt(s2usens*s2uspec) - covsesp) ;

				&estmuAcv; /* logit(sens) change for covariate levels*/
				&estmuBcv; /* logit(spec) change for covariate levels*/
				
				/* estimates of average operating points and other 
				conversions to HSROC parameterisation */
				&estMuAlevels; /* elogit(sens) for each level of the covariate */ 
				&estMuBlevels; /* elogit(spec) for each level of the covariate */
				&estDOR; /* diagnostic odds ratio for each level of the covariate */ 
				&estRelSens; /* relative sensitivity for each level of the covariate */ 
				&estRelSpec; /* relative specificity for each level of the covariate */ 
				&estRDOR; /* relative diagnostic odds ratio for each level of the covariate */ 
				&estLRpos; /* positive likelihood ratio for each level of the covariate */ 
				&estLRneg; /* negative likelihood ratio for each level of the covariate */ 
				&estAlpha; /* alpha for each level of the covariate except the reference category*/ 
				&estTheta; /* theta for each level of the covariate except the reference category*/
				&contrastse;
				&contrastsp;
			run;
			quit;

			%endcvanalysis:;

		%end;

	%end;
	/* create data sets in the format required from results of the analysis */
	%bivarout(covariate=&covariate, cvtype=&cvtype, cveffect=&cveffect, 
			cvsummorder=&cvsummorder, byvar=&byvar);
	run;

	/* if macro execution is not terminated prematurely due to an error of 
	some sort then set global variable metadas to 1, i.e., successful execution so far */
	%let metadas=1;
	
%mend;


/********************************************************************
*																	*
* 				BIVARIATE ANALYSIS WITH NO COVARIATE				*
*																	*
********************************************************************/


%macro bivarnocv(data=, tech=, hessout=, cialpha=, subject=, outreffs=, pms=, byname=, modelnum=, predict=);

	/* set global variable metadas to 0 to begin with */
	%let metadas=0;

	%if %upcase(&predict) = Y %then %let predictlogit= %str(predict logitp out=_metadas_a_logitp_&modelnum);
	%else %let predictlogit= ;

	%if &bylevels > 1 %then %let
		proctitle = %str("Bivariate analysis &modelnum without covariate - &byname");
	%else %let proctitle = %str("Bivariate analysis without covariate - &byname");

	/*ODS OUTPUT */
	ods output StartingValues=_metadas_a_sv_&modelnum
		Parameters=_metadas_a_parms_&modelnum
		ParameterEstimates=_metadas_a_pe_&modelnum
		FitStatistics=_metadas_a_fit_&modelnum
		AdditionalEstimates=_metadas_a_addest_&modelnum
		CovMatAddEst=_metadas_a_covaddest_&modelnum
		CovMatParmEst=_metadas_a_covparmest_&modelnum
		ConvergenceStatus=_metadas_a_convgstat_&modelnum;

	%if &hessout ~=%str() %then %do;
		ods output Hessian=_metadas_a_hessian_&modelnum;
	%end;

	proc nlmixed data=&data cov ecov df=1000 start alpha=&cialpha &hessout &tech;
		title &proctitle;
		parms &pms;/*initial values for analysis*/
		bounds s2usens >= 0; /* set boundary constraint so variance is not less than zero */
		bounds s2uspec >= 0;
		logitp= (msens+usens)*sens + (mspec+uspec)*spec;
		p = exp(logitp)/(1+exp(logitp));
		model true ~ binomial(n,p);
		random usens uspec ~ normal([0,0],[s2usens,covsesp,s2uspec]) subject=&subject &outreffs;/* */

		&predictlogit;
			
		/*Estimate correlation of expected 
		logit(sensitivity)and logit(specificity)*/
		/* To some extent the order of the estimate statements is important in 
		extracting data for output so if you change it check 
		that the tables are still ok - any changes necessary should 
		be done to bivarout */
		estimate 'Corr(logits)' covsesp/(SQRT(s2usens)*(SQRT(s2uspec))) ;

		/* estimates of average operating point */
		/*estimate 'sensitivity' exp(msens)/(1+exp(msens));
		estimate 'specificity' exp(mspec)/(1+exp(mspec));*/
		estimate 'logDOR' log((exp(msens)/(1+exp(msens)))/(1-(exp(msens)/(1+exp(msens))))/
				((1-(exp(mspec)/(1+exp(mspec))))/(exp(mspec)/(1+exp(mspec)))));
		estimate 'logLR+' log((exp(msens)/(1+exp(msens)))/(1-(exp(mspec)/(1+exp(mspec)))));
		estimate 'logLR-' log((1-(exp(msens)/(1+exp(msens))))/(exp(mspec)/(1+exp(mspec))));

		/* convert to HSROC parameterisation */
		/* theta is the threshold parameter, lambda is the accuracy parameter*/				
		/* beta is the shape parameter*/
		estimate 'Lambda' (s2uspec/s2usens)**0.25 * msens  + (s2usens/s2uspec)**0.25 * mspec ;
		estimate 'Theta' 0.5* ( (s2uspec/s2usens)**0.25 * msens - (s2usens/s2uspec)**0.25 * mspec ) ;
		estimate 'beta' log( sqrt(s2uspec/s2usens) ) ;
		estimate 'Var(accuracy)'   2*( sqrt(s2usens*s2uspec) + covsesp) ;
		estimate 'Var(threshold)' 0.5*( sqrt(s2usens*s2uspec) - covsesp) ;
	run;
	quit;

	/* if macro execution is not terminated prematurely due to an error of 
	some sort then set global variable metadas to 1, i.e., successful execution so far */
	%let metadas=1;

%mend;

/********************************************************************
*																	*
* 		CREATE STRING OF PARAMETERS AND THEIR STARTING VALUES 		*
*		FOR BIVARIATE MODEL FROM A PARAMETER ESTIMATES TABLE			*							
*																	*
********************************************************************/

%macro createbpars (tbpe=, reffs=);

	/* set global variable metadas to 0 to begin with */
	%let metadas=0;

	%if %sysfunc(exist(&tbpe)) %then %do;

		/* if we do not have parameter estimates for the random effects then do this */
		%if %upcase(&reffs) = N %then %do;
			data _null_;
			   	set &tbpe;
				select (Parameter);
						when ('msens')
							do;
							call symput('msens', put(Estimate, 5.2));
							end;
						when ('mspec')
							do;
							call symput('mspec', put(Estimate, 5.2));
							end;
						otherwise
							do;	
							end;
						end;
				/*if parameter='msens' then call symput('msens', put(Estimate, 3.));
				if parameter='mspec' then call symput('mspec', put(Estimate, 3.));	*/				
			run;

			%let num = 5; /* number of steps */
			%let randeffsvar= %str(s2usens=0 to 1 by 0.2 s2uspec=0 to 1 by 0.2 covsesp = -1 to 1 by 0.5);
		%end;

		/* we have already fitted random effects model and now fitting
		model with covariate so use the parameter values from the model without 
		covariate as starting values using a grid search of these values within
		the range +/- 1 */
		%else %if %upcase(&reffs) = Y %then %do;
			data _null_;
			   	set &tbpe;
				select (Parameter);
						when ('msens')
							do;
							call symput('msens', put(Estimate, 5.2));
							end;
						when ('mspec')
							do;
							call symput('mspec', put(Estimate, 5.2));
							end;
						when ('s2usens')
							do;
							call symput('s2usens', put(Estimate, 5.3));
							end;
						when ('s2uspec')
							do;
							call symput('s2uspec', put(Estimate, 5.3));
							end;
						when ('covsesp')
							do;
							call symput('covsesp', put(Estimate, 5.3));
							end;
						otherwise
							do;	
							end;
						end;
				/*if parameter='msens' then call symput('msens', put(Estimate, 3.));
				if parameter='mspec' then call symput('mspec', put(Estimate, 3.));
				if parameter='s2usens' then call symput('s2usens', put(Estimate, 5.2));
				if parameter='s2uspec' then call symput('s2uspec', put(Estimate, 5.2));
				if parameter='covsesp' then call symput('covsesp', put(Estimate, 5.2));*/
			run;

			%let num=2; /* using this number of steps so nlmixed doesn't take forever */

			/* create range of values for the variance terms 0 to +1 and 
			covariance value to +1. For some reason covariance term does not like 
			range from -1 */
			%let ubs2usens = %sysevalf(&s2usens+1);
			%let s2usensbynum = %sysevalf(&ubs2usens/&num);
			%let s2usenssv = %str(s2usens = 0 to &ubs2usens by &s2usensbynum); /* must remember to check this range */
			
			%let ubs2uspec = %sysevalf(&s2uspec+1);
			%let s2uspecbynum = %sysevalf(&ubs2uspec/&num);
			%let s2uspecsv = %str(s2uspec = 0 to &ubs2uspec by &s2uspecbynum); /* must remember to check this range */

			%let ubcovsesp = %sysevalf(&covsesp+1);
			%let covsespbynum = %sysevalf(&ubcovsesp/&num);
			%let covsespsv = %str(covsesp =  0 to &ubcovsesp by &covsespbynum); /* must remember to check this range */

			%let randeffsvar = %str(&s2usenssv &s2uspecsv &covsespsv);
		%end;

		/* create range of values (lower bound is -1 of the value and upper bound
		is +1 of the value) for mean logit sensitivity and specificity.
		Use number of steps	depending on whether or not we have the random effects */
		%let lbmsens = %sysevalf(&msens-1);
		%let ubmsens = %sysevalf(&msens+1);
		%let msensbynum= %sysevalf((&ubmsens-&lbmsens)/&num); 
		%let msenssv= %str(msens = &lbmsens to &ubmsens by &msensbynum);

		%let lbmspec = %sysevalf(&mspec-1);
		%let ubmspec = %sysevalf(&mspec+1);		
		%let mspecbynum= %sysevalf((&ubmspec-&lbmspec)/&num); 
		%let mspecsv = %str(mspec = &lbmspec to &ubmspec by &mspecbynum);

		%let pms = %str(&msenssv &mspecsv) &randeffsvar;

	%end;

	%else %put The dataset &tbpe does not exist;

	/* if macro execution is not terminated prematurely due to an error of 
	some sort then set global variable metadas to 1, i.e., successful execution so far */
	%let metadas=1;

%mend;


/********************************************************************
*																	*
* 		CREATE PARAMETER AND ESTIMATE STATEMENTS 					*
*		FOR A COVARIATE	FOR THE BIVARIATE MODEL						*
*																	*
********************************************************************/

%macro cvparsbivar(covariate=, cvtype=, cveffect=,
				cset1=, cset2=, cset3=, cset4=, 
				cspa1=, cspa2=, cspa3=, cspa4=);

	/* set global variable metadas to 0 to begin with */
	%let metadas=0;

	/* A:
	INITIALISE MACRO  VARIABLES */
	/* initialise these macro variables as null or with the appropriate 
	estimate statement for the reference category if categorical covariate
	otherwise if continuous nlevels= 1 */

	%let csenslist0 = ;
	%let cspeclist0 = ;
	%let plist0 = ;
	%let secv0 = ;
	%let spcv0 = ;
	%let estmuA0= ;
	%let estmuB0= ;
	
	%let lnSens0= log( exp(msens)/(1+exp(msens)))%str(;);
	%let lnSpec0= log(exp(mspec)/(1+exp(mspec)))%str(;);
	%let lnDOR0= log((exp(msens)/(1+exp(msens)))/(1-(exp(msens)/(1+exp(msens))))/
				((1-(exp(mspec)/(1+exp(mspec))))/(exp(mspec)/(1+exp(mspec)))))%str(;);
	%let estDOR0 = estimate 'logDOR_0' &lnDOR0;
	%let estLRp0= estimate 'logLR+_0' log((exp(msens)/(1+exp(msens)))/(1-(exp(mspec)/(1+exp(mspec)))))%str(;);
	%let estLRn0= estimate 'logLR-_0' log((1-(exp(msens)/(1+exp(msens))))/(exp(mspec)/(1+exp(mspec))))%str(;);
	%let estAlphaCvL0= ;
	%let estThetaCvL0= ;
	%let estMuACvL0= ;
	%let estMuBCvL0= ;
	%let estRDOR0 = ;
	%let estRelSens0 = ;
	%let estRelSpec0 = ;

	
	/* B:
	CREATE PARAMETERS AND ESTIMATE STATEMENTS AND REGRESSION EQUATION*/
	/* For each level of the covariate (except the reference level) create parameters for 
	msens and/or mspec */
	%do I = 1 %to &nlevels;
		%let j = %eval(&I - 1);
	
		/* msens */
		%let msens=%str(msens_cv&I);
		%if %superq(cset&I) = %str() %then %let psens=&msens=0; /* simply use zero as starting value for
																the additional parameter if none is given */
		%else %let psens=&msens=%superq(cset&I);
	
		/* mspec */
		%let mspec=%str(mspec_cv&I);
		%if %superq(cspa&I)=%str() %then %let pspec=&mspec=0; /* simply use zero as starting value for
																the additional parameter if none is given */
		%else %let pspec=&mspec=%superq(cspa&I) ;
	
		/*create string of parameters with their starting values 
		also create lists for contrasts statements*/ 
		%if %upcase(&cveffect)=SESP or &cveffect=%str() %then %do; /*effect on the 2 parameters */
			%let plist= &psens &pspec;
			%let csens = &msens;
			%let cspec = &mspec;
		%end;
		%else %if %upcase(&cveffect)=SE %then %do; /* covariate effect on sensitivity only*/
			%let plist=&psens;
			%let csens = &msens;
			%let mspec=0; 
			%let cspec= ;
		%end;
		%else %if %upcase(&cveffect)=SP %then %do; /* covariate effect on specificity only*/
			%let plist=&pspec;
			%let cspec = &mspec;
			%let msens=0; 
			%let csens= ;
		%end;

		%let %str(plist&I)= %superq(plist&j) &plist; /* build string of parameters and their 
													 starting values */
	
		%if &I ~= &nlevels %then %do;
			%let %str(csenslist&I)= %superq(csenslist&j) msens+&csens,; /* for use with contrast statement build string 
													of parameters without their starting values */
			%let %str(cspeclist&I)= %superq(cspeclist&j) mspec+&cspec,;
		%end;
		%else %do;
			%let %str(csenslist&I)= %superq(csenslist&j) msens+&csens;
			%let %str(cspeclist&I)= %superq(cspeclist&j) mspec+&cspec;
		%end;
		
		/* Now to create estimate statements for the additional parameters */
		%if %upcase(&cvtype)=CON %then %do;
			/*%let lname3 = %str(sensitivity for a unit change in cv1);
			%let lname4 = %str(specificity for a unit change in cv1);*/
			%let trueposORTitle = %str(True positive log odds ratio  1);
			%let truenegORTitle = %str(True negative log odds ratio  1);
			%let RDORTitle = %str(logRDOR 1);
			%let RSensTitle = %str(logRelative sensitivity 1);
			%let RSpecTitle = %str(logRelative specificity 1);		
		%end;
		%else %do;
			/*%let lname3 = %str(sensitivity cv level &I);
			%let lname4 = %str(specificity cv level &I); */
			%let trueposORTitle = %str(True positive log odds ratio  cv level &I vs 0);
			%let truenegORTitle = %str(True negative log odds ratio  cv level &I vs 0);
			%let RDORTitle = %str(logRDOR cv level &I vs 0);
			%let RSensTitle = %str(logRelative sensitivity cv level &I vs 0);
			%let RSpecTitle = %str(logRelative specificity cv level &I vs 0);
		%end;
		%let ElogitSeTitle = %str(msens_&I);
		%let ElogitSpTitle = %str(mspec_&I);
		%let DORTitle = %str(logDOR_&I);
		%let LRposTitle = %str(logLR+_&I);
		%let LRnegTitle = %str(logLR-_&I);
		%let alphaTitle = %str(Lambda_&I);
		%let thetaTitle = %str(Theta_&I);	
		%let betatitle = %str(beta_&I);
		%let compse = %str(Pooled test for sensitivity);
		%let compsp = %str(Pooled test for specificity);

		%let estA = estimate "&trueposORTitle" &msens;

		%let estB = estimate "&truenegORTitle" &mspec;

		/* estimates of average operating points and relative measures */
		/* The statements preceded by log could be simplified but leaving them so that it is 
		obvious to anyone inspecting or modifying the macro what the function is and that the 
		estimates have been obtained on the log scale */

		%let estlnD = log(((exp(msens+&msens)/(1+exp(msens+&msens)))/(1-(exp(msens+&msens)/(1+exp(msens+&msens)))))
					/((1-(exp(mspec+&mspec)/(1+exp(mspec+&mspec))))/(exp(mspec+&mspec)/(1+exp(mspec+&mspec)))));

		%let estD = estimate "&DORTitle" &estlnD;

		%let estRD = estimate "&RDORTitle" &estlnD - &lnDOR0;

		%let estLnSens = log(exp(msens+&msens)/(1+exp(msens+&msens)));

		%let estRSens = estimate "&RSensTitle" &estLnSens - &lnSens0;

		%let estLnSpec = log(exp(mspec+&mspec)/(1+exp(mspec+&mspec)));

		%let estRSpec = estimate "&RSpecTitle" &estLnSpec - &lnSpec0;

		%let estLp = estimate "&LRposTitle" log((exp(msens+&msens)/(1+exp(msens+&msens)))/(1-(exp(mspec+&mspec)/(1+exp(mspec+&mspec)))));

		%let estLn = estimate "&LRnegTitle" log((1-(exp(msens+&msens)/(1+exp(msens+&msens))))/(exp(mspec+&mspec)/(1+exp(mspec+&mspec))));

		%let estAlphaL = estimate "&alphaTitle" ((s2uspec/s2usens)**0.25 *(msens+&msens)+(s2usens/s2uspec)**0.25*(mspec+&mspec))
				- ((s2uspec/s2usens)**0.25 * msens+(s2usens/s2uspec)**0.25 *mspec); /* compute alpha for a covariate level other than the reference */
		
		%let estThetaL = estimate "&thetaTitle" (0.5*((s2uspec/s2usens)**0.25 * (msens+&msens)-(s2usens/s2uspec)**0.25*(mspec+&mspec)))
				- (0.5*((s2uspec/s2usens)**0.25*msens - (s2usens/s2uspec)**0.25 * mspec)); /* compute theta for a covariate level other than the reference */
		
		%let estMuAL = estimate "&ElogitSeTitle" msens+&msens; /* elogit(sens) for each level of the covariate */  

		%let estMuBL = estimate "&ElogitSpTitle" mspec+&mspec; /* elogit(spec) for each level of the covariate  */
		
		
		/* Now need to build expressions used in the regression equation and estimate statements*/
		%if %eval(&I < &nlevels) %then %do; 
			%let secv= (&msens * %str(cv&I)) +; /* for expression involving sensitivity */
			%let spcv= (&mspec * %str(cv&I)) +; /* for expression involving specificity */
			%let estmuA = %str(&estA) %str(;);
			%let estmuB = %str(&estB) %str(;);	
			%let estDOR = %str(&estD) %str(;);
			%let estRDOR = %str(&estRD) %str(;);
			%let estRelSens = &estRSens %str(;);			
			%let estRelSpec = &estRSpec %str(;);
			%let estLRp = %str(&estLp) %str(;);
			%let estLRn = %str(&estLn) %str(;);
			%let estAlphaCvL = %str(&estAlphaL) %str(;);
			%let estThetaCvL = %str(&estThetaL) %str(;);
			%let estMuACvL = %str(&estMuAL) %str(;);
			%let estMuBCvL = %str(&estMuBL) %str(;);
		%end;
		%else %do;
			%let secv=(&msens * %str(cv&I));			
			%let spcv=(&mspec * %str(cv&I));
			%let estmuA = &estA;
			%let estmuB = &estB;
			%let estDOR = &estD;
			%let estRDOR = &estRD;
			%let estRelSens = &estRSens;			
			%let estRelSpec = &estRSpec;
			%let estLRp = &estLp;
			%let estLRn = &estLn;
			%let estAlphaCvL = &estAlphaL;
			%let estThetaCvL = &estThetaL;
			%let estMuACvL = &estMuAL;
			%let estMuBCvL = &estMuBL;
		%end;

		%let %str(secv&I) = &&secv&j &secv; /* concatenate expressions */
		%let %str(spcv&I) = &&spcv&j &spcv;	
		%let %str(estmuA&I) = &&estmuA&j  &estmuA;
		%let %str(estmuB&I) = &&estmuB&j  &estmuB;
		%let %str(estDOR&I)= &&estDOR&j  &estDOR;
		%let %str(estRDOR&I)= &&estRDOR&j  &estRDOR;
		%let %str(estRelSens&I)= &&estRelSens&j  &estRelSens;
		%let %str(estRelSpec&I)= &&estRelSpec&j  &estRelSpec;
		%let %str(estLRp&I)= &&estLRp&j  &estLRp;
		%let %str(estLRn&I) = &&estLRn&j  &estLRn;
		%let %str(estAlphaCvL&I)= &&estAlphaCvL&j  &estAlphaCvL;
		%let %str(estThetaCvL&I)= &&estThetaCvL&j  &estThetaCvL;
		%let %str(estMuACvL&I)= &&estMuACvL&j  &estMuACvL;
		%let %str(estMuBCvL&I)= &&estMuBCvL&j  &estMuBCvL;
		run;
	%end;

	/* Put parameter list together and the equation and contrast statements*/
	%let j = %eval(&I - 1);
	%let cvparamlist = %superq(plist&j);

	%if %upcase(&cveffect)=SESP or &cveffect=%str() %then %do;
		%let logitp = (msens + usens + %superq(secv&j))*sens +(mspec + uspec + %superq(spcv&j)) * spec;
		%let contrastse = contrast "&compse" msens, %superq(csenslist&j);
		%let contrastsp = contrast "&compsp" mspec, %superq(cspeclist&j);
	%end;
	%else %if %upcase(&cveffect)=SE %then %do;
		%let logitp = (msens + usens + %superq(secv&j))*sens +(mspec + uspec) * spec;
		%let contrastse = contrast "&compse" msens, %superq(csenslist&j);
		%let contrastsp= ;
	%end;
	%else %if %upcase(&cveffect)=SP %then %do;
		%let logitp = (msens + usens)*sens +(mspec + uspec + %superq(spcv&j)) * spec;
		%let contrastsp = contrast "&compsp" mspec, %superq(cspeclist&j);
		%let contrastse= ;
	%end;
	

	/* no contrast statements if covariate is continuous  */
	/*%if %upcase(&cvtype)= CON %then %do;		
		%let contrastse= ;
		%let contrastsp= ;
	%end;*/

	%let estmuAcv = &&estmuA&j;
	%let estmuBcv = &&estmuB&j;	
	%let estDOR = &&estDOR&j;
	%let estRDOR = &&estRDOR&j;
	%let estRelSens = &&estRelSens&j;
	%let estRelSpec = &&estRelSpec&j;
	%let estLRpos = &&estLRp&j;
	%let estLRneg = &&estLRn&j;
	%let estAlpha = &&estAlphaCvL&j;
	%let estTheta = &&estThetaCvL&j;
	%let estMuAlevels= &&estMuACvL&j;
	%let estMuBlevels= &&estMuBCvL&j;
	
	run;

	/* if macro execution is not terminated prematurely due to an error of 
	some sort then set global variable metadas to 1, i.e., successful execution so far */
	%let metadas=1;

%mend;


/********************************************************************
*																	*
* 		CREATE DATA SETS FOR OUTPUT OF BIVARIATE MODEL RESULTS		*							
*																	*
********************************************************************/

/* NOTE: similar to hsrocout especially to begin with and could have modified 
it to output both models but maybe more readable and manageable separately */

%macro bivarout(covariate=, cvtype=, cveffect=, cvsummorder=, byvar=);

	/* set global variable metadas to 0 to begin with */
	%let metadas=0;

	%put %str(************************);
	%put %str(CREATE TABLES OF RESULTS);
	%put %str(************************); 

	/* create blank data set for storing SeElogitSe, SeElogitSp, CovEs and 
	number of studies */
	%createds();
	run;

	%do k=1 %to &bylevels;

		/* if there is a BY variable get the name of the current test or by category. 
		If no BY variable but test is specified then use the name of the test */ 
		%if &byvar ~= %str() %then %do;
			data _null_;
			   	set _metadas_&byvar;
				if bylevels=&k then call symput('bylevelname', &byvar);
			run;
		%end;
		%else %if &byvar=%str() and &test ~= %str() %then %do;
			%let bylevelname=&test;
		%end;
		%else %if &byvar=%str() and &test = %str() %then %do;
			%let bylevelname=%str(test);
		%end;

		%if %sysfunc(exist(_metadas_ds&k)) %then %do;
			data _null_;
				set _metadas_ds&k nobs=numobs;
				call symput('numobs',numobs);
			run;
			%let nstudies = %eval(&numobs/2);
		%end;

		/* Give each estimate in the additional estimates table 
		a unique identifier if the table exists*/
		%if %sysfunc(exist(_metadas_a_addest_&k)) and %sysfunc(exist(_tb_se)) %then %do;

			data _metadas_a_addest_&k;
				set _metadas_a_addest_&k;
				id=_n_;
			run;

			/* get exponents of logDOR, logLR- and logLR+.
			Append to additional estimates table (_a_addest_&k) */
			data _metadas_a_addest_temp (drop=Label);
				length newlabel $ 14;
				set _metadas_a_addest_&k;
				substr(label,1,3)='';
				newlabel=left(trim(label));
				expestimate=exp(estimate);
				explower=exp(lower);
				expupper=exp(upper);
				where label contains 'logL' or label contains 'logD';
				rename Estimate = LogEstimate
						lower = LogLower
						upper = LogUpper;
				StandardError=.;
				tValue=.;
				Probt=.;
				output;
			run;

			data _metadas_a_addest_temp (drop=LogEstimate LogLower LogUpper);
				set _metadas_a_addest_temp;
				rename newlabel=Parameter
						expestimate = Estimate
						explower = Lower
						expupper = Upper;
			run;

			/* get the inverse transformation of logit sensitivity and specificity */
			data _metadas_a_pe_sesp;
				length Parameter $ 14;
				set _metadas_a_pe_&k;
				invlogitestimate=exp(estimate)/(1 + exp(estimate));
				invlogitlower=exp(lower)/(1 + exp(lower));
				invlogitupper=exp(upper)/(1 + exp(upper));
				where Parameter = 'msens' or Parameter = 'mspec';
				rename Estimate = LogitEstimate
						Lower = LogitLower
						Upper = LogitUpper;
				StandardError=.;
				tValue=.;
				Probt=.;
				if Parameter = 'msens' then Parameter = 'Sensitivity';
				else if Parameter = 'mspec' then Parameter = 'Specificity';
				output;
			run;

			data _metadas_a_pe_sesp (drop=LogitEstimate LogitLower LogitUpper);
				set _metadas_a_pe_sesp;
				rename 	invlogitestimate = Estimate
						invlogitlower = Lower
						invlogitupper = Upper;
			run;

			/* Create data set of measures of test accuracy */
			data _metadas_a_tmp_summst_&k (keep=parameter estimate lower upper);
				set _metadas_a_pe_sesp _metadas_a_addest_temp;
			run;
			
			%if %sysfunc(exist(_metadas_a_addest_temp)) %then %do;
				proc datasets memtype=data nodetails nolist; 
					delete _metadas_a_addest_temp; 
				run;
				quit;
			%end;

			%if %sysfunc(exist(_metadas_a_pe_sesp)) %then %do;
				proc datasets memtype=data nodetails nolist; 
					delete _metadas_a_pe_sesp; 
				run;
				quit;
			%end;

			/* Get the standard error for msens and mspec.
		     They should be in the first 2 rows of the table */
		    data _null_;
			   	set _metadas_a_pe_&k;
				if Parameter='msens' then call symput('SeELogitSe', StandardError);
				else if Parameter='mspec' then call symput('SeELogitSp', StandardError);
			run;

			data _metadas_a_tmp_se_&k;
			   	set _tb_se;
				SeELogitSe=symget('SeElogitSe');
				SeELogitSp=symget('SeElogitSp');
				Studies=resolve('&nstudies');
			run;

			/*Get the covariance CovEs */
			data _null_;
			   	set _metadas_a_covparmest_&k;
				if row=1 then call symput('CovEs', mspec);
				stop;
			run;

			data _metadas_a_tmp_se_&k;
			   	set _metadas_a_tmp_se_&k;
				CovEs=symget('CovEs');
			run;

			/* _tb_nocvse_&k is a wide format so transpose */
			proc transpose data=_metadas_a_tmp_se_&k out=_metadas_a_tmp_se_&k;
			run;

			data _metadas_a_tmp_se_&k(drop = _NAME_);
				set _metadas_a_tmp_se_&k;
				label _LABEL_= 'Parameter'
						COL1= 'Estimate';
			run;

			/* Create data set of alternative model parameters, i.e., if method is 
			bivariate then obtain data set of HSROC model parameters */
			data _metadas_a_tmp_statpms_&k(drop=alpha df id);
			   	set _metadas_a_addest_&k;
				rename tValue = z
						Probt = Probz
						label= Parameter;
				label tValue = 'z'
						Probt = 'Pr > |z|';
				where id > 4; 
			run;

			/* get corr(logits) from additional estimates table 
			and append to parameter estimates table */
			data _metadas_a_tmp_corr_&k(drop=id);
			   	set _metadas_a_addest_&k;
				where label = 'Corr(logits)';
				rename label = Parameter; 
			run;

			data _metadas_a_pe_&k;				
				length Parameter $ 14;
			   	set _metadas_a_pe_&k;
			run;

			data _metadas_a_pe_&k;
			   	set _metadas_a_pe_&k _metadas_a_tmp_corr_&k;
			run;

			data _metadas_a_pe_&k(drop=Alpha DF);
			   	set _metadas_a_pe_&k;
				format RM_Name $char14.;
				rename tValue = z
						Probt = Probz;
				label tValue = 'z'
						Probt = 'Pr > |z|';
				RM_Name=Parameter;
				select (Parameter);
						when ('msens')
							do;
							RM_Name='E(logitSe)';
							end;
						when ('mspec')
							do;
							RM_Name='E(logitSp)';
							end;
						when ('s2usens')
							do;
							RM_Name='Var(logitSe)';
							end;
						when ('s2uspec')
							do;
							RM_Name='Var(logitSp)';
							end;
						when ('covsesp')
							do;
							RM_Name='Cov(logits)';
							end;
						when ('Corr(logits)')
							do;
							RM_Name='Corr(logits)';
							end;
						otherwise
							do;	
							end;
						end;
			run;
		%end;
		%else %do;
			%put The data set _metadas_a_addest_&k and/or _tb_se does not exist.;
		%end;
		
		/* if we have a covariate create a table with the estimates we need for the bivariate model
		in Revman */
		%if &covariate ~= %str() %then %do;
					
			/* Get parameter estimates */
			%if %sysfunc(exist(_metadas_cv_pe_&k)) %then %do;
				data _metadas_cv_pe_all_ds&k(drop=Alpha DF);
					set _metadas_cv_pe_&k;
					id=_n_;	
					rename tValue=z
							Probt=Probz;
					label tValue = 'z'
						Probt = 'Pr > |z|';
				run;

				/* Get parameter estimates for level 0*/
				data _metadas_cv_pe_cv0_ds&k (drop=Gradient);
					length Parameter $ 14;
					set _metadas_cv_pe_all_ds&k;
					where id between 1 and 5;	
				run;

				/* Get s2usens, s2uspec and covsesp as we are not estimating these for each level */
				data _tb_s2u_&k (drop=Gradient);
					length Parameter $ 14;
		   			set _metadas_cv_pe_all_ds&k;
					where id between 3 and 5;	
				run;
			%end;
			%else %do;
				%put %str(MODEL FAILURE: Parameter estimates for &bylevelname with covariate &covariate were not produced.
						This may be due to failure to converge or other issues with the model and/or data.);
			%end;

			%if %sysfunc(exist(_metadas_cv_addest_&k)) %then %do;

					data _metadas_cv_ae_all_ds&k(drop=Alpha DF);
						set _metadas_cv_addest_&k;
						id=_n_;	
						relativestat=.;
						rename tValue=z
							Probt=Probz;
						label tValue = 'z'
							Probt = 'Pr > |z|';
					run;

					/* might be useful to have the correlation too 
					in the parameter estimates table so get it and
					append to the variances */
					data _metadas_tmp_corr_cv_&k;
			   			set _metadas_cv_ae_all_ds&k;
						where id =1;
						rename label = Parameter;						
					run;

					data _tb_s2u_&k;
			   			set _tb_s2u_&k _metadas_tmp_corr_cv_&k;
					run;
				
					data _metadas_cv_pe_cv0_ds&k;
			   			set _metadas_cv_pe_cv0_ds&k _metadas_tmp_corr_cv_&k;
					run;

					proc datasets;
						delete _metadas_tmp_corr_cv_&k;
					run;
					quit;
				
					/* create a variable to identify relative values such as RDOR, relative sens and spec
					and change in sens and spec */
					data _metadas_cv_ae_rel_ds&k;
						set _metadas_cv_ae_all_ds&k;
						relativestat=1;	
						where label contains "True" or label contains "RDOR" or label contains "Relative";
					run;

					/* now merge with the data set containing all the additional parameters */
					proc sort data = _metadas_cv_ae_rel_ds&k;
						by id;
					run;

					proc sort data = _metadas_cv_ae_all_ds&k;
						by id;
					run;

					data _metadas_cv_ae_all_ds&k;
	   					merge _metadas_cv_ae_all_ds&k _metadas_cv_ae_rel_ds&k;
	   					by id;
	   				run;	

					data _metadas_cv_ae_cv0_ds&k;
		   				set _metadas_cv_ae_all_ds&k;
						where (label contains "0" or id between 2 and 6) 
								and relativestat~=1;	
					run;
			%end;
			%else %do;
				%put %str(MODEL FAILURE: Additional estimates for &bylevelname with covariate &covariate were not produced. 
						This may be due to failure to converge or other issues with the model and/or data.);
			%end;

			%do j=0 %to &nlevels;

				/* reset these macro variables to zero */
				%let numobs = 0;
				%let nstudies =0;

				/* get the number of studies for the level of the covariate */
				%if %upcase(&cvtype) ~= CON %then %do;
					data _tmp_;
			   			set _metadas_ds&k;
						where cvlevels=&j;	
					run;
					data _null_;
						set _tmp_ nobs=numobs;
						call symput('numobs',numobs);
					run;
					%let nstudies = %eval(&numobs/2); /* get number of studies for the covariate level */			
				%end;

				/* only do this if there's at least one study with the level */
				%if &nstudies > 0 or %upcase(&cvtype) = CON %then %do; 

					/* Get additional estimates for each level of the covariate */
					%if %sysfunc(exist(_metadas_cv_ae_all_ds&k)) %then %do;
						
						%if &j > 0 %then %do;
							data &dsprefixae&j&sub&k;
				   				set _metadas_cv_ae_all_ds&k;
								where label contains "&j" or id between 4 and 6;
							run;

							/* manipulate data sets in order to get parameter
							estimates for other levels of the covariate */
							data &dsprefixpe&j&sub&k;
								set _metadas_cv_ae_all_ds&k ;
								rename Label= Parameter;
								where Label contains "msens_&j" or Label contains "mspec_&j";
							run;

							/* append the data set above to the one containing the variances */
							data &dsprefixpe&j&sub&k;
								set &dsprefixpe&j&sub&k _tb_s2u_&k;
							run;
							
							data _temp_HSROCparms;
				   				set &dsprefixae&j&sub&k;
								where label contains "Lambda_&j" or label contains "Theta_&j";	
							run;
							data &dsprefixae&j&sub&k;
				   				set &dsprefixae&j&sub&k;
								if Label = "Lambda_&j" or Label = "Theta_&j" then delete;
							run;

							data &dsprefixae&j&sub&k;
								set _temp_HSROCparms &dsprefixae&j&sub&k;
							run;

							proc datasets;
								delete _temp_HSROCparms;
							run;
							quit;

						%end;

						/*Get the SE and covariance CovEs for msens and mspec
						first get the id from _metadas_ae_cv&j_&k which should match 
						the row number in the covariance matrix table. The standard
						error should be from row 1 and 2 of the data set.
						To get the covariance use the id for msens as the row
						and the id of mspec as the column */						
						
						/* if it is the reference level get the covariance from
						row 1 in mspec column of the covparmest table 
						otherwise get it from the covaddest table using the 
						generated column name */
						%if &j= 0 %then %do;
							data _null_;
							   	set &dsprefixpe&j&sub&k;
								if Parameter="msens" then do;
									call symput('SeELogitSe', StandardError);
								end;
								else if Parameter="mspec" then do;
									call symput('SeELogitSp', StandardError);
								end;
							run;
							data _null_;
							   	set _metadas_cv_covparmest_&k;
								if row=1 then call symput('CovEs', mspec);
								stop;
							run;
						%end;
						%else %do;
							data _null_;
							   	set &dsprefixae&j&sub&k;
								if label="msens_&j" then do;
									call symput('SeELogitSe', StandardError);
									call symput('sensid', id);
								end;
								if label="mspec_&j" then do;
									call symput('SeELogitSp', StandardError);
									call symput('specid', left(id));
								end;
							run;

							%let covcol = Cov&specid;

							data _null_;
							   	set _metadas_cv_covaddest_&k;
								if row=resolve('&sensid') then call symput('CovEs', resolve(&covcol));
							run;
						%end;

						data &dsprefixcov&j&sub&k;
						   	set _tb_se;
							SeELogitSe=symget('SeElogitSe');
							SeELogitSp=symget('SeElogitSp');
							CovEs=symget('CovEs');
							Studies=resolve('&nstudies');
						run;

						/* _tb_cov_cv&j_ds&k is a wide format so transpose */
						proc transpose data=&dsprefixcov&j&sub&k out=&dsprefixcov&j&sub&k;
						run;

						data &dsprefixcov&j&sub&k(drop = _NAME_);
							set &dsprefixcov&j&sub&k;
							label _LABEL_= 'Parameter'
									COL1= 'Estimate';
						run;

						/* just some tidying up of data sets */
						data &dsprefixae&j&sub&k;
			   				set &dsprefixae&j&sub&k;							
							orderno=_n_;
							cvgroup=&j;
							rename Label=Parameter;
						run;

						data &dsprefixpe&j&sub&k (keep=parameter estimate standarderror z probz lower upper);
			   				set &dsprefixpe&j&sub&k;
						run;	

						/* Create one table for estimates of summary statistics for all the levels of the covariate */
						%if &j = 0 %then %do;
							data _temp_msens;
				   				set &dsprefixpe&j&sub&k;
								where Parameter contains "msens" or Parameter contains "mspec";	
								cvgroup=0;
							run;
							data _metadas_cv_summary_&k;
								length Parameter $ 45;
								set _temp_msens _metadas_cv_ae_cv0_ds&k;
							run;

							proc datasets;
								delete _temp_msens;
							run;
							quit;

						%end;
						%if &j > 0 %then %do;
							data _metadas_cv_summary_&k ;
								set _metadas_cv_summary_&k &dsprefixae&j&sub&k;
							run;
						%end;
						/* only keep the first 6 observations in this data set, 
						i.e., the HSROC model parameters */
						data &dsprefixae&j&sub&k (keep=parameter estimate standarderror z probz lower upper); 
			   				set &dsprefixae&j&sub&k;
							where orderno < 6;
						run;		
					%end;
					%else %do;
						%put %str(MODEL FAILURE: Additional estimates for &bylevelname with covariate &covariate 
							were not produced. This may be due to failure to converge or other issues with the model and/or data.);
					%end;
				%end;
			%END;

			/* delete these intermediate tables */
			%if %sysfunc(exist(_metadas_cv_ae_rel_ds&k)) %then %do;
				proc datasets memtype=data nodetails nolist; 
					delete _metadas_cv_ae_rel_ds&k; 
				run;
				quit;
			%end;
			%if %sysfunc(exist(_metadas_cv_ae_all_ds&k)) %then %do;
				proc datasets memtype=data nodetails nolist; 
					delete _metadas_cv_ae_all_ds&k; 
				run;
				quit;
			%end;
			%if %sysfunc(exist(_metadas_cv_pe_all_ds&k)) %then %do;
				proc datasets memtype=data nodetails nolist; 
					delete _metadas_cv_pe_all_ds&k; 
				run;
				quit;
			%end;

			/* order the summary table as requested by the user 
			STAT (the default) will order by the summary statistic while level 
			just orders by the level of the covaraite so all stats
			grouped together for each level */
			%if %sysfunc(exist(_metadas_cv_summary_&k)) %then %do;

				/* get exponents of the true positve and true negative log odds ratios 
				logDOR, logRDOR, log relative sensitivity and specificity, logLR- and logLR+ 
				and rename them by searching for log and replacing with nothing. */
				data _tb_cvsummary_temp;
					set _metadas_cv_summary_&k;
					RegularExpressionId = prxparse('s/log |log//');
					call prxchange(RegularExpressionId, -1, parameter);
					expestimate=exp(estimate);
					explower=exp(lower);
					expupper=exp(upper);
					where parameter contains 'True' or parameter contains 'logL' or parameter contains 'logD' or parameter contains 'logR';
					rename Estimate = LogEstimate;
					rename lower = LogLower;
					rename upper = LogUpper;					
					output;
				run;

				data _tb_cvsummary_temp (drop=LogEstimate LogLower LogUpper);
					set _tb_cvsummary_temp;
					rename 	expestimate = Estimate
							explower = Lower
							expupper = Upper;
				run;

				data _metadas_cv_summary_&k;
					set _metadas_cv_summary_&k;				
					if parameter='msens_1' then call symput('SeID', id);
				run;

				%let idsens = %eval(&SeID -1); /* redo id for sens level 0 for ordering later */			
				%let idspec = %eval(&SeID + &nlevels); /* redo id for spec level 0 for ordering later */			

				data _metadas_cv_summary_&k;
					set _metadas_cv_summary_&k;				
					if parameter='msens' then id = resolve('&idsens');
					else if parameter='mspec' then id = resolve('&idspec');
				run;

				/* get the inverse transformation of logit sensitivity and specificity */
				%if %upcase(&cvtype)= CON %then %do;
					data _tb_cvsummary_temp2;
						set _metadas_cv_summary_&k;
						RegularExpressionId1 = prxparse("s/msens_1/Sensitivity for a unit change in covariate/");
						RegularExpressionId2 = prxparse("s/mspec_1/Specificity for unit change in covariate/");
						RegularExpressionId3 = prxparse("s/msens/Sensitivity for cv = 0/");
						RegularExpressionId4 = prxparse("s/mspec/Specificity for cv = 0/");
						call prxchange(RegularExpressionId1, -1, parameter);
						call prxchange(RegularExpressionId2, -1, parameter);
						call prxchange(RegularExpressionId3, -1, parameter);
						call prxchange(RegularExpressionId4, -1, parameter);
						invlogitestimate=exp(estimate)/(1 + exp(estimate));
						invlogitlower=exp(lower)/(1 + exp(lower));
						invlogitupper=exp(upper)/(1 + exp(upper));
						where parameter contains 'ms';
						sensspec=1;
						rename Estimate = LogitEstimate;
						rename Lower = LogitLower;
						rename Upper = LogitUpper;
						output;
					run;
				%end;
				%else %do;
					data _tb_cvsummary_temp2;
						set _metadas_cv_summary_&k;
						RegularExpressionId1 = prxparse("s/msens_/Sensitivity for cv level /");
						RegularExpressionId2 = prxparse("s/mspec_/Specificity for cv level /");
						RegularExpressionId3 = prxparse("s/msens/Sensitivity for cv level 0/");
						RegularExpressionId4 = prxparse("s/mspec/Specificity for cv level 0/");
						call prxchange(RegularExpressionId1, -1, parameter);
						call prxchange(RegularExpressionId2, -1, parameter);
						call prxchange(RegularExpressionId3, -1, parameter);
						call prxchange(RegularExpressionId4, -1, parameter);
						invlogitestimate=exp(estimate)/(1 + exp(estimate));
						invlogitlower=exp(lower)/(1 + exp(lower));
						invlogitupper=exp(upper)/(1 + exp(upper));
						where parameter contains 'ms';
						sensspec=1;
						rename Estimate = LogitEstimate;
						rename Lower = LogitLower;
						rename Upper = LogitUpper;
						output;
					run;
				%end;

				data  _tb_cvsummary_temp2 (drop=LogitEstimate LogitLower LogitUpper);
					set  _tb_cvsummary_temp2;
					rename 	invlogitestimate = Estimate
							invlogitlower = Lower
							invlogitupper = Upper;
				run;

				/* mark the log estimates so they can be deleted from the data set eventually 
				need to do it this way because can't use contains with if statement so create a temporary 
				data set and variable for the records to be deleted and then merge with the summary data set */
				data _tb_temp_&k;
					set _metadas_cv_summary_&k;
					fordelete=1;
					where parameter contains 'True' or parameter contains 'logL' 
						or parameter contains 'logD' or parameter contains 'logR'
						or parameter contains 'msens' or parameter contains 'mspec';
				run;

				proc sort data = _tb_temp_&k;
					by id;
				run;

				proc sort data = _metadas_cv_summary_&k;
					by id;
				run;

				data _metadas_cv_summary_&k;
   					merge _metadas_cv_summary_&k _tb_temp_&k;
   					by id;
   				run;

				/* delete the temporary data set */
				%if %sysfunc(exist(_tb_temp_&k)) %then %do;
					proc datasets memtype=data nodetails nolist; 
						delete _tb_temp_&k; 
					run;
					quit;
				%end;

				/* delete log estimates of parameters */
				data _metadas_cv_summary_&k;
					set _metadas_cv_summary_&k;
					if fordelete=1 then delete;
				run;

				/* append the transformed estimates to the rest of the summary data set */
				data _metadas_cv_summary_&k;
					set _metadas_cv_summary_&k _tb_cvsummary_temp2 _tb_cvsummary_temp;
				run;
				
				/* delete temporary data sets */
				%if %sysfunc(exist(_tb_cvsummary_temp)) %then %do;
					proc datasets memtype=data nodetails nolist; 
						delete _tb_cvsummary_temp; 
					run;
					quit;
				%end;

				%if %sysfunc(exist(_tb_cvsummary_temp2)) %then %do;
					proc datasets memtype=data nodetails nolist; 
						delete _tb_cvsummary_temp2; 
					run;
					quit;
				%end;

				/* If group is specified, items are listed in the table according 
				to covariate level. If stat is specified, items are listed 
				according to summary statistic such that all levels of the 
				covariate are grouped together for the statistic. */
				%if %upcase(&cvsummorder)= STAT or &cvsummorder = %str() %then %do;
					proc sort data = _metadas_cv_summary_&k;
						by id parameter;
					run;
				%end;
				%else %if %upcase(&cvsummorder)= LEVEL %then %do;
					proc sort data = _metadas_cv_summary_&k;
						by cvgroup;
					run;
				%end;

				/* create data set for summary statistics  */
				data _metadas_cv_statsummary_&k (keep=Parameter Estimate Lower Upper);
					set _metadas_cv_summary_&k;
					where (orderno > 5 and relativestat=.) or sensspec=1;		
				run;

				/* create data set for relative statistics*/
				data _metadas_cv_relsummary_&k (keep=Parameter Estimate Lower Upper Probz);
					set _metadas_cv_summary_&k;
					where relativestat=1;		
				run;

				%if %upcase(&cvtype)= CON %then %do;
					data _metadas_cv_relsummary_&k (drop=RegularExpressionId1);
						set _metadas_cv_relsummary_&k;
						RegularExpressionId1 = prxparse("s/ 1//");
						call prxchange(RegularExpressionId1, -1, parameter);
					run;
				%end;

				%if %sysfunc(exist(_metadas_cv_summary_&k)) %then %do;
					proc datasets memtype=data nodetails nolist; 
						delete _metadas_cv_summary_&k; 
					run;
					quit;
				%end;

			%end;
		%end;
	%end;

	/* if macro execution is not terminated prematurely due to an error of 
	some sort then set global variable metadas to 1, i.e., successful execution so far */
	%let metadas=1;

%mend;



