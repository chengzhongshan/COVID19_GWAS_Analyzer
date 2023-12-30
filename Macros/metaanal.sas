/* =========================================================
 
 This macro produces the Laird and DerSimonian weighted 
 average of betas given several betas and their variances.
 
 includes changes made by Polyna Khudyakova
(last change was done in August, 2015)
 
 also, allows loglinear or linear models;
 user to give conf bounds instead of coeff and var/se
 
 calculates measures of heterogeneity: R_I, CV_B and 
 newly developed Rb (Aug. 2015)
 ========================================================= */
   
%macro metaanal(
                coeff  = T,   /* whether giving coeff or OR/RR.
			       if OR/RR, no need for point est */
		beta   = beta,    /* Input betas  REQUIRED if COEFF=T */
                se_or_var = v, /* whether you are giving the macro the standard
				error (s) or the variances (v) of the coefficients
				if COEFF = T  */
				 varnamelcb  =,  /* variable name for lower confidence bound of OR/RR
						    if COEFF = F */
				 varnameucb  =,  /* variable name for upper confidence bound of OR/RR
						    if COEFF = F */
			/*  need to give either beta and var or se  OR 
			    varnamelcb and varnameucb */
				   var    = var,     /* variable name for variances */
                se     =se,       /* variable name for standard errors */
		data   = ,  /* Input data set  REQUIRED */
				       studylab = studylab,  /* labels for each study  REQUIRED */
		name   =,         /* Name of variable of interest  REQUIRED */
				   explabel=,        /* descriptive title of exposure  REQUIRED */
		outcomelabel=,    /* descriptive title of outcome  REQUIRED */
		wt     = 1,
		outdat =,   /* Output data set */
		pooltype=random,
		notes=nonotes,
		printcoeff=F,
                loglinear=t,  /* whether the underlying analysis is log-linear (logistic, 
			       phreg, log-binomial, poisson) or not */
		noprint =F,
                pvalueformat=pvalue6.4
		);
   
   /* upcasing true-false param */
%let coeff=%upcase(&coeff);
%let noprint=%upcase(&noprint);
%let printcoeff=%upcase(&printcoeff);
%let pooltype=%upcase(&pooltype);
%let loglinear=%upcase(&loglinear);
%let notes=%upcase(&notes);
%let se_or_var=%upcase(&se_or_var);
   
%local paramprob;
   /* deal with potential problems */
%if %length(&data) eq 0
   or  (%length(&beta) eq 0  and %length(&varnamelcb) eq 0 )
 /*
  or %length(&name) eq 0
  */
   or %length(&studylab) eq 0
   or (&pooltype ne FIXED and &pooltype ne RANDOM and &pooltype ne BOTH)
   or %length(&explabel) eq 0 or %length(&outcomelabel) eq 0
   or (&se_or_var ne S and &se_or_var ne V)
   %then %do;
      %let paramprob = 1;
      data _null_;
      %if %length(&data) eq 0 %then %do;
	 put 'ERR''OR in macro run:  No data set name was given for DATA';
	 %end;
      %if %length(&beta) eq 0 and %length(&varnamelcb) eq 0 %then %do;
	 put 'ERR''OR in macro run:  No variable name was given for BETA or VARNAMELCB';
	 %end;
      %if %length(&studylab) eq 0 %then %do;
	 put 'ERR''OR in macro run:  No value was given for STUDYLAB';
	 %end;
      %if "&pooltype" ne "FIXED" and "&pooltype" ne "BOTH" and "&pooltype" ne "RANDOM" %then %do;
	 put 'ERR''OR in macro call:  Method for pooling (POOLTYPE) (fixed, random, or both )';
	 put '   not specified.';
	 %end;
      %if %length(&explabel) eq 0 %then %do;
         put 'ERR''OR in macro call:  You did not describe the exposure in EXPLABEL';
         %end;
      %if %length(&outcomelabel) eq 0 %then %do;
         put 'ERR''OR in macro call:  You did not describe the outcome in OUTCOMELABEL';
         %end;
      put 'The macro will stop.';
      
      file print;
      %if %length(&data) eq 0 %then %do;
	 put 'ERR''OR in macro run:  No data set name was given for DATA';
	 %end;
      %if %length(&beta) eq 0 and %length(&varnamelcb) eq 0 %then %do;
	 put 'ERR''OR in macro run:  No variable name was given for BETA or VARNAMELCB';
	 %end;
      %if "&se_or_var" ne 'S' and "&se_or_var" ne 'V' %then %do;
	 put 'ERR''OR in macro call:  You did not specify whether you were';
	 put '      giving the macro the variances or the standard errors';
	 put '      of the coefficients.';
	 %end;
      %if "&se_or_var" eq "V" and %length(&var) eq 0 %then %do;
	 put 'ERR''OR in macro run:  No variable name was given for VAR';
	 %end;
      %if "&se_or_var" eq "S" and %length(&se) eq 0 %then %do;
	 put 'ERR''OR in macro run:  No variable name was given for SE';
	 %end;
      %if %length(&studylab) eq 0 %then %do;
	 put 'ERR''OR in macro run:  No value was given for STUDYLAB';
	 %end;
      %if "&pooltype" ne "FIXED" and "&pooltype" ne "BOTH" and "&pooltype" ne "RANDOM" %then %do;
	 put 'ERR''OR in macro call:  Method for pooling (POOLTYPE) (fixed, random, or both )';
	 put '   not specified.';
	 %end;
      %if %length(&explabel) eq 0 %then %do;
         put 'ERR''OR in macro call:  You did not describe the exposure in EXPLABEL';
         %end;
      %if %length(&outcomelabel) eq 0 %then %do;
         put 'ERR''OR in macro call:  You did not describe the outcome in OUTCOMELABEL';
         %end;
      put 'The macro will stop.';
