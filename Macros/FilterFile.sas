%macro FilterFile( 
       filefullpath      /* input file fullpath                                  */
      ,ExcludedLineRegx  /*Lines will be excluded if match the regexpression     */
      ,KeptLineRegx      /*Lines will be kept if match the regexpression*/
      ,system            /* The system to run the macro: Linux or Windows        */
      ,fileoutfullpath   /* Output data into a new file                          */
) ;

   /* PURPOSE: automatically change file contents by applying regexpression to exclude BLANK lines and matched lines
    *
    * NOTE:    %FilterFile is designed to be run on SAS installations using the Windows O/S or Linux
    */

/*
   *For Linux;
   %if %eval( %upcase( &system ) = LINUX ) %then %do;
     %let cat_cmd=cat;
   %end;
   %else %do;
    *For windows
     %let cat_cmd=type;
	%end;
*Note: it is not beneficial to use type in windows, as directly reading file using infile would be more efficient!;
	*/

     filename OUT "&fileoutfullpath";
   %if %eval( %upcase( &system ) = LINUX ) %then %do;
     %let cat_cmd=cat;/*For Linux*/
	/* run cat or type command as pipe to get contents of file */
   /* but the tool type in window is too slow*/
   filename FILECONT pipe "&cat_cmd &filefullpath";
   data _tmp_;
      infile FILECONT length=reclen;
      *letting line length equal to 32767 will crash old computer; 
      *input line $varying32767. reclen ;
       input line :$5000. ;
      *if reclen = 0 then delete;
      if prxmatch("/^\s*$/",line)
         then delete;
	 %if %eval("&ExcludedLineRegx"^="") %then %do;
      if prxmatch("/&ExcludedLineRegx/",line)
		 then delete;
	 %end;
	 %if %eval("&KeptLineRegx"^="") %then %do;
      if prxmatch("/&KeptLineRegx/",line);
	 %end;
   run;
   %end;
   %else %do;
     /*For windows*/
      /* run cat or type command as pipe to get contents of file */
      /* but the tool type in window is too slow*/
   filename FILECONT "&filefullpath";
   data _tmp_;
      infile FILECONT lrecl=5000;
      *letting line length equal to 32767 will crash old computer; 
      *input line $varying32767. reclen ;
       input line :$5000.;
      if prxmatch("/^\s*$/",line)
         then delete;
	 %if %eval("&ExcludedLineRegx"^="") %then %do;
      if prxmatch("/&ExcludedLineRegx/",line)
		 then delete;
	 %end;
	 %if %eval("&KeptLineRegx"^="") %then %do;
      if prxmatch("/&KeptLineRegx/",line);
	 %end;
   run;
	%end;

   data _null_;
   set _tmp_;
   file OUT;
   put line;
   run;


%mend FilterFile;

/*
options mprint mlogic symbolgen;

%FilterFile( filefullpath=C:\Users\ZC254\Desktop\tmp.sh     
      ,ExcludedLineRegx=#
      ,KeptLineRegx= 
      ,system=Windows 
				  ,fileoutfullpath=C:\Users\ZC254\Desktop\tmp.txt
                 ) ;
*/

