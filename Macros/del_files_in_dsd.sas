%macro del_files_in_dsd(dsd,filevar,indir,match_rgx);
 proc sql noprint;
 select count(&filevar) into: n
 from &dsd;
 proc sql noprint;
 select unique(&filevar) into:v1-:v%sysfunc(left(&n))
 from &dsd
 %if %eval("&match_rgx" ne "") %then %do;
  where prxmatch("/&match_rgx/i",&filevar)
 %end;
 ;
  %do i=1 %to &n;
    %put "Going to delete the file: &indir\&&v&i";
    %del_file_with_fullpath(fullpath=&indir\&&v&i);
  %end;
%mend;
/*

%get_filenames(location=%bquote(C:\Users\Sam\Desktop\x),dsd_out=filenames,match_rgx=);

%del_files_in_dsd(dsd=filenames,filevar=memname,indir=C:\Users\Sam\Desktop\x,match_rgx=);

*/



