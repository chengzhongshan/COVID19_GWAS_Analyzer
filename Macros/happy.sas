/***************************************************************************
 Program Name: happy.sas
 Program date: 23 Feb 2005
 Programmer Name: Peter Kraft, modifying code by Rong Chen

 Run proc haplotype and output the result from this procedure;
 output the summary haploype and z score for haplotypes.
                
 input           id           : id
                 indsn        : input data
                 keep         : only keep the variables that are needed, and the input order of snps will be the same as alleles of snps in the final haplotypes
                 style        : 0-1-2 count input (SNP) or m1 m2 two-marker (MAR) input
                 outdsn1      :
                 outdsn2      :
                 outadd       : data set with scores of additive model for each subject.  
                 outreces     : data set with scores of recesive model for each subject.
                 outdomnant   : data set with scores of dominant model for each subject.
                 outcodomnant : data set with scores of co-dominant model for each subject.
                 thresh       :
                 range        : cutoff for pooling "rare" haplotypes (default 1%)
                 dir          : directory that the output files will be saved to
                 stratum      : the strata
                 covar        : covariates for running the main effect
                 covar1       : covariates for running the effects by stratum
                 formt        : format's name for the stratum
                 caco         : variable for caco 
                 cutoff       :

 output
                 mainxxx.html:  output descriptive statistics and main effect of haplotypes
                 strataxxx.html: output effect in stratum and interaction   


 mods            12jul04 (PK) Added option for SNP or MAR input style
                 21jul04 (PK) Embedded "numargs" macro
                 27jul04 (PK) Embedded "hap_main" and "hap_strata" macros
                 23feb05 (PK) Added est=stepem option to allow for long haplos
                 23feb05 (PK) Added id &id according to new proc hap syntax
                 23feb05 (PK) Retained id &id in output data set
*********************************************************************************/
/* DEFINE MACROFUNCTION NUMARGS */
%macro numargs(arg);
   %if &arg= %then %do;
        0
      %end;
    %else %do;
       %let n=1;
       %do %until (%scan(&arg,%eval(&n),%str( ))=%str()); 
         %let n=%eval(&n+1);
       %end;
       %eval(&n-1)
    %end;
