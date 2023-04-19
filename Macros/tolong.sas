%macro tolong(widedata,longdata,id,suffix,suffixlo,suffixhi,vars,types=,lengths=,numprint=,quiet=);
  /* 
  widedata - name of input data file that is in wide form
  longdata - name of output data file that will be in long form
  id       - variable that uniquely identifies the wide records
  suffix   - variable name for the suffix of the wide variables
  suffixlo - the lowest value of the suffix variable
  suffixhi - the highest value of the suffix variable
  vars     - a list of the base names to transpose

  optional parameters
    types    - a list of the types of the long variables separated by spaces.
               N for numeric and C for character.  This is optional.  If
               omitted, all variables are assumed to be numeric.
    lengths  - a list of the lengths of the long variables separated by spaces.
               This is optional.  If omitted, lengths of 8 are assumed.
    numprint - number of wide records to print for verification
    quiet    - suppress PROC PRINT and PROC MEANS for verification
               NO - display proc print and proc means
               YES - suppress display of proc print and proc means 
  */

  %if &numprint =  %then %let numprint = 10 ;
  %if &quiet    =  %then %let quiet    = NO ;
  %let quiet = %upcase(&quiet) ;

  * count up how many variables in vars, store in VARNUM;
  %let varnum = 1;
  %let varname = %scan(&vars,&varnum," ");
  %do %until (&varname = );
    %let varnum=%eval(&varnum + 1);
    %let varname = %scan(&vars,&varnum," ");
  %end;
  %let nvars = %eval(&varnum - 1);

  * get the last variable from the id, sore in LASTID ;
  %let idnum = 1;
  %let idname = %scan(&id,&idnum," ");
  %do %until (&idname = );
    %let idnum=%eval(&idnum + 1);
    %let idname = %scan(&id,&idnum," ");
  %end;
  %let nids = %eval(&idnum - 1);
  %let lastid = %scan(&id,&nids);

  %put ------------------------------------------------------------------ ;
  %put - Reshape Wide to Long: Actions to take summarize below            ; 
  %put ------------------------------------------------------------------ ;
  %put - Input  (wide) data file is                        : &widedata    ;
  %put - Output (long) data file is                        : &longdata    ;
  %put - Variable that uniquely identifies wide records is : &id          ;  
  %put - Variable name for suffix of wide variable is      : &suffix      ;
  %put - and can range from: &suffixlo to &suffixhi ;
  %put - Wide variables to long variables... ;

  * start the data step.  Make widedata from longdata by id;
  data &longdata ;
    set &widedata ;

    * make ARRAY, and DROP for each variable in VARS ;
    * *********************************************;
    %do varnum = 1 %to &nvars ;
      %let varname = %scan(&vars   ,&varnum," ");
      %let vartype = %scan(&types  ,&varnum," ");
      %let varlen  = %scan(&lengths,&varnum," ");
      %if &vartype =  %then %let vartype = N;
      %if &varlen  =  %then %let varlen  = 8;
      %if &vartype = C %then %let dollar = $; %else %let dollar = ;

      array _array&varnum(&suffixlo:&suffixhi) 
		    &dollar &varlen &varname&suffixlo - &varname&suffixhi ;
      drop  &varname&suffixlo - &varname&suffixhi ;

      %put -  &varname&suffixlo ... &varname&suffixhi -> &varname of type &vartype and length &varlen ;

    %end;
    * *********************************************;

    do &suffix = &suffixlo to &suffixhi;

      * *********************************************;
      %do varnum = 1 %to &nvars ;
        %let varname = %scan(&vars,&varnum," ");
        %let vartype = %scan(&types  ,&varnum," ");
        %if &vartype =  %then %let vartype = N;
        %if &vartype = C %then %let dot = " "; %else %let dot = .;

        &varname = _array&varnum(&suffix) ;
    
      %end;
      * *********************************************;

      output;
    end;

  run;

  %if &quiet NE YES %then
  %do;

    title1 "1A. Verify reshaping of wide to long using PROC PRINT of &numprint wide records";
    title2 "    Compare this print of the wide data (&widedata) below with the "        ; 
    title3 "    PROC PRINT of the long data (&longdata) in Step 1B below"   ;
    title5 "PROC PRINT of WIDE data file &widedata";
    proc print data=&widedata(obs=&numprint);
      var &id 
      %do varnum = 1 %to &nvars ;
        %let varname = %scan(&vars,&varnum," ");
        &varname&suffixlo - &varname&suffixhi
      %end;
      ;
    run;

    title1 "1B. Verify reshaping of wide to long using PROC PRINT of &numprint wide records.";
    title2 "    Compare this print of the long data below (&longdata) with the "        ; 
    title3 "    PROC PRINT of the wide data (&widedata) in step 1A above."   ;
    title5 "PROC PRINT of LONG data file &longdata";
    proc print data=&longdata(obs= %eval(&numprint*(&suffixhi-&suffixlo+1))  );
      var &id &suffix &vars ;
    run;

    title1 "2A. Verify reshaping of wide to long using proc means";
    title2 "    Compare this PROC MEANS for the wide data (&widedata) with the "        ; 
    title3 "    PROC MEANS of the long data (&longdata) in step 2B below"   ;
	title5 "PROC MEANS of WIDE data file &widedata";
    proc means data=&widedata;
      var 
      %do j = &suffixlo %to &suffixhi ;
        %do varnum = 1 %to &nvars ;
          %let varname = %scan(&vars,&varnum," ");
          %let vartype = %scan(&types  ,&varnum," ");
          %if &vartype NE C %then &varname&j ;
        %end;
      %end;
      ;
    run;

    title1 "2B. Verify reshaping of wide to long using PROC MEANS";
    title2 "    Compare this PROC MEANS for the long data (&longdata) below" ;
    title3 "    with the PROC MEANS of the wide data (&widedata) in step 2A above"    ;
   
    title5 "PROC MEANS of LONG data file &longdata";
    proc means data=&longdata;
      class  &suffix;
      var 
      %do varnum = 1 %to &nvars ;
        %let varname = %scan(&vars,&varnum," ");
        %let vartype = %scan(&types  ,&varnum," ");
        %if &vartype NE C %then &varname ;
      %end;
      ;
    run;
  %end;

%mend tolong;
