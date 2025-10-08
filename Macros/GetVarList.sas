/* MACRO %GetVarList
Version: 	2.01
Author: 	Daniel Mastropietro
Created: 	27-Dec-2004
Modified:	20-Jun-2016 (previous: 17-Aug-2006)

DESCRIPTION:
This macro parses a list of variables in a dataset by converting the keywords
_ALL_, _NUMERIC_, _CHAR_, hyphen strings (such as in x1-x7, id--name), and colon references
to variables (as in id:) into a regular list of variables.

Note that if just the list of all variables is wished use %GetVarOrder which runs
much faster.

USAGE:
%GetVarList(data, var=_ALL_, check=0, log=1);

REQUIRED PARAMETERS:
- data:			Input dataset. Data options can be specified but THEY ARE IGNORED.

OPTIONAL PARAMETERS:
- var:			List of variables to parse.
				It can contain the keywords _ALL_, _NUMERIC_, _CHAR_ and hyphen strings
				such as in x1-x7.
				Default: _ALL_

- check:		Check for existence of the variables in the dataset?
				If check = 1 the list of variables obtained as the result of the parsing
				procedure is checked for existence in the dataset. Those variables not found
				in the dataset are listed in the log with a WARNING message.
				Possible values: 0 => No, 1 => Yes
				default: 0

- log:			Show messages in the log?
				Possible values: 0 => No, 1 => Yes
				default: 1

RETURNED VALUES:
A blank-separated list with the variable names in the input dataset matching the keywords.

NOTES:
1.- If the last variable in a double hyphen string is found before the first variable, a WARNING
is issued and the returned list for that string is empty.

2.- The addition of parameter CHECK= was essentially due to the call that is performed to %GetVarList
from macro %CheckInputParameters, where the message of existence or non-existence of variables is
performed there (i.e. when calling %GetVarList from %CheckInputParameters, I don't want the macro
%GetVarList to check for existence of the variables in the dataset because I want this task to be
done by %CheckInputParameters, so that the appropriate messages are issued by this macro. Therefore
I call %GetVarList with CHECK=0 from within %CheckInputParameters).

3.- If just the list of all variables in the dataset is wished, use rather %GetVarOrder which
runs much faster.

OTHER MACROS AND MODULES USED:
- %ExistVar
- %IsNumber
- %MakeListFromName
- %RemoveFromList
- %RemoveRepeated

SEE ALSO:
- %GetVarNames

EXAMPLES:
1.- %let vars = %GetVarList(test, var=x1-x5 count: id--name, check=1);
The list of passed variables that exist in dataset TEST is returned and stored in macro variable VARS.

2.- %let vars = %GetVarList(test, var=x1-x5 count: id--name);
Same as above but the variables resulting from the parsing process are NOT checked for existence in
dataset TEST.
*/
%MACRO GetVarList(data, var=_ALL_, check=0, log=1);
%local i j;
%local hyphen hyphen2 name name2 nro_elements vari varlist;
%local character charFound firstFound lastFound;
%local colon namlen; 
%* Variables used when reading variables in the dataset;
%local data_name dsid nvars rc varname vartype;
%local numvar charvar allvar;
%* Variables used to parse hyphen strings;
%local start stop;

%* Check if the list of variables contains any of the reserved keywords for variables reference;
%if ~(%sysfunc(indexw(%quote(%upcase(&var)), _ALL_)) or
	%sysfunc(indexw(%quote(%upcase(&var)), _NUMERIC_)) or
	%sysfunc(indexw(%quote(%upcase(&var)), _CHAR_)) or
	%index(%quote(%upcase(&var)), -) or
	%index(%quote(%upcase(&var)), :)) %then
	%let varlist = &var;
%else %do;
%* Initialize list of variables to return;
%let varlist = ;

%* Open input dataset;
%let data_name = %scan(%quote(&data), 1, '(');
%let dsid = %sysfunc(open(&data_name));
%if ~&dsid %then
   	%put GETVARLIST: ERROR - Dataset %upcase(&data_name) does not exist.;