%mend numargs;
/************************************************
 Program Name: hap_strata.sas
 Program date: Feb 24th, 2004
 Programmer Name: Rong Chen

 purpose :  --- This program is for getting effect in stratum  
                and interactions for that stratum

 input variable: 
         dsn :   input dataset;

 output reports:
        
        strataxxx.html 
**************************************************/
%macro hap_strata(dsn);
   /*output the frequencies by stratum */
   footnote;
   title;
   filename reports "&dir.strata&stratum..html" ;
   ods html body=reports(no_top_matter no_bottom_matter);
      proc tabulate data=freq&dsn;
         class &caco cat &stratum;
         var score;
         table &stratum, (cat=' ' all='subtotal' )*score=' ',
               &caco=' '*(sum='frequency' colpctsum='percent'*f=pctfmt9.)
               all = 'Pool'*(sum='frequency' colpctsum='percent'*f=pctfmt9.) / rts=20 row=float;
         %if &formt ne %then %do;
            format &stratum &formt;
         %end; 
      run;
    ods html close;
   
   /* effect in stratum  */
   data &dsn;
      set &dsn;
      array  irtva{%eval(&varnum-1)} irtva2 -irtva&varnum;
      array  z{%eval(&varnum-1)} z2 - z&varnum;
      do i= 1 to %eval(&varnum-1);
         irtva{i} = z{i}*&stratum;
      end;
   run;

   proc sort data=&dsn;
      by &stratum;
   run;

   proc logistic data=&dsn;
      model &caco= z2-z&varnum &covar1/rl;
      by &stratum;
      where %if &type=2 %then &stratum not in (' '); %else &stratum^=.;;
      ods output OddsRatios = &stratum.tmp;
   run;

   /* fit the model for interaction */
   /* only fit stratum into the model when it is numeric */
   /* if it is character, ask users to create numeric variable */
   %if &type=2 %then %do;
      %put "_NOTE_: &stratum is character variable.";
      %put "_NOTE_: Please create &stratum as numeric variable to caculate interaction";
   %end;
   %else %if &type=1 %then %do; 
  
      proc logistic data=&dsn;
         model &caco= z2-z&varnum &covar1 &stratum/rl;
         ods output FitStatistics=&stratum.fit1(keep=Criterion InterceptAndCovariates
                                                where=(Criterion='-2 Log L'));
         ods output GlobalTests=&stratum.df1(keep=df);
      run;

   
      proc sort data=&stratum.df1 nodupkey;
         by df;
      run;

      /* model with interaction terms  */
      proc logistic data=&dsn;
         model &caco = z2-z&varnum &stratum &covar1 irtva2-irtva&varnum /rl;
         ods output FitStatistics=&stratum.fit2(keep=Criterion InterceptAndCovariates
                                                 rename=(InterceptAndCovariates=Intercept2)
                                                 where=(Criterion='-2 Log L'));
         ods output GlobalTests=&stratum.df2(keep=df rename=(df=df2));
         ods output ParameterEstimates=&stratum.parm;
         ods output OddsRatios=&stratum.odds;
     run;

     /* prepare data with interaction in stratum */
     proc sort data=&stratum.df2 nodupkey;
        by df2;
     run;

     data inter&stratum;
        merge &stratum.fit1 &stratum.fit2 &stratum.df1 &stratum.df2;
        chi = abs(InterceptAndCovariates - Intercept2);
        dfn = abs(df-df2);
        pvalue=round(1-probchi(chi, dfn),.01);

        call symput('itr', trim(left(pvalue)));
        call symput('inter1', trim(left(round(InterceptAndCovariates,.01))));
        call symput('inter2', trim(left(round(Intercept2,.01))));
        call symput('df', trim(left(dfn)));
     run;
   %end; 

   /* prepare data with  effects in stratum */
   data n&stratum;
      set &stratum.tmp;
      length grp $10. ;

      grp="&stratum";
      subgrp=&stratum;
        ;
   run;

   filename reports "&dir.strata&stratum..html" mod;
   ods html body=reports(no_top_matter no_bottom_matter);
   proc report data=n&stratum;
      column grp subgrp Effect OddsRatioEst LowerCL UpperCL;
      define grp / group 'Covariate' center width=15;
      define subgrp / group 'Sub Group' center width=15;
      define Effect  / display 'Haplotype' center width=15;
      define OddsRatioEst/ display 'Odds Ratio' center width=10;
      define LowerCL / display 'Lower' center width=10;
      define UpperCL /display  'Upper '    center width=10;

      break after subgrp/skip;

      compute after grp;
        line '  ';
       %if &type=1 %then %do; 
         line  @10 "Model without interaction: -2 log L= &inter1";
         line  @10 "Model with interaction   : -2 log L= &inter2";
         line  @10 "Degree of freedom is     :  &df";
         line  @10 "P for interaction is     :  &itr";
       %end;
      endcomp;
      %if &formt ne %then %do;
        format subgrp &formt;
      %end;
      %if &covar1 ne %then %do;
        footnote "Unconditional logistical model adjust by &covar1";
      %end;
  run;
  ods html close;
  proc datasets library=work nolist;
/*     delete &stratum.tmp &stratum.fit1 &stratum.df1 */
/*            &stratum.fit2 &stratum.df2 &stratum.parm*/
/*            &stratum.odds inter&stratum n&stratum;*/
  quit;
