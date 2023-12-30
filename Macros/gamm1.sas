*Paper link;
*https://watermark.silverchair.com/jrsssb_61_2_381.pdf?token=AQECAHi208BE49Ooan9kkhW_Ercy7Dm3ZL_9Cf3qfKAc485ysgAAA14wggNaBgkqhkiG9w0BBwagggNLMIIDRwIBADCCA0AGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMkAebIOeSQqavUZk6AgEQgIIDEamwDFPGXs4FTB6VRA8tlXej8y6AOAXPBkY39KNliOI6OGXw6SD9Pq1qq-8fCkEeWaaX_Ob89kY_GpfkjYP_DHrj3yatI5opiitGqIKdo-2_P342gRYfI3Iui89C3BBr1kSAY8oUCyjiBFkJiq45k1NNNY4xejuhsH2m7eU2nxR3uzNNV0avO1_HvktNq8gnvJYKFBMttytbIEL83JX8ltYvtKVk8encJ5HilN7TvtVvoi6OMbd1y-9730zV1haSAskyDu5cud3SpjMpXtnscMSDtQq9igDFsmqd3hPNEzBSYnBVBst4sN3XTxxa6k-8dwtgkHkGxMXTpQ0wL_qgLm5iFLtZqtzXyvxBHYaWno9F2ik80JBnLhVHiA90i0v2yvRUYF7AaYW9H0iZdcGvxRYBee0p2-niHxnVkwlKTeRexXY0b1ougO1o0fCCiXEFQQ1W7E6SnE_6E68sSpyWJXS_q79RubGsj5vNAvSslk_TOnJSMK-0_DmWueaFNEQK-7ULAtgV-pvFgyUM5tD15XYhIVK4CGaPqjYLff0y-u0wxR5OUBFTnZ2kwZZ1oUf9UqYc2OFaJ_pil5YssnBfJjKZC0da9DDperR_RJ_SqL8DeD0Fn0cNzhMC9GbTtx5YSsPJ1CgTeB-ZE6rqGa7kT9YKFfEuE27SwhU2Z_brc8h17TLL7gMlsc4xLvIZ2CfN1nRr-bDxWqvkTTmw958Ro9HFu0QVo3nvde8FKyR0Zn2Whg7hMEeEuJbA27GD4U2uWqqyGfK4vZGk3XtlWoSRsqYKTFdGLw7QdC9ClvgKxf9NhpoXpmarzFO_ckZ14uVSwScnsAvZuoxUn1o8P7PO05lzDXzRLYgKWS3CYpWx1YuWMW2QGAS6XUILgCYI-WMaKFgiU56cABtxgGX3qIxtVsiZljMsUKifm7Xs2lTNgUUlH5xyBO4VqHdNTVR1RdyXVEYhciTaaghaSFnV0fevaqFNRB3i0jzU9y8KtOUFLkBCFKR11tkRPYzVFfxhrui-SsDmZEYi3UVR4sQBGa-lROkA;
*Read proc gampl, which does not consider correlated variance structure.;
*https://documentation.sas.com/doc/en/statcdc/14.2/statug/statug_hpgam_examples03.htm;

/* 
********************************************************************;

                         Macro name: %gamm1


        ~~~~~~~~ GENERALIZED ADDITIVE MIXED MODELS ~~~~~~~~
Lin, X and Zhang, D. (1999) Inference in generalized additive mixed models 
by using smoothing splines. JRSSB. 55(2):381-400

                             Version 1.0


                              Function: 

    This macro fits the following GAMM model to longitudinal data:
         
         E(yi|bi, Ui) = mui; Var(yi|bi, Ui) = phi ai^{-1} v(mui),

    g(mui) = X1*beta + f1(X21) + .. + fp(X2p) + Z1*b1i +..+ Zc*bci + Ui(tij),

  where beta is parametric fixed effects, fj(.) are smooth functions, bki
  is random effects, Ui(.) is a Gaussian process. Double penalized maximum
  likelihood is used to estimate beta, fj, while (modified) REML is used to
  estimate the variance components and/or phi under GLMM representation of GAMM. 



                          Macro developer: 

                       Daowen Zhang, Xihong Lin
                     Department of Biostatistics
                     The University of Michigan
                        Ann Arbor, MI 48109
                      E-mail: dzhang@umich.edu
                              xlin@sph.umich.edu


                   (C) Daowen Zhang, Xihong Lin
 
 
                        Date: Dec. 9, 1996


  Call statement:
                                           Default
  %gamm1(data=,                            {_Last_}
        dep=,
        dist=,                             {Normal}
        link=,
        dispers=,                          {Y}
        weight=,
        intinf1=,                          {N}
        offset=,
        fixed=,
        smthvar=,
        fitmod=,                           {Y}
        smooth=,
        method=,
        lintest=,
        vartest=,
        random=,
        type=,                             {sim}
        process=,
        time=,
        gt=,
        g1t=,
        g2t=,
        id=,
        maxiter=,                          {50}
        conv=,                             {0.00001}
        print=                             {Y}
        outbeta= 
        outbstd=  
        outvar=
        outvstd=
        outran= 
        outprs=                                                
        outsmth=  
        outband= 
        outlscor=
        outvscor=
        keeplast=                          {N}
        symsize=                           {1022976} 
        worksize=                          {1022976})

  where 
        data     = name of the data set to be used;
        dep      = dependent variable (y);
        dist     = distribution name for dependent variable;
        link     = link function g(.);
        dispers  = jointly etimate dispersion variance parameter (Y/N);
        weight   = weight variable in propertion of binomial distribution;
        intinf1  = whether or not to include intercept in f1(x);
        offset   = offset for Poisson regression;
        fixed    = fixed effects covariates (X1);  / s -- print the solution;
                   THERE MUST BE A SPACE BEFORE AND AFTER /!!
        smthvar  = covariate that needs smoothed (X2); if missing, 
                   a GLMM is fitted;
        fitmod   = Y/N -- whether or not fit the specified model; usefule when
                   only lineaity test or variance component test is desired;
        smooth   = 1/smoothing parameters, can be missing;
        lintest  = Y/N -- request the performance of linearity test based on
                   the score test statistics for the first covariate in X2, 
                   or the first covariate in X1 if smthvar is missing; The 
                   default is N; 
        vartest  =Y/N  
        method   = ML/REML -- Method to be used to fit the model; Default
                   is REML; ML is only effective if smthvar is missing;
        random   = random effects covariates (Z); The random effects
                   covariance matrix is assumed to be unstructured;  
                   /s -- print the solution;
        type     = type of the covariance matrix of the random effects;
                   sim/un;
        process  = name of the process: 
                   AR   --- AR(1); 
                   OU   --- Ornstein-Uhlenbeck process,
                   NOU1 --- Nonhomogeneous OU process with log-variance 
                            function: log(v(t)) = a0 + a1*g(t), where g(t) is
                            specified in gt,
                   NOU2 --- Nonhomogeneous OU process with log-variance 
                            function: log(v(t)) = a0 + a1*exp(alpha*t),
                   NOU3 --- Nonhomogeneous OU process with log-variance 
                            function: log(v(t)) = a0 + a1*t + a2*t^2,
                   NOU4 --- Nonhomogeneous OU process with log-variance 
                            function: log(v(t)) = a0 + a1*g1(t) + a2*g2(t),
                   NOU5 --- Nonhomogeneous OU process with variance 
                            function: v(t) = a0 + a1*t + a2*t^2,
                   NOU6 --- Nonhomogeneous OU process with variance 
                            function: v(t) = a0 + a1*g(t),
                   NOU7 --- Nonhomogeneous OU process with variance 
                            function: v(t) = a0 + a1*g1(t) + a2*g2(t), where
                            g1(t), g2(t) must be two pieces of curves,
                   IOU  --- Integrated OU process,
                   W    --- Wiener process (Brownian motion),
                   IW   --- Integrated Wiener process;

        time     = time variable representing the order of obs; not 
                   required for AR, but the data should be sorted by time; 
        gt       = g(t), the function in NOU1, defined by users. The default
                   is g(t) = t;  
        g1t      = g1(t) in NOU4 and NOU7;
        g2t      = g2(t) in NOU4 and NOU7;
        id       = identification variable for subjects; if missing, then the 
                   data are assumed to be independent;
        maxiter  = maximum number of iterations (maximum=100);
        conv     = convergence criterion using relative difference of the
                   likelihood;
        print    = flag requesting output for model fitting information and
                   variance components be printed (Y/N);
        outbeta  = output data set storing the estimates of beta;
        outbstd  = output data set of std of beta; 
        outvar   = output data set for smoothing parameter and
                   variance components;
        outvstd  = output data set for std of variance components;
        outran   = output data set storing the estimates of random effects;         
        outprs   = output data set storing the estimated Gaussian process;
        outsmth  = output data set storing the est of f(.) in 203 equally
                   spaced points, with two more boundary points added;
        outband  = output data set storing the est std and band for f(.) 
                   at the knots.
        outlscor = output data set storing the linearity test related info.
        outvscor = output data set storing the var comp test related info.  
        keeplast = keep the estimates at the last step.
        symsize  = size of symbolspace.
        worksize = size of workspace.
  

  Example:

    provided later.


  Reference: 

    provided later.

  CAUTION: 
    There must be at least 3 distinct tij's in order to fit f(.).
  Otherwise the program would crash.

*********************************************************************
*/


%macro gamm1(data=_last_, dep=, dist=, link=, dispers=, weight=, 
            intinf1=, offset=, fixed=, smthvar=, fitmod=, smooth=, 
            lintest=, vartest=, method=, random=, type=, process=, 
            time=, gt=, g1t=, g2t=, id=, maxiter=, conv=, parm=, 
            print=, outbeta=, outbstd=, outvar=, outvstd=, outran=,
            outprs=, outsmth=, outband=, outlscor=, outvscor=, 
            keeplast=, symsize=1022976, worksize=1022976); 

options replace;

/* Covert some key words to upper cases */ 

%let dist = %upcase(&dist);
%let link = %upcase(&link);
%let dispers = %upcase(&dispers);
%let lintest = %upcase(&lintest);
%let vartest = %upcase(&vartest);
%let method = %upcase(&method);
%if &method^=ML and &method^=REML %then
  %let method=REML;
%let type = %upcase(&type);
%let fitmod = %upcase(&fitmod);
%let process = %upcase(&process);
%let print = %upcase(&print);
%let time = %upcase(&time);
%let gt = %upcase(&gt);
%let g1t = %upcase(&g1t);
%let g2t = %upcase(&g2t);
%let intinf1 = %upcase(&intinf1);
%let keeplast = %upcase(&keeplast);

%if %length(&maxiter)=0 %then
  %let maxiter=50;

%if %length(&conv)=0 %then
  %let conv=0.0001;

%if %length(&type)=0 %then
  %let type=SIM;

%if %length(&print)=0 %then
  %let print=Y;

%if %length(&dispers)=0 %then
  %let dispers=Y;

%if %length(&intinf1)=0 %then
  %let intinf1=N;

%if %length(&lintest)=0 %then
  %let lintest=N;

%if %length(&vartest)=0 %then
  %let vartest=N;

%if %length(&method)=0 %then
  %let method=REML;

%if %length(&keeplast)=0 %then
  %let keeplast=N;

%if %length(&dist)=0 %then
  %let dist=NORMAL;

%if %length(&fitmod)=0 %then
  %let fitmod=Y;

%if &dist=NORMAL or &dist=GAMMA %then 
  %let dispers=Y;

%if &type^=SIM and &type^=UN %then
  %let type=SIM;

%if %length(&link)=0 %then %do;
  %if &dist=NORMAL %then 
    %let link=IDENTITY;
  %else %if &dist=BINOMIAL %then 
    %let link=LOGIT;
  %else %if &dist=POISSON %then
    %let link=LOG;
  %else %if &dist=GAMMA %then
    %let link=LOG;
%end;


%let canolink=0;
%if &dist=NORMAL and &link=IDENTITY %then 
  %let canolink=1;
%else %if &dist=BINOMIAL and &link=LOGIT %then 
  %let canolink=1;
%else %if &dist=POISSON and &link=LOG %then
  %let canolink=1;


/* See if stop the program */

%if %length(&data) = 0 %then %do;
  %put MNOTE: Data set is missing! ;
  %goto exit;
%end;
%else %if %length(&dep) = 0 %then %do;
  %put MNOTE: Dependent variable is missing! ;
  %goto exit;
%end;
%else %if %length(&process) ^= 0 %then %do;
  %if &process ^=AR and %length(&time) = 0 %then %do;
    %put MNOTE: Time variable for &process process is missing! ;
    %goto exit;
  %end;
  %if (&process=NOU4 or &process=NOU7) and 
      (%length(&g1t)=0 or %length(&g2t)=0) %then %do;
    %put MNOTE: g1(t) or g2(t) for &process process is missing! ;
    %goto exit;
  %end;    
%end;

%if &dist=NORMAL %then %do;
  %if &link^=IDENTITY %then %do;
    %put MNOTE: Program does not support &link link! ;
    %goto exit;
  %end; 
%end;
%else %if &dist=BINOMIAL %then %do;
  %if &link^=LOGIT and &link^=PROBIT and &link^=CLOGLOG %then %do;
    %put MNOTE: Program does not support &link link! ;
    %goto exit;
  %end; 
%end;
%else %if &dist=POISSON %then %do;
  %if &link^=LOG %then %do;
    %put MNOTE: Program does not support &link link! ;
    %goto exit;
  %end; 
%end;
%else %if &dist=GAMMA %then %do;
  %if &link^=LOG %then %do;
    %put MNOTE: Program does not support &link link! ;
    %goto exit;
  %end;  
%end;   
%else %do;
  %put MNOTE: Program does not support &dist distribution! ;
  %goto exit;
%end;

/* Count the number of fixed effects: Max = 50 */

%let p1=0;
%let X1=%str();
%do i=1 %to 50;
  %let temp = %qscan(&fixed, &i, %str( ));
  %if &temp=%str( ) or &temp=%str(/) %then %goto done1;
  %let p1=%eval(&p1+1);
  %let X1=&X1 &temp;
%end;
%done1: ;
%if &temp=%str(/) %then %do;
  %let i=%eval(&i+1);
  %let temp = %qscan(&fixed, &i,%str( ));
  %let prnfix = %upcase(&temp);
%end; 
%else 
  %let prnfix=N;

 
/* Count the number of smooth variables: Max = 50 */

%let X2=&smthvar;
%let p2=0;
%do i=1 %to 50;
  %if %scan(&X2, &i)= %then %goto done2;
  %let p2=%eval(&p2+1);
%end;
%done2: ;


%if &p1=0 and &p2=0 %then 
  %let lintest=N;


/* Count the number of random effects: Max = 50, and get random effects */

%if &type=SIM %then %do;
  %let c=0;
  %let i=1;
  %let q=%str();
  %let Z=%str();
  %let nzs=0;
  %let temp=%qscan(&random,&i,%str( ));
  %if &temp=%str( ) or &temp=%str(/) %then %goto done3;
  %do %while(&temp^=%str( ));
    %let c=%eval(&c+1);
    %let t=0;
    %do %while(&temp^=%str(+) and &temp^=%str( ) and &temp^=%str(/));
      %let Z=&Z %scan(&random, &i,%str( ));
      %let t=%eval(&t+1);
      %let i=%eval(&i+1);
      %let temp=%qscan(&random,&i,%str( ));
    %end;
    %let q=&q &t;
    %let nzs=%eval(&nzs+&t);
    %if &temp=%str( ) or &temp=%str(/) %then %goto done3;
    %let i=%eval(&i+1);
    %let temp=%qscan(&random,&i,%str( ));
    %if &temp=%str( ) or &temp=%str(/) %then %goto done3;     
  %end;
%end;
%else %do;
  %let i=1;
  %let q=0;
  %let Z=%str();
  %let temp=%qscan(&random,&i,%str( ));
  %if &temp=%str( ) or &temp=%str(/) %then %goto done3;
  %do %while(&temp^=%str( ));
    %do %while(&temp^=%str(+) and &temp^=%str( ) and &temp^=%str(/));
      %let Z=&Z %scan(&random, &i,%str( ));
      %let q=%eval(&q+1);
      %let i=%eval(&i+1);
      %let temp=%qscan(&random,&i,%str( ));
    %end;    
    %if &temp=%str( ) or &temp=%str(/) %then %goto done3;  
    %let i=%eval(&i+1);
    %let temp=%qscan(&random,&i,%str( ));
    %if &temp=%str( ) or &temp=%str(/) %then %goto done3;
  %end;
%end;
%done3: ;
%if &type^=SIM %then %do;
  %let nzs=&q;
  %let c=%eval((&q)*(&q+1)/2);  /* c = number of par in random eff */
%end;  
%if &temp=%str(/) %then %do;
  %let zvar=%scan(&random, 1, /);
  %let prnran = %upcase(%scan(&random, 2, /));
%end; 
%else %do;
  %let zvar=&random;
  %let prnran=N;
%end;


/* Check if there are valid taus in the input */

%let lambda=0;
%if &p2>0 %then %do;
%if %length(&smooth)>0 %then %do;
  %let t=0;
  %let i=1;
  %let stop=0;
  %do %while(%qscan(&smooth,&i,%str( ))^=%str( ) and &stop=0 and &t < &p2);
    %if %qscan(&smooth,&i,%str( )) <= 0 %then 
      %let stop=1;
    %let i=%eval(&i+1);
    %let t=%eval(&t+1);
  %end;
  %if &t = &p2 and &stop=0 %then
     %let lambda=1;
  %if &lambda=0 %then;
    %put MNOTE: Input smoothing parameters are invalid! ; 
%end; 
%if &lambda=0 %then
  %let method=REML;
%end;

%if &lambda=1 %then
  %let lintest=N;


/* Look at the process */

%let prs=0;                         /* prs = # of pars in the process */
%if %length(&process)>0 %then %do;
  %if &process=AR %then %do;
    %let prs=2;
  %end;
  %else %if &process=OU %then %do;
    %let prs=2;
  %end;
  %else %if &process=NOU1 %then %do;
    %let prs=3;
  %end;
  %else %if &process=NOU2 %then %do;
    %let prs=4;
  %end;
  %else %if &process=NOU3 %then %do;
    %let prs=4;
  %end;
  %else %if &process=IOU %then %do;
    %let prs=2;
  %end; 
  %else %if &process=W %then %do;
    %let prs=1;
  %end; 
  %else %if &process=IW %then %do;
    %let prs=1;
  %end; 
  %else %if &process=NOU4 %then %do;
    %let prs=4;
  %end;  
  %else %if &process=NOU5 %then %do;
    %let prs=4;
  %end;  
  %else %if &process=NOU6 %then %do;
    %let prs=3;
  %end;  
  %else %if &process=NOU7 %then %do;
    %let prs=4;
  %end;
  %else %do;
    %put MNOTE: Program does not support &process porcess! ;
    %goto exit;
  %end;
%end;

%if &type^=SIM or &c=0 or &lambda=1 %then 
  %let vartest=N;

/* dim gives the numbers of parameters for (tau, theta, gamma, phi) */ 


%if &dispers=Y %then %do;
  %if &lambda=1 %then  
    %let dim=0 &c &prs 1;
  %else
    %let dim=&p2 &c &prs 1;
%end;
%else %do;
  %if &lambda=1 %then  
    %let dim=0 &c &prs 0;
  %else
    %let dim=&p2 &c &prs 0;
%end;
       

%let d2=%scan(&dim, 1);
%let d3=%eval(&d2 + 1);
%let d4=%eval(&d2 + %scan(&dim, 2));
%let d5=%eval(&d4 + 1);
%let d6=%eval(&d4 + %scan(&dim, 3));
%let d7=%eval(&d6 + 1);
%let d8=%eval(&d6 + %scan(&dim, 4));


  /* See if we can do bias correction */

%if &prs=0 and &type=SIM and &dist=BINOMIAL and &dispers=N and
  &link=LOGIT and &c>=1 %then 
    %let correct=1;
%else
  %let correct=0;

/* Count the number of values in parm  */

%let nps=0;
%do i=1 %to 50;
  %if %qscan(&parm, &i, %str( ))= %then %goto done4;
  %let nps=%eval(&nps+1);
%end;
%done4: ;  

%if &maxiter>100 %then
  %let maxiter=100;


