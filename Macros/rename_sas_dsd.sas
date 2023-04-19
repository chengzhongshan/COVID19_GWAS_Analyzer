%macro rename_sas_dsd(
dsdin,
dsdout
);

*rename the &dsdin as &dsdout;
%if %index(&dsdin,.) %then %do;
  %let _dsdin_=%scan(&dsdin,2,.);
	 %let _inlib_=%scan(&dsdin,1,.);
%end;
%else %do;
  %let _dsdin_=&dsdin;
	 %let _inlib_=work;
%end;

%if %index(&dsdout,.) %then %do;
  %let _dsdout_=%scan(&dsdout,2,.);
	 %let _outlib_=%scan(&dsdout,1,.);
%end;
%else %do;
  %let _dsdout_=&dsdout;
	 %let _outlib_=work;
%end;

%if "&_outlib_"^="&_inlib_" %then %do;
 proc datasets nolist force;
 copy in=&_inlib_ out=&_outlib_ memtype=data move;
 select &_dsdin_;
 run;
%end;
%else %do;
 %if "&_dsdin_"^="&_dsdout_" %then %do;
  proc datasets lib=&_inlib_ nolist force;
  change &_dsdin_=&_dsdout_;
  run;
	%end;
	%else %do;
 	%put No need to change &dsdin into &dsdout as they are the same!;
	%end;
%end;

%mend;

/*Demo:

libname mylib 'fullpath to your lib';
*libname mylib 'J:\Coorperator_projects\ACE2_2019_nCOV\Covid19_transcriptomic_analysis\hypertension_sc_COVID19_SAS_dsd';
*Note: the a_copy will be moved into the lib mylib as a_copy;
%rename_sas_dsd(
dsdin=a_copy,
dsdout=mylib.a_copy
);

*Note: the a_norm will be renamed ad a_copy;
%rename_sas_dsd(
dsdin=a_norm,
dsdout=a_copy
);

*/

