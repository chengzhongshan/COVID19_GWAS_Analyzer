%macro Multfiles2Matrix(file_dir,flrxp,tgt,value,value_type,value_cutoff_formula,matrix_dsd,debug);
%get_filenames(location=%bquote(&file_dir),dsd_out=filenames);

%if &debug=1 %then %do;
%ImportFilesInDSDbyScan(filedsd=filenames
                 ,filename_var=memname
		         ,filedir=&file_dir
                 ,fileRegexp=&flrxp
                 ,dsdout=dsd
                 ,firstobs=1
                 ,dlm='09'x
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
		         ,notverbose=0
                 ,debug=1
);
%end;
%else %do;
%ImportFilesInDSDbyScan(filedsd=filenames
                 ,filename_var=memname
		         ,filedir=&file_dir
                 ,fileRegexp=&flrxp
                 ,dsdout=dsd
                 ,firstobs=1
                 ,dlm='09'x
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
		         ,notverbose=1
                 ,debug=0
);
%end;

*Make sure to remove duplicates by &tgt and memname;
*otherwise it will be failed in transpose;
proc sort data=dsd out=uniq_dsd dupout=dup4debug nodupkeys;
by &tgt memname;
run;
%if &value ne %then %do;
*Change &value into number if &value_type=1;
%if &value_type=1 %then %do;
 data uniq_dsd(drop=&value);
 set uniq_dsd;
 digital_value=input(&value,best32.);
 run;
 data uniq_dsd;
 set uniq_dsd;
 rename digital_value=&value;
 run;
 data uniq_dsd;
 set uniq_dsd;
 %if &value_cutoff_formula ne %then %do;
 if &value_cutoff_formula;
 %end;
 run;
%end;
%end;

%else %do;
 %let value=value;
 data uniq_dsd;
 set uniq_dsd;
 value=1;
 run;
%end;

proc transpose data=uniq_dsd out=&matrix_dsd;
var &value;
by &tgt notsorted;
id memname;
run;

*For degub;
%if &debug=0 %then %do;
proc datasets lib=work noprint;
delete dsd uniq_dsd dup4debug filenames;
run;
%end;

%mend;

/*
*Case 1;
*For value is empty,just create value in output matrix and check overlap between different dsd;
*options mprint symbolgen mlogic;
%Multfiles2Matrix(file_dir=F:\NewTCGAAssocRst\WGS_Filter_Opitimization
                 ,flrxp=read
                 ,tgt=Rowlabels
                 ,value=
				 ,value_type=1
				 ,value_cutoff_formula=_log10_p_>=2
                 ,matrix_dsd=VarscanMatrix
                 ,debug=0);
*/

/*
*Case 2;
*For value is NOT empty,just filter value with cutoff and output matrix;
*options mprint symbolgen mlogic;
%Multfiles2Matrix(file_dir=F:\NewTCGAAssocRst\WGS_Filter_Opitimization
                 ,flrxp=read
                 ,tgt=Rowlabels
                 ,value=_log10_p_
				 ,value_type=1
				 ,value_cutoff_formula=_log10_p_>=2
                 ,matrix_dsd=VarscanMatrix
                 ,debug=0);

*Get the overlapping level;
data VarscanMatrix;
set VarscanMatrix;
array x{*} _numeric_;
total=0;
do i=1 to dim(x);
total=total+(x{i}^=.);
end;
output;
drop i;
run;
*/
