%macro SASZip_Lite(zip=, sfdr=, fstyl=, tfdr=);
/****************************************************************
The code posted below is provided "AS IS" with NO WARRANTIES.
ZIP: directory and file name of zip archive
SFDR: directory of source files (to be zipped)
FSTYL: File type of source files; value: *.* as "zip a folder"
TFDR: Target directory for unzipped files (for unzip)

Limitation of the macro:
In VBscript, the sleep is only 3000. For large size dir, it will
failed with problem!
*****************************************************************/
%local zip sfdr fstyl tfdr vbadir p q mode;
/* Set up a temporary working folder for VBScript */
%let vbsdir=c:\MyZi$Dir;
options noxwait;
/* To initiate a clean working space */
%if %sysfunc(fileexist("&vbsdir"))=1 %then %sysexec rd /s/q "&vbsdir";
%if %index(%upcase(&zip), .ZIP)=0 %then %let zip=&zip..zip;
%let mode=;
/* Compress (zip) files */
%if %length(&sfdr)>0 and (%length(&zip)>0) %then %do;
/* Extract directory name of the zip file, if no such folder, generate one */
%let q=%sysfunc(tranwrd(&zip, %scan(&zip, -1, %str(\)), %str( )));
%let q=%substr(&q, 1, %length(&q)-1);
%if %sysfunc(fileexist("&q"))=0 %then %sysexec md "&q";
/* Copy all requested files from a validated source folder to a temporary folder,
and keep their original time stamps */
%if %length(&sfdr)>0 and %sysfunc(fileexist("&sfdr"))=1 %then %do;
%let mode=z;
%sysexec md "&vbsdir";
%if %qupcase(&fstyl)^=%str(*.*) %then %do;
%sysexec md "&vbsdir.\temp_zip";
%sysexec copy "&sfdr.\&fstyl" "&vbsdir.\temp_zip";
%end;
%end;
%end;
%else %if %length(&tfdr)>0 and %length(&zip)>0 and %sysfunc(fileexist("&zip"))>0
%then %do; /* Unzip files */
%let mode=u;
%sysexec md "&vbsdir";
%end;
%if &mode=z or &mode=u %then %do;
/* Generate VBScript based on different modes */
data _null_;
FILE "&vbsdir.\xpzip.vbs";
put 'Set ZipArgs = WScript.Arguments';
put 'InputFile = ZipArgs(0)';
put 'TgtFile = ZipArgs(1)';
put 'Set objShell = CreateObject("Shell.Application")';
put 'Set source = objShell.NameSpace(InputFile).Items';
put 'soucnt = objShell.NameSpace(InputFile).Items.Count';
%if &mode=z %then %do;
put 'CreateObject("Scripting.FileSystemObject").CreateTextFile(TgtFile,
True).Write "PK" & Chr(5) & Chr(6) & String(18, Chr(0))';
put 'objShell.NameSpace(TgtFile).CopyHere(source)';
put 'Do Until objShell.NameSpace(TgtFile).Items.Count = soucnt';
put 'wScript.Sleep 3000';
put 'Loop';
%end;
%else put 'objShell.NameSpace(TgtFile).CopyHere(source)'; ;
put 'wScript.Sleep 3000';
run;
/* Run VBScript file for data archiving */
%if &mode=z %then %do;
%if %qupcase(&fstyl)=%str(*.*) %then %sysexec CScript "&vbsdir.\xpzip.vbs"
"&sfdr" "&zip";
%else %sysexec CScript "&vbsdir.\xpzip.vbs" "&vbsdir.\temp_zip" "&zip";
%end;
%else %sysexec CScript "&vbsdir.\xpzip.vbs" "&zip" "&tfdr";
%end;
/* Clean up */
%if %sysfunc(fileexist("&vbsdir"))=1 %then %sysexec rd /s/q "&vbsdir";
%mend SASZip_Lite;

/*The SAS macro shown above is a fully functional version. It can compress single or multiple files located at a specific
folder into a zip archive or decompress a zip file to a target folder.
To unzip a zip archive, users only need to provide the full name of zipped file and the directory of the target folder to
two macro variables (zip and tfdr), respectively.*/
/* Usage demo 1: Unzip archived files in Raw_2011.zip to folder extrt1 */
*%SASZip_Lite(zip=c:\work\study1\raw_ds\Raw_2011.zip, tfdr=C:\work\raw\extrt1);

/*For data compression, this macro has three basic options to generate zip files. By default, it zips all SAS datasets in
the specified folder into a single file. It can also zip either a specific file type or whole contents (i.e., files and
subfolders) of a folder into a zip archive by specifying the file extension to the macro variable ¡®fstyl¡¯. 
Examples for these three options are displayed below.*/
/* Usage demo 2a: Zip all SAS datasets in a folder (Raw_ds) to a single zip file */
*%SASZip_Lite(zip=C:\work\raw\test 1.zip, sfdr=C:\work\my_extract\Raw_ds);
/* Usage demo 2b: Zip all *.DOC files in a folder to a single zip file */
*%SASZip_Lite(zip=c:\Doc temp\my_output.zip, sfdr=C:\work\5Y\Sasout\doc,fstyl=%str(*.doc));
/* Usage demo 2c: Zip all files & subfolders in a folder to a single zip file */
*%SASZip_Lite(zip=c:\Doc temp\my_folder.zip, sfdr=C:\work\5Y\adhoc, fstyl=%str(*.*));
