%macro InstallGitHubZipPackage(
git_zip=https://github.com/chengzhongshan/COVID19_GWAS_Analyzer/archive/refs/heads/main.zip,
homedir=%sysfunc(pathname(HOME)),/*SAS OnDemand for Academics HOME folder*/
InstallFolder=NewMacros, /*Put all uncompressed files into the folder under the homedir*/
DeletePreviousFolder=0, /*Delete previous InstallFolder if existing in the target homedir*/
excluded_files_rgx=Evaluate_FOXP4_SNPs_with_both_long_COVID_and_severe_COVID|COVID19_GWAS_Analyzer_STAR_Protocol_Demo_Codes4MAP3K19|HGI_Hospitalization_GWAS_Analyzer 
/*Exclude files matched with perl regular expressions, which should be separated by | and 
no () is needed to wrap these perl regular expression, as () will be added within the macro*/
);

%if %sysfunc(fileexist(%bquote(&homedir/&InstallFolder))) and &DeletePreviousFolder=1 %then %do;
 %_recursiveDelete(root_path=&homedir/&InstallFolder,lev=0,rmFiles_lev0=Y);
 %let dir=&homedir/&InstallFolder;
 filename del_dir "&dir";
 data _null_;
   rc=fdelete('del_dir');
   put rc=;
   msg=sysmsg();
   put msg=;
 run;
%end;
%else %if %sysfunc(fileexist(%bquote(&homedir/&InstallFolder))) and &DeletePreviousFolder=0 %then %do;
 %put Previous dir &homedir/&InstallFolder exists, and the macro var DeletePreviousFolder is 0;
 %put SAS will stop now unless you provide the value 1 to the macro var DeletePreviousFolder;
 %abort 255;
%end;


%_dwn_http_file(httpfile_url=&git_zip,outfile=sas.zip,outdir=%sysfunc(getoption(work)));

%_mp_unzip(
ziploc="%sysfunc(getoption(work))/sas.zip",
outdir=&homedir/&InstallFolder,
UnzipAllFilesIntoOneFolder=1,
excluded_files_rgx=&excluded_files_rgx
);

%mend;
/*Demo codes:;

filename install url "https://raw.githubusercontent.com/chengzhongshan/COVID19_GWAS_Analyzer/main/Macros/InstallGitHubZipPackage.sas";
%include install;

%InstallGitHubZipPackage(
git_zip=https://github.com/chengzhongshan/COVID19_GWAS_Analyzer/archive/refs/heads/main.zip,
homedir=%sysfunc(pathname(HOME)),
InstallFolder=Macros,
DeletePreviousFolder=1 
);


%let macrodir=%sysfunc(pathname(HOME))/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;
%macroparas(macrorgx=github);

*/



**************************Sub-macros used by the above macro*************************************;

%macro _getuniquefileref(prefix=_,maxtries=1000,lrecl=32767);
  %local rc fname;
  %if &prefix=0 %then %do;
    %let rc=%sysfunc(filename(fname,,temp,lrecl=&lrecl));
    %if &rc %then %put %sysfunc(sysmsg());
    &fname
  %end;
  %else %do;
    %local x len;
    %let len=%eval(8-%length(&prefix));
    %let x=0;
    %do x=0 %to &maxtries;
      %let fname=&prefix%substr(%sysfunc(ranuni(0)),3,&len);
      %if %sysfunc(fileref(&fname)) > 0 %then %do;
        %let rc=%sysfunc(filename(fname,,temp,lrecl=&lrecl));
        %if &rc %then %put %sysfunc(sysmsg());
        &fname
        %return;
      %end;
    %end;
    %put unable to find available fileref after &maxtries attempts;
  %end;
%mend _getuniquefileref;

%macro _mf_mkdir(dir
)/*/STORE SOURCE*/;
 
  %local lastchar child parent;
 
  %let lastchar = %substr(&dir, %length(&dir));
  %if (%bquote(&lastchar) eq %str(:)) %then %do;
    /* Cannot create drive mappings */
    %return;
  %end;
 
  %if (%bquote(&lastchar)=%str(/)) or (%bquote(&lastchar)=%str(\)) %then %do;
    /* last char is a slash */
    %if (%length(&dir) eq 1) %then %do;
      /* one single slash - root location is assumed to exist */
      %return;
    %end;
    %else %do;
      /* strip last slash */
      %let dir = %substr(&dir, 1, %length(&dir)-1);
    %end;
  %end;
 
  %if (%sysfunc(fileexist(%bquote(&dir))) = 0) %then %do;
    /* directory does not exist so prepare to create */
    /* first get the childmost directory */
    %let child = %scan(&dir, -1, %str(/\:));
 
    /*
      If child name = path name then there are no parents to create. Else
      they must be recursively scanned.
    */
 
    %if (%length(&dir) gt %length(&child)) %then %do;
      %let parent = %substr(&dir, 1, %length(&dir)-%length(&child));
      %_mf_mkdir(&parent)
    %end;
 
    /*
      Now create the directory.  Complain loudly of any errs.
    */
 
    %let dname = %sysfunc(dcreate(&child, &parent));
    %if (%bquote(&dname) eq ) %then %do;
      %put %str(ERR)OR: could not create &parent + &child;
      %abort cancel;
    %end;
    %else %do;
      %put Directory created:  &dir;
    %end;
  %end;
  /* exit quietly if directory did exist.*/
