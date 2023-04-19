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

   %if %eval( %upcase( &system ) = LINUX ) %then %do;
     %let cat_cmd=cat;/*For Linux*/
   %end;
   %else %do;
     %let cat_cmd=type;/*For windows*/
	%end;

   /* run cat or type command as pipe to get contents of file */

   filename FILECONT pipe "&cat_cmd &filefullpath";
   filename OUT "&fileoutfullpath";
   data _tmp_;
      infile FILECONT length=reclen;
      input line $varying32767. reclen ;
      if reclen = 0 then delete;
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

