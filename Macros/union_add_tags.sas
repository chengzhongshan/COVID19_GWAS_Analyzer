%macro union_add_tags(dsds=,     /*Name of the datasets, separated by space    */
                       out=       /*Name of combined data set     */);
 %local vars_all_numeric nobs;
 %let vars_all_numeric=0;
 %let i=1;  
 %do %while(%scan(&dsds,&i,%str( )) ne);
  %let f=%scan(&dsds,&i,%str( ));	 
  %put going to process &f and name it temporarily as _D_&i;
  *The original macro only selects char variables by restricting type=2;
  *it would fail when all vars from these dataset are numeric vars;
  proc contents data=&f noprint 
      out=_D_&i(keep=name type length where=(type=2));
  run;
  
 %let nobs=%totobsindsd(work._D_&i);
 %if &nobs=0 %then %let vars_all_numeric=1;

  proc sort data=_D_&i;by name;run;

  data _D_&i;
  set _D_&i;
  rename length=length&i;
  run;

  data _DD_&i;
/*  be careful about filename*/
  length dsd $50.;
  set &f;
  dsd="&f";
  run;

  %let i=%eval(&i+1);
 %end;

 %let i=%eval(&i-1);

  %if (&i<1 ) %then %do;
  %put "You provided dsds are less than 2, which are &dsds";
  %Abort 255;
  %end;
  %else %do;
  %put "You provided dsds are &dsds";
  %end;

  /*  %let cwd=%qsubstr(
             %sysget(sas_execfilepath),
             1,
             %length(%sysget(sas_execfilepath))-%length(%sysget(sas_execfilename))-1
           );*/
%let cwd= %sysfunc(getoption(work));

%if &vars_all_numeric=0 %then %do;
   /*Delete combined.sas*/
   %del_file_with_fullpath(fullpath=&cwd/combined.sas);

   data _null_;
      file "&cwd/combined.sas";
      merge _D_: end=last;
      by name;
      if _n_ = 1 then do;
         put "Data &out;";
		 put "length ";
	  end;
      l = max(of length1-length&i);
	  len=cat(name,' ','$',strip(left(put(l,$5.))));
     /*the 3. after l will make the number of l in 3 integer format*/
     /*Be carefull here, as some variable indeed is very long*/
     /*put "   length " name " $ " l 5.";";*/
	  put len;

      if last then do;
	     put ";";
         put "   set _DD_:;";
         put "run;";
      end;
   run;

   %include "&cwd/combined.sas";
   %end;
   %else %do;
      *When all vars are numeric, just use set to combine all these datasets;
       data &out;
	   set _DD_:;
	   run;
   %end;

   /*Delete combined.sas*/
   %del_file_with_fullpath(fullpath=&cwd/combined.sas);
   proc datasets noprint;
   delete _D:;
   run;
   *Remove duplicates;
   proc sort data=&out nodupkeys;by _all_;run;
%mend union_add_tags;