%end;
   
%if %length(&wt) eq 0 %then %do;  %let wt=1;
   data _null_;
   put "WARN" "ING in macro run:  WT (the change of interest in &var was set to 1" ;
   run;
   %end;
   
%if %length(&outdat) eq 0 %then %do;
   %if &noprint ne F %then %do;
      data _null_;
      put 'WARN''ING in macro run:  NOPRINT was not set to F, but no';
      put '       value was given for OUTDAT.';
      put 'The macro set NOPRINT to F.';
      file print;
      put 'WARN''ING in macro run:  NOPRINT was not set to F, but no';
      put '       value was given for OUTDAT.';
      put 'The macro set NOPRINT to F.';
      run;
      %end;
%end;
   
   
   
%if &paramprob eq 1 %then %goto errend;
   
   
   options  &notes nosyntaxcheck formdlim='-';
   
data _datlist_;  set &data  end=_end_ ;
   retain _nse _nvar _nbeta 0;
%if "&loglinear" eq "T" %Then %do;
%if "&coeff" eq "T" %then %do;
   beta=&beta;
   %if "&se_or_var" eq "V" %then %do;  var=&var;   se=sqrt(&var);  %end;
   %else %do;  se=&se;  var=&se * &se ;  %end;
   odr=exp(&wt*&beta);
   lor=exp(&wt*(&beta-1.96*se));
   uor=exp(&wt*(&beta+1.96*se));
%end;
%if "&coeff" eq "F" %then %do;
   beta=mean(log(&varnameucb), log(&varnamelcb) );
   se=(log(&varnameucb)-beta)/1.96;  var=se * se ;
   odr=exp(&wt * &beta);
   lor=&varnamelcb;
   uor=&varnameucb;
%end;
   label se='std error of study coefficient'  odr='study OR/RR'  lor='study lower 95% CL for OR/RR'
      uor='study upper 95% CL for OR/RR'
      beta='study coefficient'  var='variance of study coefficient'
      ;
%end;
%else %do;  /* loglinear=f */
   %if "&coeff" eq "T" %then %do;
      beta=&beta;
      %if "&se_or_var" eq "V" %then %do;  var=&var;  se=sqrt(var);  %end;
      %else %do;  se=&se;  var=&se * &se ;  %end;
      %end;
   %if "&coeff" eq "F" %then %do;
      beta=mean(&varnameucb, &varnamelcb);
      se=(&varnameucb-beta)/1.96;  var=se*se;
      %end;
   label se='std error of study coefficient'
      beta='study coefficient'
      var = 'variance of study coefficient'
      ;
