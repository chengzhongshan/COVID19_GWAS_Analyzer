%macro AddSpaces4str(str=test_str,add2end=1,nspaces=3,char4space=-);
%local _ns_ _str_;
%let _str_=&str;
%do _ns_=1 %to &nspaces;
   %if &add2end=1 %then %do;
		   %let _str_=&_str_%str(&char4space);
	%end;
	%else %do;
		   %let _str_=%str(&char4space)&_str_;
	%end;
	%if &_ns_=&nspaces %then %do;
     &_str_
	 %end;
%end;
%mend;

/*Demo codes;
*Note: due to sas automatically removes tailing or leading spaces;
*it is necessary to use the char4space to replace each space;
*Note: only resolve but not dosubl can assign the value to bb;
*dosubl only returns the numeric value 0 or others to indicate the successful running of dosubl;

data x;
input aa $10.;
cards;
abc
cdef
;
*Note: only resolve but not dosubl can assign the value to bb;
*dosubl only returns the numeric value 0 or others to indicate the successful running of dosubl;
 *https://support.sas.com/kb/53/059.html;

data x;
set x;
bb=resolve('%AddSpaces4str(str='||aa||',add2end=1,nspaces=3,char4space=-)');
len_bb=length(bb);
len_aa=length(aa);
run;

proc print;run;

*/
