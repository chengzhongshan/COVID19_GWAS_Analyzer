
%macro rename_files_in_dsd(dsd,filevar,indir,newfilevar);
 *Remove duplicates in newfilevar;
 proc sort data=&dsd nodupkeys;
 by &newfilevar;
 run;

 proc sql noprint;
 select count(&filevar) into: n
 from &dsd;
 proc sql noprint;
 select &filevar into:v1-:v%sysfunc(left(&n))
 from &dsd;
 proc sql noprint;
 select &newfilevar into:nv1-:nv%sysfunc(left(&n))
 from &dsd;

 %do i=1 %to &n;
    *Method 1;
	*%let rc=%sysfunc(rename(%bquote(&indir\&&v&i),%bquote(&indir\&&nv&i),file));

    *Method 2;
    data _null_;
    *rc=rename("oldfile","newfile","file");
	rc=rename("&indir\&&v&i","&indir\&&nv&i",'file');
    run;

	*Method 3;
	*options noxwait xsync;
	*x rename "&indir\&&v&i","&indir\&&nv&i";

 %end;

%mend;

/*
options mprint mlogic symbolgen;
%get_filenames(location=%bquote(C:\Users\Sam\Desktop\xx),dsd_out=filenames);
data filenames;
set filenames;
newfile=catx('.',memname,'new');
run;
%rename_files_in_dsd(dsd=filenames,
                 filevar=memname,
                 indir=C:\Users\Sam\Desktop\xx,
                 newfilevar=newfile);
*/