%end;
   if se ne . then _nse=_nse+1;  if var ne . then _nvar=_nvar+1;
   if &beta ne . then _nbeta=_nbeta+1;
   if _end_ then do;
      call symput('_nse', trim(left(_nse)));
      call symput('_nvar', trim(left(_nvar)));
      call symput ('_nbeta', trim(left(_nbeta)));
      end;
   run;
   
%if &_nse eq 0 or &_nvar eq 0 or &_nbeta eq 0 %then %do;
   data _null_;
   put 'ERR''OR in macro run:';
   put '    There is not enough information to do the metaanalysis';
   if &_nbeta eq 0 then put "    All values of the variable %upcase(&beta) are missing.";
   if &_nvar eq 0 then put "    All values of the variable %upcase(&var) are missing.";
   if &_nse eq 0 then put "    All values of the variable %upcase(&se) are missing.";
   file print;
   put '    There is not enough information to do the metaanalysis';
   if &_nbeta eq 0 then put "    All values of the variable %upcase(&beta) are missing.";
   if &_nvar eq 0 then put "    All values of the variable %upcase(&var) are missing.";
   if &_nse eq 0 then put "    All values of the variable %upcase(&se) are missing.";
   call symput ('paramprob', 1);
   run;
%end;
%if &paramprob eq 1 %then %goto errend;
   
