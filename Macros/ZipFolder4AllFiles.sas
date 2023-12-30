*https://communities.sas.com/t5/ODS-and-Base-Reporting/ODS-PACKAGE-with-CALL-EXECUTE-not-quot-releasing-quot-created/td-p/720928;
%macro ZipFolder4AllFiles(target_dir,outzip,outdir,rgx2keep_file=.);
/*
This macro will try to get all files without spaces and compress
them into a single zip file;
Limitations: (1) files from subdirectories will also be compressed
but without keeping the subdirecotry in the final compressed zip
file!
*/

/* This sets up a folder that contains just the data we want */

options dlcreatedir;
%let curdir=%curdir;

data _null_;
rc=dlgcdir("&target_dir");
put rc=;
run;
*Note: file_rgx is char insensitive for prxmatch;
%list_files2globalvar(dir=&target_dir,
file_rgx=&rgx2keep_file,filelistvar=allfiles);
%put All files in the dir &target_dir: &allfiles;
%let nfiles=%eval(%sysfunc(countc(&allfiles,:))+1);

/* End of setup */
/* generate series of ODS PACKAGE ADD statements */
/* One for each data set file                    */
/* Creating a ZIP file with ODS PACKAGE */
/* important to provide nopf*/
ods package(datazip) open nopf;
%do xi=1 %to &nfiles;
%let file=%qscan(&allfiles,&xi,:);
ods package(datazip) add file="&target_dir/&file";
%end;
ods package(datazip) publish archive
  properties(
   archive_name="&outzip..zip"
   archive_path="&outdir"
  );
ods package(datazip) close;

/* If you have SAS 9.4, you can use FILENAME ZIP           */
/* To remove the "PackageMetaData" item from your ZIP file */
filename pkg ZIP "&outdir/&outzip..zip" member="PackageMetaData";
data _null_;
  if (fexist('pkg')) then
  rc = fdelete('pkg');
run;
filename pkg clear;
data _null_;
rc=dlgcdir("&curdir");
put rc=;
run;

%mend;
/*Demo:
options mprint mlogic symbolgen;
%ZipFolder4AllFiles(target_dir=/home/cheng.zhong.shan/Macros,
outzip=SAS_Macros_backup,
outdir=/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan);

*/

