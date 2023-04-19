%macro DirRecursiveSearch(/*It will use SAS internal functions to search dir recursively*/
root_path=_NONE_,/*All dirs under it will be searched recursively*/
lev=0,
SR_Files_lev0=Y
);

/**********************************************************************
 
    Parameters:
 
    root_path - All directories and files under this root will be searched.

**********************************************************************/ 
        %local rc root_path root_ID root_FN fname_path fname_ID fname_FN ifile nfile;
 
        %if %bquote(&root_path) = _NONE_ %then %return;
 
        /* Use filename to check whether ROOT DIR can be opened */
        %let rc = %sysfunc(filename(root_FN,%bquote(&root_path)));

        %if &rc ^= 0 %then %do;
            %put %sysfunc(sysmsg());
            %return;
        %end;

       /*Then open the ROOT DIR and Check files and directores in the USER INPUT ROOT DIR*/

        %let root_ID = %sysfunc(dopen(&root_FN));
        /* Get a list of all files in root directory */
        %let nfile = %sysfunc(dnum(&root_ID));
        /* Loop over these files and dirs*/
        %do ifile = 1 %to &nfile;
           /* Read pathname of file */
           /* Create dir refs &&fname_FN_&ifile for printing*/
            %local fname_path_&ifile;
            %let fname_path_&ifile = %sysfunc(dread(&root_ID,&ifile));
            /* Set fileref */
            %local fname_FN_&ifile;
             %put &root_path/&&fname_path_&ifile;
	      /*For some files, it will not pass the filename function test*/
	      /*This is why we print it before the following test and return NULL*/
	      /*Returen NULL to avoid of error messages*/
            %let rc = %sysfunc(filename(fname_FN_&ifile,&root_path/&&fname_path_&ifile));			
            %if &rc ^= 0 %then %do;
               %put %sysfunc(sysmsg());
               %return;
            %end;
        %end;

        /*This step is like a duplicate as the above, but it include the %DirRecursiveSearch function!*/
        /*Which means the above procedure is actually prepared for the %DirRecursiveSearch Function*/

        /* Loop over all files in directory */
        %do ifile = 1 %to &nfile;
            /* Test to see if it is a directory */
           /* use dir refs &&fname_FN_&ifile generated previously*/
            %let fname_ID = %sysfunc(dopen(&&fname_FN_&ifile));

            %if &fname_ID ^= 0 %then %do;
                /* %put &root_path/&&fname_path_&ifile is a directory;*/
                /* Close test */
                %let close = %sysfunc(dclose(&fname_ID));
                /* Close root path */
                %let close_root = %sysfunc(dclose(&root_ID));
                /* Print files in this directory */
                %DirRecursiveSearch(root_path=&root_path/&&fname_path_&ifile,lev=%eval(&lev+1));
                /* Reopen root path */
                %let root_ID = %sysfunc(dopen(&root_FN));
            %end;

            %else %if &SR_Files_lev0 = Y or &lev > 0 %then %do;
                  %put &root_path/&&fname_path_&ifile;
            %end;
        %end;
      /*IMPORTANT:close the &root_FN. Otherwise, it is not able to create a dir with the same time!*/
      %let final_root_ID = %sysfunc(dclose(&root_ID));
%mend;

/*This macro can have some problems when search files in multi-deep dirctories*/

/*

*It will use SAS internal functions to search dir recursively;
%DirRecursiveSearch(root_path=C:\Users\Sam\Desktop\Ultra edit);

%The above macro will output all filenames into the file named as &OUTFULLPATH;
%No know the exact reason why the macro uses an internal macro appendfilename2txt;
%Finally figure out that if running the macro importallmacros before executing dirrecursivesearch;
%the output will be put into log as supposed! So the importallmacros will affect the output!;

proc import datafile="&OUTFULLPATH" dbms=tab out=filenames replace;
getnames=no;guessingrows=max;
run;
proc print;run;

*/