footnote"GAMM Macro: dep=&dep, id=&id, dist=&dist, link=&link";
footnote2"smoothed variables=&X2";

/* Give a footnote to the fixed effects */
%let maxvar=8;

%let xvar=;
%let control=&maxvar;
%if &control > &p1 %then 
  %let control=&p1;
%do i=1 %to &control; 
  %let _x=%scan(&X1, &i);
  %let xvar=&xvar &_x; 
%end;
footnote3"fixed effects=&xvar";

%let restvar=%eval(&p1 - &maxvar);
%let iternum=1;

%start: %if &restvar > 0 %then %do;
  %let xvar=%str();
  %let control=%eval((&iternum+1)*&maxvar);
  %if &control > &p1 %then 
  %let control=&p1;
  %do i=%eval(1+&iternum*&maxvar) %to &control; 
    %let _x=%scan(&X1, &i);
    %let xvar=&xvar &_x; 
  %end;

  %let iternum=%eval(&iternum + 1);
  %let notenum=%eval(&iternum + 2);
  footnote&notenum"+&xvar";
  %let restvar = %eval(&restvar - &maxvar);
  %goto start;
%end;


/* Give a footnote to the random effects */

%let notenum=%eval(&iternum  + 3);
%if &type=SIM %then %do;
  footnote&notenum"random effects=&zvar";
%end;
%else %do;
  footnote&notenum"random effects=&Z";
%end;
/* Give a footnote to the Gaussian process */

%let notenum=%eval(&notenum+1);
%let notenum2=%eval(&notenum+1);
%if &prs=0 %then %do;
  footnote&notenum"Gaussian process=";
%end;
%else %if &process=AR %then %do;
  footnote&notenum"Gaussian process=AR(1)";
%end;
%else %if &process=OU %then %do;
  footnote&notenum"Gaussian process=Ornstein-Uhlenbeck process";
%end;
%else %if &process=NOU1 %then %do;
  footnote&notenum"Gaussian process=Nonhomogeneous OU process with";
  footnote&notenum2"log-variance function: log(V(t)) = a0 + a1*g(t)";
%end;
%else %if &process=NOU2 %then %do;
  footnote&notenum"Gaussian process=Nonhomogeneous OU process with";
  footnote&notenum2"log-variance function: log(V(t)) = a0 + a1*exp(alpha*t)";
%end;
%else %if &process=NOU3 %then %do;
  footnote&notenum"Gaussian process=Nonhomogeneous OU process with";
  footnote&notenum2"log-variance function: log(V(t)) =  a0 + a1*t + a2*t^2";
%end;
%else %if &process=IOU %then %do;
  footnote&notenum"Gaussian process=Integrated OU process";
%end;
%else %if &process=W %then %do;
  footnote&notenum"Gaussian process=Wiener process (Brownian motion)";
%end;
%else %if &process=IW %then %do;
  footnote&notenum"Gaussian process=Integrated Wiener process";
%end;
%else %if &process=NOU4 %then %do;
  footnote&notenum"Gaussian process=Nonhomogeneous OU process with";
  footnote&notenum2"log-variance function: log(V(t)) = a0 + a1*g1(t) + a2*g2(t)";
%end;
%else %if &process=NOU5 %then %do;
  footnote&notenum"Gaussian process=Nonhomogeneous OU process with";
  footnote&notenum2"variance function: V(t) = a0 + a1*t + a2*t^2";
%end;
%else %if &process=NOU6 %then %do;
  footnote&notenum"Gaussian process=Nonhomogeneous OU process with variance";
  footnote&notenum2"variance function: V(t) = a0 + a1*g(t)";
%end;
%else %if &process=NOU7 %then %do;
  footnote&notenum"Gaussian process=Nonhomogeneous OU process with variance";
  footnote&notenum2"variance function: V(t) = a0 + a1*g1(t) + a2*g2(t)";
%end;


/* Delete obs with missing values; */

data _setup; set &data;
  %if %length(&id)=0 %then %str(_id = _n_;);
   
  keep %if %length(&id)=0 %then %str(_id);
    &id &dep &X1 &X2 &Z &time &gt &g1t &g2t &weight &offset;

  zmiss=0;
  %do i=1 %to &p1;
    zz=%scan(&X1, &i);
    if zz=. then zmiss=1;
  %end;
  %do i=1 %to &p2;
    zz=%scan(&X2, &i);
    if zz=. then zmiss=1;
  %end;
  %let i=1;
  %do %while (%qscan(&Z,&i,%str( ))^=%str( ));;
    zz=%scan(&Z, &i,%str( ));
    if zz=. then zmiss=1;
    %let i=%eval(&i + 1);
  %end;  
  if &dep=. or zmiss=1 then delete;
run;


/* Use Proc GenMod in SAS to get initial values for beta */

data temp; set _setup;
  %if &dist=BINOMIAL %then %do;
    %if %length(&weight)>0 %then
      %str(_trial_ = round(&weight);
           &dep = round(&dep*&weight););
    %else
      %str(_trial_ = 1;);
  %end;
run;

ods listing close;
proc GenMod data=temp;
  %if &dist=BINOMIAL %then 
    %str(model &dep/_trial_=&X1 / dist=&dist link=&link);
  %else
    %str(model &dep=&X1 / dist=&dist link=&link);
  %if %length(&offset)=0 %then %str(;);
  %else %str(offset=&offset;);
  ODS output ParameterEstimates=_parm_;
run;
ods listing;

proc means n data=_setup noprint;
  var &dep;
  output out=temp n=&dep;
run;

data _null_; set temp;
  call symput('n', &dep);
run;


%let coefdim = %eval(1+&p1-&p2);

  /* Get the distinct knots */

%let totb=0;   /* totb = total # of B's */
%if &p2=0 and &p1>0 and &lintest=Y %then 
  %let totb=1;
%else %if &p2>0 %then
  %let totb=&p2;

%do j=1 %to &totb;

  %if &p2=0 %then
    %let X2j = %scan(&X1, &j);
  %else
    %let X2j = %scan(&X2, &j);

  data knot&j; set _setup;
    keep &X2j;
  run;

  proc sort data=knot&j;
    by &X2j;
  run;

  data knot&j; set knot&j;
    by &X2j;
    if first.&X2j=1;  
    knot=&X2j;
    keep knot; 
  run;

  proc means n data=knot&j noprint;
    var knot;
    output out=temp n=knot;
  run;  

  %if &p2>0 %then %do;
    data _null_; set temp;
      call symput('numk', knot);
    run;

    %if &j=1 %then
      %let dimf1 = %eval(&numk - 2);

    %let coefdim = %eval(&coefdim + &numk);
  %end;

%end;


/* Get the number of observations for each subject */
 
proc sort data = _setup; 
  %if %length(&id)=0 %then
    %str(by _id;);
  %else 
    %str(by &id;);
run;

proc means n noprint data=_setup;
  %if %length(&id)=0 %then
    %str(by _id;);
  %else 
    %str(by &id;);
 
  var &dep;
  output out=_nobs n=&dep;
run;

data _nobs; set _nobs;
  _n=&dep;
  keep %if %length(&id)=0 %then %str(_id);
       %else %str(&id); _n;

run; 

data _subject; set _nobs;
  keep %if %length(&id)=0 %then %str(_id;); %else %str(&id;);
run;

proc means n data=_subject noprint;
  var %if %length(&id)=0 %then %str(_id;); %else %str(&id;);
  output out=_subject n=%if %length(&id)=0 %then %str(_id;); %else %str(&id;);
run;

data _null_; set _subject;
  call symput('m', %if %length(&id)=0 %then %str(_id); %else %str(&id););
run;  
         /* m is the number of subjects */


proc iml symsize=&symsize worksize=&worksize;


/* Macro defining B matrices */

%macro defineB;

%if &totb>0 %then %do;
  %if &p2=0 %then %do;
    bnknot=0;
    brknot=0;
  %end;
  %else %do;
    nknot = j(&totb, 1, 0);
    rknot = nknot;
    X2mean = nknot;
  %end;
%end;

%do j=1 %to &totb;

  /* Create matrices Q R defined in Green's book */
 
  use knot&j; setin knot&j;
  read all var{knot}; 
  
  temp1 = nrow(knot);                       /* # of distinct knots */
  temp2 = temp1 - 2;                        /* Rank of R defined later */

  X2&j = knot;
  %if &p2>0 %then %do;  
    X2mean[&j] = sum(X2&j) / temp1;                    /* center X2 */
    CX2&j = X2&j - X2mean[&j];                    
  %end;

  h = knot[2:temp1] - knot[1:temp1-1];

  /* q1 q2 q3 are three diagonal vectors of Q */
  q1&j = 1/h[1:temp2];
  q3&j = 1/h[2:temp2+1];
  q2&j = -(q1&j+q3&j);

  /* dr is the main diag, lr is the adjacent diag of R */
  dr&j = (h[1:temp2] + h[2:temp2+1])/3;
  if temp2>1 then
    lr&j = h[2:temp2]/6;

  /*    Cholesky decomposition of R=LDL^T   */
  /* dr became the diag of D,  lr became off diag of L */
  if temp2 > 1 then do;
    do i=2 to temp2;
      lr&j[i-1] = lr&j[i-1]/dr&j[i-1];
      dr&j[i] = dr&j[i] - lr&j[i-1]**2*dr&j[i-1];
    end;
  end;

  Q = j(temp1, temp2, 0);

  do i=1 to temp2;
    Q[i,i] = 1/h[i];
    Q[i+2, i] = 1/h[i+1];
    Q[i+1,i] = -(Q[i,i] + Q[i+2, i]);
  end;

  %if &p2=0 %then %do;
    B = Q * inv(Q`*Q);
  %end;
  %else %do;
    B&j = Q * inv(Q`*Q);
  %end;

  temp = j(temp2,temp2,0);

  do i=1 to temp2;
    temp[i,i] = 1;
  end;

  do i=1 to temp2-1;
    temp[i+1, i] = lr&j[i];
  end;

  %if &p2=0 %then %do;
    B = B * temp * diag(sqrt(dr&j));
  %end;
  %else %do;
    B&j = B&j * temp * diag(sqrt(dr&j));
  %end;

  free Q;

  %if %length(&outsmth)=0 or &p2=0 %then %do;
    free q1&j q2&j q3&j dr&j lr&j;
  %end;

  %if &p2=0 %then %do;
    bnknot = temp1;
    brknot = temp2;
  %end;
  %else %do;
    nknot[&j] = temp1;
    rknot[&j] = temp2;
  %end;

%end;  

%mend defineB;


/* Macro to read data */

%macro readdata;

  use _setup; setin _setup;

  read all var{&dep} into Y; 
  
  %if &p1>0 %then %do;
    read all var{&X1} into X1;
  %end;  

  %if &p2>0 %then %do;
    read all var{&X2} into X2;
    CX2 = X2;
    do j=1 to &p2;
      CX2[, j] = X2[, j] - X2mean[j];     /*  center X2  */
    end;
  %end;

  %if &c>0 %then %do;
    read all var{&Z} into Z; 
  %end;

  %if %length(&weight)>0 %then %do;
    read all var{&weight} into weight;
  %end;

  %if %length(&offset)>0 %then %do;
    read all var{&offset} into offset;
  %end;

  %if &prs>0 %then %do;
    %if &process ^=AR %then %do; 
      read all var{&time} into time; 
      %if &process=NOU5 %then %do;
        mint=min(time);
        maxt=max(time);
      %end;
      %if (&process=NOU1 or &process=NOU6) and %length(&gt)>0 and 
        %upcase(&gt) ^= %upcase(&time) %then %do;
        read all var{&gt} into gt;
      %end;
      %if &process=NOU4 or &process=NOU7 %then %do;
        read all var{&g1t} into g1t;
        read all var{&g2t} into g2t;
      %end;
    %end;   
  %end;

  %if %length(&outprs)>0 %then %do; 
    %if %length(&id)=0 %then %do;
      read all var{_id} into _id;
    %end;
    %else %do;
      read all var{&id} into _id;
    %end;
  %end;

  n = nrow(Y);       /* n is the total number of observations */

  use _nobs; setin _nobs;
  read all var{_n};    /* _n contains the number of obs for subject */

  %if %length(&outran)>0 or &prnran=S %then %do;
    %if %length(&id)=0 %then %do;
      read all var{_id} into id;
    %end;
    %else %do;
      read all var{&id} into id;
    %end;    
  %end;

  use _parm_; setin _parm_;
  read all var{Estimate} into parm;

  %if &lambda=1 %then %do;
    smooth = j(&p2, 1, 0);
    %do j=1 %to &p2;
      %let temp = %scan(&smooth, &j);
       smooth[&j] = &temp;
    %end;
  %end;

  m=&m;

  m1 = j(m,1,1);        /* m1 is the starting point of cumulant number of obs */
  m2 = m1;              /* m2 is the end point of cumulant number of obs */
  m2[1] = _n[1];
  do i=2 to m;
    m1[i] = m2[i-1] + 1;
    m2[i] = m2[i-1] + _n[i];
  end;

  %if &p1=0 and &p2=0 %then %do;
    X = j(n,1,1);
  %end;
  %else %if &p2=0 %then %do;
    X = j(n,1,1) || X1;
  %end;
  %else %do;
    X = j(n,1,1) || X1 || CX2;
  %end;

%mend readdata;


/* macro to get incidence matrix for each smoothed variable */

%macro getorder;

  %if &totb>0 %then %do;
    if &p2=0 then
      border = j(n,1,0);
    else
      order = j(n,&p2,0);
  %end;

  %do j=1 %to &totb;
    do i=1 to m;
      if &p2=0 then
        temp1 = X1[m1[i]: m2[i], &j];
      else
        temp1 = X2[m1[i]: m2[i], &j];
      temp2 = temp1;
      do j=1 to _n[i];
        r=1;
        find=0;
        do while (find=0);
          if temp1[j] = X2&j[r] then do;
            temp2[j] = r;
            find = 1;
          end;
          else
            r = r+1;
        end;
      end;
      if &p2=0 then
        border[m1[i]: m2[i], &j] = temp2;
      else
        order[m1[i]: m2[i], &j] = temp2;
    end;
  %end; 

%mend getorder;


  /*  function to get trace(A*B)   */ 

start trc(A, B);
  tr = 0;
  n = nrow(A);
  do i=1 to n;
    tr = tr + A[i,]*B[,i];
  end;
  return(tr);
finish; 


  /* Function to compare if A=B  */

start equal(A,B);
  nrowa=nrow(A);
  ncola=ncol(A);
  nrowb=nrow(B);
  ncolb=ncol(B);
  result=(nrowa=nrowb & ncola=ncolb);
  if result=1 then do;
    temp=(A=B);
    if sum(temp)=nrowa*ncola then
      result=1;
    else 
      result=0;
  end;
  return(result);
finish; 



  /*  function to form a matrix from a vector */

start formmat(vec);
  nvec = nrow(vec);
  dim = (sqrt(1+8*nvec) - 1)/2;
    
  Mat = j(dim, dim, 0);
    
  l=1;
  do i=1 to dim;
    do j=1 to i;
      Mat[i,j] = vec[l];
      l=l+1;
    end;
  end;

  do i=2 to dim;
    do j=1 to i-1;
      Mat[j,i] = Mat[i,j];
    end;
  end;

  return(Mat);
finish;  



 /*  function to form a vector from a matrix */

start formvec(Mat);
  dim = nrow(Mat);
  nvec = dim*(dim+1)/2;

  vec = j(nvec, 1, 0);

  l=1;
  do i=1 to dim;
    do j=1 to i;
      vec[l] = Mat[i,j];
      l = l + 1;
    end;
  end;

  return(vec);
finish;


  /*  function to get N_{i}B   */