%mend _mf_mkdir;

%macro _recursiveDelete(root_path=_NONE_,lev=0,rmFiles_lev0=Y);
 
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
                %_recursiveDelete(root_path=&root_path/&&fname_path_&ifile,lev=%eval(&lev+1));
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
%mend _recursiveDelete;

%macro _dwn_http_file(httpfile_url,outfile,outdir);
%if "&outfile"="" %then %do;
%let outfile=%sysfunc(prxchange(s/.*\///,-1,&httpfile_url));
%end;
%if "&outdir"="" %then %do;
*%let outdir=%curdir;
%let outdir=%sysfunc(getoption(work));
%end;
%put Downloaded file will be put into here:;
%put &outdir/&outfile;
filename out "&outdir/&outfile";
proc http
 url="&httpfile_url"
 method="get" out=out;
run;
filename out clear;

%put &SYS_PROCHTTP_STATUS_CODE;
%if "&SYS_PROCHTTP_STATUS_CODE"^="200" %then %do;
 %put SYS_PROCHTTP_STATUS_CODE is &SYS_PROCHTTP_STATUS_CODE;
 %put Please check your provided URL:;
 %put &httpfile_url;
 %put You may test it directly in any browser to ensure it works!;
 %abort 255;
%end;

%mend;

%macro _mp_unzip(
  ziploc=
  ,outdir=%sysfunc(pathname(work))
  ,UnzipAllFilesIntoOneFolder=0 
  /*Extract all files in the main- and sub-folders and put them into the supplied outdir*/
  ,excluded_files_rgx= /*put multiple file regular expressions separated by | that should be excluded*/
)/*/STORE SOURCE*/;
 
%local f1 f2 ;
%let f1=%_getuniquefileref();
%let f2=%_getuniquefileref();
 
/* Macro variable &datazip would be read from the file */
filename &f1 ZIP &ziploc;
 
/* create target folder */
%_mf_mkdir(&outdir)
 
/* Read the "members" (files) from the ZIP file */
data _data_(keep=memname isFolder);
  length memname $200 isFolder 8;
  fid=dopen("&f1");
  if fid=0 then stop;
  memcount=dnum(fid);
  do i=1 to memcount;
    memname=dread(fid,i);
    /* check for trailing / in folder name */
    isFolder = (first(reverse(trim(memname)))='/');
    output;
  end;
  rc=dclose(fid);
run;
 
filename &f2 temp;
 
/* loop through each entry and either create the subfolder or extract member */
data _null_;
  set &syslast;
  file &f2;
  
  *Decide whether to put files into a single output folder;
  %if &UnzipAllFilesIntoOneFolder=0 %then %do;
  if isFolder then do;
    call execute('%_mf_mkdir(&outdir/'!!memname!!')');
  end;
  %end;
  
    *memname will be changed if UnzipAllFilesIntoOneFolder is true;
    bname=cats('(',memname,')');
    
  if not isFolder then do;
   *Decide whether to put files into a single output folder;
   %if &UnzipAllFilesIntoOneFolder=0 %then %do;
    qname=quote(cats("&outdir/",memname));
   %end;
   %else %do;
    memname=prxchange('s/.*[\/\\]([^\/\\]+)$/$1/',1,memname);
    qname=quote(cats("&outdir/",memname));
   %end;

    *Exclude these files matched with file regular expression;
   %if %length(&excluded_files_rgx)>0 %then %do;
    if prxmatch("/(&excluded_files_rgx)/i",memname) then do;
         call symputx('run_inc',0);
    end;
    else do;
         call symputx('run_inc',1);
     end;
   %end;

    put '/* hat tip: "data _null_" on SAS-L */';
    put 'data _null_;';
    put '  infile &f1 ' bname ' lrecl=32767 recfm=F length=length eof=eof unbuf;';
    put '  file ' qname ' lrecl=32767 recfm=N;';
    put '  input;';
    put '  put _infile_ $varying32767. length;';
    put '  return;';
    put 'eof:';
    put '  stop;';
    put 'run;';
  end;
run;

%if &run_inc=1 %then %do; 
   %inc &f2/source2;
%end;
 
filename &f2 clear;
 
%mend _mp_unzip;





