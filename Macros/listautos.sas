%macro listautos;
%local autoref i ref refpath;
/** Retrieve the value of the SASAUTOS option **/
%let autoref = %qsysfunc(getoption(sasautos));
%let i=0;
%do %until(&ref eq); 
	/** Pull off the first item contained within SASAUTOS **/
	%let ref = %qscan(&autoref,&i+1,%str(() ,));
	/** If everything has been read or if empty leave the macro **/
	%if &ref eq %then %return;
	/** Check to see if the item returned contains quotes **/
	/** If it does not precede to the next %LET statement **/
	%if %sysfunc(indexc(&ref,%str(%'),%str(%"))) eq 0 %then %do; 
	/** Return the path the fileref points to **/
	%let refpath=%qsysfunc(pathname(&ref));
	%let i = %eval(&i + 1); 
	/** Print location fileref path **/
	%put &i &ref &refpath;
	%end;
	/** We hit this %ELSE if the item contains quotes, not a fileref **/
	%else %do;
	%let i = %eval(&i + 1);
	/** Print location path **/
	%put &i &ref;
	%end;
%end;
%mend listautos;
/*%listautos */


