/**********************************************************************
 
    Parameters:
 
    root_path - All directories and files under this root will be deleted.
      The root_path will not be deleted (just empty)
    lev - Used by the recursion algorithm, no need to modify default
    rmFiles_lev0 - Set this to N if you only want to delete directories
      in the root_path and leave the files alone (any files in
      subdirectories WILL be deleted)
 
 
**********************************************************************/

%macro recursiveDelete(root_path=_NONE_,lev=0,rmFiles_lev0=Y);
 
        %local rc root_path root_ID root_FN fname_path fname_ID fname_FN ifile nfile;
 
        %if %bquote(&root_path) = _NONE_ %then
            %return;
 
        %put Recursion level &lev;
        %put root_path = &root_path;
 
        /* Open root directory */
        %let rc = %sysfunc(filename(root_FN,&root_path));
        %if &rc ^= 0 %then %do;
            %put %sysfunc(sysmsg());
            %return;
        %end;
        %put root_FN = &root_FN;
        %let root_ID = %sysfunc(dopen(&root_FN));
 
 
        /* Get a list of all files in root directory */
        %let nfile = %sysfunc(dnum(&root_ID));
        %do ifile = 1 %to &nfile;
 
            /* Read pathname of file */
           /* Create dir refs &&fname_FN_&ifile for downstream deletion*/
            %local fname_path_&ifile;
            %let fname_path_&ifile = %sysfunc(dread(&root_ID,&ifile));
 
            /* Set fileref */
            %local fname_FN_&ifile;
            %let rc = %sysfunc(filename(fname_FN_&ifile,&root_path/&&fname_path_&ifile));
            %if &rc ^= 0 %then %do;
                %put %sysfunc(sysmsg());
                %return;
            %end;
 
        %end;
 
        /* Loop over all files in directory */
        %do ifile = 1 %to &nfile;
 
            /* Test to see if it is a directory */
		    /* use dir refs &&fname_FN_&ifile generated previously*/
            %let fname_ID = %sysfunc(dopen(&&fname_FN_&ifile));
            %if &fname_ID ^= 0 %then %do;
 
                %put &root_path/&&fname_path_&ifile is a directory;
 
                /* Close test */
                %let close = %sysfunc(dclose(&fname_ID));
 
                /* Close root path */
                %let close_root = %sysfunc(dclose(&root_ID));
 
                /* Remove files in this directory */
                %recursiveDelete(root_path=&root_path/&&fname_path_&ifile,lev=%eval(&lev+1));
                %put Returning to recursion level &lev;
 
                /* Remove directory */
                %put Deleting directory &root_path/&&fname_path_&ifile;
                %let rc = %sysfunc(fdelete(&&fname_FN_&ifile));
                %put %sysfunc(sysmsg());
 
                /* Reopen root path */
                %let root_ID = %sysfunc(dopen(&root_FN));
 
            %end;
            %else %if &rmFiles_lev0 = Y or &lev > 0 %then %do;
                %put Deleting file &root_path/&&fname_path_&ifile;
                %let rc = %sysfunc(fdelete(&&fname_FN_&ifile));
                %put %sysfunc(sysmsg());
            %end;
 
        %end;
      /*IMPORTANT:close the &root_FN. Otherwise, it is not able to create a dir with the same time!*/
      %let final_root_ID = %sysfunc(dclose(&root_ID));
%mend recursiveDelete;

/*%recursiveDelete(root_path=&upper_dir/_DELETE_,lev=0,rmFiles_lev0=Y);*/