start NBi(i, orderi, B) global(_n);
  k = nrow(B);
  r = ncol(B);
  temp = (1:k)`;
  if equal(orderi, temp) then
    u = B;
  else do;
    u = j(_n[i], r, 0);
    do j=1 to _n[i];
      u[j,] = B[orderi[j],];
    end;
  end;
  return(u);
finish;


  /*  function to get NB   */

start NB(orderj, B) global(_n, m, m1, m2);
  k = nrow(B);
  r = ncol(B);
  orderi = orderj[m1[1]: m2[1]];
  u = NBi(1, orderi, B);
  do i=2 to m;
    orderi = orderj[m1[i]: m2[i]];
    temp = NBi(i, orderi, B);
    u = u // temp;
  end;
  return(u);
finish;


  /*  Function to get corresponding row and column  */
 
  start rowcol(j);
    k=j;
    l=1;
        
    do while (k > 0);
      k=k-l;
      l=l+1;
    end;
    l=l-1;
    k=k+l;

    a=j(2,1,0);
    a[1]=l;
    a[2]=k;
    return(a);
  finish;

  /*  Macro AutoInit initializes theta1 automatically  */

%macro AutoInit;

  %if &p2>0 and &lambda=0 %then %do;
    do l=1 to &d2; 
      theta1[l] = 1;
    end;
  %end;

  %if &c>0 %then %do;                    /* random statement ?   */
    %if &type=SIM %then %do;
      do l=&d3 to &d4; 
        theta1[l] = 1;
      end;    
    %end;
    %else %do; 
      l=&d3;
      do i=1 to &q;
        do j=1 to i;
          if i=j then 
            theta1[l] = 1;
          else
            theta1[l] = -0.5;
          l = l + 1;
        end;
      end;
    %end;
  %end;

  %if &prs>0  %then %do;                       /*  Any process ?   */
    %if &process=AR or &process=OU %then %do;  /*  AR + OU   */
      theta1[l] = 0.8;
      theta1[l+1] = 1;
    %end;
    %else %if &process=NOU1 %then %do;        /*  NOU1 case   */
      theta1[l] = 0.8;
      theta1[l+1] = 0;
      theta1[l+2] = 0;
    %end; 
    %else %if &process=NOU2 %then %do;        /*  NOU2 case   */
      theta1[l] = 0.8;
      theta1[l+1] = -1;
      theta1[l+2] = 1;
      theta1[l+3] = 1;
    %end;
    %else %if &process=NOU3 %then %do;        /*  NOU3 case   */
      theta1[l] = 0.8;
      theta1[l+1] = 0;
      theta1[l+2] = 0;
      theta1[l+3] = 0;
    %end; 
    %else %if &process=IOU %then %do;        /*  IOU case   */
      theta1[&d5]=1;
      theta1[&d6]=1;
    %end;
    %else %if &process=W %then %do;          /*  Wiener case */
      theta1[&d5] = 1;
    %end;
    %else %if &process=IW %then %do;         /*  IW case     */
      theta1[&d5] = 1;
    %end;
    %else %if &process=NOU4 %then %do;       /*  NOU4 case   */
      theta1[l] = 0.8;
      theta1[l+1] = 0;
      theta1[l+2] = 0;
      theta1[l+3] = 0;
    %end; 
    %else %if &process=NOU5 %then %do;       /*  NOU5 case   */
      theta1[l] = 0.8;
      theta1[l+1] = 1;
      theta1[l+2] = 0;
      theta1[l+3] = 0;
    %end; 
    %else %if &process=NOU6 %then %do;        /*  NOU6 case   */
      theta1[l] = 0.8;
      theta1[l+1] = 1;
      theta1[l+2] = 0;
    %end; 
    %else %if &process=NOU7 %then %do;        /*  NOU7 case   */
      theta1[l] = 0.8;
      theta1[l+1] = 1;
      theta1[l+2] = 0;
      theta1[l+3] = 0;
    %end; 
  %end;


  %do i=&d7 %to &d8;                       /*  Dispersion parameter ?  */  
    theta1[&i] = 1;
  %end;

%mend AutoInit;


   /*  Check if theta1 is in the parm space */

%macro findcrt2;

  crit2=1;

  %if &d2 >= 1 %then %do;
     do i=1 to &d2;
       crit2 = crit2 & theta1[i]>0;
     end;
  %end;

  %if &c > 0 %then %do;
     %if &type=SIM %then %do;  
       if crit2=1 then
         do i=&d3 to &d4;
           crit2 = crit2 & theta1[i]>0;
         end;
     %end;
     %else %do;
       l=&d3;
       if crit2=1 then do;
         do i=1 to &q;
           do j=1 to i;
             D[i,j] = theta1[l];
             D[j,i] = D[i,j];
             l=l+1;
           end;
         end;
         temp=eigval(D);
         do i=1 to &q;    
           crit2 = crit2 & temp[i]>0;
         end;
      end;
    %end;
  %end;

  %if &prs>0 %then %do;
    %if &process=AR %then %do;
      crit2 = crit2 & abs(theta1[&d5])<=1 & theta1[&d6]>0;
    %end;
    %else %if &process=OU %then %do;
      crit2 = crit2 & theta1[&d5]<=1 & theta1[&d5]>0 & theta1[&d6]>0;
    %end;
    %else %if &process=NOU1 %then %do;
      crit2 = crit2 & theta1[&d5]<=1 & theta1[&d5]>0;
    %end;
    %else %if &process=NOU2 %then %do;
      crit2 = crit2 & theta1[&d5]<=1 & theta1[&d5]>0;
    %end;
    %else %if &process=NOU3 %then %do;
      crit2 = crit2 & theta1[&d5]<=1 & theta1[&d5]>0;
    %end;
    %else %if &process=IOU %then %do;
      crit2 = crit2 & theta1[&d5]>0 & theta1[&d6]>0;
    %end;
    %else %if &process=W %then %do;
      crit2 = crit2 & theta1[&d5]>0;
    %end;
    %else %if &process=IW %then %do;
      crit2 = crit2 & theta1[&d5]>0;
    %end;
    %else %if &process=NOU4 %then %do;
      crit2 = crit2 & theta1[&d5]<=1 & theta1[&d5]>0;
    %end;
    %else %if &process=NOU5 %then %do;
      varn1 = theta1[&d5+1] + theta1[&d5+2]*mint + theta1[&d6]*mint**2;
      varn2 = theta1[&d5+1] + theta1[&d5+2]*maxt + theta1[&d6]*maxt**2;     
      minvar=min(varn1, varn2);
      if theta1[&d6]>0 then do;
        tzero = - theta1[&d5+2]/(2*theta1[&d6]);
        if tzero > mint & tzero < maxt then do;
           varn = theta1[&d5+1] + theta1[&d5+2]*tzero + theta1[&d6]*tzero**2;
           minvar=min(minvar, varn);
        end;
      end;     
      crit2 = crit2 & theta1[&d5]<=1 & theta1[&d5]>0 & minvar>0; 
    %end;
    %else %if &process=NOU6 %then %do;
      varn = theta1[&d5+1] + theta1[&d6]#gt;
      minvar = min(varn1); 
      crit2 = crit2 & theta1[&d5]<=1 & theta1[&d5]>0 & minvar>0; 
    %end;
    %else %if &process=NOU7 %then %do;
      varn = theta1[&d5+1] + theta1[&d5+2]#g1t + theta1[&d6]#g2t;
      minvar = min(varn); 
      crit2 = crit2 & theta1[&d5]<=1 & theta1[&d5]>0 & minvar>0; 
    %end;
  %end;  

  %if &d8 >= &d7 %then %do;
    crit2 = crit2 & theta1[&d7]>0;
  %end;

%mend findcrt2;


/* Macro to find f_{j} and Nf_{j} */ 

%macro findf;

  %if &coefdim < &n %then %do;
    %if &p2 > 0 %then %do;
      %do j=1 %to &p2;    
        f&j = CX2&j * beta1[nx+&j] + B&j * beta1[cut1[&j]: cut2[&j]];
        Nf&j = NB(order[, &j], f&j); 
      %end;
    %end;
  %end;
  %else %do;
    %do j=1 %to &p2;
      f&j = CX2&j * beta1[nx+&j] + B&j * a&j;
      Nf&j = NB(order[, &j], f&j);   
    %end;    
  %end;

%mend findf;


  /* Macro Initial Initializes theta from input or automatically  */

%macro Initial;

  %if &d2>=1 %then %do;
    uplim = 10**(10);
    lowlim = 1/uplim;
  %end;

  %if &dist=BINOMIAL and &link=PROBIT %then %do;
    twopi = 8*atan(1);
  %end;

  nx = &p1 + 1;     /* number of fixed effects, including intercept */
  fixnum = nx + &p2;

  vstart = j(m, 1, 1);
  vend = vstart;
  vend[1] = _n[1]*(_n[1] + 1)/2;
  do i=2 to m;
    vstart[i] = vend[i-1] + 1;
    vend[i] = vend[i-1] + _n[i]*(_n[i] + 1)/2;
  end;

  WM = j(vend[m], 1, 0);  /* store W in a vector */ 
  
  %if &coefdim < &n %then %do;
    dimbt = &coefdim;
    if &p2>0 then do;
      cut1 = j(&p2, 1, 0);             /* starting pt for a in Ba  */
      cut2 = cut1;                     /* end pt for a in Ba       */
      cut1[1] = fixnum +1;
      cut2[1] = fixnum + rknot[1];
      do j=2 to &p2;
        cut1[j] = cut2[j-1] + 1;
        cut2[j] = cut2[j-1] + rknot[j];
      end;       
    end;   
  %end;
  %else %do;
    dimbt = fixnum;
    %do i=1 %to &p2;
      a&i = j(rknot[&i], 1, 0);
    %end;
 
    %do j=&d3 %to &d8;   /* store the derivative as a vector */
      V&j = j(vend[m], 1, 0);
    %end;   

    VM = j(vend[m], 1, 0);  /* store V in a vector */ 

  %end;

  %if &c>0 %then %do;
    %if &type=SIM %then %do;
      %if &ltest=0 and &vtest=0 %then %do;
        q1 = j(&c, 1, 1);       /* starting pt for Z */
        q2 = q1;                /* end pt for Z */
        q2[1] = %scan(&q, 1);
        %do i=2 %to &c;
          %let temp = %scan(&q, &i);
          q1[&i] = q2[&i-1] + 1;
          q2[&i] = q2[&i-1] + &temp;
        %end;
        nz = q2[&c];
      %end;
      %else %if &vtest=1 %then %do;
        q1 = j(&c, 1, 1);       /* starting pt for Z */
        q2 = q1;                /* end pt for Z */
        q2[1] = %scan(&q, 2);
        %let j=%eval(&c+1);
        %do i=3 %to &j;
          %let temp = %scan(&q, &i);
          q1[&i-1] = q2[&i-2] + 1;
          q2[&i-1] = q2[&i-2] + &temp;
        %end;
        nz = q2[&c];
      %end;
    %end;
    %else %do;
      nz = &q;
    %end;
    %if &ltest=0 %then %do;
      dimb = m * nz;             /* dimension for random effects */
      bvec = j(dimb, 1, 0);  
      bcut1 = j(m, 1, 1);        /* starting pt for random effects */
      bcut2 = bcut1;             /* end pt for random effects      */
      bcut2[1] = nz;
      do i=2 to m;
        bcut1[i] = bcut2[i-1] + 1;
        bcut2[i] = bcut2[i-1] + nz;
      end; 
    %end;
  %end;

  %if &prs>0 %then %do;
    uvec = j(n, 1, 0);
  %end;

  beta1 = j(dimbt, 1, 0);
  %if &ltest=0 %then %do;
    if parm[1] ^= . then
      beta1[1:nx] = parm[1:nx];
  %end;
  %else %if %length(&smthvar)>0 %then %do;
    if parm[1] ^= . then
      beta1[1:nx-1] = parm[1:nx-1];
  %end;
  

  %do j=1 %to &p2;
    f&j = j(rknot[&j], 1, 0);
    Nf&j = j(n, 1, 0);
  %end;

  /*  D = the variance matrix for the random effects  */

  %if &type^=SIM and &c>0 %then %do;  
    D = j(&q, &q, 0);
  %end; 
  
  %if &fitmod=Y %then %do;
    %if &d8=&nps and &ltest=0 and &vtest=0 %then %do;
      if &d8>0 then           
        theta1 = j(&d8, 1, 0);
      %do i=1 %to &d8;
         theta1[&i] = %scan(&parm, &i, %str( ));
      %end;
   
      %findcrt2;

      if crit2=0 then do; 
         %AutoInit; 
      end;
    %end;
    %else %if &ltest=0 and &vtest=0 %then %do;
      if &d8>0 then           
        theta1 = j(&d8, 1, 0);   
      %AutoInit;
      %if &dist=NORMAL or &dist=GAMMA %then %do;
        if parm[1] ^= . then do;
          temp = nrow(parm);          
          %if &dist=NORMAL %then %do;
            theta1[&d8] = (parm[temp])**2;
          %end;
          %else %do; 
            theta1[&d8] = 1/parm[temp];
          %end;
        end;
      %end;
    %end;
    %else %do;
      if &d8>0 then           
        theta1 = j(&d8, 1, 0);

      %if &ltest=1 %then %do;
        if converg0=1 & &d8>0 then
          theta1 = theta[2:&d8+1];
        else do;
          %AutoInit; 
        end;
      %end;
  
      %if &vtest=1 %then %do;
        if converg0=1 & &d8>0 then do;
          if &d2<1 then
            theta1 = theta[2:&d8+1];
          else if &d8=&d2 then
            theta1 = theta[1:&d2];
          else do;
            theta1[1:&d2] = theta[1:&d2];
            theta1[&d3:&d8] = theta[&d3+1:&d8+1];
          end;
        end;
        else do;
          %AutoInit; 
        end;
      %end;
    %end;
  %end;
  %else %do; 
    if &d8>0 then           
      theta1 = j(&d8, 1, 0); 
    %AutoInit;
  %end;
%mend Initial;


/* Macro to find working vector and inverse of working matrix, eta and mu */ 

%macro formwork;

  eta = X[, 1:nx] * beta1[1:nx];

  %do j=1 %to &p2;
    eta = eta + Nf&j;
  %end;

  %if &c>0 %then %do;
    do i=1 to m;
      eta[m1[i]: m2[i]] = eta[m1[i]: m2[i]] + 
        Z[m1[i]: m2[i],]*bvec[bcut1[i]: bcut2[i]];
    end;
  %end;

  %if &prs>0 %then %do;
    eta = eta + uvec;
  %end;

  %if %length(&offset)>0 %then %do;
     eta = eta + offset;
  %end;   

  %if &dist=NORMAL %then %do;
    %if &link=IDENTITY %then %do;
      mu = eta;
      worky = Y;
      workv = j(n, 1, 1);
      gdmu = workv;
    %end;
  %end;
  %else %if &dist=BINOMIAL %then %do;
    %if &link=LOGIT %then %do;
      expeta = exp(eta);
      mu = expeta/(1+expeta);
      vmu = mu # (1 - mu);
      gdmu = 1/vmu;
      worky = eta + gdmu # (Y - mu);
      workv = gdmu;
    %end;
    %else %do;
      %if &link=PROBIT %then %do;
        mu = probnorm(eta);
        gdmu = sqrt(twopi) # exp(eta##2/2);
      %end;
      %else %if &link=CLOGLOG %then %do;
        mu = 1 - exp(-exp(eta));
        temp = 1 - mu;
        gdmu = -1/(temp#log(temp));
      %end;
      vmu = mu # (1 - mu);
      worky = eta + gdmu # (Y - mu);
      workv = vmu # gdmu##2;      
    %end;
  %end;
  %else %if &dist=POISSON %then %do;
    %if &link=LOG %then %do;
      mu = exp(eta);
      gdmu = 1 / mu;
      worky = eta + gdmu # (Y - mu);
      workv = gdmu;
    %end;
  %end;
  %else %if &dist=GAMMA %then %do;
    %if &link=LOG %then %do;
      mu = exp(eta);
      gdmu = 1 / mu;
      worky = eta + gdmu # (Y - mu);
      workv = j(n, 1, 1);
    %end;
  %end;          

  %if %length(&weight)>0 %then %do;
    workv = workv / weight;
  %end;

  %if &dispers=Y %then %do;
    Vderv = workv;                 /* derivative of V to phi */;
    workv = workv # theta1[&d8];
  %end;

%mend formwork;


%macro arvarn;              /* variance for ar process */

  do j=1 to _n[i];
    E[j,j] = theta1[&d6];
  end;
  do k=2 to _n[i];
    E[1,k] = E[1, k-1]*theta1[&d5];
    do j=2 to _n[i]+1-k;
      E[j, j+k-1] = E[1,k];
    end;
  end;
  do k=2 to _n[i];
    do j=1 to _n[i]+1-k;
      E[j+k-1,j] = E[j,j+k-1];
    end;
  end; 

%mend arvarn;


%macro ouvarn;             /*  variance for OU process  */

  logrho=log(theta1[&d5]);
  timei=time[m1[i]: m2[i]];

  do j=1 to _n[i];
    E[j,j] = theta1[&d6];
  end;

  do j=2 to _n[i];
    do k=1 to j-1;
      dist=abs(timei[j]-timei[k]);
      E[j,k] = theta1[&d6]*exp(dist*logrho);
      E[k,j] = E[j,k];
    end;
  end;

%mend ouvarn;


%macro nou1varn;           /*  variance for NOU1 process */

  logrho=log(theta1[&d5]);
  timei=time[m1[i]: m2[i]];

  %if %length(&gt)>0 and %upcase(&gt) ^= %upcase(&time) %then %do;
    temp=theta1[&d6]*gt[m1[i]:m2[i]];
  %end;
  %else %do;
    temp=theta1[&d6]*timei;
  %end;

  do j=1 to _n[&i];
    E[j,j] = exp(theta1[&d5+1]+temp[j]);
  end;

  do j=2 to _n[i];
    do k=1 to j-1;
      dist=abs(timei[j]-timei[k]);
      avg=(temp[j]+temp[k])/2;
      E[j,k] = exp(theta1[&d5+1]+avg+dist*logrho);
      E[k,j] = E[j,k];
    end;
  end;

%mend nou1varn;


%macro nou2varn;           /*  variance for NOU2 process */

  logrho=log(theta1[&d5]);
  timei=time[m1[i]: m2[i]];
  temp=theta1[&d6]*exp(theta1[&d5+1]*timei);

  do j=1 to _n[i];
    E[j,j] = exp(theta1[&d5+2]+temp[j]);
  end;

  do j=2 to _n[i];
    do k=1 to j-1;
      dist=abs(timei[j]-timei[k]);
      avg=(temp[j]+temp[k])/2;
      E[j,k] = exp(theta1[&d5+2]+avg+dist*logrho);
      E[k,j] = E[j,k];
    end;
  end;

%mend nou2varn;


%macro nou3varn;           /*  variance for NOU3 process */

  logrho=log(theta1[&d5]);
  timei=time[m1[i]: m2[i]];
  temp=theta1[&d5+2]*timei + theta1[&d6]*timei##2;

  do j=1 to _n[i];
    E[j,j] = exp(theta1[&d5+1]+temp[j]);
  end;

  do j=2 to _n[i];
    do k=1 to j-1;
      dist=abs(timei[j]-timei[k]);
      avg=(temp[j]+temp[k])/2;
      E[j,k] = exp(theta1[&d5+1]+avg+dist*logrho);
      E[k,j] = E[j,k];
    end;
  end;

%mend nou3varn;


%macro nou4varn;           /*  variance for NOU4 process */

  logrho=log(theta1[&d5]);
  timei=time[m1[i]: m2[i]];
  g1ti=g1t[m1[i]: m2[i]];
  g2ti=g2t[m1[i]: m2[i]]; 
  temp=theta1[&d5+2]*g1ti + theta1[&d6]*g2ti;

  do j=1 to _n[i];
    E[j,j] = exp(theta1[&d5+1]+temp[j]);
  end;

  do j=2 to _n[i];
    do k=1 to j-1;
      dist=abs(timei[j]-timei[k]);
      avg=(temp[j]+temp[k])/2;
      E[j,k] = exp(theta1[&d5+1]+avg+dist*logrho);
      E[k,j] = E[j,k];
    end;
  end;

%mend nou4varn;


%macro nou5varn;           /*  variance for NOU5 process */

  logrho=log(theta1[&d5]);
  timei=time[m1[i]: m2[i]];
  temp=theta1[&d5+1] + theta1[&d5+2]*timei + theta1[&d6]*timei##2;

  do j=1 to _n[i];
    E[j,j] = temp[j];
  end;

  do j=2 to _n[i];
    do k=1 to j-1;
      dist=abs(timei[j]-timei[k]);      
      E[j,k] = sqrt(temp[j]*temp[k])*exp(dist*logrho);
      E[k,j] = E[j,k];
    end;
  end;

%mend nou5varn;


%macro nou6varn;           /*  variance for NOU6 process */

  logrho=log(theta1[&d5]);
  timei=time[m1[i]: m2[i]];

  %if %length(&gt)>0 and %upcase(&gt) ^= %upcase(&time) %then %do;
    temp=theta1[&d5+1] + theta1[&d6]*gt[m1[i]: m2[i]];
  %end;
  %else %do;
    temp=theta1[&d5+1] + theta1[&d6]*timei;
  %end;

  do j=1 to _n[i];
    E[j,j] = temp[j];
  end;

  do j=2 to _n[i];
    do k=1 to j-1;
      dist=abs(timei[j]-timei[k]);
      E[j,k] = sqrt(temp[j]*temp[k])*exp(dist*logrho);
      E[k,j] = E[j,k];
    end;
  end;

%mend nou6varn;


%macro nou7varn;           /*  variance for NOU7 process */

  logrho=log(theta1[&d5]);
  timei=time[m1[i]: m2[i]];
  g1ti=g1t[m1[i]: m2[i]];
  g2ti=g2t[m1[i]: m2[i]]; 
  temp=theta1[&d5+1] + theta1[&d5+2]*g1ti + theta1[&d6]*g2ti;

  do j=1 to _n[i];
    E[j,j] = temp[j];
  end;

  do j=2 to _n[i];
    do k=1 to j-1;
      dist=abs(timei[j]-timei[k]);     
      E[j,k] = sqrt(temp[j]*temp[k])*exp(dist*logrho);
      E[k,j] = E[j,k];
    end;
  end;

%mend nou7varn;


%macro iouvarn;        /*  variance for IOU process  */

  timei=time[m1[i]: m2[i]];
  temp=theta1[&d5]*timei;
  temp1=exp(-temp);

  ratio=theta1[&d6]/(theta1[&d5]**2);

  do j=1 to _n[i];
    E[j,j] = 2*(temp[j]+temp1[j]-1)*ratio;
  end;

  do j=2 to _n[i];
    do k=1 to j-1;
      dist=abs(timei[j]-timei[k]);
      mst=min(temp[j], temp[k]);
            
      E[j,k] = (2*mst+temp1[j]+temp1[k]-1-exp(-theta1[&d5]*dist))*ratio;
      E[k,j] = E[j,k];
    end;
  end;  

%mend iouvarn;


%macro wvarn;        /* variance for Wiener process */

  temp=theta1[&d5]*time[m1[i]: m2[i]];

  do j=1 to _n[i];
    E[j,j] = temp[j];
  end;    

  do j=2 to _n[i];
    do k=1 to j-1;   
      E[j,k] = min(temp[j], temp[k]);
      E[k,j] = E[j,k];
    end;
  end;

%mend wvarn;


%macro iwvarn;       /* variance for IW process */ 

  timei=time[m1[i]: m2[i]];
  
  do j=1 to _n[i];
    do k=1 to j;   
      time1=min(timei[j],timei[k]);
      time2=max(timei[j],timei[k]); 
      E[j,k] = theta1[&d5]*time1**2*(3*time2-time1)/6;
    end;
  end;  

  do j=2 to _n[i];
    do k=1 to j-1;
      E[k,j] = E[j,k]; 
    end;
  end; 

%mend iwvarn;


/* Macro to find W for the normal eqn, by absorbing random effects */

%macro findW;
    
  %if &coefdim < &n %then %do;
    HWY = j(dimbt, 1, 0);                /* HWY = H` * W * Y           */
    C = j(dimbt, dimbt, 0);              /* Initialize the coef matrix */
  %end;

  %if &c>0 and &type^=SIM %then %do;
     D = formmat(theta1[&d3:&d4]);
  %end;

  do i=1 to m;
    E = j(_n[i], _n[i], 0);

    %if &prs>0 %then %do;      
      %if &process=AR %then                       /*     AR case      */ 
        %arvarn; 
      %else %if &process=OU %then                 /*     OU case      */  
        %ouvarn;
      %else %if &process=NOU1 %then               /*     NOU1 case    */ 
        %nou1varn;
      %else %if &process=NOU2 %then               /*     NOU2 case    */ 
        %nou2varn;
      %else %if &process=NOU3 %then               /*     NOU3 case    */ 
        %nou3varn;
      %else %if &process=IOU %then                /*     IOU case     */
        %iouvarn;
      %else %if &process=W %then                  /*     Wiener case  */
        %wvarn;
      %else %if &process=IW %then                 /*     IW case      */
        %iwvarn;
      %else %if &process=NOU4 %then               /*     NOU4 case    */ 
        %nou4varn;
      %else %if &process=NOU5 %then              /*     NOU5 case    */ 
        %nou5varn;
      %else %if &process=NOU6 %then              /*     NOU6 case    */ 
        %nou6varn;
      %else %if &process=NOU7 %then              /*     NOU7 case    */ 
        %nou7varn;
    %end;  

    %if &c>0 %then %do;
      %if &type^=SIM %then %do;
        Zi = Z[m1[i]: m2[i],];
        E = E + Zi * D * (Zi)`;  
      %end;
      %else %do;
        do j=1 to &c;
          Zi = Z[m1[i]: m2[i], q1[j]:q2[j]];
          E = E + (theta1[&d3+j-1] # Zi) * (Zi)`;
        end;
      %end;
    %end;

    temp = workv[m1[i]: m2[i]]; 
    do j=1 to _n[i];
      E[j,j] = E[j,j] + temp[j];
    end;

    W = inv(E); 
    WM[vstart[i]:vend[i]] = formvec(W);

    %if &coefdim < &n %then %do;
      Hi = X[m1[i]: m2[i], ];
      %do j=1 %to &p2;
        Hi = Hi || NBi(i, order[m1[i]: m2[i],&j], B&j);
      %end;
      Yi = worky[m1[i]: m2[i]];
      WH = W * Hi;
      C = C + (Hi)` * WH;
      HWY = HWY + (WH)` * Yi;
    %end;
    %else %do; 
      VM[vstart[i]: vend[i]] = formvec(E);
    %end;
  end;  

  %if &coefdim < &n %then %do;      
    %if &p2>0 %then %do;
      %if &lambda=0 %then %do;
         lambda = 1/theta1[1:&d2];
      %end;
      %else %do;
        lambda = 1/smooth;
      %end;

      C0 = C; 
 
      do j=1 to &p2;
        do k=cut1[j] to cut2[j];
          C[k, k] = C[k, k] + lambda[j];
        end;
      end;
    %end;

    Cinv = inv(C); 

  %end;