proc iml;
   reset noname noprint spaces=0;
   
   use _datlist_;
   
   read all var{beta}   into beta;
   read all var{var}    into var;
   read all var{&studylab} into labels;
   
   dim = nrow(var);
   df = dim-1;
   
   odr = exp(&wt*beta);
   se = sqrt(var);
   ll = exp(&wt*beta-1.96*&wt*se);
   uu = exp(&wt*beta+1.96*&wt*se);
   lab = "str";
   
   w = (j(dim,1,1) /var);
   
   vsrf=1/sum(w);
   wfixed=w/sum(w);
   
   betaf = (wfixed`*beta) ;
   sef = sqrt(vsrf);
   blowf    = betaf - 1.96*sef;
   bhighf   = betaf + 1.96*sef;
   
   orf = exp(&wt*betaf);
   orlowf    = exp(&wt*blowf);
   orhighf   = exp(&wt*bhighf);
   
   zscoref = betaf / sef;
   chi2f   = zscoref*zscoref;
   pchi2f  = 1 - probchi(chi2f,1);
   
   
   wm = diag(w);
   q = (( beta - betaf )`)* wm * ( beta - betaf );
   phet = 1-probchi(q,df);
   
   tau2 = max(0,(q-(dim-1))/(sum(w) - (w`*w/sum(w)) ));
   sqsumw=w`*w;
   sumw=sum(w); 
   wrand = (j(dim,1,1) / ( var + tau2 ));
   vsrr= 1/sum(wrand);
   wrand = wrand/sum(wrand);
   betar = wrand`*beta ;
     
   ser  = sqrt(vsrr);
   blowr    = betar - 1.96*sqrt(vsrr);
   bhighr   = betar + 1.96*sqrt(vsrr);

***********************************;
*Aug. 2015 (PK);
***********************************;
ab=j(dim,1,0);
bb=j(dim,1,0);
rrb=j(dim,1,0);
   ab=var*(sum(w) - (w`*w/sum(w)));
www=(sum(w) - (w`*w/sum(w)));
rb=0;
dgq_b=1;
do i=1 to dim;
   rb=rb+tau2/(tau2+var[i]);
   bb[i,1]=1/((q+ab[i,1]-df)**2);
end;
rb=rb/dim;
   dgq_b=ab`*bb/dim;
   orr = exp(&wt*betar);
   orlowr    = exp(&wt*blowr);
   orhighr   = exp(&wt*bhighr);
   
   zscorer = betar / ser;
   chi2r   = zscorer*zscorer;
   pchi2r  = 1 - probchi(chi2r,1);
      
* Aug. 2015 (PK) added rb and dgq_b;
   create _out_ var{betaf betar sef ser blowf bhighf blowr bhighr zscoref zscorer chi2f chi2r pchi2f pchi2r
                    sqsumw sumw w tau2 orf orr orlowf orlowr orhighf orhighr q df phet 
                    rb dgq_b  fwt rwt vsrf vsrr dim};
   append;
   create _labs_ var{labels};
   append;
   
   
   quit;
   

%if &notes eq NOTES %then %do;
  proc print data=_labs_;  title2 '_labs_';  run;
  proc print data=_out_ (obs=5);  title2 'out';  run;
%end;
   
data _out1_;  set _out_;  if _n_ eq 1;
   call symput ('_tau2_', trim(left(tau2)));
   run;
   
   
   
data _labs_;
   set _labs_;
   length _name_ $20;
   _name_ = "study_"||left(put(_n_, z2.0));
proc transpose data=_labs_ out=_labs_;
   var labels;
   run;

%if &notes eq NOTES %then %do;
  proc print data=_labs_;  title2 '_labs_';  run;
%end;

   
data _summary_;
   * length name $35;
   merge _out1_ _labs_;
   drop _name_;
   if tau2 gt 0 or vsrf gt 0 then do;  r_i=tau2 / (tau2 + dim*vsrf);  pr_i=round(100*r_i, .1);  end;
   if betar ne 0 then do;  cv_betaw=sqrt(tau2) / abs(betar);
   pcv_betaw=round(100*cv_betaw, .1);
   end;
   call symput('r_i', trim(left(r_i)));
   call symput('pr_i', trim(left(pr_i)));
   call symput('cvbetaw', trim(left(cv_betaw)));
   call symput('pcvbetaw', trim(left(pcv_betaw)));
   call symput ('df', trim(left(df)));
   label 
      betaf='pooled coeff from fixed effects model'
      betar='pooled coeff from random effects model'
      sef='pooled SE from fixed effects model'
      ser='pooled SE from random effects model'
      blowf='pooled lower 95% CL for coeff from fixed effects model'  
      blowr='pooled lower 95% CL for coeff from random effects model'
      bhighf='pooled upper 95% CL for coeff from fixed effects model'  
      bhighr='pooled upper 95% CL for coeff from random effects model'
      zscoref='pooled z-score from fixed effects model'  
      zscorer='pooled z-score from random effects model'
      chi2f='pooled Chi-squared from fixed effects model'  
      chi2r='pooled Chi-squared from random effects model'
      pchi2f='p-value based on pooled Chi-squared from fixed effects model'  
      pchi2r='p-value based on pooled Chi-squared from random effects model'
      orf='pooled OR from fixed effects model'  
      orr='pooled OR from random effects model'
      orlowf='pooled lower 95% CL for OR from fixed effects model'  
      orlowr='pooled lower 95% CL for OR from random effects model'
      orhighf='pooled upper 95% CL for OR from fixed effects model'  
      orhighr='pooled upper 95% CL for OR from random effects model'
      q='Q-statistic'
      df='degrees of freedom for Q-statistic'
      phet='p-value for test of heterogeneity'
      r_i='between-studies fraction of variance'
      pr_i='between-studies percent of variance'
      cv_betaw='between-studies coeff of variance, as fraction'
      pcv_betaw='between-studies coeff of variance, as percent'
      tau2='estimate of between-studies variance'
      ;
   call symput('betar', trim(left(betar)));
   call symput('sqsumw', trim(left(sqsumw)));
   call symput('sumw', trim(left(sumw)));
   call symput('qstat', trim(left(q)));
   run;

%if &notes eq NOTES %then %do;
  proc print data=_summary_  (obs=5);  title2 '_summary_';  run;
%end;

   
data _datlist_;  set _datlist_;
   if var gt 0 then fwtx=1/var;
   if var gt 0 or &_tau2_ gt 0 then rwtx=1/(var+ &_tau2_);
   if var gt 0 then do;  w1=1/var;  w2=w1/var;  w3=w2/var;  end;
   run;

%if &notes eq NOTES %then %do;
  proc print;  title2 '_datlist_ first time';
%end;

   
proc means noprint data=_datlist_;  var fwtx rwtx w1 w2 w3 ;
   output  out=_sums_  sum=sumf sumr w1 w2 w3    n(fwtx)=numstud ;
   run;
   
data _datlist_;
   if _n_ eq 1 then set _sums_;  set _datlist_;
   fwt=fwtx/sumf;  rwt=rwtx/sumr;
   label fwt='weight in fixed effects model'
      rwt='weight in random effects model'
      ;
   run;
   
data _summary_;
   if _n_ eq 1 then set _sums_;  set _summary_;
   tau2=&_tau2_;
   ;
   betahat=betaf;  betahat2=betahat*betahat;
   betahatr=betar;  betahatr2=betahatr*betahatr;
   varq=2*(numstud-1) +4*(w1-w2/w1)*tau2 + 2*(w2-2*w3/w1 +w2**2/w1**2)*tau2*tau2;
   seq=sqrt(varq);
   if &qstat ne 0 then varlogq=varq/&qstat/&qstat;
   selogq=sqrt(varlogq);
   lclq=exp(log(&qstat)-1.96*selogq);  uclq=exp(log(&qstat)+1.96*selogq);
   qlow=max(0,&qstat-1.96*seq);  qhi=&qstat+1.96*seq;
   c1=numstud-1;  c2=numstud*&sqsumw/(&sumw*&sumw)-1;
   rilow=1-(c1-c2)/(&qstat-1.96*seq -c2);  rihi=1-(c1-c2)/(&qstat+1.96*seq -c2);
   varri=(c1-c2)**2 / (&qstat-c2)**4 * varq;
   lcri=r_i-1.96*sqrt(varri);   ucri=r_i+1.96*sqrt(varri);
   lclri=max(0,100*lcri);  uclri=min(100,100*ucri);
   rilow=max(0,100*rilow);  rihi=min(100,100*rihi);
   vartau2=varq/(w1-w2/w1)**2;
   if tau2 gt 0 then vartau=vartau2/4/tau2;
   if tau2 gt 0 then varcvb=vartau2/(4*tau2*betahatr2)+vsrr*tau2/(betahatr2*betahatr2);
   /*varlogcvb=varcvb/cv_betaw/cv_betaw;
   selogcvb=sqrt(varlogcvb);
   cvblow=exp(log(cv_betaw)-1.96*selogcvb);  cvbhi=exp(log(cv_betaw)+1.96*selogcvb);*/
   cvblow=max(0,cv_betaw-1.96*sqrt(varcvb));  cvbhi=cv_betaw+1.96*sqrt(varcvb);
* Aug. 2015 (PK);
   varrb=(dgq_b**2)*varq;
   lcrb=rb-1.96*sqrt(varrb);   ucrb=rb+1.96*sqrt(varrb);
   lclrb=max(0,100*lcrb);      uclrb=min(100, 100*ucrb);
   lrb=round(100*rb, .1);
   if _n_ eq 1 then do;
      call symput('qlow', trim(left(qlow)));
      call symput('qhi', trim(left(qhi)));
      call symput('rilow', trim(left(rilow)));
      call symput('rihi', trim(left(rihi)));
      call symput('cvblow', trim(left(cvblow)));
      call symput('cvbhi', trim(left(cvbhi)));
      call symput('lclq', trim(left(lclq)));
      call symput('uclq', trim(left(uclq)));
      call symput('lclri', trim(left(lclri)));
      call symput('uclri', trim(left(uclri)));
      call symput('lclrb', trim(left(lclrb)));
      call symput('uclrb', trim(left(uclrb)));
      call symput('lrb', trim(left(lrb)));
      end;
   run;
   
%if &notes eq NOTES %then %do;
  proc print data=_datlist_ (obs=5);  title2 'datlist';  run;
  title2;
%end;

   
data _null_;  set _out_;
   q=round(q, .0001);
   format phet &pvalueformat;
   length phetc $7.;  phetc=put(phet, &pvalueformat);
   call symput('phet', trim(left(phetc)));
   tau2=round(tau2, .0001);
   call symput ('tau2', trim(left(tau2)));
   run;
   
   title4 "Studies of &explabel and &outcomelabel";
   title5 'listing of input data';
proc print label data=_datlist_;
   %if "&loglinear" eq T %then %do;
      var &studylab &beta se &var odr lor uor fwt rwt;
      format odr lor uor fwt rwt 8.2;
      %end;
   %else %do;
      var &studylab &beta se fwt rwt;
      %end;
   run;
   
data _niceout_;  set _summary_;
   length shortname $10 varlabel $70 varvalue $60 varname $10 vv1 vv3 vv5 $8 vv2 vv4 $2 vv6 $1 ;
   pvalue=.;  format pvalue &pvalueformat;
   *modtype='f';
   %if "&loglinear" eq "T" %then %do;
      varname='orf';  varlabel='OR/RR from fixed effects model (95% CI)';
      shortname='OR/RR (F)';
      vv1=put(orf, 8.2);  vv2=' (';  vv3=put(orlowf, 8.2);  vv4=', ';  vv5=put(orhighf, 8.2);
      vv6=')';
      varvalue=compress(vv1) || vv2 || compress(vv3) || vv4 || compress(vv5) || vv6 ;
      %end;
   %else %do;
      varname='coefff';  varlabel='Coefficient from fixed effects model (SE)';
      shortname='Coeff';
      vv1=put(betaf, 8.4);  vv2=' (';  vv3=put(sef, 8.4);   vv4=', '; vv6=')';
      varvalue=compress(vv1) || ' ' || compress(vv2 || vv3 || vv6);
      %end;
   pvalue=pchi2f;
   output;
%if "&printcoeff" eq "T" %then %do;
   varname='betaf';  varlabel='Coefficient from fixed effects model';
   shortname='Coeff. (F)';  
   vv1=put(betaf, 8.2);  vv3=put(blowf, 8.2);  vv5=put(bhighf, 8.2);  vv4=', ';  vv6=')';
   varvalue=compress(vv1) || vv2 || compress(vv3) || vv4 || compress(vv5) || vv6 ;
   pvalue=pchi2f;
   output;
%end;
*modtype='r';
   %if "&loglinear" eq "T" %then %do;
      varname='orr';  varlabel='OR/RR from random effects model (95% CI)'; 
      shortname='OR/RR (R)';
      vv1=put(orr, 8.2);  vv2=' (';  vv3=put(orlowr, 8.2);  vv4=', ';  vv5=put(orhighr, 8.2);
      vv6=')';
      varvalue=compress(vv1) || vv2 || compress(vv3) || vv4 || compress(vv5) || vv6 ;
      %end;
   %else %do;
      varname='coeff';  varlabel='Coefficient from random effects model (SE)';
      shortname='Coeff';
      vv1=put(betar, 8.4);  vv2=' (';  vv3=put(ser, 8.4);  vv4=', ';  vv6=')';
      varvalue=compress(vv1) || ' ' ||compress(vv2 || vv3 || vv6);
      %end;
   pvalue=pchi2r;
   output;
%if "&printcoeff" eq "T" %then %do;
   varname='betar';  varlabel='Coefficient from random effects model';
   shortname='Coeff. (R)';
   vv1=put(betar, 8.2);  vv3=put(blowr, 8.2);  vv5=put(bhighr, 8.2);  vv4=', ';  vv6=')';
   varvalue=compress(vv1) || vv2 || compress(vv3) || vv4 || compress(vv5) || vv6 ;
   pvalue=pchi2r;
   output;
%end;
    /* statistics relating to heterogeneity */
   varname="qstat";  varlabel="Q-statistic for heterogeneity with &df degree(s) of freedom";
   shortname='Q';
   vv1=put(&qstat, 10.4); 
* The change below done by P. Khudyakov (July 21st, 2015);
*****************************************************************************************;
* Since it is assumed that Q statistics has Chi square distribution, 
which is skewed and by applying the Log-transformation, we can get approximately normal 
distribution and then to calculate CI as for normal distribution. 
When the value of Q is too small, the log-transformation does not work.
Therefore, to avoid further confusion, we decided to exclude CIs of Q from the output;
*****************************************************************************************;
/* vv3=put(&qlow, 10.4);  vv5=put(&qhi, 10.4);
   varvalue=compress(vv1)|| vv2 || compress(vv3) || vv4 || compress(vv5) || vv6 ;
*/
   varvalue=compress(vv1) ;
   pvalue=phet;
   output;
   varname=tau2;  varlabel='Estimate of between-studies variance (tau squared)';
   shortname='tau2';
   varvalue=left(put(tau2, 10.4));
   pvalue='.';
   output;
   if tau2 gt 1e-10 then do;
      varname='ri';  varlabel='Between-studies variance as a percent of total variance (r(i))';
      shortname='r(i)';
      vv1=put(&pr_i, 5.1);  vv3=put(&lclri, 5.1);  vv5=put(&uclri, 5.1);  vv4=', ';  vv6=')';
      varvalue=compress(vv1) || vv2 || compress(vv3) || vv4 || compress(vv5) || vv6 ;
      pvalue=.;
      output;
      varname='cvb';  varlabel='SQRT(Between-studies variance)/coeff. from random-effects model (CVB)';
      shortname='CVB';
      vv1=put(&cvbetaw, 7.3);  vv3=put(&cvblow, 7.3);  vv5=put(&cvbhi, 7.3);   vv4=', ';  vv6=')';
      varvalue=compress(vv1) || vv2 || compress(vv3) || vv4 || compress(vv5) || vv6 ;
      pvalue=.;
      output;
* Aug. 2015 (PK);
      varname='rb';  varlabel='New between-studies variance as a percent of total variance (r(b))';
      shortname='r(b)';
      vv1=put(lrb, 7.1);  vv3=put(&lclrb, 7.1);  vv5=put(&uclrb, 7.1);  vv4=', ';  vv6=')';
      varvalue=compress(vv1) || vv2 || compress(vv3) || vv4 || compress(vv5) || vv6 ;
      pvalue=.;
      output;
   end;
   
   *modtype='f';
   drop vv1-vv6;
   run;

%if &notes eq NOTES %then %do;
  proc print data=_datlist_  (obs=5);  run;
%end;
   
   
data _niceout_;  set _niceout_;
   label varlabel='Description'
      shortname='Statistic'
      varvalue='Value (95% CI)'
      pvalue='P'
      testing='Hypothesis being tested'
      pvaluec='P (testing hypothesis)'
      ;
   length pvaluec  $20  testing $75 ;
/*
   if varlabel eq: 'OR/RR' then do;
      pvaluec=put(pvalue, &pvalueformat) || '(Is OR/RR different from 1?)';
      testing='Is OR/RR  different from 1?';
      end;
*/
   if shortname eq: 'OR/RR (F)' then do;
      pvaluec=put(pvalue, &pvalueformat) || '(Is OR/RR different from 1?)';
      testing='Is OR/RR  different from 1? (Fixed effects model)';
      end;
   else if shortname eq: 'OR/RR (R)' then do;
      pvaluec=put(pvalue, &pvalueformat) || '(Is OR/RR different from 1?)';
      testing='Is OR/RR  different from 1? (Random effects model)';
      end;
   else if varname eq 'betaf' then  testing='Is coeff. different from 0? (Fixed effects model)';
   else if varname eq 'betar' then testing='Is coeff. different from 0? (Random effects model)';
   else if varlabel eq: 'Q' then do;
      pvaluec=put(pvalue, &pvalueformat) || '(Is there heterogeneity among the studies?)';
      testing='Is there heterogeneity among the studies?';
      end;
   else do;   pvaluec=' ';  testing=' ';  end;
   run;
   
%if &notes eq NOTES %then %do;
   proc print data=_niceout_ (obs=5);  title2 '_niceout_';  run;
   title2 ;
%end;
   
   
   title4 "Studies of &explabel and &outcomelabel";
   
proc print data=_niceout_ label ;  var shortname varvalue pvalue testing;
%if "&pooltype" eq "RANDOM" %then %do;
  where index(varlabel, 'fixed') le 0;
  %end;
%if "&pooltype" eq "FIXED" %then %do;
  where index(varlabel, 'random') le 0;
  %end;
proc print data=_niceout_ label ;  var shortname varlabel;
%if "&pooltype" eq "RANDOM" %then %do;
  where index(varlabel, 'fixed') le 0;
  %end;
%if "&pooltype" eq "FIXED" %then %do;
  where index(varlabel, 'random') le 0;
  %end;
   
   
   
%if %length(&outdat) ne 0 %then %do;
   data &outdat._d;  set _datlist_
   %if "&loglinear" eq T %then %do;
      (keep= &studylab &beta se &var odr lor uor fwt rwt)
      %end;
   %else %do;
      (keep= &studylab &beta se fwt rwt)
   %end;
;
run;
   data &outdat._p;  set _niceout_  (keep=shortname varvalue pvalue testing varlabel) ;  run;
%end;
   
proc datasets mt=data nolist;
   delete _niceout_ _summary_ _datlist_ _sums_ _out_ _labs_;  run;
   
%errend:
   options notes syntaxcheck;
%mend ;

