%macro merge_dsd_by_comm_vars(dsds=,     /*Name of the datasets, separated by space    */
                              out=,       /*Name of combined data set     */
                              comm_vars_rgx= /*Common vars regulary expression among these datasets; no '()' is allowed!*/);

 %let commvar_length=8;
 %let dsd_with_largest_var=;

 %let i=1;  
 %do %while(%scan(&dsds,&i,%str( )) ne);
  %let f=%scan(&dsds,&i,%str( ));	 
  %put going to process &f and name it temporarily as _D_&i;
  data _tmpvars_;
  set &f;
  run;
  %vars_length_dsd(lib=work,
                dsd=_tmpvars_
                ,vars_rgx=&comm_vars_rgx
				,dsdout=_D_&i
                ,sum_vars_length=1
                ,sum_vars_lengthoutvar=var_length_sum);

 
  *Sort these datasets with comm_vars_rgx, necessary for later mergering process;
  proc sql noprint;
  select unique(name) into: commvars separated by ' '
  from _D_&i;
  proc sort data=&f out=_DD_&i;by &commvars;run;
  *Keep unique rows for different variable type;
  /*proc sort data=_D_&i nodupkeys; by type descending;run;*/
  *Only focus on the length of char vars, as merging of numeric variable will be fine;
  data _D_&i;
  set _D_&i;
  keep var_length_sum name type;
  where type=2;
  run;
  data _D_&i;
  set _D_&i(obs=1);*Only keep one record;
  name=upcase(name);
  rename var_length_sum=length&i;
  run;

  *Create macro var to record the length;
  proc sql noprint;
  select length&i into: varlength
  from _D_&i;

    
  %if %eval(&varlength>&commvar_length) %then %do;
   %let dsd_with_largest_var=_DD_&i &dsd_with_largest_var;
/*   %put dsd_with_largest_var is &dsd_with_largest;*/
  %end;
  %else %do;
   %let dsd_with_largest_var=&dsd_with_largest_var _DD_&i;
/*   %put dsd_with_largest_var is &dsd_with_largest;*/
  %end;


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

   /*Delete combined.sas*/
   %del_file_with_fullpath(fullpath=&cwd/combined.sas);

   *Make sure put FIRST for the dsd with the largest length of common vars;
   data sasscript;
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
      *Keep the dsd with largest common vars length at first for correct mergeing;
      if last then do;
	     put ";";
         put "   merge &dsd_with_largest_var _DD_:; by &commvars;";
         put "run;";
      end;
   run;
  
   %include "&cwd/combined.sas";
   /*Delete combined.sas*/
   %del_file_with_fullpath(fullpath=&cwd/combined.sas);
   proc datasets noprint;
   delete _D:;
   run;
   *Remove duplicates;
   proc sort data=&out nodupkeys;by _all_;run;
%mend;

/*Demo:
%merge_dsd_by_comm_vars(dsds=Zscore_gse10246 Zscore_gse10327,
                       out=zzzz,
                       comm_vars_rgx=_genesymbol_);

*/


