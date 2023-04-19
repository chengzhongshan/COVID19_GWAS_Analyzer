%macro union(dsn1=,     /*Name of the first data set    */
             dsn2=,     /*Name of the second data set   */
             out=       /*Name of combined data set     */);
   
   proc contents data=&dsn1 noprint 
      out=out1(keep=name type length where=(type=2));

   proc contents data=&dsn2 noprint 
      out=out2(keep=name type length where=(type=2));
   run;
   proc sort data=out1;by name;run;
   proc sort data=out2;by name;run;

  /*  %let cwd=%qsubstr(
             %sysget(sas_execfilepath),
             1,
             %length(%sysget(sas_execfilepath))-%length(%sysget(sas_execfilename))-1
           );*/
%let cwd= %sysfunc(getoption(work));

   /*Delete combined.sas*/
   %del_file_with_fullpath(fullpath=&cwd/combined.sas);

   data _null_;
      file "&cwd/combined.sas";
      merge out1 out2(rename=(length=length2)) end=last;
      by name;
      if _n_ = 1 then put "Data &out;";
      l = max(length,length2);
     /*the 3. after l will make the number of l in 3 integer format*/
     /*Be carefull here, as some variable indeed is very long*/
      put "   length " name " $ " l 5.";";
      if last then do;
         put "   set &dsn1 &dsn2;";
         put "run;";
      end;
   run;

   %include "&cwd/combined.sas";

   /*Delete combined.sas*/
   %del_file_with_fullpath(fullpath=&cwd/combined.sas);
   proc datasets noprint;
   delete out1 out2;
   run;
%mend union;