%mend hap_strata;
/***********************************************
 Program Name: hap_main.sas
 Program date: Feb 24th, 2004
 Programmer Name: Rong Chen

 purpose :  --- This program is for getting main effect  

 input variable: 
         dsn :   input dataset;

 output reports:
        
        mainxxx.html 

 output dataset:
        freq&dsn 
**************************************************/
%global flag  varnum;
%macro hap_main(dsn);
   proc sort data=n&indsn;
      by id;
   run;

   data &dsn freq&dsn;
      merge n&indsn &dsn;
   run;  

   data freq&dsn;
      set freq&dsn;
      length cat $%eval(&h*(&x+3)).;
      array z{*} z1 - z&h;
      %do i= 1 %to &h;
        score=z{&i};
        cat ="z&i "||"&&labelh&i";
        output;
      %end;
   run;

   /* if the frequency of the rare haplotypes  */
   /* is <= 2.5% then cut off the rare haplotypes */
   proc summary data=freq&dsn noprint;
      class cat;
      var score;
      output out=tempn sum=;
   run;

   data tempn(drop=_TYPE_ _FREQ_);
      set tempn;
      retain total;
      if _TYPE_=0 then total=score;
      percent=round(score/total,0.0001);
      if _TYPE_ = 0 then delete;
      if percent<= &cutoff then do;
          call symput("flag", 1);
          call symput("cat", cat);
      end; 
   run;

   /* output the main effect */
   filename report "&dir.main&dsn..html";
   ods html body=report(no_bottom_matter);

     proc tabulate data=freq&dsn;
        class &caco cat;
        var score;
        table (cat=' ')*score=' ',
               &caco=' '*(sum='frequency' colpctsum='percent'*f=pctfmt9.)
               all='Pool'*(sum='frequency' colpctsum='percent'*f=pctfmt9.) /rts=20 row=float;
        %if %upcase(&dsn) NE NULL %then %do;
          title " Descriptive Statistics and main effect of haplotypes in additive model ";
        %end;
        %else %if %upcase(&dsn) NE NULL %then %do;
          title " Descriptive Statistics and main effect of haplotypes in recessive model ";
        %end;
        %else %if %upcase(&dsn) NE NULL %then %do;
          title " Descriptive Statistics and main effect of haplotypes in dominant model ";
        %end;
        %else %if %upcase(&dsn) NE NULL %then %do;
          title " Descriptive Statistics and main effect of haplotypes in co-dominant model ";
        %end;
        %if &flag ne %then %do;
          footnote " The frequency of &cat <= &cutoff, it will not be included in future analysis";
        %end;  
      run;
  ods html close;


   /* fit the model for main effect      */
   /* also test to see if haplotype has  */ 
   /* significant effect on the outcome  */  
   data _null_;
      %if &flag ne %then %do;   
        %let varnum=%eval(&h-1);
      %end;
      %else %do;
        %let varnum=&h;
      %end;
   run;
 
   proc logistic data=&dsn;
      model &caco=z2-z&varnum &covar/rl;
      ods output OddsRatios = main&dsn;
      ods output FitStatistics=tmpfit1(keep=Criterion InterceptAndCovariates
                                       where=(Criterion='-2 Log L'));
      ods output GlobalTests=tmpdf1(keep=df); 
   run;

   proc sort data=tmpdf1 nodupkey;
      by df;
   run;

   %if &covar ne %then %do;
      /* LRT test the two models      */ 
      proc logistic data=&dsn;
        model &caco=&covar/rl;
        ods output FitStatistics = tmpfit2(keep=Criterion InterceptAndCovariates
                                          rename=(InterceptAndCovariates=Intercept2)
                                          where=(Criterion='-2 Log L'));
        ods output GlobalTests=tmpdf2(keep=df rename=(df=df2));
      run;

      proc sort data=tmpdf2 nodupkey;
         by df2;
      run;

      data temp;
         merge tmpfit1 tmpdf1 tmpfit2 tmpdf2;
         chi=abs(InterceptAndCovariates - Intercept2);
         dfn = abs(df-df2);
         pvalue=round(1-probchi(chi,dfn),.0001);
         call symput('hap', trim(left(pvalue)));
         call symput('inter1', trim(left(round(InterceptAndCovariates,.01))));
         call symput('inter2', trim(left(round(Intercept2,.01))));
         call symput('df', trim(left(dfn)));
      run;
   %end; 

   
   filename report "&dir.main&dsn..html" mod;
   ods html body=report(no_top_matter no_bottom_matter);

     proc report data=main&dsn;
        column Effect OddsRatioEst LowerCL UpperCL;
        define Effect / group 'Haplotype' center width=10;
        define OddsRatioEst / display 'Odds Ratio' center width=10;
        define LowerCL / display  'Lower'   center width=10;
        define UpperCL / display  'Upper'   center width=10;

        break after Effect/skip;
        
        compute after; 
          line ' ';
          %if &covar ne %then %do;
            line @10 "Model without haplotypes : -2 logL= &inter2";
            line @10 "Model with haplotypes    : -2 logL= &inter1";
            line @3 "Degree of freedom is     :       &df";      
            line @4 "P of LRT test is         :       &hap";
          %end;      
       endcomp;
       footnote "Unconditinal logistical model adjusted for &covar";
     run;
  ods html close;
  proc datasets nolist library=work;
     delete main&dsn temp tmpfit1 tmpdf1 tmpfit2 tmpdf2 tempn;
  quit;