%mend findW;


/* Macro to find marginal variance for worky under GLMM representation */ 

%macro findvinv;

  temp = j(n, n, 0);

  %if &p2>0 %then %do;
    %if &lambda=1 %then
      %do j=1 %to &p2;
        temp1 = NB(order[,&j], B&j);
        temp = temp + (smooth[&j] # temp1) * temp1`; 
      %end;
    %else
      %do j=1 %to &p2;
        temp1 = NB(order[,&j], B&j);
        temp = temp + (theta1[&j] # temp1) * temp1`; 
      %end;
  %end;  
  
  do i=1 to m;
    temp1 = formmat(VM[vstart[i]:vend[i]]);
    temp[m1[i]: m2[i], m1[i]: m2[i]] = 
      temp[m1[i]: m2[i],m1[i]: m2[i]] + temp1;
  end;
   
  vinv = inv(temp);    

%mend findvinv;


/* Macro to find beta, f_{j}, residual, random effects, and process */

%macro findbeta;

  %findW;

  %if &coefdim < &n %then %do;
    beta1 = Cinv * HWY;
  %end;
  %else %do;
    %findvinv;
    temp1 = X` * vinv;
    VBbeta = inv(temp1 * X);
    VBXV = VBbeta * temp1;
    beta1 = VBXV * worky;
    %do j=1 %to &p2;
      temp = NB(order[, &j], B&j);
      a&j = (theta1[&j] # temp`) * vinv * (worky - X*beta1);
    %end;
    vinv0 = vinv;
    %if &method=REML %then %do;
      vinv = vinv - (temp1)` * VBXV; /* projection matrix under GLMM */  
    %end;
  %end;

  %findf;

  resid = worky - X[, 1:nx] * beta1[1:nx];

  %do j=1 %to &p2;
    resid = resid - Nf&j;
  %end;

  %if &c>0 %then %do;              /* find random effects */

    do i=1 to m;
      W = formmat(WM[vstart[i]:vend[i]]);
      residi = resid[m1[i]: m2[i]]; 
      Zi = Z[m1[i]: m2[i],];      
      %if &type^=SIM %then %do;
        bvec[bcut1[i]:bcut2[i]] = D * (Zi)` * W * residi;
      %end;
      %else %do;
        do j=1 to &c;
          Zi[, q1[j]:q2[j]] = theta1[&d3+j-1] # Zi[, q1[j]:q2[j]];
        end;
        bvec[bcut1[i]:bcut2[i]] = (Zi)` * W * residi;
      %end; 
    end;
  %end;

  %if &prs>0 %then %do;           /* find stochastic process */
    
    do i=1 to m;
      W = formmat(WM[vstart[i]:vend[i]]);
      residi = resid[m1[i]: m2[i]];
      E = j(_n[i], _n[i], 0);
   
      %if &process=AR %then                       /*     AR case      */ 
        %arvarn; 
      %else %if &process=OU %then                 /*     OU case      */  
        %ouvarn;
      %else %if &process=NOU1 %then               /*     NOU1 case    */ 
        %nou1varn;
      %else %if &process=NOU2 %then               /*     NOU2 case    */ 
        %nou2varn;
      %else %if &process=NOU3 %then               /*     NOU3 case    */ 
        %nou3varn;
      %else %if &process=IOU %then                /*     IOU case     */
        %iouvarn;
      %else %if &process=W %then                  /*     Wiener case  */
        %wvarn;
      %else %if &process=IW %then                 /*     IW case      */
        %iwvarn;
      %else %if &process=NOU4 %then               /*     NOU4 case    */ 
        %nou4varn;
      %else %if &process=NOU5 %then               /*     NOU5 case    */ 
        %nou5varn;
      %else %if &process=NOU6 %then               /*     NOU6 case    */ 
        %nou6varn;
      %else %if &process=NOU7 %then               /*     NOU7 case    */ 
        %nou7varn;
     
      uvec[m1[i]:m2[i]] = E * W * residi;
    end;
  %end;

 
%mend findbeta;


  /**********************************************************/
  /*                                                        */
  /*     The folowing macros find the derivatives of        */
  /*   the variance matrices for different processes        */
  /*                                                        */ 
  /**********************************************************/ 

%macro arderv;      /* Deriv of var for AR case  */

  tempV&d5 = j(_n[i], _n[i], 0);      /* d(V)/d(theta(d5))        */
  tempV&d6 = j(_n[i], _n[i], 1);      /* d(V)/d(theta(d6))        */

  if _n[i] > 1 then do;

    tempV&d5[1,2] = theta0[&d6];
    tempV&d6[1,2] = theta0[&d5];
      
    if _n[i] > 2 then do;
      do k=3 to _n[i];
        tempV&d5[1,k] = tempV&d5[1,(k-1)] * theta0[&d5] * (k-1)/(k-2);
        tempV&d6[1,k] = tempV&d6[1,(k-1)] * theta0[&d5];  
      end;

      do k=2 to _n[i];     
        do j=2 to _n[i]+1-k;
          tempV&d5[j, j+k-1] = tempV&d5[1,k];
          tempV&d6[j, j+k-1] = tempV&d6[1,k];
        end;
      end;

      do k=2 to _n[i];
        do j=1 to _n[i]+1-k;
          tempV&d5[j+k-1,j] = tempV&d5[j, j+k-1];
          tempV&d6[j+k-1,j] = tempV&d6[j, j+k-1];
        end;
      end;
    end;

  end;

%mend arderv;


%macro ouderv;     /* Deriv of var for OU case   */

  tempV&d5 = j(_n[i], _n[i], 0);      /* d(V)/d(theta(d5))        */
  tempV&d6 = j(_n[i], _n[i], 1);      /* d(V)/d(theta(d6))        */

  timei=time[m1[i]:m2[i]];
  logrho=log(theta0[&d5]);
  ratio=theta0[&d6]/theta0[&d5];

  do j=2 to _n[i];
    do k=1 to j-1;
      dist=abs(timei[k]-timei[j]);

      tempV&d6[j,k] = exp(dist*logrho);
      tempV&d6[k,j] = tempV&d6[j,k];

      tempV&d5[j,k] = tempV&d6[j,k]*dist*ratio;
      tempV&d5[k,j] = tempV&d5[j,k];
    end;
  end; 

%mend ouderv;


%macro nou1derv;      /* Deriv of var mat for NOU1 case  */

  %do j=&d5 %to &d6;
    tempV&j = j(_n[i], _n[i], 0);
  %end;

  timei=time[m1[i]:m2[i]];
  
  %if %length(&gt)>0 and &gt ^=&time %then %do;
    gti=gt[m1[i]:m2[i]];
  %end;
  %else %do;
     gti=timei;
  %end;

  temp=theta0[&d6]*gti;
  logrho=log(theta0[&d5]);

  %let ind=%eval(&d5+1);

  do j=1 to _n[i];
    tempV&ind[j,j] = exp(theta0[&d5+1]+temp[j]);
    tempV&d6[j,j] = tempV&ind[j,j]*gti[j];
  end;


  do j=2 to _n[i];
    do k=1 to j-1;
      dist=abs(timei[k]-timei[j]);
      avg=(temp[k]+temp[j])/2;

      tempV&ind[j,k] = exp(theta0[&d5+1]+avg+dist*logrho);
      tempV&ind[k,j] = tempV&ind[j,k];
   
      tempV&d5[j,k] = tempV&ind[j,k] * dist / theta0[&d5];
      tempV&d5[k,j] = tempV&d5[j,k];

      tempV&d6[j,k] = tempV&ind[j,k] * (gti[k]+gti[j])/2;      
      tempV&d6[k,j] = tempV&d6[j,k];
    end;
  end;

%mend nou1derv;


%macro nou2derv;      /* Deriv of var mat for NOU2 case  */

  %do j=&d5 %to &d6;
    tempV&j = j(_n[i], _n[i], 0);
  %end;

  timei=time[m1[i]:m2[i]];
  logrho=log(theta0[&d5]);

  %let ind1=%eval(&d5+1);
  %let ind2=%eval(&d5+2);

  temp=exp(theta0[&ind1]*timei);
  temp1=theta0[&d6]*temp;
  temp2=timei#temp;
  temp3=theta0[&d6]*temp2;

  do j=1 to _n[i];
    tempV&ind2[j,j] = exp(theta0[&ind2]+temp1[j]);
    tempV&ind1[j,j] = tempV&ind2[j,j]*theta0[&d6]*temp2[j];
    tempV&d6[j,j] = tempV&ind2[j,j]*temp[j];
  end;

  do j=2 to _n[i];
    do k=1 to j-1;
      dist=abs(timei[k]-timei[j]);
      avg=(temp1[k]+temp1[j])/2;

      tempV&ind2[j,k] = exp(theta0[&ind2]+avg+dist*logrho);
      tempV&ind2[k,j] = tempV&ind2[j,k];

      tempV&ind1[j,k] = tempV&ind2[j,k]*(temp3[j]+temp3[k])/2;
      tempV&ind1[k,j] = tempV&ind1[j,k]; 

      tempV&d5[j,k] = tempV&ind2[j,k] * dist / theta0[&d5];
      tempV&d5[k,j] = tempV&d5[j,k];

      tempV&d6[j,k] = tempV&ind2[j,k] * (temp[k]+temp[j])/2;;      
      tempV&d6[k,j] = tempV&d6[j,k];
    end;
  end;

%mend nou2derv;


%macro nou3derv;      /* Deriv of var mat for NOU3 case  */

  %do j=&d5 %to &d6;
    tempV&j = j(_n[i], _n[i], 0);
  %end;

  %let ind1=%eval(&d5+1);
  %let ind2=%eval(&d5+2);

  timei=time[m1[i]:m2[i]];
  timei2 = timei##2;

  temp=theta0[&ind2]*timei + theta0[&d6]*timei2;
  logrho=log(theta0[&d5]);

  do j=1 to _n[i];
    tempV&ind1[j,j] = exp(theta0[&ind1]+temp[j]);
    tempV&ind2[j,j] = tempV&ind1[j,j]*timei[j];
    tempV&d6[j,j] = tempV&ind1[j,j]*timei2[j];
  end;


  do j=2 to _n[i];
    do k=1 to j-1;
      dist=abs(timei[k]-timei[j]);
      avg=(temp[k]+temp[j])/2;

      tempV&ind1[j,k] = exp(theta0[&ind1]+avg+dist*logrho);
      tempV&ind1[k,j] = tempV&ind1[j,k];
   
      tempV&d5[j,k] = tempV&ind1[j,k] * dist / theta0[&d5];
      tempV&d5[k,j] = tempV&d5[j,k];

      tempV&ind2[j,k] = tempV&ind1[j,k] * (timei[k]+timei[j])/2;      
      tempV&ind2[k,j] = tempV&ind2[j,k];

      tempV&d6[j,k] = tempV&ind1[j,k] * (timei2[k]+timei2[j])/2;      
      tempV&d6[k,j] = tempV&d6[j,k];
    end;
  end;

%mend nou3derv;


%macro nou4derv;      /* Deriv of var mat for NOU4 case  */

  %do j=&d5 %to &d6;
    tempV&j = j(_n[i], _n[i], 0);
  %end;

  %let ind1=%eval(&d5+1);
  %let ind2=%eval(&d5+2);

  timei=time[m1[i]:m2[i]];
  g1ti=g1t[m1[i]:m2[i]];
  g2ti=g2t[m1[i]:m2[i]];

  temp=theta0[&ind2]*g1ti + theta0[&d6]*g2ti;
  logrho=log(theta0[&d5]);

  do j=1 to _n[i];
    tempV&ind1[j,j] = exp(theta0[&ind1]+temp[j]);
    tempV&ind2[j,j] = tempV&ind1[j,j]*g1ti[j];
    tempV&d6[j,j] = tempV&ind1[j,j]*g2ti[j];
  end;


  do j=2 to _n[i];
    do k=1 to j-1;
      dist=abs(timei[k]-timei[j]);
      avg=(temp[k]+temp[j])/2;

      tempV&ind1[j,k] = exp(theta0[&ind1]+avg+dist*logrho);
      tempV&ind1[k,j] = tempV&ind1[j,k];
   
      tempV&d5[j,k] = tempV&ind1[j,k] * dist / theta0[&d5];
      tempV&d5[k,j] = tempV&d5[j,k];

      tempV&ind2[j,k] = tempV&ind1[j,k] * (g1ti[k]+g1ti[j])/2;      
      tempV&ind2[k,j] = tempV&ind2[j,k];

      tempV&d6[j,k] = tempV&ind1[j,k] * (g2ti[k]+g2ti[j])/2;      
      tempV&d6[k,j] = tempV&d6[j,k];
    end;
  end;

%mend nou4derv;

%macro nou5derv;      /* Deriv of var mat for NOU5 case  */

  %do j=&d5 %to &d6;
    tempV&j = j(_n[i], _n[i], 0);
  %end;

  %let ind1=%eval(&d5+1);
  %let ind2=%eval(&d5+2);

  timei=time[m1[i]:m2[i]];
  timei2=timei##2;

  temp=theta0[&ind1]+theta0[&ind2]*timei + theta0[&d6]*timei2;
  logrho=log(theta0[&d5]);

  do j=1 to _n[i];
    tempV&ind1[j,j] = 1;
    tempV&ind2[j,j] = timei[j];
    tempV&d6[j,j] = timei2[j];
  end;


  do j=2 to _n[i];
    do k=1 to j-1;
      dist=abs(timei[k]-timei[j]);
      temp1 = sqrt(temp[k]/temp[j]);
      temp2 = exp(dist*logrho);
      temp3 = sqrt(temp[k]*temp[j]);

      tempV&ind1[j,k] = (temp1+1/temp1)*temp2/2;
      tempV&ind1[k,j] = tempV&ind1[j,k];
   
      tempV&d5[j,k] = temp3 * dist * temp2 / theta0[&d5];
      tempV&d5[k,j] = tempV&d5[j,k];

      tempV&ind2[j,k] = (temp1*timei[j]+timei[k]/temp1)*temp2/2;     
      tempV&ind2[k,j] = tempV&ind2[j,k];

      tempV&d6[j,k] =  (temp1*timei2[j]+timei2[k]/temp1)*temp2/2;   
      tempV&d6[k,j] = tempV&d6[j,k];
    end;
  end;

%mend nou5derv;


%macro nou6derv;      /* Deriv of var mat for NOU6 case  */

  %do j=&d5 %to &d6;
    tempV&j = j(_n[i], _n[i], 0);
  %end;

  timei=time[m1[i]:m2[i]];
  
  %if %length(&gt)>0 and &gt ^= &time %then %do;
    gti=gt[m1[i]:m2[i]];
  %end;
  %else %do;
     gti=timei;
  %end;

 %let ind=%eval(&d5+1);

  temp=theta0[&ind]+theta0[&d6]*gti;
  logrho=log(theta0[&d5]);

  do j=1 to _n[i];
    tempV&ind[j,j] = 1;
    tempV&d6[j,j] = gti[j];
  end;


  do j=2 to _n[i];
    do k=1 to j-1;
      dist=abs(timei[k]-timei[j]);
      temp1 = sqrt(temp[k]/temp[j]);
      temp2 = exp(dist*logrho);
      temp3 = sqrt(temp[k]*temp[j]);

      
      tempV&ind[j,k] = (temp1+1/temp1)*temp2/2;
      tempV&ind[k,j] = tempV&ind[j,k];
   
      tempV&d5[j,k] = temp3 * dist * temp2 / theta0[&d5];;
      tempV&d5[k,j] = tempV&d5[j,k];

      tempV&d6[j,k] = (temp1*gti[j]+gti[k]/temp1)*temp2/2;    
      tempV&d6[k,j] = tempV&d6[j,k];
    end;
  end;

%mend nou6derv;


%macro nou7derv;      /* Deriv of var mat for NOU7 case  */

  %do j=&d5 %to &d6;
    tempV&j = j(_n[i], _n[i], 0);
  %end;

  %let ind1=%eval(&d5+1);
  %let ind2=%eval(&d6+2);

  timei=time[m1[i]:m2[i]];
  g1ti=g1t[m1[i]:m2[i]];
  g2ti=g2t[m1[i]:m2[i]];

  temp=theta0[&ind1] + theta0[&ind2]*g1ti + theta0[&d6]*g2ti;
  logrho=log(theta0[&d5]);

  do j=1 to _n[i];
    tempV&ind1[j,j] = 1;
    tempV&ind2[j,j] = g1ti[j];
    tempV&q2[j,j] = g2ti[j];
  end;


  do j=2 to _n[i];
    do k=1 to j-1;
      dist=abs(timei[k]-timei[j]);

      temp1 = sqrt(temp[k]/temp[j]);
      temp2 = exp(dist*logrho);
      temp3 = sqrt(temp[k]*temp[j]);

      tempV&ind1[j,k] = (temp1+1/temp1)*temp2/2;
      tempV&ind1[k,j] = tempV&ind1[j,k];
   
      tempV&d5[j,k] = temp3 * dist * temp2 / theta0[&d5];
      tempV&d5[k,j] = tempV&d5[j,k];

      tempV&ind2[j,k] = (temp1*g1ti[j]+g1ti[k]/temp1)*temp2/2;     
      tempV&ind2[k,j] = tempV&ind2[j,k];

      tempV&d6[j,k] =  (temp1*g2ti[j]+g2ti[k]/temp1)*temp2/2;   
      tempV&d6[k,j] = tempV&d6[j,k];
 
    end;
  end;

%mend nou7derv;


%macro iouderv;         /* Deriv of var mat for IOU case  */

  tempV&d5 = j(_n[i], _n[i], 0);      /* d(V)/d(theta(q1))        */
  tempV&d6 = j(_n[i], _n[i], 0);      /* d(V)/d(theta(q2))        */
  
  timei=time[m1[i]:m2[i]];
  temp=theta0[&d5]*timei;
  temp1=exp(-temp);
  temp2=timei#temp1;
  
  alpha2=theta0[&d5]**2;
  ratio=theta0[&d6]/theta0[&d5];

  do j=1 to _n[i];
    tempV&d6[j,j] = 2*(temp[j]+temp1[j]-1)/alpha2;
    tempV&d5[j,j] = 2*((timei[j]-temp2[j])/theta0[&d5] - tempV&d6[j,j])*ratio;
  end;

  do j=2 to _n[i];
    do k=1 to j-1;
      dist=abs(timei[j]-timei[k]); 
      mst=min(temp[j], temp[k]);
            
      tempV&d6[j,k] = (2*mst+temp1[j]+temp1[k]-1-exp(-theta0[&d5]*dist))/alpha2;
      tempV&d6[k,j] = tempV&d6[j,k];
      
      mst=min(timei[j],timei[k]); 
      tempV&d5[j,k] = ((2*mst-temp2[j]-temp2[k]
                  +dist*exp(-theta0[&d5]*dist))/theta0[&d5] 
                  - 2*tempV&d6[j,k])*ratio;
      tempV&d5[k,j] = tempV&d5[j,k];       

    end;
  end;  

%mend iouderv;


%macro wderv;         /* Deriv of var mat for Wiener case  */
  
  tempV&d5 = j(_n[i], _n[i], 0);        /* d(V)/d(theta(d5))        */
  timei = time[m1[i]:m2[i]];

  do j=1 to _n[i];
    tempV&d5[j,j] = timei[j];
  end;    

  do j=2 to _n[i];
    do k=1 to j-1;   
      tempV&d5[j,k] = min(timei[j], timei[k]);
      tempV&d5[k,j] = tempV&d5[j,k];
    end;
  end;

%mend wderv;

%macro iwderv;      /* Deriv of var mat for IW case  */
  
  tempV&d5 = j(_n[i], _n[i], 0);      /* d(V)/d(theta(d5))        */
  timei = time[m1[i]:m2[i]];

  do j=1 to _n[i];
    do k=1 to j;   
      time1=min(timei[j],timei[k]);
      time2=max(timei[j],timei[k]); 
      tempV&q1[j,k] = time1**2*(3*time2-time1)/6;
    end;
  end;  

  do j=2 to _n[i];
    do k=1 to j-1;
      tempV&d5[k,j] = tempV&d5[j,k]; 
    end;
  end; 

%mend iwderv;


/* Macro to find derivatives */

%macro findderv;

  %if &c>0 %then %do;
    %if &type ^=SIM %then %do;
      %do j=&d3 %to &d4;
        a = rowcol(&j-&d3+1);
        z1 = Z[m1[i]:m2[i], a[1]];
        z2 = Z[m1[i]:m2[i], a[2]];
        temp = z1 * (z2)`;
        
        if a[1] ^= a[2] then 
          temp = temp + (temp)`;

        %if &coefdim < &n %then %do;
          WV&j = W * temp;
          %if &method=REML %then %do;
            HWV&j = (WH)` * temp;
          %end;
        %end;
        %else %do;
          V&j[vstart[i]:vend[i]] = formvec(temp);
        %end;
      %end;
    %end;
    %else %do;
      %do j=&d3 %to &d4;
        z1 = Z[m1[i]:m2[i], q1[&j-&d3+1]:q2[&j-&d3+1]];
        temp = z1 * (z1)`;
        %if &coefdim < &n %then %do;
          WV&j = W * temp;
          %if &method=REML %then %do;
            HWV&j = (WH)` * temp;
          %end;
        %end;
        %else %do;
          V&j[vstart[i]:vend[i]] = formvec(temp);
        %end; 
      %end;
    %end;
  %end;

  %if &prs>0 %then %do;
    %if &process=AR %then 
      %arderv;
    %else %if &process=OU %then
      %ouderv;
    %else %if &process=NOU1 %then 
      %nou1derv;
    %else %if &process=NOU2 %then 
      %nou2derv;
    %else %if &process=NOU3 %then 
      %nou3derv;
    %else %if &process=IOU %then
      %iouderv;
    %else %if &process=W %then
      %wderv;
    %else %if &process=IW %then
      %iwderv;
    %else %if &process=NOU4 %then 
      %nou4derv;
    %else %if &process=NOU5 %then 
      %nou5derv;
    %else %if &process=NOU6 %then 
      %nou6derv;
    %else %if &process=NOU7 %then 
      %nou7derv;
  %end; 

  %if &coefdim < &n %then %do;
    %do j=&d5 %to &d6;
      WV&j = W * tempV&j;
      %if &method=REML %then %do;
        HWV&j = (WH)` * tempV&j;
      %end;
    %end;
  %end;
  %else %do;
   %do j=&d5 %to &d6;
     V&j[vstart[i]:vend[i]] = formvec(tempV&j);
   %end;
  %end;

  %do j=&d5 %to &d6;
    free tempV&j;
  %end;

  %if &dispers=Y %then %do;
    temp = diag(Vderv[m1[i]:m2[i]]);
    %if &coefdim < &n %then %do;
      WV&d8 = W * temp;
      %if &method=REML %then %do;
        HWV&d8 = (WH)` * temp;
      %end;
    %end;
    %else %do;
      V&d8[vstart[i]:vend[i]] = formvec(temp);
    %end;    
  %end;  

  %if &method=REML %then %do;
    %if &coefdim < &n %then %do;
      %do j=&d3 %to &d8;
        FM&j = FM&j + HWV&j * WH;
      %end;
      %if &ltest=0 and &vtest=0 %then  
        %do j=&d3 %to &d8;
           %do k=&j %to &d8;
             F&j&k = F&j&k + HWV&j * WV&k * WH; 
           %end;
        %end;
    %end; 
  %end;
  free temp;

%mend findderv;


/* Macro to find theta and smoothing parameters when coefdim < n */

%macro case1;

  %if &method=REML %then %do;
    %do j=&d3 %to &d8;
      FM&j = j(dimbt,dimbt , 0);
      %do k=&j %to &d8;
        F&j&k = j(dimbt, dimbt, 0);
      %end; 
    %end;
  %end;
    
  %do j=1 %to &d2;
    u&j = j(1, rknot[&j], 0);
    HC&j = C0[cut1[&j]:cut2[&j],]*Cinv;
    %do k=&j %to &d2; 
      temp1 = C0[cut1[&j]:cut2[&j], cut1[&k]:cut2[&k]];
      temp2 = C0[,cut1[&k]:cut2[&k]];
      temp3 = temp1 - HC&j * temp2;
      temp4 = (temp3)`;
      if &k=&j then
        Deriv[&j] = - trace(temp3);
      Fisher[&j, &k] = trc(temp3, temp4);
    %end;
  %end;

  do i=1 to m;

    residi = resid[m1[i]: m2[i]];
    W = formmat(WM[vstart[i]:vend[i]]);
    Hi = X[m1[i]: m2[i], ];
    %do j=1 %to &d2;
      Hi = Hi || NBi(i, order[m1[i]: m2[i],&j], B&j);
    %end;
    WH = W * Hi;
    %do j=1 %to &d2;
      u&j = u&j + (residi)` * WH[, cut1[&j]:cut2[&j]]; 
    %end;
 
    %if &d8>&d2 %then 
      %findderv;

    %do j=&d3 %to &d8;
      Deriv[&j] = Deriv[&j] + ((residi)`*WV&j) * (W*residi) - trace(WV&j);
      %do k=&j %to &d8;
        temp = WV&k;
        Fisher[&j, &k] = Fisher[&j, &k] + trc(WV&j, temp);
      %end;
    %end;

  end;  

  %do j=1 %to &d2;
    Deriv[&j] = Deriv[&j] + u&j * (u&j)`;
  %end;

  %if &method=REML %then %do;
    %do j=1 %to &d2;
      temp&j = C0[, cut1[&j]:cut2[&j]] * HC&j;
      %do k=&d3 %to &d8;
        Fisher[&j, &k] = trace(FM&k[cut1[&j]:cut2[&j],cut1[&j]:cut2[&j]])
          - 2*trc(FM&k[ ,cut1[&j]:cut2[&j]], HC&j);
      %end;
    %end;
 
    %do j=&d3 %to &d8;
       FM&j = FM&j * Cinv;
    %end;

    %do j=1 %to &d2;
       %do k=&d3 %to &d8;
         Fisher[&j, &k] = Fisher[&j, &k] + trc(temp&j, FM&k);
       %end;
    %end; 

    %do j=&d3 %to &d8;
      Deriv[&j] = Deriv[&j] + trace(FM&j);
      %do k=&j %to &d8;
        temp = FM&k;
        Fisher[&j, &k] = Fisher[&j, &k] - 2 * trc(F&j&k, Cinv)
          + trc(FM&j, temp);
      %end;
    %end;   
  %end;

  Deriv = Deriv / 2;

  do i=2 to &d8;
    do j=1 to i-1;
      Fisher[i,j] = Fisher[j,i];
    end;
  end;

  Fisher = Fisher/2;

  Finv = inv(Fisher);
  theta1 = Finv * Deriv + theta0;

%mend case1;


/* Macro to find theta and smoothing parameters when coefdim >= n */

%macro case2;

  %do j=1 %to &d2;
    u&j = j(1, rknot[&j], 0);
    temp = NB(order[,&j], B&j);
    temp1&j = vinv * temp;
    temp2&j = (temp)` * temp1&j;
  %end;

  %do j=1 %to &d2;
    Deriv[&j] = - trace(temp2&j); 
    %do k=&j %to &d2;
      %if &k=&j %then %do;
        temp = temp2&k;       
        Fisher[&j, &k] = trc(temp, temp2&j);
      %end;
      %else %do;
        temp =  NB(order[,&k], B&k);
        temp1 = (temp)` * temp1&j;
        temp = (temp1)`;
        Fisher[&j, &k] = trc(temp, temp1);
      %end;
    %end;
  %end; 


  do i=1 to m;
    %if &d8>&d2 %then
      %findderv;

  end;

  do i=1 to m;

    residi = resid[m1[i]: m2[i]];
    W = formmat(WM[vstart[i]:vend[i]]);
    Wr = W * residi;
    %do j=1 %to &d2;
      Hi = NBi(i, order[m1[i]: m2[i],&j], B&j); 
      u&j = u&j + (Wr)` * Hi; 
    %end;

    %do j=&d3 %to &d8;
       temp = vinv[m1[i]: m2[i], m1[i]: m2[i]]; 
       temp2 = formmat(V&j[vstart[i]:vend[i]]); 
       Deriv[&j] = Deriv[&j] + (Wr)` * temp2 * Wr - trc(temp, temp2); 
    %end;

  end;

  %do j=1 %to &d2;
     temp1 = temp1&j; 
     %do k=&d3 %to &d8;
       temp2 = (temp1)`;
       do i=1 to m;
         temp = formmat(V&k[vstart[i]:vend[i]]); 
         temp2[, m1[i]: m2[i]] = temp2[, m1[i]: m2[i]] * temp;
       end;
       Fisher[&j, &k] = trc(temp2, temp1); 
     %end;
  %end;

  %do j=&d3 %to &d8;
    temp1 = vinv;
    do i=1 to m;
      temp = formmat(V&j[vstart[i]:vend[i]]);
      temp1[, m1[i]: m2[i]] = temp1[, m1[i]: m2[i]] * temp;
    end;
    %do k=&j %to &d8;
       %if &k=&j %then %do;
         temp2 = temp1;
       %end;
       %else %do;
         do i=1 to m;
           temp2 = vinv;
           temp = formmat(V&k[vstart[i]:vend[i]]);
           temp2[, m1[i]: m2[i]] = temp2[, m1[i]: m2[i]] * temp;
         end;
       %end;
       Fisher[&j,&k] = trc(temp1, temp2);
    %end;
  %end;
  
  %do j=1 %to &d2;
    Deriv[&j] = Deriv[&j] + u&j *  (u&j)`;
  %end;

  Deriv = deriv / 2;

  do i=2 to &d8;
    do j=1 to i-1;
      Fisher[i,j] = Fisher[j,i];
    end;
  end;

  Fisher = Fisher/2;

  Finv = inv(Fisher);
  theta1 = Finv * Deriv + theta0;

%mend case2;


/* Macro to find theta and smoothing parameters */

%macro findpar;
  
  Deriv = j(&d8, 1, 0);
  Fisher = j(&d8, &d8, 0);

  %if &coefdim < &n %then
    %case1;
  %else 
    %case2;

%mend findpar;


%macro prog;

  %Initial;

  iternum = 1;
  beta0 = beta1;
  %if &d8>0 %then %do;
    theta0 = theta1;
  %end;

  %if &print^=N %then %do;
    criteria = j(101, 1, .);
  %end;

  %formwork;

  %findbeta;

  %if &d8>0 %then %do;

    %findpar;

    %findcrt2; 

    do while (crit2=0);
      theta1 = (theta0 + theta1)/2;
      %findcrt2;
    end;

  %end;

  temp1 = beta1[1:fixnum];
  temp2 = beta0[1:fixnum];
  temp = abs(temp1 - temp2);
  temp2 = abs(temp1) + abs(temp2);
  temp = temp / temp2;
  crit1 = max(temp);

  if &d8>0 then do;
    temp1 = abs(theta1-theta0);
    temp2 = abs(theta1) + abs(theta0);
    temp = temp1 / temp2;
    tempcrit = max(temp);

    crit1 = max(crit1, tempcrit);
  end;

  crit1 = 2*crit1;

  %if &print^=N %then %do;
    criteria[2] = crit1;
  %end;

  crit3 = 1;
  do i=1 to &d2;
    if (theta1[i]>uplim) | (theta1[i]<lowlim) then
      crit3=0;
  end;

  contin = (crit1 > &conv) & crit3; 
 
  do while (contin & (iternum < &maxiter));

    iternum = iternum + 1;
    beta0 = beta1;
    %if &d8>0 %then %do;
      theta0 = theta1; 
    %end;

    %formwork;

    %findbeta;
    
    %if &d8>0 %then %do;  

      %findpar;
 
      %findcrt2;
 
      do while (crit2=0);
        theta1 = (theta0 + theta1)/2;
        %findcrt2;
      end;

    %end;

    temp1 = beta1[1:fixnum];
    temp2 = beta0[1:fixnum];
    temp = abs(temp1 - temp2);
    temp2 = abs(temp1) + abs(temp2);
    temp = temp / temp2;
    crit1 = max(temp);

    if &d8>0 then do;
      temp1 = abs(theta1-theta0);
      temp2 = abs(theta1) + abs(theta0);
      temp = temp1 / temp2;
      tempcrit = max(temp);

      crit1 = max(crit1, tempcrit);
    end;

    crit1 = 2*crit1;

    %if &print^=N %then %do;
      criteria[iternum+1] = crit1;
    %end;

    crit3 = 1;
    do i=1 to &d2;
      if (theta1[i]>uplim) | (theta1[i]<lowlim) then
        crit3=0;
    end;

    contin = (crit1 > &conv) & crit3;
   
  end;

  converg = (crit1 <= &conv); 

  %if &print^=N and &ltest=0 and &vtest=0 %then %do;
    temp = criteria[1: iternum+1];
    criteria = temp;
    if iternum>10 then do;
      criteria = criteria[1:5] // criteria[iternum-4:iternum+1];
      iternum = (0:4)`//(iternum-4:iternum+1)`;
    end;
    else 
      iternum = (0:iternum)`;
  %end;

  %if &method=REML and &coefdim < &n %then
    %do j=&d3 %to &d8;
      free FM&j;
      %do k=&j %to &d8;
        free F&j&k;
      %end;
    %end;

  %if &coefdim > &n and &ltest=0 and &vtest=0 %then
    %do j=&d3 %to &d8;
      free V&j;
    %end;

%mend prog;


%macro outinfo;

  print, "Iteration History";

  print iternum criteria;

  if contin=0 then do;
    if crit1 <= &conv then 
      print, "Convergence criteria met.";
    else do;
      print, "Program did not converge.";
      print "At least one smoothing parameter coverged to boundary.";
    end; 
  end; 
  else 
    print, "Program did not converge."; 

  descript = m // n;
  rname = {"Number of Subjects" "Number of Observations"
    %do j=1 %to &p2;
      %let temp = %scan(&X2,&j);
      "Number of Knots of &temp"&_space 
    %end;};
  %do j=1 %to &p2;
    descript = descript // nknot[&j];
  %end;

  cname={"VALUE"};  
  print, "Model Fitting Information for &dep",,
          descript [rowname=rname colname=cname];

  %if &c>0 and &type^=SIM %then %do;
    rname={
      %do i=1 %to &q;
        %let temp="%upcase(%scan(&Z, &i))"&_space; &temp
      %end;};
    cname=rname;
    if converg=1 | &keeplast=Y then do;
      print,, 'Covariance Matrix for Random Effects',,
              D [rowname=rname colname=cname];
    end;
  %end;

  free iternum criteria descript cname;

%mend outinfo;


   /***********************************************/
   /*                                             */
   /*   Macro OUTVARN outputs the estimates       */
   /*  and se of the smmothing and variance       */
   /*  components                                 */
   /*                                             */
   /***********************************************/

%macro outvarn;

  if converg=1 | &keeplast=Y then do;
    _se = sqrt(vecdiag(Finv)); 
    chisq =  (theta1 / _se)##2;  
    p_value = 1 - probchi(chisq, 1);
  end;
  else do;
    _se = j(&d8, 1, .);
    theta1 = _se;
    chisq = _se;
    p_value = _se;
  end;

  var_se = theta1 || _se || chisq || p_value;

  cov_parm = {%do j=1 %to &d2; "Smooth&j"&_space %end;
    %if &type=SIM %then 
      %do j=1 %to &c;
        "Theta&j"&_space
      %end;
    %else
    %do i=1 %to &q;
      %do j=1 %to &i;
        "D(&i,&j)"&_space
      %end;
    %end;
    %if &prs>0 %then %do;
      %if &process=AR %then %do;
        "AR"&_space "Diag"&_space %end;
      %else %if &process=OU %then %do;
         "Rho"&_space "Diag"&_space %end;
      %else %if &process=NOU1 %then %do;
         "Rho"&_space "A0"&_space "A1"&_space %end;
      %else %if &process=NOU2 %then %do;
         "Rho"&_space "Alpha"&_space "A0"&_space "A1"&_space %end;
      %else %if &process=NOU3 %then %do;
         "Rho"&_space "A0"&_space "A1"&_space "A2"&_space %end;
      %else %if &process=IOU %then %do;
         "Alpha"&_space "Sigma^2"&_space %end;
      %else %if &process=W %then %do;
         "Sigma^2"&_space %end;
      %else %if &process=IW %then %do;
         "Sigma^2"&_space %end; 
      %else %if &process=NOU4 %then %do;
         "Rho"&_space "A0"&_space "A1"&_space "A2"&_space %end;
      %else %if &process=NOU5 %then %do;
         "Rho"&_space "A0"&_space "A1"&_space "A2"&_space %end; 
      %else %if &process=NOU6 %then %do;
         "Rho"&_space "A0"&_space "A1"&_space %end;  
      %else %if &process=NOU7 %then %do;
         "Rho"&_space "A0"&_space "A1"&_space "A2"&_space %end;    
    %end;
    %if &dispers=Y %then %do;
      %if &dist=NORMAL %then
        %str("Residual");
      %else
        %str("Phi");
    %end;};


  col = {"Estimate"  "Se"  "Chisq"  "P_value"};

  %if &print^=N %then %do;
    create var_se&cor from var_se[rowname=cov_parm colname=col];
    append from var_se[rowname=cov_parm];
  %end; 
         
  cov_parm = {"Correct"} || cov_parm;
  %if &cor=0 %then %do;  
    %if %length(&outvar)>0 %then %do;
      _var = 0 || (theta1)`;
      create &outvar from _var[colname=cov_parm];
      append from _var;
    %end;

    %if %length(&outvstd)>0 %then %do;
      _std = 0 || (_se)`;
      create &outvstd from _std[colname=cov_parm];
      append from _std;
    %end;
  %end;
  %else %do;
    %if %length(&outvar)>0 %then %do;
      _var = 1 || (theta1)`;
      create _outvar1 from _var[colname=cov_parm];
      append from _var;
    %end;

    %if %length(&outvstd)>0 %then %do;
      _std = 1 || (_se)`;
      create _outvsd1 from _std[colname=cov_parm];
      append from _std;
    %end;
  %end;

%mend outvarn;




   /***********************************************/
   /*                                             */
   /*   Macro OUTPARM outputs the estimates       */
   /*  and se of the parameters in the            */
   /*  parametric part                            */
   /*                                             */
   /***********************************************/

%macro outparm;

  %if &p2=0 %then %do;  /* no smoothing */
    if converg=1 | &keeplast=Y then do;
      beta = beta1;
      _se = sqrt(vecdiag(Cinv)); 
      chisq = (beta / _se)##2;
      p_value = 1 - probchi(chisq, 1);
    end;
    else do;
      beta = j(nx, 1, .);
      _se = beta;
      chisq = beta;
      p_value = beta;
    end;

    beta_se = beta || _se || chisq || p_value;
 
    xnames = {"INTERCEPT" 
      %do i=1 %to &p1;
        %let temp="%upcase(%scan(&X1, &i))"&_space; &temp
      %end;};

    col = {"beta"  "se"  "chisq"  "p_value"};      

    %if &prnfix=S %then %do;
      create beta_se&cor from beta_se[rowname=xnames colname=col];
      append from beta_se[rowname=xnames];
    %end;

    xnames = {"Correct"} || xnames;
    %if &cor=0 %then %do;
      %if %length(&outbeta)>0 %then %do;
        _beta = 0 || (beta)`;
        create &outbeta from _beta[colname=xnames];
        append from _beta;
      %end;

      %if %length(&outbstd)>0 %then %do;
        _std = 0 || (_se)`;
        create &outbstd from _std[colname=xnames];
        append from _std;
      %end;
    %end;
    %else %do;
      %if %length(&outbeta)>0 %then %do;
        _beta = 1 || (beta)`;
        create _outbt1 from _beta[colname=xnames];
        append from _beta;
      %end;

      %if %length(&outbstd)>0 %then %do;
        _std = 1 || (_se)`;
        create _outbsd1 from _std[colname=xnames];
        append from _std;
      %end;
    %end;

  %end;     
  %else %do;      /* there is smoothing */
    %if &coefdim<&n %then %do;
      if converg=1 | &keeplast=Y then do;
        beta = beta1[1:nx];
        Vbeta = MM2[1:nx, 1:nx];
        F_se = sqrt(vecdiag(Vbeta));  /* naive freq stderr */
        F_chisq = (beta / F_se)##2; 
        F_p = 1 - probchi(F_chisq, 1);  /* p value based on naive se */
        Vbeta = Cinv[1:nx, 1:nx];
        B_se = sqrt(vecdiag(Vbeta));  /* Bayesian type se  */
        B_chisq = (beta / B_se)##2; 
        B_p = 1 - probchi(B_chisq, 1);  /* p value based on Bayse se */
      end;
      else do;
        beta = j(nx, 1, .); 
        F_se = beta;
        F_chisq = beta;
        F_p = beta;
        B_se = beta;
        B_chisq = beta;
        b_p = beta;
      end;

      beta_se = beta || F_se || F_chisq || F_p || B_se || B_chisq || B_p;
                
    %end;
    %else %do;
      if converg=1 | &keeplast=Y then do;
        beta = beta1[1:nx];
        temp1 = (VBXV)`;
        do i=1 to m;
          Vtemp = formmat(VM[vstart[i]:vend[i]]);
          temp1[m1[i]:m2[i],] = Vtemp * temp1[m1[i]:m2[i],];
        end;
        VFbeta = VBXV * temp1;
        F_se = sqrt(vecdiag(VFbeta[1:nx,1:nx]));   /* naive freq stderr */
        F_chisq = (beta / F_se)##2;        
        F_p = 1 - probchi(F_chisq, 1);  /* p value based on naive se */
        B_se = sqrt(vecdiag(VBbeta[1:nx,1:nx]));   /* Bayesian type se  */
        B_chisq = (beta / B_se)##2; 
        B_p = 1 - probchi(B_chisq, 1);  /* p value based on Bayse se */
      end;
      else do;
        beta = j(nx, 1, .); 
        F_se = beta;
        F_chisq = beta;
        F_p = beta;
        B_se = beta;
        B_chisq = beta;
        b_p = beta;
      end;

      beta_se = beta || F_se || F_chisq || F_p || B_se || B_chisq || B_p;

    %end;

    xnames = {"INTERCEPT" 
      %do i=1 %to &p1;
        %let temp="%upcase(%scan(&X1, &i))"&_space; &temp
      %end;};

    col = {"beta"  "F_se"  "F_chisq"  "F_p" "B_se" "B_chisq" "B_p"};

    %if &prnfix=S %then %do;
      create beta_se&cor from beta_se[rowname=xnames colname=col];
      append from beta_se[rowname=xnames];
    %end;

    xnames = {"Correct"} || xnames;
    %if &cor=0 %then %do;
      %if %length(&outbeta)>0 %then %do;
        _beta = 0 || (beta)`;
        create &outbeta from _beta[colname=xnames];
        append from _beta;
      %end; 

      %if %length(&outbstd)>0 %then %do;
        type={"Freq" "Bays"};
        _std = j(2,1,0) || ((F_se)` // (B_se)`);
        create &outbstd from _std[rowname=type colname=xnames];
        append from _std[rowname=type];
      %end;
    %end;
    %else %do;
      %if %length(&outbeta)>0 %then %do;
        _beta = 1 || (beta)`;
        create _outbt1 from _beta[colname=xnames];
        append from _beta;
      %end; 

      %if %length(&outbstd)>0 %then %do;
        type={"Freq" "Bays"};
        _std = j(2,1,1) || ((F_se)` // (B_se)`);
        create _outbsd1 from _std[rowname=type colname=xnames];
        append from _std[rowname=type];
      %end;
    %end;     

  %end; 

%mend outparm;


   /***********************************************/
   /*                                             */
   /*   Macro OUTRAND outputs the estimates       */
   /* of the random effects                       */
   /*                                             */
   /***********************************************/

%macro outrand;

%if &prnran=S or %length(&outran)>0 %then %do;

  %if &c>0 %then %do;

    subject = j(dimb, 1, 0);
    do i=1 to &m;
      subject[bcut1[i]:bcut2[i]] = id[i];
    end;
      
    ran = subject || bvec;
    Effect = {
       %do k=1 %to &m; 
         %do i=1 %to &nzs;
             %let temp="%upcase(%scan(&Z, &i))"&_space; &temp
         %end; %end;};
              
    col = {"Subject"  "Estimate"};
    %if &prnran=S %then %do;      
      create _ran_ from ran[rowname=Effect colname=col];
      append from ran[rowname=Effect]; 
    %end;   
   
    %if %length(&outran)>0 %then %do;
       col = {"Subject" "Estimate"};
       create &outran from ran[rowname=Effect colname=col];
       append from ran[rowname=Effect];
    %end;

  %end;

%end;

%mend outrand;


   /***********************************************/
   /*                                             */
   /*   Macro OUTPROCS outputs the estimates      */
   /*  of the Gaussian process                    */
   /*                                             */
   /***********************************************/

%macro outprocs;
  
  %if &prs>0 and %length(&outprs)>0 %then %do;
    process = _id || uvec;
    col = {"Subject"  "Process"};
    create &outprs from process[colname=col];
    append from process;    
  %end;       
    
%mend outprocs;

   /***********************************************/
   /*                                             */
   /*   Macro OUTPUTF outputs the estimates,      */
   /*  band and variance of the estimated f(.)    */
   /*                                             */
   /***********************************************/

%macro outputf;

  %if %length(&outband)>0 %then %do;
    %do j=1 %to &p2;
      %if &coefdim<&n %then %do;
      if converg=1 | &keeplast=Y then do;
      %if &intinf1=Y and &j=1 %then %do;
        f1 = f1 + beta1[1];
        temp1 = j(nknot[1],1,1) || CX21 || B1;
        temp2 = MM2[1, cut1[1]:cut2[1]] // MM2[nx+1, cut1[1]:cut2[1]];
        temp3 = (MM2[1, 1] || MM2[1, nx+1])//(MM2[nx+1, 1] || MM2[nx+1, nx+1]);
        temp3 = temp3 || temp2;
        temp4 = (temp2)` || MM2[cut1[1]:cut2[1],cut1[1]:cut2[1]];
        temp2 = temp3 // temp4;
      %end;
      %else %do;
        temp1 = CX2&j || B&j;
        temp2 = MM2[nx+&j, cut1[&j]:cut2[&j]];
        temp3 = MM2[nx+&j, nx+&j] || temp2;
        temp4 = (temp2)` || MM2[cut1[&j]:cut2[&j],cut1[&j]:cut2[&j]];
        temp2 = temp3 // temp4;
      %end;

        Varf = temp1 * temp2 * (temp1)`;    /* freq variance */
        F_se = sqrt(vecdiag(varf));
        temp2 = 1.959964*F_se;
        F_U95 = f&j + temp2;
        F_L95 = f&j - temp2;

      %if &intinf1=Y and &j=1 %then %do; 
        temp2 = Cinv[1, cut1[1]:cut2[1]] // Cinv[nx+1, cut1[1]:cut2[1]]; 
        temp3 = (Cinv[1, 1] || Cinv[1, nx+1])
                //(Cinv[nx+1, 1] || Cinv[nx+1, nx+1]);
        temp3 = temp3 || temp2;
        temp4 = (temp2)` || Cinv[cut1[1]:cut2[1],cut1[1]:cut2[1]];
        temp2 = temp3 // temp4;   
      %end; 
      %else %do;  
        temp2 = Cinv[nx+&j, cut1[&j]:cut2[&j]];
        temp3 = Cinv[nx+&j, nx+&j] || temp2;
        temp4 = (temp2)` || Cinv[cut1[&j]:cut2[&j],cut1[&j]:cut2[&j]];
        temp2 = temp3 // temp4; 
      %end;

        Varf = temp1 * temp2 * (temp1)`;    /* Bayes variance */
        B_se = sqrt(vecdiag(varf)); 
        temp2 = 1.959964*B_se; 
        B_U95 = f&j + temp2;
        B_L95 = f&j - temp2;
      end;        
      %end;
      %else %do;
      if converg=1 | &keeplast=Y then do;
        if &lambda=0 then
          taoj = theta1[&j];
        else 
          taoj = smooth[&j];

        temp3 = temp1&j;
        do i=1 to m;
          temp4 = formmat(VM[vstart[i]:vend[i]]);
          temp3[m1[i]:m2[i],] = temp4 * temp3[m1[i]:m2[i],];
        end;
        temp4 = taoj # (VBXV * temp3);

        temp3 = (taoj**2) # (temp1&j)` * temp3;

      %if &intinf1=Y and &j=1 %then %do;
        f1 = f1 + beta1[1];
        temp1 = j(nknot[1],1,1) || CX2&j || B&j;
        temp2 = (VFbeta[1,1] || VFbeta[1,nx+1])
                //(VFbeta[nx+1,1] || VFbeta[nx+1,nx+1]);        
        temp4 = temp4[1, ] // temp4[nx+1, ];        
      %end;
      %else %do;
        temp1 = CX2&j || B&j;
        temp2 = VFbeta[nx+&j,nx+&j];        
        temp4 = temp4[nx+&j, ];
       %end;

        temp2 = (temp2 || temp4)//((temp4)` || temp3);

        Varf = temp1 * temp2 * (temp1)`;    /* freq variance */
        F_se = sqrt(vecdiag(varf));
        temp2 = 1.959964*F_se;
        F_U95 = f&j + temp2;
        F_L95 = f&j - temp2;        
       
        temp3 = - (taoj**2) # temp2&j;
        do k=1 to rknot[&j];
          temp3[k,k] = temp3[k,k] +  taoj;
        end;

        temp4 = (VBbeta * (X)`) * (vinv - vinv0)*NB(order[, &j], B&j); 
        temp4 = taoj # temp4; 

      %if &intinf1=Y and &j=1 %then %do;
        temp2 = (VBbeta[1,1] || VBbeta[1,nx+1])
                // (VBbeta[nx+1,1] || VBbeta[nx+1,nx+1]);
        temp4 = temp4[1,] // temp4[nx+1,];
      %end;
      %else %do;
        temp2 = VBbeta[nx+&j,nx+&j];
        temp4 = temp4[nx+&j, ];
      %end;

 
        temp2 = (temp2 || temp4)//((temp4)` || temp3);

        Varf = temp1 * temp2 * (temp1)`;    /* Bayes variance */
        B_se = sqrt(vecdiag(varf));
        temp2 = 1.959964*B_se;
        B_U95 = f&j + temp2;
        B_L95 = f&j - temp2;
      end;
      %end;
      if converg=1 | &keeplast=Y then
        temp = X2&j || f&j || F_se || F_L95 || F_U95 
               || B_se || B_L95 || B_U95;
      else do;
        temp1 = j(nknot[&j], 1, .);
        temp = X2&j || temp1 || temp1 || temp1 || temp1 
               || temp1 || temp1 || temp1;
      end;
      
      %let temp = %scan(&X2, &j);
      temp1 = j(nknot[&j], 1, "&temp");
      smthvar = smthvar // temp1;
      temp = j(nknot[&j], 1, &cor) || temp;

      band = band // temp;
    %end;
    cname = {"Correct" "knot" "fhat" "F_Se" "F_L95" "F_U95" 
             "B_Se" "B_L95" "B_U95"};
    %if &cor=0 %then %do;
      create &outband from band[rowname=smthvar colname=cname];
      append from band[rowname=smthvar];
    %end;
    %else %do;
      create _outbnd1 from band[rowname=smthvar colname=cname];
      append from band[rowname=smthvar];
    %end;
    free band;
  %end;


  %if %length(&outsmth)>0 %then %do;
    %if %length(&outband)=0 and &intinf1=Y and &p2>0 %then %do;
      f1 = f1 + beta1[1];
    %end;
    %do j=1 %to &p2;
      r = rknot[&j];
      k = nknot[&j];
      _z=q1&j#f&j[1:r] + q2&j#f&j[2:r+1] + q3&j#f&j[3:r+2];
      _x=j(r,1,0);
     
      /* Solve L(_x)=_z  */
      _x[1]=_z[1];
      do i=2 to r;
        _x[i]=_z[i]-lr&j[i-1]#_x[i-1];
      end; 
      
      _z=_x/dr&j;

      /* Solve L^T(_x)=_z  */
       _x[r]=_z[r];
      do i=1 to r-1;
        _x[r-i]=_z[r-i]-_x[r-i+1]#lr&j[r-i];
      end;

      gamma=j(k, 1, 0);
      gamma[2:r+1]=_x;

      temp = X2&j[k] - X2&j[1];
      _x = j(203, 1, 0);
      spline  = j(203, 1, .);

    if converg=1 | &keeplast=Y then do;

      _x[1] = X2&j[1] - temp*0.05;
      _x[2:202] = X2&j[1] + temp#(0:200)`/200;
      _x[203] = X2&j[k] + temp*0.05;

      f1prime = (f&j[2]-f&j[1])/(X2&j[2]-X2&j[1]) -
         (X2&j[2]-X2&j[1])*gamma[2]/6;
      spline[1] = f&j[1] - (X2&j[1]-_x[1])*f1prime;
      spline[2] = f&j[1];

      i = 3;
      j = 1; 
      do while (j<k);
        temp = X2&j[j+1] - X2&j[j];
        do while (_x[i] <= X2&j[j+1]);
          temp1 = _x[i] - X2&j[j];
          temp2 = X2&j[j+1] - _x[i];
          spline[i] = (temp1*f&j[j+1]+temp2*f&j[j])/temp     
          -temp1*temp2*((1+temp1/temp)*gamma[j+1]+(1+temp2/temp)*gamma[j])/6;
          i = i + 1;
        end;
        j = j + 1;
      end; 

      spline[202] = f&j[k];
      fnprime = (f&j[k] - f&j[k-1])/(X2&j[k]-X2&j[k-1])
            +(X2&j[k]-X2&j[k-1])*gamma[k-1]/6; 
      spline[203] = f&j[k] + (_x[203]-X2&j[k])*fnprime;

    end;

      temp = j(203, 1, &cor) || _x || spline;
 
      out = out // temp;

      %let temp = %scan(&X2, &j);
      temp1 = j(203, 1, "&temp");
      smthvar = smthvar // temp1;
    %end;

    cname = {"Correct" "Knot" "fhat"};
    %if &cor=0 %then %do;
      create &outsmth from out[rowname=smthvar colname=cname];
      append from out[rowname=smthvar];
    %end;
    %else %do;
      create _outsm1 from out[rowname=smthvar colname=cname];
      append from out[rowname=smthvar];
    %end;
    free out;
  %end; 

%mend outputf;


 /* macro to bias-correct tau and theta */

%macro corpar;
  eta = X * beta1[1:fixnum];     /* eta under tau=0 and theta=0 */
  mu = exp(eta) / (1+exp(eta));
  vu = mu # (1-mu);
  dvu = 1 - 2#mu;

  WM0 = vu;
  WM1 = vu # dvu;
  WM2 = -2 # vu##2 + (dvu)##2 # vu;

  %if %length(&weight)>0 %then %do;
    WM0 = WM0 # weight;
    WM1 = WM1 # weight;
    WM2 = WM2 # weight;
  %end;

  cstart = j(&d4, 1, 1);
  cend = j(&d4, 1, 0);

  %if &d2>=1 %then %do;
    cend[1] = rknot[1];

    do j=2 to &d2;
      cstart[j] = cend[j-1] + 1;
      cend[j] = cend[j-1] + rknot[j];
    end;
    
    %if &c > 0 %then %do;    
      cstart[&d3:&d4] = cend[&d2] + q1;
      cend[&d3:&d4] = cend[&d2] + q2;
    %end;
  %end;
  %else %do;
    cstart = q1;
    cend = q2;
  %end;


  %if &c=0 %then %do;
    temp = NB(order[, 1], B1);
    %if &d2>1 %then
      %do j=2 %to &d2;
        temp = temp || NB(order[,&j], B&j);  /* temp = NB */
      %end;
  
    temp3 = temp;
    do i=1 to n;
      temp3[i, ] = WM0[i] # temp[i, ];      /* temp3 = W NB */
    end;

    temp1 = (temp)` * temp3;      /* temp1 = (NB)` * W * NB  */

    temp1 = temp1##2;

    temp = j(cend[&d2], &d2, 0);
    do j=1 to &d2;
      temp2 = j(cend[&d2], 1, 0);
      do k=cstart[j] to cend[j];
        temp2 = temp2 + temp1[,k];
      end;
      temp[,j] = temp2;   
    end;

    temp1 = temp;
    temp = j(&d2, &d2, 0);
    do j=1 to &d2;
      temp2 = j(1, &d2, 0);
      do k=cstart[j] to cend[j];
        temp2 = temp2 + temp1[k, ];
      end;
      temp[j,] = temp2;   
    end;
    free temp3;
  %end;
  %else %if &d2<1 %then %do;
    WZ = Z;
  
    do i=1 to n;
      WZ[i, ] = WM0[i] # Z[i, ];
    end;  
  
    temp3 = (Z[m1[1]: m2[1], ])` * WZ[m1[1]: m2[1], ];
    do i=2 to m;
      temp3 = temp3 // (Z[m1[i]: m2[i], ])` * WZ[m1[i]: m2[i], ];
    end; 
 
    temp3 = temp3##2;

    temp = j(dimb, &d4, 0);
    do j=1 to &d4;
      temp2 = j(dimb, 1, 0);
      do k=cstart[j] to cend[j];
        temp2 = temp2 + temp3[,k];
      end;
      temp[,j] = temp2;
    end;
    
    temp1 = j(nz, &d4, 0);
    do i=1 to m;
      temp1 = temp1 + temp[bcut1[i]:bcut2[i], ];
    end;

    temp = j(&d4, &d4, 0);

    do j=1 to &d4;
      temp2 = j(1, &d4, 0);
      do k=cstart[j] to cend[j];
        temp2 = temp2 + temp1[k, ];
      end;
      temp[j,] = temp2;
    end;
    free WZ temp3;
  %end;
  %else %do;
    temp = NB(order[, 1], B1);
    %if &d2>1 %then
      %do j=2 %to &d2;
        temp = temp || NB(order[,&j], B&j);  /* temp = NB */
      %end;

    temp3 = temp;
    do i=1 to n;
      temp3[i, ] = WM0[i] # temp[i, ];   /* temp3 = W NB */
    end;   

    temp1 = (temp)` * temp3;

    temp = (temp3)`;
    temp2 = temp[, m1[1]: m2[1]] * Z[m1[1]: m2[1], ];
    do i=2 to m;
      temp2 = temp2 || temp[, m1[i]: m2[i]] * Z[m1[i]: m2[i], ];
    end;

    WZ = Z;
  
    do i=1 to n;
      WZ[i, ] = WM0[i] # Z[i, ];
    end;  

    temp3 = (Z[m1[1]: m2[1], ])` * WZ[m1[1]: m2[1], ];
    do i=2 to m;
      temp3 = temp3 // (Z[m1[i]: m2[i], ])` * WZ[m1[i]: m2[i], ];
    end;

    temp1 = temp1##2;
    temp2 = temp2##2;
    temp3 = temp3##2;

    temp1 = temp1 // (temp2)`; 
    temp = j(cend[&d2] + dimb, &d2, 0);
    do j=1 to &d2;
      temp4 = j(cend[&d2] + dimb, 1, 0);
      do k=cstart[j] to cend[j];
        temp4 = temp4 + temp1[, k];
      end;
      temp[,j] = temp4;
    end;

    temp1 = j(cend[&d2], nz, 0);
    do i=1 to m;
      temp1 = temp1 + temp2[, bcut1[i]:bcut2[i]];
    end;

    temp2 = temp1 // temp3;

    temp1 = j(cend[&d2] + dimb, &c, 0);
    do j=1 to &c;
      temp3 = j(cend[&d2] + dimb, 1, 0);
      do k=q1[j] to q2[j];
        temp3 = temp3 + temp2[, k];
      end;
      temp1[, j] = temp3;
    end;

    temp1 = temp || temp1;

    temp = j(&d4, &d4, 0);
    do j=1 to &d2;
      temp2 = j(1, &d4, 0);
      do k=cstart[j] to cend[j];
        temp2 = temp2 + temp1[k, ];
      end;
      temp[j,] = temp2;   
    end;

    temp3 = temp1[cstart[&d3]:nrow(temp1), ];
    temp2 = j(nz, &d4, 0);
    do i=1 to m;
      temp2 = temp2 + temp3[bcut1[i]:bcut2[i], ];
    end;

    do j=&d3 to &d4;
      temp1 = j(1, &d4, 0);
      do k=q1[j-&d3+1] to q2[j-&d3+1];
        temp1 = temp1 + temp2[k, ];
      end;
      temp[j,] = temp1;   
    end;
    free WZ temp3 temp4;        
  %end;

  Cp = temp/2;

  %if &d2>= 1 %then %do;
    temp = (B1)##2;
    temp1 = NB(order[, 1], temp);
    %if &d2>1 %then
      %do j=2 %to &d2;
        temp = (B&j)##2;
        temp1 = temp1 || NB(order[,&j], temp);  /* temp1 = (NB)##2 */
      %end;  

    %if  &c>0 %then %do;
      temp = Z##2;
      temp1 = temp1 || temp;
    %end;
  %end;
  %else %do;
    temp1 = Z##2;
  %end;

  temp = j(n, &d4, 0);
  do j=1 to &d4;
    temp2 = j(n, 1, 0);
    do k=cstart[j] to cend[j];
      temp2 = temp2 + temp1[, k];
    end;
    temp[, j] = temp2;
  end;

  temp1 = temp;
  do i=1 to n;
    temp1[i, ] = WM2[i] # temp[i, ];
  end;

  JZJ = (temp)` * temp1;
   
  do i=1 to n;
    temp1[i, ] = WM1[i] # temp[i, ];
  end;

  BM = X` * temp1;

  temp1 = X;
  do i=1 to n;
    temp1[i, ] = WM0[i] # temp1[i, ];
  end;    

  temp = X` * temp1;

  BXB = (BM)` * inv(temp) * BM;  

  Cq = Cp + (JZJ - BXB)/4;
 
  GM = inv(Cq) * Cp;
  
  theta1 = GM * theta1;

  Finv = GM * Finv * (GM)`; 

  free GM BM JZJ temp temp1 temp2;

%mend corpar;


  /* Macro only to bias-correct theta */

%macro cortheta;

if converg=1 | &keeplast=Y then do;
  eta = X * beta1[1:fixnum];     /* eta under tau=0 and theta=0 */
  mu = exp(eta) / (1+exp(eta));
  vu = mu # (1-mu);
  dvu = 1 - 2#mu;

  WM0 = vu;
  WM1 = vu # dvu;
  WM2 = -2 # vu##2 + (dvu)##2 # vu;

  %if %length(&weight)>0 %then %do;
    WM0 = WM0 # weight;
    WM1 = WM1 # weight;
    WM2 = WM2 # weight;
  %end;

  WZ = Z;
  do i=1 to n;
    WZ[i, ] = WM0[i] # Z[i, ];
  end;

  temp3 = (Z[m1[1]: m2[1], ])` * WZ[m1[1]: m2[1], ];
  do i=2 to m;
    temp3 = temp3 // (Z[m1[i]: m2[i], ])` * WZ[m1[i]: m2[i], ];
  end;

  temp3 = temp3##2;

  temp = j(dimb, &c, 0);
  do j=1 to &c;
    temp2 = j(dimb, 1, 0);
    do k=q1[j] to q2[j];
      temp2 = temp2 + temp3[,k];
    end;
    temp[,j] = temp2;
  end;

  temp1 = j(nz, &c, 0);
  do i=1 to m;
    temp1 = temp1 + temp[bcut1[i]:bcut2[i], ];
  end;
 
  Cp = j(&c, &c, 0);
  
  do j=1 to &c;
    temp2 = j(1, &c, 0);
    do k=q1[j] to q2[j];
      temp2 = temp2 + temp1[k, ];
    end;
    Cp[j,] = temp2;
  end;

  Cp = Cp/2;  

  free WZ;

  temp1 = Z##2;

  temp = j(n, &c, 0);
  do j=1 to &c;
    temp2 = j(n, 1, 0);
    do k=q1[j] to q2[j];
      temp2 = temp2 + temp1[, k];
    end;
    temp[, j] = temp2;      /* temp = Z2 * J */
  end;  
 
  temp1 = temp;
  do i=1 to n;
    temp1[i, ] = WM2[i] # temp[i, ];
  end;

  JZJ = (temp)` * temp1;

  do i=1 to n;
    temp1[i, ] = WM1[i] # temp[i, ];
  end;

  BM = X` * temp1;

  temp1 = X;
  do i=1 to n;
    temp1[i, ] = WM0[i] # temp1[i, ];
  end;    

  temp = X` * temp1;

  BXB = (BM)` * inv(temp) * BM;  

  Cq = Cp + (JZJ - BXB)/4;

  GM = inv(Cq) * Cp;

  %if 1>&d2 %then %do;
    theta1 = GM * theta1;
    Finv = GM * Finv * (GM)`;
  %end;
  %else %do;
    temp = GM * theta1[&d3:&d4];
    theta1[&d3:&d4] = temp;
    temp1 = GM * Finv[&d3:&d4, 1:&d2];
    temp2 = GM * Finv[&d3:&d4, &d3:&d4] * (GM)`;
    Finv[&d3:&d4, 1:&d2] = temp1;
    Finv[1:&d2, &d3:&d4] = (temp1)`;
    Finv[&d3:&d4, &d3:&d4] = temp2;
  %end;    

  free GM BM BXB JZJ temp temp1 temp2;

end;

%mend cortheta;


/* Global lineaity test for independent data */

%macro testlin1;

if converg=1 then do;
  df = j(2,1,0);
  chisq = df;
  p_value = df;
  smean = df;

  workw = 1/workv;

  temp1 = X;
  do i=1 to n;
    temp1[i, ] = sqrt(workw[i])#temp1[i, ];
  end;

  temp2 = Cinv * (temp1)`;

  HM = j(n,1,0);

  do i=1 to n;
    HM[i] = temp1[i, ]*temp2[, i];
  end;

  %if &dist=BINOMIAL %then %do;
    vdmu = 1 - 2#mu;
  %end;

  W0 = workw; 
  Wtild = (1 - HM)#workw;
  %if &canolink=0 %then %do;
    %if &dist=BINOMIAL %then %do;
      %if &link=PROBIT %then %do;
        gddmu = (gdmu##2)#eta;
      %end;
      %else %if &link=CLOGLOG %then %do;
        gddmu = (1 + log(1-mu))#(gdmu)##2;
      %end;  
      EMat = (vdmu#gdmu + vmu#gddmu)#workw##2#gdmu;
      %if %length(&weight)>0 %then %do;
        Emat = Emat/weight;
      %end;
    %end;
    temp = EMat#(Y - mu);
    W0 = W0 + temp;
    Wtild = Wtild + temp;
  %end;

  temp1 = NB(border, B);

  NBN = temp1 * (temp1)`;

  %if &canolink=1 and %length(&weight)=0 %then %do;
    temp1 = (Y-mu);
  %end;
  %else %do;
    %if &canolink=1 %then %do;
      gdw = weight;
    %end;
    %else %do;
      gdw = gdmu#workw;
    %end;
    temp1 = (Y-mu)#gdw;
  %end;

  score = (((temp1)` * NBN) * temp1)/2; 

  do i=1 to n;
    temp = NBN[i,i];
    smean[1] = smean[1] + W0[i] # temp;
    smean[2] = smean[2] + Wtild[i] # temp;
  end;

  smean = smean / 2;

  %if &dist=BINOMIAL %then %do;
    K3M = vdmu#vmu;
    K4M = -2#(vmu)##2 + (vdmu) # K3M;
  %end;
  %else %if &dist=POISSON %then %do;
    K3M = mu;
    K4M = mu;
  %end;

  %if %length(&weight)>0 %then %do;
    temp = (weight)##2;
    K3M = K3M / temp;
    K4M = K4M / (weight#temp);
  %end;

  %if &canolink=1 and %length(&weight)=0 %then %do;
    RM = K4M + 2#(workw)##2;
    CM = k3M;
  %end;
  %else %do;
    temp = (gdw)##3;    
    RM = K4M # gdw # temp + 2#(workw)##2;
    CM = k3M # temp;
    %if &canolink=0 %then %do;
      %if &dist=BINOMIAL %then %do;
        temp = vmu;
        %if %length(&weight)>0 %then %do;
          temp = temp / weight;
        %end;
        RM = RM + (Emat##2)#temp - 2#(gdw##2)#Emat#K3M;
        CM = CM - gdw # Emat # temp;
      %end;
    %end;
  %end;

  temp1 = 0;
  do i=1 to n;
    temp1 = temp1 + NBN[i,i]##2 * RM[i];
  end;
 
  temp2=0;
  do i=1 to n;
    do j=i+1 to n;
      temp2 = temp2 + NBN[i,j]##2 * workw[i] * workw[j]; 
    end;
  end;

  temp1 = temp1/4 + temp2;

  temp2 = j(nx, 1, 0);
  do i=1 to n;
    temp = X[i, ];
    temp2 = temp2 + (NBN[i,i]*CM[i])#(temp)`;
  end;
  temp2 = temp2/2;

  svar = temp1 - (temp2)` * Cinv * temp2;

  free temp temp1 temp2 temp3 RM CM K3M K4M NBN HM Wtild W0 workw gdw;

  do i=1 to 2;
    temp =  svar / (2*smean[i]);
    df[i] = smean[i] / temp;
    chisq[i] = score/temp;
  end;

  do i=1 to 2;
    if chisq[i] > 0 then 
      p_value[i] = 1 - probchi(chisq[i], df[i]);
    else  
      p_value[i] = 1;
  end; 
  free smean svar;
end;
else do;
   df = j(2, 1, .);
   chisq = df;
   p_value = df;
end;

  %if &print^=N %then %do;
    %if %length(&smthvar)=0 %then
      %let temp = %scan(&X1,1);
    %else 
      %let temp = %scan(&X2,1);
    version={'Bias-uncorrected', 'Bias-corrected'};
    print, "Score test of linearity for covariate &temp";
    print version chisq df p_value[format=6.4];
  %end;

  %if %length(&outlscor)>0 %then %do;
    version={1,2};
    scorinfo = version || chisq || df || p_value;
    cname = {"Version" "Chisq" "df" "P_value"};
    create &outlscor from scorinfo[colname=cname];
    append from scorinfo;
  %end;  

  free chisq df score p_value; 

%mend testlin1;


/* Individual lineaity test if coefdim < n */

%macro testlin2;

if converg=1 then do; 

  %do j=1 %to &d2;
    FM1&j = j(rknot[&j], brknot, 0);
    FM2&j = j(rknot[&j], &coefdim, 0); 
  %end;
  %do j=&d3 %to &d8;
    FM1&j = j(brknot, &coefdim, 0); 
  %end;

  %do j=&d3 %to &d8;
    FM&j = j(dimbt, dimbt, 0);
  %end;

  HWB = j(&coefdim, brknot, 0);
  BPB = j(brknot, brknot, 0);
  temp1 = j(1, brknot, 0);
  Itao = j(&d8, 1, 0);

  do i=1 to m;
    W = formmat(WM[vstart[i]: vend[i]]);
    Hi = X[m1[i]:m2[i], ];
    residi = resid[m1[i]:m2[i]];
    %do j=1 %to &d2;
      Hi = Hi || NBi(i, order[m1[i]:m2[i], &j], B&j);
    %end;
    WH = W * Hi;
    BMi = NBi(i, border[m1[i]:m2[i]], B);
    WB = (W * BMi);
    HWB = HWB + (Hi)` * WB;
    BPB = BPB + (BMi)` * WB;
    temp1 = temp1 + (residi)` * WB;

    %if &d8>&d2 %then 
      %findderv;
 
    %do j=1 %to &d2;
      temp2 = NBi(i, order[m1[i]:m2[i], &j], B&j);
      FM1&j = FM1&j + (temp2)` * WB;
      FM2&j = FM2&j + (temp2)` * WH;
    %end;

    %do j=&d3 %to &d8;
      FM1&j = FM1&j + (HWV&j * WB)`; 
      temp2 = (BMi)` * WV&j;
      Itao[&j] = Itao[&j] + trc(temp2, WB);
    %end;
  end;

  CHWB = Cinv * HWB;
  BPB = BPB - (HWB)` * CHWB;

  temp=BPB;

  svar = trc(BPB, temp)/2;

  score = (temp1 * (temp1)`)/2;

  smean = trace(BPB)/2;
  
  %do j=1 %to &d2;
    temp = FM1&j - FM2&j*CHWB;
    temp1 = (temp)`;
    Itao[&j] = trc(temp, temp1);
  %end;
    
  %do j=&d3 %to &d8;
    Itao[&j] = Itao[&j] - 2*trc(FM1&j, CHWB);
    temp1 = (CHWB)`;
    temp2 = FM&j * CHWB;
    Itao[&j] = Itao[&j] + trc(temp1, temp2);
  %end;
           
  Itao = Itao/2;

  svar = svar - (Itao)` * Finv * Itao;

  temp =  svar / (2*smean);
  df = smean / temp;
  chisq = score/temp;

  if chisq > 0 then 
    p_value = 1 - probchi(chisq, df);
  else  
    p_value = 1; 

  free score smean svar Itao BPB HWB 
    temp temp1 temp2 Hi BMi W WB CHWB;  

  %do j=1 %to &d2;
   free FM1&j FM2&j;
  %end;
  %do j=&d3 %to &d8;
    free FM1&j; 
  %end;

  %do j=&d3 %to &d8;
    free FM&j;
  %end;
end;
else do;
  chisq = .;
  df = .;
  p_value = .;
end;

  %if &print^=N %then %do;
    %if %length(&smthvar)=0 %then
      %let temp = %scan(&X1,1);
    %else 
      %let temp = %scan(&X2,1);
    print, "Score test of linearity for covariate &temp";
    print chisq df p_value[format=6.4];
  %end;

  %if %length(&outlscor)>0 %then %do;
    scorinfo = chisq || df || p_value;
    cname = {"Chisq" "df" "P_value"};
    create &outlscor from scorinfo[colname=cname];
    append from scorinfo;
  %end;  

  free chisq df p_value;

%mend testlin2;


/* Individual lineaity test if coefdim >= n */

%macro testlin3;

if converg=1 then do;

  NBM = NB(border, B);

  PB = vinv * NBM;

  BPB = (NBM)` * PB;

  Itao = j(&d8, 1, 0);
  Wresid = j(n, 1, );

  do i=1 to m;
    W = formmat(WM[vstart[i]: vend[i]]);
    Wresid[m1[i]:m2[i]] = W * resid[m1[i]:m2[i]];
  end;

  temp = NBM * Wresid;

  score = ((temp)`*temp)/2;
  smean = trace(BPB)/2;

  temp = BPB;
  svar = trc(temp, BPB)/2;

  %do j=1 %to &d2;
    temp = (NB(order[,&j], B&j))` * PB;
    temp1 = temp`;
    Itao[&j] = trc(temp, temp1);
  %end;  
  
  %do j=&d3 %to &d8;
    temp = (PB)`;
    do i=1 to m;
      temp1 = formmat(V&j[vstart[i]:vend[i]]);
      temp[, m1[i]:m2[i]] = temp[, m1[i]:m2[i]] * temp1;
    end;
    Itao[&j] = trc(temp, PB); 
  %end;
  
  Itao = Itao/2;

  svar = svar - (Itao)` * Finv * Itao;

  temp =  svar / (2*smean);
  df = smean / temp;
  chisq = score/temp;

  if chisq > 0 then 
    p_value = 1 - probchi(chisq, df);
  else  
    p_value = 1; 

  free score smean svar Itao NBM BPB PB 
    temp temp1 W Wresid;

end;
else do;
  chisq = .;
  df = .;
  p_value = .;
end;

  %if &print^=N %then %do;
    %if %length(&smthvar)=0 %then
      %let temp = %scan(&X1,1);
    %else 
      %let temp = %scan(&X2,1);
    print, "Score test of linearity for covariate &temp";
    print chisq df p_value[format=6.4];
  %end;

  %if %length(&outlscor)>0 %then %do;
    scorinfo = chisq || df || p_value;
    cname = {"Chisq" "df" "P_value"};
    create &outlscor from scorinfo[colname=cname];
    append from scorinfo;
  %end;  

  free chisq df p_value;

%mend testlin3;


  /* Macro to do linearity test */

%macro testlin;

  %let method=REML;

  %if &p2>0 %then %do;
    B = B1;
    BCX2 = CX21;
    bnknot=nknot[1];
    brknot=rknot[1];
    border=order[,1];

    %if &p2>1 %then %do;
      nknot=nknot[2:&p2];
      rknot=rknot[2:&p2];
      order=order[, 2:&p2];

      %do j=2 %to &p2;
        %let temp = %eval(&j-1);
        B&temp = B&j;
        CX2&temp = CX2&j;
      %end;    
    %end;

    %let p2 = %eval(&p2 - 1);
    %let p1 = %eval(&p1 + 1);
    %let coefdim = %eval(&coefdim - &dimf1);
    
    %let d2 = %eval(&d2 - 1);
    %let d3 = %eval(&d3 - 1);
    %let d4 = %eval(&d4 - 1);
    %let d5 = %eval(&d5 - 1);
    %let d6 = %eval(&d6 - 1);
    %let d7 = %eval(&d7 - 1);
    %let d8 = %eval(&d8 - 1);    
    
    %prog; 

    %if &correct=1 %then %do;
      %cortheta;

      %formwork;

      %findbeta;
    %end;

  %end;
  %else %if &fitmod^=Y %then %do;

    %prog; 

    %if &correct=1 %then %do;
      %cortheta;

      %formwork;

      %findbeta;
    %end;

  %end;

  %let ltest=1;
  %if &d8=0 %then 
    %testlin1;    /* Global linearity test for independent data */
  %else %if &coefdim<&n %then
    %testlin2;    /* Individual linearity test when &coefdim<&n */
  %else 
    %testlin3;    /* Individual linearity test when &coefdim>=&n */

  %if %length(&smthvar)>0 %then %do;

    %let d2 = %eval(&d2 + 1);
    %let d3 = %eval(&d3 + 1);
    %let d4 = %eval(&d4 + 1);
    %let d5 = %eval(&d5 + 1);
    %let d6 = %eval(&d6 + 1);
    %let d7 = %eval(&d7 + 1);
    %let d8 = %eval(&d8 + 1);    
   
    %let p2 = %eval(&p2 + 1);
    %let p1 = %eval(&p1 - 1);
    %let coefdim = %eval(&coefdim + &dimf1);

    %if &p2>1 %then %do;
      order = border || order;
      nknot = bnknot // nknot;
      rknot = brknot // rknot;
      
      %do j=2 %to &p2;
        %let temp = %eval(&j-1);
        B&j = B&temp;
        CX2&j = CX2&temp;
      %end;       
      B1 = B;
      CX21 = BCX2;

      free BCX2;
    %end;

  %end;
  %let ltest=0;
  free B border bnknot brknot;

%mend testlin;  


%macro testvar1;

if converg=1 then do;

  Z_score = j(2, 1, 0);
  smean = Z_score;
  p_value = Z_score;

  workw = 1/workv; 

  temp1 = X;
  do i=1 to n;
    temp1[i, ] = (sqrt(workw[i]))#temp1[i, ];
  end;

  if &p2=0 then do;
    temp2 = Cinv * (temp1)`;
  end;
  else do;
    temp = X;
    do i=1 to n;
      temp[i, ] = workw[i]#temp[i, ];
    end;
    temp2 = inv((X)` * temp);
    temp2 = temp2 * (temp1)`;
  end;

  HM = j(n,1,0);

  do i=1 to n;
    HM[i] = temp1[i, ]*temp2[, i];
  end;  

  %if &dist=BINOMIAL %then %do;
    vdmu = 1 - 2#mu;
  %end;

  W0 = workw;
  Wtild = (1 - HM)#workw;
  %if &canolink=0 %then %do;
    %if &dist=BINOMIAL %then %do;
      %if &link=PROBIT %then %do;
        gddmu = (gdmu##2)#eta;
      %end;
      %else %if &link=CLOGLOG %then %do;
        gddmu = (1 + log(1-mu))#(gdmu)##2;
      %end;  
      EMat = (vdmu#gdmu + vmu#gddmu)#workw##2#dgmu;
      %if %length(&weight)>0 %then %do;
        Emat = Emat/weight;
      %end;
    %end;
    temp = EMat#(Y - mu);  
    W0 = workw + temp
    Wtild = Wtild + temp;
  %end;

  WZ = Z1M;
  WtZ = Z1M;
  do i=1 to n;
    WZ[i,] = W0[i]#Z1M[i,];
    WtZ[i, ] = Wtild[i]#Z1M[i,];
  end;

  %if &canolink=1 and %length(&weight)=0 %then %do;
    temp = (Y-mu);
  %end;
  %else %do;
    %if &canolink=1 %then %do;
      gdw = weight;
    %end;
    %else %do;
      gdw = gdmu#workw;
    %end;
    temp = (Y-mu)#gdw;
  %end;

  score = 0;
  do i=1 to m;
    temp1 = Z1M[m1[i]:m2[i], ];
    temp2 = temp[m1[i]:m2[i]];
    temp3 = (temp1)` * temp2;
    score = score + (temp3)`*temp3;
    temp2 = WZ[m1[i]:m2[i], ];
    smean[1] = smean[1] + trc((temp1)`, temp2);
    temp2 = WtZ[m1[i]:m2[i], ];
    smean[2] = smean[2] + trc((temp1)`, temp2);
  end;
  
  score = score/2;
  smean = smean/2; 

  %if &dist=BINOMIAL %then %do;
    K3M = vdmu#vmu; 
    K4M = -2#(vmu)##2 + (vdmu) # K3M;
  %end;
  %else %if &dist=POISSON %then %do;
    K3M = mu;
    K4M = mu;
  %end;

  %if %length(&weight)>0 %then %do;
    temp = (weight)##2;
    K3M = K3M / temp;
    K4M = K4M / (weight#temp);
  %end; 

  %if &canolink=1 and %length(&weight)=0 %then %do;
    RM = K4M + 2#(workw)##2;
    CM = k3M;
  %end;
  %else %do;
    temp = (gdw)##3;
    RM = K4M # gdw # temp + 2#(workw)##2;
    CM = k3M # temp;
    %if &canolink=0 %then %do;
      %if &dist=BINOMIAL %then %do;
        temp = vmu;
        %if %length(&weight)>0 %then %do;
          temp = temp / weight;
        %end;
        RM = RM + (Emat##2)#temp - 2#(gdw##2)#Emat#K3M;
        CM = CM - gdw # Emat # temp;
      %end;
    %end;
  %end;

  temp1 = 0;
  temp2 = j(fixnum, 1, 0);
  do i=1 to m;
    temp3 = Z1M[m1[i]:m2[i], ];
    temp4 = RM[m1[i]:m2[i]];
    temp5 = CM[m1[i]:m2[i]];
    Xi = X[m1[i]:m2[i], ];
    do j=1 to _n[i];
      temp = temp3[j, ];
      aii = temp * (temp)`;
      temp1 = temp1 + aii**2 * temp4[j]; 
      temp = Xi[j, ];
      temp2 = temp2 + (aii*temp5[j])#(temp)`; 
    end;
  end;
    
  temp2 = temp2/2;

  temp3 = 0;
  do i=1 to m;
    temp4 = Z1M[m1[i]:m2[i], ];
    RiM = workw[m1[i]:m2[i]];
    do j=1 to _n[i];
      do k=j+1 to _n[i]; 
        aii = temp4[j, ]*(temp4[k, ])`;
        temp3 = temp3 + aii**2 * (RiM[j] * RiM[k]);
      end;
    end;
  end; 

  temp1 = temp1/4 + temp3; 

  svar = temp1 - (temp2)` * Cinv * temp2;

  free temp temp1 temp2 temp3 temp4 temp5 workw gdw
       RM CM K3M K4M HM Wtild RiM aii Xi WZ WtZ;

  do i=1 to 2;
    Z_score[i] = (score - smean[i])/sqrt(svar); 
    p_value[i] = 1 - probnorm(Z_score[i]);  
  end;
end;
else do;
  Z_score = j(2, 1, .);
  p_value = Z_score;  
end;

  %if &print^=N %then %do;
    version={'Bias-uncorrected', 'Bias-corrected'};
    print, "Score test for variance component theta1";
    print version Z_score p_value[format=6.4];
  %end;

  %if %length(&outvscor)>0 %then %do;
    version={1, 2};
    scorinfo = version || Z_score || p_value;
    cname = {"Version" "Z_score" "P_value"};
    create &outvscor from scorinfo[colname=cname];
    append from scorinfo;
    free scorinfo version Z_score p_value;
  %end;  
  
%mend testvar1;


%macro testvar2;

if converg=1 then do;

  score = 0;
  smean = 0;
  svar = 0;
  Itao = j(&d8, 1, 0); 

  HWH1 = j(&coefdim, &coefdim, 0);
  HWH2 = HWH1;

  %do j=1 %to &d2;
    FM1&j = j(rknot[&j], &coefdim, 0); 
  %end;
  %do j=&d3 %to &d8;
    FM1&j = j(&coefdim, &coefdim, 0);
  %end;
  %do j=&d3 %to &d8;
    FM&j = j(dimbt, dimbt, 0);
  %end;

  do i=1 to m;
    W = formmat(WM[vstart[i]: vend[i]]);
    Z1Mi = Z1M[m1[i]:m2[i], ];
    residi = resid[m1[i]:m2[i]];
    Hi = X[m1[i]:m2[i], ];
    %do j=1 %to &d2;
      Hi = Hi || NBi(i, order[m1[i]:m2[i], &j], B&j);
    %end;
    WZ = W * Z1Mi;
    WH = W * Hi;
      
    temp1 = (residi)` * WZ;
    score = score + temp1 * (temp1)`;

    ZWZ = (Z1Mi)` * WZ;
    smean = smean + trace(ZWZ);
                 
    temp = ZWZ;
    svar = svar + trc(temp, ZWZ); 
 
    ZWH = (WZ)` * Hi;
    HWH1 = HWH1 + (ZWH)` * ZWZ * ZWH;
    HWH2 = HWH2 + (ZWH)` * ZWH;     
      
    %do j=1 %to &d2;
      temp1 = NBi(i, order[m1[i]:m2[i], &j], B&j);
      temp2 = (temp1)` * WZ;
      temp = temp2;
      Itao[&j] = Itao[&j] + trc((temp)`, temp2);
      FM1&j = FM1&j + temp2 * ZWH;
    %end;

    %if &d8>&d2 %then 
      %findderv;

    temp = WZ * (Z1Mi)`;

    %do j=&d3 %to &d8;
      Itao[&j] = Itao[&j] + trc(temp, WV&j);
      FM1&j = FM1&j + HWV&j * WZ * ZWH;
    %end;
  end;

  score = score / 2;

  HWHC = HWH2 * Cinv; 
  smean = (smean - trace(HWHC))/2;
 
  temp = HWHC;
  svar = svar - 2*trc(HWH1, Cinv) + trc(temp, HWHC);
  svar = svar/2;

  %do j=1 %to &d2;
    Itao[&j] = Itao[&j] - 2*trc(FM1&j, (HC&j)`);
    temp = HC&j * HWH2;
    Itao[&j] = Itao[&j] + trc(temp, (HC&j)`); 
  %end;  

  %do j=&d3 %to &d8;
    Itao[&j] = Itao[&j] - 2*trc(FM1&j, Cinv);
    temp = FM&j*Cinv;
    Itao[&j] = Itao[&j] + trc(temp, HWHC); 
  %end;
     
  Itao = Itao/2;

  svar = svar - (Itao)` * Finv * Itao;

  %do j=1 %to &d8;
    free FM1&j;
  %end;
  %do j=&d3 %to &d8;
    free FM&j;
  %end;
  free HWH1 HWH2 ZWH HWHC  W WZ Z1Mi temp temp1 temp2 Itao;

  Z_score = (score - smean)/sqrt(svar);
  p_value = 1 - probnorm(Z_score);

  free score smean svar; 
end;
else do;
  Z_score = .;
  p_value = .;
end;

  %if &print^=N %then %do;
    print, "Score test for variance component theta1";
    print Z_score p_value[format=6.4];
  %end;

  %if %length(&outvscor)>0 %then %do;
    scorinfo = Z_score || p_value;
    cname = {"Z_score" "P_value"};
    create &outvscor from scorinfo[colname=cname];
    append from scorinfo;
    free scorinfo Z_score p_value;
  %end;  

%mend testvar2;


%macro testvar3;
  
if converg=1 then do;

  score = 0;
  smean = 0;
  svar = 0;

  Itao = j(&d8, 1, 0); 

  ZPZ = j(m*numz1, m*numz1, 0);
  %do j=1 %to &d2;
    ZPB&j = j(m*numz1, rknot[&j], 0);  
  %end;

  PZ1 = j(n, m*numz1, 0);      /* PZ1 = P * Z1  */
  do i=1 to m;
    residi = resid[m1[i]:m2[i]];
    W = formmat(WM[vstart[i]: vend[i]]);
    Z1Mi = Z1M[m1[i]:m2[i], ];
    WZ = W * Z1Mi;
    temp1 = (residi)` * WZ;
    score = score + temp1 * (temp1)`;
    PZ1[, (i-1)*numz1+1:i*numz1] = Vinv[, m1[i]:m2[i]] * Z1Mi;
  end;

  %do j=&d3 %to &d8;
    temp1 = PZ1;
    do i=1 to m;
      temp2 = formmat(V&j[vstart[i]:vend[i]]);
      temp1[m1[i]:m2[i], ] = temp2 * temp1[m1[i]:m2[i], ];
    end;
    Itao[&j] = trc((PZ1)`, temp1);
  %end;

  do i=1 to m;
    Z1Mi = Z1M[m1[i]:m2[i], ];
    ZPZ[(i-1)*numz1+1:i*numz1, ] = (Z1Mi)` * PZ1[m1[i]:m2[i], ];
    %do j=1 %to &d2;
      ZPB&j[(i-1)*numz1+1:i*numz1, ] = (Z1Mi)`*temp1&j[m1[i]:m2[i],];
    %end;   
  end;    
     
  score = score / 2;
  smean = trace(ZPZ) / 2;
  temp = ZPZ;
  svar = trc(temp, ZPZ) / 2;


  %do j=1 %to &d2;
    temp = ZPB&j;
    Itao[&j] = trc((temp)`, ZPB&j);
  %end;

  Itao = Itao / 2;

  svar = svar - (Itao)` * Finv * Itao;

  free PZ1 ZPZ; 
  %do j=1 %to &d2;
    free ZPB&j;
  %end;

  Z_score = (score - smean)/sqrt(svar);
  p_value = 1 - probnorm(Z_score);

  free score smean svar W WZ Z1Mi 
    temp temp1 temp2 Itao;
end;
else do;
  Z_score = .;
  p_value = .;
end;

  %if &print^=N %then %do;
    print, "Score test for variance component theta1";
    print Z_score p_value[format=6.4];
  %end;

  %if %length(&outvscor)>0 %then %do;
    scorinfo = Z_score || p_value;
    cname = {"Z_score" "P_value"};
    create &outvscor from scorinfo[colname=cname];
    append from scorinfo;
    free scorinfo Z_score p_value;
  %end;  

%mend testvar3;


  /* Macro to do test for the first variance component */  

%macro testvar;

  %let method=REML;
  
  Z1M = Z[, q1[1]:q2[1]];
  numz1 = q2[1];
  
  %if &c>1 %then %do;
    Z = Z[, q1[2]:q2[&c]];
  %end;

  %let c = %eval(&c - 1); 
  %let d4 = %eval(&d4 - 1);
  %let d5 = %eval(&d5 - 1);
  %let d6 = %eval(&d6 - 1);
  %let d7 = %eval(&d7 - 1);
  %let d8 = %eval(&d8 - 1);

  %prog;

  %if &c>0 and &correct=1 %then %do;
    %cortheta;

    %formwork;

    %findbeta;
  %end;

  %let vtest=1;
  %if &d8=0 %then 
    %testvar1;                        /* Global test for one variance component */
  %else %do;
    %if &coefdim<&n %then  
      %testvar2;
    %else
      %testvar3;
  %end;

  %let c = %eval(&c + 1);
  %let d4 = %eval(&d4 + 1);
  %let d5 = %eval(&d5 + 1);
  %let d6 = %eval(&d6 + 1);
  %let d7 = %eval(&d7 + 1);
  %let d8 = %eval(&d8 + 1);

  %let vtest=0;
 
%mend testvar;

       /***********************************************/
       /*                                             */
       /*                MAIN PROGRAM                 */
       /*                                             */
       /***********************************************/ 

  %if &print^=N %then %do; 
    print, "Macro: GAMM -- Generalized Additive Mixed Models";
    print "(c) Daowen Zhang, Xihong Lin, The University of Michigan";
  %end;

  %let _space = %str();

  %let ltest=0;
  %let vtest=0;

  reset spaces=4;

  %defineB;

  %readdata;

  %getorder;

  %if &fitmod=Y %then %do;
    %prog;
   
    converg0 = converg;

    %if &print^=N %then
      %outinfo;

    %let cor=0;

    %if &p2>0 and &coefdim<&n %then %do;
      MM1 = Cinv * C0;
      MM2 = MM1 * Cinv;
    %end;

    %if &d8>=1 %then 
      %outvarn;

    %outparm;

    %if &p2>0 %then
      %outputf;

    %if &correct=1 %then %do; 
      if converg=1 then do;
        %cortheta;

        %formwork;
 
        %findbeta;

        %let cor=1;

        %if &p2>0 and &coefdim<&n %then %do;
          MM1 = Cinv * C0;
          MM2 = MM1 * Cinv;
        %end;
      end;
      %if &d8>=1 %then 
        %outvarn;

      %outparm;

      %if &p2>0 %then
        %outputf;
    %end; 

    %outrand;

    %outprocs;

    if &d8>1 & converg0=1 then 
      theta = theta1;
  %end;


  %if &lintest=Y %then %do;
    %if &fitmod^=Y %then 
      %Initial;

    %testlin;
  %end;

  %if &vartest=Y %then %do;
    %if &fitmod^=Y %then 
      %Initial;
 
    %testvar;
  %end;

quit;

  /* Print the information for covariance matrix */
%if &fitmod=Y %then %do;
%if &print^=N %then %do;

  %if &d8>=1 %then %do;
    %if &correct=1 %then %do;
      Title2 "Estimates of the Variance Components Before Bias Correction";
    %end;
    %else %do;
      Title2 "Estimates of the Variance Components";
    %end;
  proc print data=Var_se0;
    id cov_parm;
    var estimate se chisq p_value;
    format estimate se chisq 7.4 p_value 6.4;
  run;
  %end;
    
  %if &prnfix=S %then %do;
    %if &correct=1 %then %do;
      Title2 "Estimates of the Fixed Fffects Before Bias Correction";
    %end;
    %else %do;
      Title2 "Estimates of the Regression Coefficients";
    %end;
    %if &p2=0 %then %do;
      proc print data=beta_se0;
        id xnames;
        var beta se chisq p_value;
        format beta se chisq 7.4 p_value 6.4;
      run;
    %end;
    %else %do;
      proc print data=beta_se0;
        id xnames;
        var beta F_se F_chisq F_p B_se B_chisq B_p;
        format beta F_se F_chisq B_se B_chisq 7.4 F_p B_p 6.4;
      run;
    %end; 
  %end;

  %if &correct=1 %then %do;

    %if &d8>=1 %then %do;
    Title2 "Estimates of the Variance Components After Bias Correction";
    proc print data=Var_se1;
      id cov_parm;
      var estimate se chisq p_value;
      format estimate se chisq 7.4 p_value 6.4;
    run;
    %end;

    %if &prnfix=S %then %do;
    Title2 "Estimates of the Fixed Effects After Bias Correction";
      %if &p2=0 %then %do;
        proc print data=beta_se1;
          id xnames;
          var beta se chisq p_value;
          format beta se chisq 7.4 p_value 6.4;
        run;
      %end;
      %else %do;
        proc print data=beta_se1;
          id xnames;
          var beta F_se F_chisq F_p B_se B_chisq B_p;
          format beta F_se F_chisq B_se B_chisq 7.4 F_p B_p 6.4;
        run;
      %end; 
    %end;

  %end;

  %if &prnran=S and &c>0 %then %do;
    Title2 "Estimates of the Random Effects";
      proc print data=_ran_;
        id Effect;
        var subject estimate;
        format estimate 7.4;
      run;
  %end;


%end; 

%if %length(&outbeta)>0 and &correct=1 %then %do;
  data &outbeta; set &outbeta _outbt1;
  run;
%end;

%if %length(&outbstd)>0 and &correct=1 %then %do;
  data &outbstd; set &outbstd _outbsd1;
  run;
%end;


%if &d8>=1 %then %do;
  %if %length(&outvar)>0 and &correct=1 %then %do;
    data &outvar; set &outvar _outvar1;
    run;
  %end;

  %if %length(&outvstd)>0 and &correct=1 %then %do;
    data &outvstd; set &outvstd _outvsd1;
    run;
  %end;
%end;

%if &p2>0 %then %do;
  %if %length(&outband)>0 and &correct=1 %then %do;
    data &outband; set &outband _outbnd1;
    run;
  %end;

  %if %length(&outsmth)>0 and &correct=1 %then %do;
    data &outsmth; set &outsmth _outsm1;
    run;
  %end;
%end;
%end;

%let dataset=_setup _nobs _subject;
%do j=1 %to &p2;
  %let dataset=&dataset knot&j;
%end;

%if &fitmod=Y %then %do;
%if print^=N %then %do;
  %if &prnfix=S %then %do;
    %let dataset=&dataset beta_se0;
    %if &correct=1 %then;
      %let dataset=&dataset beta_se1;
  %end;
  %if &d8>0 %then %do;
    %let dataset=&dataset var_se0;
    %if &correct=1 %then
      %let dataset=&dataset var_se1; 
  %end;
  %if &prnran=S and &c>0 %then 
    %let dataset=&dataset _ran_; 
%end;
%end;

proc datasets nolist;
  delete &dataset;
run;  

  /*  Clear titles and footnotes */

  title ' ';

  footnote ' ';

%exit: %mend gamm1;
