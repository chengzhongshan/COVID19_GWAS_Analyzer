/* MACRO %GetVarAttrib
Version: 		1.00
Author: 		Daniel Mastropietro
Created: 		07-Jun-2012
Modified: 		07-Jun-2012

DESCRIPTION:
Returns the requested attribute of a given variable in a dataset.

USAGE:
%GetVarAttrib(data, var, fun);

REQUIRED PARAMETERS:
- data:		Input dataset where the variable of interest exists.

- var:		Variable for which the requested attribute should be retrieved.

- fun:		SAS file I/O function to be used to retrieve the requested attribute
			Examples are: vartype, varlen, varlabel, varnum, etc.

RETURNED VALUES:
The value of the attribute associated with the specified I/O function for the given variable
in the specified dataset.

OTHER MACROS AND MODULES USED IN THIS MACRO:
None

SEE ALSO:
- %GetVarType
- %GetVarNames
- %GetVarOrder
- %GetVarList

EXAMPLES:
%let xlen = %GetVarAttrib(test, x, fun=varlen);
Macro variable 'xlen' contains the length of variable X in dataset TEST.
*/
%MACRO GetVarAttrib(data, var, fun);
%local data_name dsid rc varnum attrib;

%let data_name = %scan(&data, 1, '(');

%* Initialize &attrib to empty in case there is an error;
%let attrib = ;
%* Open input dataset;
%let dsid = %sysfunc(open(&data_name));
	%** Note that data options are accepted in the open statement but I still use &data_name
	%** because I need it for the %PUT below in case there is an error;
%if &dsid = 0 %then
	%put GETVARATTRIB: ERROR - Dataset %upcase(&data_name) does not exist.;
%else %do;
	%let varnum = %sysfunc(varnum(&dsid,&var));
	%if &varnum = 0 %then
		%put GETVARATTRIB: ERROR - Variable %upcase(&var) does not exist in dataset %upcase(&data_name).;
	%else
		%let attrib = %sysfunc(&fun(&dsid,&varnum));
	%* Close input dataset;
	%let rc = %sysfunc(close(&dsid));
%end;

&attrib
%MEND GetVarAttrib;