%mend hap_main;
/* MAIN BODY OF HAPPY */
%macro happy(id=id,
             indsn=in,
             keep=, /*SNPs, as well as its order, will be used to generate haplotypes*/
             style=SNP,
             outdsn1=happlotb,
             outdsn2=origfreq,
             outadd=addscre, 
             outreces=null, 
             outdomnant=null,
             outcodomnant=null,
             thresh=.0001,
             range=.01,
             dir=,
             stratum=, 
             covar=, 
             covar1=, 
             formt=, 
             caco=, 
             cutoff=0.05);

   %if &style^=SNP & &style^=MAR %then %do;
      %put ERROR(happy): Invalid style.;
	  %goto exit;
   %end;

   /* format the percentage */
   proc format ;
      picture pctfmt low-high = '009.00%';
   run;
   %let num=%numargs(&keep);

	 *Updated to make the original input dataset with the designated orders for these input snps;
	 *This is necessary;
	 data &indsn;
	 retain &keep;
	 set &indsn;
	 run;

/************************************************/
/* ORIGINAL RONG FORMAT - ONLY IF STYLE="SNP"   */
/************************************************/

   %if &style=SNP %then %do;
     /* format the data into a proper form */
     %let tot=%eval(&num*2);
     %put &num;

/*		 %idx4list_in_alphabet_ord(*/
/*     list=&keep, */
/*     outdsd=snplist_order, */
/*     index_list_var=snpidx4list*/
/*     );*/
/*    %put The index for the input snp list sorted in alphabet order is:;*/
/*    %put &snpidx4list;*/

		 *It is confirmed that the array function will not automatically sort the snp names in the array function;
      *Thus, there is no need to use the macro var snpidx4list;

     data tmp&indsn(keep=&id snp1-snp&num m1-m&tot) n&indsn(drop=snp1-snp&num m1-m&tot);
        set &indsn;
				*Note: array function will sort snp column names automatically;
				*So the order of snps columns in the original input sas dataset will be lost;
        array snps{&num} &keep;
        array snpname{&num} snp1 - snp&num; /* this for renaming the snps */
        array ms{&tot} $1. m1 - m&tot;
 				*No need to use the snpidx4list as the array function will not sort the snp column names automatically!;
				*So the var xi is not necessary, but for learning purpose, let us keep it;
				xi=1;
        do i= 1 to dim(snps);
/*				 do i= &snpidx4list;*/
					*Note that the snps array has been sorted for these columns in the sas dataset &indsn;
				  *By using xi to for assigning data from the array snps to snpname, it will keep the original snp order;
          snpname{xi}=snps{i};
          j =2*xi-1;
          k =2*xi;   
          if snps{i} =0 then do;
             ms{j}="0";
             ms{k}="0";
          end;
          else if snps{i}=1 then do;
            ms{j}="0";
            ms{k}="1";
          end;
          else if snps{i}=2 then do;
            ms{k}="1";
            ms{j}="1";
          end;
          else do;
            ms{k}=" ";
            ms{j}=" ";
          end;

          if snps{i} in (99, .) then snpname{i}=.;

					xi=xi+1;
        end;

        /* only keep the obs that are needed for proc haplotype */
        if sum(of snp1 - snp&num)=. then delete;
     run;

   %end; /*massage input data, style=SNP */

