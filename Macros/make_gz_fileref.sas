%macro make_gz_fileref(
zip=,/*full path for the gz file*/
outgzfileref=fromzip /*A fileref for the uncompressed zip file*/
);

%if "&sysscp"="WIN" %then %do;
	*Need to use 7zip in Windows;
	*Uncompress gz file;
 *Actionable command: 7z e B1_vs_B2.zscore.txt.gz -y;
	%let _gzfile_=%scan(&zip,-1,/\);
	*need to consider [\/\\] for the separator of &zip;
	%let _gzdir_=%sysfunc(prxchange(s/(.*)[\/\\][^\/\\]+/$1/,-1,&zip));
	*Need to confirm whether the _gzdir_ is parsed correctly;
	*When the &zip var only contains relative path without '.' at the beginning of the dir string;
	*The prxchange function can not generate right dir;
	%if %direxist(&_gzdir_) %then %do;
	 %put your gz file dir is &_gzdir_, which exists;
	%end;
	%else %do;
		%put your gz file dir is &_gzdir_, but which does not exist;
		%abort 255;
	%end;


	%put you gz file is &_gzfile_;
	%let filename4dir=%sysfunc(prxchange(s/(.bgz|.tgz|gz)//i,-1,&_gzfile_));
	*This is to prevent the outdir4file with the same name as the gz file;
	*windows will failed to create the dir if the gz file exists;
	%if %sysfunc(exist(&_gzdir_/&filename4dir)) %then %do;
	%put The dir &filename4dir exists, and we assume the file has been uncompressed!;
	%end;
	%else %do;
 %Run_7Zip(
 Dir=&_gzdir_,
 filename=&_gzfile_,
 Zip_Cmd=e, 
 Extra_Cmd= -y ,
 outdir4file=&filename4dir
 );
	*Use the filename to create a dir to save uncompressed file;
	*Note Run_7Zip will change dir into outdir4file;
	%end;

	%let uncmp_gzfile=%sysfunc(prxchange(s/\.gz//,-1,&_gzfile_));
	*Use regular expression to match file, as the uncompressed file may have different appendix, such as tsv.gz.tmp;
	filename  &outgzfileref "&_gzdir_/&filename4dir/*";
%end;

%else %do;
  filename  &outgzfileref ZIP "&zip" GZIP;
%end;

%mend;

/*Demo codes:;
*The macro can generate a fileref for compressed gz file;
*The newly created gz fileref can be used by the traditional infile command;
*In Windows system, the macro will run 7ZIP to uncompress the input gz file first;
*then create a fileref for the uncompressed file;

%make_gz_fileref(
zip=fullpath4gzfile,
outgzfileref=fromzip 
);
*/

