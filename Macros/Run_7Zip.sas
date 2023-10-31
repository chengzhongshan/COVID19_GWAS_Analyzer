%macro Run_7Zip(Dir=,          /* Windows path of directory to examine*/
                 filename=,      /* Target for 7Z                      */   
                 Zip_Cmd= x,     /* add commands listed belowing, such as x to run with fullpath
																	                   and e to extract with filename without fullpath */
                 Extra_Cmd=-y,    /* add extra commands: assume Yes on all queries
																	                    -so >x.txt output data into a new file */
																	outdir4file=			/*output uncompressed file into a new dir under the 1st macro var &Dir*/
                 ) ;
/*
Usage: 7z <command> [<switches>...] <archive_name> [<file_names>...]
       [<@listfiles...>]

<Commands>
  a: Add files to archive
  b: Benchmark
  d: Delete files from archive
  e: Extract files from archive (without using directory names)
  l: List contents of archive
  t: Test integrity of archive
  u: Update files to archive
  x: eXtract files with full paths
<Switches>
  -ai[r[-|0]]{@listfile|!wildcard}: Include archives
  -ax[r[-|0]]{@listfile|!wildcard}: eXclude archives
  -bd: Disable percentage indicator
  -i[r[-|0]]{@listfile|!wildcard}: Include filenames
  -m{Parameters}: set compression Method
  -o{Directory}: set Output directory
  -p{Password}: set Password
  -r[-|0]: Recurse subdirectories
  -scs{UTF-8 | WIN | DOS}: set charset for list files
  -sfx[{name}]: Create SFX archive
  -si[{name}]: read data from stdin
  -slt: show technical information for l (List) command
  -so: write data to stdout
  -ssc[-]: set sensitive case mode
  -ssw: compress shared files
  -t{Type}: Set type of archive
  -u[-][p#][q#][r#][x#][y#][z#][!newArchiveName]: Update options
  -v{Size}[b|k|m|g]: Create volumes
  -w[{path}]: assign Work directory. Empty path means a temporary directory
  -x[r[-|0]]]{@listfile|!wildcard}: eXclude filenames
  -y: assume Yes on all queries
*/

%local fullfilepath;
%let Dir=%sysfunc(prxchange(s/\\/\//,-1,&Dir));

%if %direxist(&_gzdir_) %then %do;
	 %put your input dir is &Dir, which exists;
	%end;
	%else %do;
		%put your input dir is &Dir, but which does not exist;
		%abort 255;
%end;

%chdir(&Dir);
%put output will be in the &Dir;
*Seems that the above code can not change dir successfully;

%let fullfilepath=%bquote(&Dir/&filename);

%if %direxist(&Dir/&outdir4file) %then %do;
 %put The dir containing uncompressed file is already there: &Dir/&outdir4file;
 %put We will not uncompress the file again;
%end;
%else %do;
options noxwait xsync;
*Note: multiple commands in windows need to be sparated by &;
*For simplicity, these commands can be split into multiple X commands, but sas failed to run;
*Note:  Only double quote but not single quote in windows can be used to escape path containing space;
%if %length(&outdir4file)>0 %then %do;
*For unknown reason, the md command can not be added with /d in Windows 10;
%put cd /d %str(%")&Dir%str(%") & md &outdir4file & cd /d %str(%")&outdir4file%str(%") & 7z &Zip_cmd %str(%")&fullfilepath%str(%") &Extra_Cmd;
X cd /d %str(%")&Dir%str(%") & md &outdir4file & cd /d %str(%")&outdir4file%str(%") & 7z &Zip_cmd %str(%")&fullfilepath%str(%") &Extra_Cmd;
%end;
%else %do;
X cd /d %str(%")&Dir%str(%") & 7z &Zip_cmd %str(%")&fullfilepath%str(%") &Extra_Cmd;
%end;
%end;
/*%abort 255;*/
%mend Run_7Zip ;

/*Demo:
x cd J:\Coorperator_projects\ACE2_2019_nCOV\Covid_GWAS_Manuscrit_Related\COVID19_HG\covid19_hg_matlab\COVID19_hosp_vs_not_hosp_B1_ALL;
*Check whether change successfully into the dir;
%CD2CWD;
%macroparas(macrorgx=list,
dir=F:\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros,
issasondemand=0
);
%list_files(.,gz);

*options mprint mlogic symbolgen;

*Uncompress gz file;
*Actionable command: 7z e B1_vs_B2.zscore.txt.gz -y;
%Run_7Zip(
Dir=J:/Coorperator_projects/ACE2_2019_nCOV/Covid_GWAS_Manuscrit_Related\COVID19_HG/covid19_hg_matlab/COVID19_hosp_vs_not_hosp_B1_ALL,
filename=B1_vs_B2.zscore.txt.gz,
Zip_Cmd=e, 
Extra_Cmd= -y,
outdir4file= xxxx
);
*Note the macro will change dir into the outdir4file;

*Compress txt into gz;
*Actionable command: 7z a B1_vs_B2.zscore.txt B1_vs_B2.zscore.txt.gz;
%Run_7Zip(
Dir=.,
filename=B1_vs_B2.zscore.txt,
Zip_Cmd=a, 
Extra_Cmd=B1_vs_B2.zscore.txt.gz
);


%Run_7Zip(
Dir=I:\sas_work_dir\_TD5332_SAM-PC_,
filename=Seurat_umap.coords.tsv.gz,
Zip_Cmd=e, 
Extra_Cmd= -y,
outdir4file= Seurat_umap.coords.tsv
);

*/