/************************************************/
/* Default PROC HAPLOTYPE FORMAT - STYLE="MAR"  */
/************************************************/

   %if &style=MAR %then %do;
     data tmp&indsn(keep=&id &keep) n&indsn(drop=&keep);
        set &indsn;
     run;
   %end; /* massage input data, style=MAR */ 

  proc sort data=tmp&indsn;
     by &id;
  run;

  proc haplotype est=stepem data=tmp&indsn out=out(keep=&id HAPLOTYPE1 HAPLOTYPE2 PROB 
                                  rename=(HAPLOTYPE1=hap1 HAPLOTYPE2=hap2)); 
     %if &style=SNP %then %do; var m1 - m&tot; %end;
     %if &style=MAR %then %do; var &keep; %end;
     id &id;
     ods output HaplotypeFreq=Hfreq(keep=Haplotype Freq);
  run;

  data out;
     set out;
     if PROB=. then PROB=0;
     PROB = round(PROB, 0.01);
     if PROB < &thresh then delete; 
  run;

  /* output the raw haplotype result in the form of per subject per line */
  ods listing;
  proc print data=out(obs=50);
     title " Raw proc haplotype result (first 50 obs)";
  run;

  data out1;
     set out;
     haplotype = tranwrd(hap1, '-', '_');
  run;

  data out2;
     set out;
     haplotype = tranwrd(hap2, '-', '_');
  run;

  data outnew;
     set out1 out2;
  run;

  proc sort data=outnew;
     by haplotype;
  run;

  data outnew;
     set outnew end=eof;
     by haplotype;
     lagh=lag(haplotype);
     if haplotype ne lagh then num+1;
     hnum=compress("H"||num,' ');

     if eof then do;
        call symput("tot", trim(left(num)));
      end;
  run;

  proc sort data=outnew;
     by &id hnum;
  run;
   
  data outnew;
     set outnew;
     by &id hnum;
     if first.hnum then totprob=PROB/2;
     else totprob+PROB/2;
     if last.hnum;
  run;

  proc transpose data=outnew out=&outdsn1(drop=_NAME_);
     id hnum; 
     idlabel haplotype;
     var totprob;
     by &id;
  run;

  data &outdsn1(drop=i);
     set &outdsn1;
     array h{&tot} h1 - h&tot;
     do i = 1 to &tot;
       if h{i}=. then h{i}=0;
     end;
  run;
  
  /* pool low frequency haplotypes (freq<0.01) */
  proc sort data=Hfreq;
     by descending Freq;
  run;

  data hfreq1 hpool;
     set Hfreq;
     by descending Freq;
     if Freq >= &range then output hfreq1;
     else output hpool;
  run;

  data hpool;
     set hpool end=eof;
     retain tot 0;
     tot+Freq;
     if eof then do;
       Haplotype="<&range";
       Freq=tot;
       drop tot;
     end;
     if eof;
  run;
       
  data &outdsn2;
     set hfreq1 hpool;
     number=_n_;
     call symput('h', trim(left(_n_)));
  run;
    
  /* create labels for haplotype output */
  %let i =1;
  %do %while(&i <= &h);

    data _null_;
      set &outdsn2;
      if _n_=&i;  
      label&i= "z&i = " ||"'"||Haplotype||"'";
      label1&i= "z1&i = " ||"'"||Haplotype||"'";
      label2&i= "z2&i = " ||"'"||Haplotype||"'";
      call symput("label&i", label&i);
      call symput("label1&i", label1&i);
      call symput("label2&i", label2&i);

      /* for the future labels */
      call symput("labelh&i", Haplotype);
   run;

   %let i=%eval(&i+1);
  %end;

  /* append the hap number to proc haplotype output */ 
  %macro app(num);
     proc sort data =out;
       by hap&num;
     run;
    
     proc sort data=&outdsn2 out=temp(keep=Haplotype number rename=(Haplotype=hap&num number=h&num));
        by Haplotype;
     run;

     data out;
        merge out(in=a) temp(in=b);
        by hap&num;
        if a and not b then h&num="&h"; 
        if a;
     run;
  %mend app;
    
  %app(num=1);
  %app(num=2);

  proc sort data=out;
     by &id; 
  run;
  
  /* calculate Z scores for the final output */ 
  /* additive model                          */
  %if %upcase(&outadd) ne NULL %then %do; 
    data &outadd(drop=hap1 hap2 PROB i h1 h2);
       set out;
       by &id;
       array z{&h} z1 - z&h;
       retain z1 - z&h;
       if first.&id then do;
         do i=1 to &h;
           z{i}=0;
         end;
       end;

       do i = 1 to &h;
         z{i} = z{i} + ((h1 eq i) + (h2 eq i))*PROB; /* additive  model*/
       end;
       if last.&id;

       %do i=1 %to &h;
         label &&label&i;
         
         /* get the length of the label for future use */
         if &i=1 then do;
           x = %length(&&label&i);
           call symput ('x', trim(left(x)));
         end; 
       %end;
      drop x;
   run;

    /* merge back to main covariates*/
      %if &caco ne %then %do; 
        %hap_main(dsn=&outadd);
        
        /* fit the model for effect in stratum and interaction with stratum */
        %if &stratum ne %then %do;

          /* detect if the stratum is character or numeric */
          proc contents data=&outadd noprint out=content(keep=Name Type where=(name="&stratum"));
          data _null_;
             set content;
             call symput('type', trim(left(type))); 
          run;

          %hap_strata(dsn=&outadd);
        %end;
      %end;
   %end;
  /* recessive model                 */
  %if %upcase(&outreces) ne NULL %then %do;
    data &outreces(drop=hap1 hap2 PROB i h1 h2);
       set out;
       by &id;
       array z{&h} z1 - z&h;
       retain z1 - z&h;
       if first.&id then do;
         do i=1 to &h;
           z{i}=0;
         end;
       end;

       do i = 1 to &h;
         z{i} = z{i} + ((h1 eq i) and (h2 eq i))*PROB; /*recessive model */
       end;
       if last.&id;

       %do i=1 %to &h;
         label &&label&i;
       %end;
    run;
    proc print data=&outreces(obs=50) label;
       title "recessive model";
    run;
  %end;
  /* dominant model */
  %if %upcase(&outdomnant) ne NULL %then %do;
    data &outdomnant(drop=hap1 hap2 PROB i h1 h2);
       set out;
       by &id;
       array z{&h} z1 - z&h;
       retain z1 - z&h;
       if first.&id then do;
         do i=1 to &h;
           z{i}=0;
         end;
       end;
  
       do i = 1 to &h;
         z{i} = z{i} + ((h1 eq i) or (h2 eq i))*PROB; /* dominant  */
       end;
       if last.&id;

       %do i=1 %to &h;
         label &&label&i;
       %end;
    run;
    proc print data=&outdomnant(obs=50) label;
       title "dominant model";
    run;
  %end;
  /* co-dominant model */
  %if %upcase(&outcodomnant) ne NULL %then %do;
    data &outcodomnant(drop=hap1 hap2 PROB i h1 h2);
       set out;
       by &id;
       array z1{&h} z11 - z1&h;
       array z2{&h} z21 - z2&h;

       retain z11 - z1&h z21 - z2&h;
       if first.&id then do;
         do i=1 to &h;
          z1{i}=0; z2{i}=0;
         end;
       end;

       do i = 1 to &h;
          z1{i} = z1{i}+(((h1 eq i) + (h2 eq i)) eq 1)*PROB;
          z2{i} = z2{i}+(((h1 eq i) + (h2 eq i)) eq 2)*PROB;
       end;
       if last.&id;

       %do i=1 %to &h;
         label &&label1&i;
         label &&label2&i;
       %end;
    run;

    proc print data=&outcodomnant(obs=50) label;
        title "co-dominant model for 1st 50 obs";
    run;
  %end;

   /* delete the extra datasets */
   proc datasets library=work nolist;
     *delete out out1 out2 outnew hpool;
   quit;
   %exit:
%mend happy;
  