%else %do;
	%* Get the number of variables in the dataset (for later use);
	%let nvars = %sysfunc(attrn(&dsid , nvars));
	%* Remove any repeated string in &var;
	%let var = %RemoveRepeated(&var, log=0);

	%* Search for the keywords _ALL_, NUMERIC_ and _CHAR_. If any of them exist
	%* construct the list of numeric variables and character variables;
	%if %index(%upcase(&var), _ALL_) or
		%index(%upcase(&var), _NUMERIC_) or
		%index(%upcase(&var), _CHAR_) %then %do;
		%* Read all variables in the order they appear in the dataset and store
		%* the list of numeric and character variables into two different macro variables;
		%let allvar = ;
		%let numvar = ;
		%let charvar = ;
		%do i = 1 %to &nvars;
			%let vartype = %sysfunc(vartype(&dsid, &i));	%* Type of variable in column &i. Either C or N;
			%let varname = %sysfunc(varname(&dsid, &i));	%* Variable name in column &i;
			%let allvar = &allvar &varname;
			%* Store the variable name in the list of numeric or character variables;
			%if %upcase(&vartype) = N %then
				%let numvar = &numvar &varname;
			%else %if %upcase(&vartype) = C %then
				%let charvar = &charvar &varname;
		%end;
	%end;

	%* If the keyword _ALL_ is present in the variable list, ignore everything else and return
	%* the list of all variables present in the dataset;
	%if %index(%upcase(&var), _ALL_) %then
		%let varlist = &allvar;
	%else %do;
		%* Parse the keywords _NUMERIC_ and _CHAR_;
		%if %index(%upcase(&var), _NUMERIC_) %then
			%let varlist = &numvar;
		%if %index(%upcase(&var), _CHAR_) %then
			%let varlist = &varlist &charvar;

		%* Remove the keywords _NUMERIC_ and _CHAR_ from the input variable list;
		%let var = %RemoveFromList(&var, _NUMERIC_ _CHAR_, log=0);

		%* Parse any hyphen strings found in the input variable list;
		%let nro_elements = %GetNroElements(&var);
		%do i = 1 %to &nro_elements;
			%* Read i-th variable (or actually i-th name in the list &var);
			%let vari = %scan(%quote(&var), &i, ' ');

			/*----- Double hyphen as in id--name -----*/
			%* Look for a double hyphen in the current variable i (e.g. id--count, which means to consider all the
			%* variables that are in between variables ID and COUNT in the order they appear in the dataset
			%* including extremes);
			%let hyphen2 = %index(&vari, --);
			%if &hyphen2 > 0 %then %do;
				%let var1 = %substr(%quote(&vari), 1, &hyphen2-1);		%* First variable to look for in the dataset;
				%let var2 = %substr(%quote(&vari), &hyphen2+2);			%* Second variable to look for in the dataset;

				%let vari = ;
				%let firstFound = 0;	%* States whether the first variable in the double hyphen string was found in the dataset;
				%let lastFound = 0;
				%let j = 1;
				%do %while (&j <= &nvars and not &lastFound);
					%** lastFound states if the second variable in the double hyphen string was found in the dataset
					%** Use WHILE instead of UNTIL because the number of variables in the dataset could be 0
					%** in which case a WHILE prevents entering the cycle and trying to read any variable from the dataset;
					%let varname = %sysfunc(varname(&dsid, &j));
					%if %quote(%upcase(&varname)) = %quote(%upcase(&var1)) or &firstFound %then %do;
						%let firstFound = 1;
						%let vari = &vari &varname;
					%end;
					%if %quote(%upcase(&varname)) = %quote(%upcase(&var2)) %then
						%let lastFound = 1;

					%let j = %eval(&j + 1);
				%end;
				%if &log %then %do;
					%if not &firstFound and not &lastFound %then %do;
						%put GETVARLIST: WARNING - No variables in %upcase(&data) match the double hyphen string %upcase(&var1--&var2).;
					%end;
					%else %if &lastFound and not &firstFound %then %do;
						%put GETVARLIST: WARNING - The ending variable %upcase(&var2) of the double-dash list was found before the starting variable %upcase(&var1).;
						%put GETVARLIST: The string will be ignored.;
					%end;
				%end;
			%end;
			/*----- Double hyphen as in id--name -----*/
			%else %do;
				/*----- Single hyphen as in x1-x3 -----*/
				%* Look for a hyphen in current variable i;
				%let hyphen = %index(&vari, -);
				%* Parse hyphen string, if a hyphen was found;
				%if &hyphen > 0 %then %do;
					%* start = number corresponding to the first variable index referred to by the
					%* hyphen string. It is initialized into an empty string because this number
					%* is constructed in the parsing process;
					%let start = ;
					%* Name of the variable referred to in the hyphen string. It is initialized
					%* to an empty string because the name is constructed in the parsing process;
					%let name = ;
					%* Indicator of whether a character was found while parsing each character from the
					%* hyphen position to the front of &vari;
					%let charFound = 0;
					%* Index used to sweep the hyphen string;
					%let j = &hyphen;
					%do %while(&j > 1);
						%let j = %eval(&j - 1);
						%* Read character at current cursor position (j-th position);
						%let character = %substr(%quote(&vari), &j, 1);
						%if ~&charFound %then
							%if ~%IsNumber(&character) %then
								%let charFound = 1;
							%else
								%let start = &character&start;	%* Construct the starting number;
						%if &charFound %then
							%let name = &character&name;
					%end;
					%* Read the second name in the hyphen string to check if it is the same as the first
					%* name found;
					%let name2 = %substr(%quote(&vari), &hyphen+1, %length(&name));
					%if %quote(%upcase(&name2)) ~= %quote(%upcase(&name)) %then %do;
						%if &log %then %do;
							%put GETVARLIST: WARNING - The names in the hyphen string &vari do not coincide.;
							%put GETVARLIST: The string will be ignored.;
						%end;
						%let vari = ;
					%end;
					%else %do;
						%* Read the ending number;
						%let stop = %substr(%quote(&vari), &hyphen+1 + %length(&name));
						%if ~%IsNumber(&stop) %then %do;
							%if &log %then %do;
								%put GETVARLIST: WARNING - The ending index in the hyphen string &vari;
								%put GETVARLIST: is not a number.;
								%put GETVARLIST: The string will be ignored.;
							%end;
							%let vari = ;
						%end;
						%else %if %sysevalf(&stop < &start) %then %do;
							%if &log %then %do;
								%put GETVARLIST: WARNING - The ending index in the hyphen string &vari;
								%put GETVARLIST: is smaller than the starting index.;
								%put GETVARLIST: The string will be ignored.;
							%end;
							%let vari = ;
						%end;
						%if %quote(&vari) ~= %then %do;	%* If no error was found;
							%let vari = %MakeListFromName(&name, start=&start, stop=&stop, step=1);
						%end;
					%end;
				%end;
				/*----- Single hyphen as in x1-x3 -----*/
				%else %do;
					/*----- Colon as in id: -----*/
					%* Look for a colon in current variable i;
					%let colon = %index(%quote(&vari), :);
					%* Parse colon if a colon was found;
					%if &colon > 0 %then %do;
						%let name = %substr(%quote(&vari), 1, &colon-1);
						%let namelen = %length(&name);
						%let vari = ;
						%do j = 1 %to &nvars;
							%let varname = %sysfunc(varname(&dsid, &j));
							%if %length(&varname) >= &namelen %then %do;
								%if %quote(%substr(%quote(%upcase(&varname)), 1, &namelen)) = %quote(%upcase(&name)) %then
									%let vari = &vari &varname;
							%end;
						%end;
					%end;
					%if &log and %quote(&vari) = %then %do;	%* No variable was found starting with &name;
						%put GETVARLIST: WARNING - No variables in %upcase(&data) were found starting with %upcase(&name).;
					%end;
					/*----- Colon as in id: -----*/
				%end;
			%end;

			%* Update list of variables;
			%let varlist = &varlist &vari;
		%end; %* while;
	%end;

	%* Close input dataset;
	%let rc = %sysfunc(close(&dsid));

	%* Check for existence of the variables in the list created if CHECK=1;
	%* WARNING: (2016/04/20) This process may considerably slow down execution for large datasets (e.g. 1 minute instead of 1 second for 3 million records);
	%if &check and %quote(&varlist) ~= %then %do;
		%* Remove repeated variables in the variable list just created;
		%* DM-2016/06/20: Commented out the call to %RemoveRepeated because it takes TOO LONG when the number of variables is 
		%* large (~ 500 or more);
		%*%let varlist = %RemoveRepeated(&varlist, log=0);

		%* Check if all variables in &varlist exist, o.w. give an error;
		%if ~%ExistVar(&data_name, %quote(&varlist), macrovar=_NotFound_, log=0) %then %do;
			%if &log %then %do;
				%put GETVARLIST: WARNING - Not all the variables passed in VAR= where found in input dataset %upcase(&data_name).;
				%put GETVARLIST: The following variables were not found:;
				%put GETVARLIST: &_NotFound_;
				%put GETVARLIST: Only the variables found are returned.;
			%end;
			%* Remove variables not found from the variable list;
			%let varlist = %RemoveFromList(&varlist, &_NotFound_, log=0);
		%end;
		%symdel _NotFound_;
		%* DO NOT use quit in this case because otherwise an error is reported;
	%end;
%end;
%end;	%* if %index...;
&varlist
%MEND GetVarList;
