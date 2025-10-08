/* MACRO %GetVarType --> Calls %GetVarAttrib with specific parameter values
Version: 		1.03
Author: 		Daniel Mastropietro
Created: 		18-Nov-2004
Modified: 		24-May-2015 (added vartype as LOCAL variable!, previous: 07-Jun-2012)

DESCRIPTION:
Returns the type (character or numeric) of a given variable in a dataset.
For more information see the macro %GetVarAttrib.

USAGE:
%GetVarType(data, var);

RETURNED VALUES:
The returned value is either C or N, depending on whether variable 'var' in dataset 'data'
is of type Character or Numeric, respectively.

EXAMPLES:
%let xtype = %GetVarType(test, x);
Macro variable 'xtype' will have value C if x is character and N if variable x is numeric.

NOTES:
This macro calls %GetVarAttrib with the third parameter FUN=vartype.
See that macro for more information.
*/
%MACRO GetVarType(data, var);
%local vartype;
%let vartype = %GetVarAttrib(&data, &var, vartype);
&vartype
%MEND GetVarType;
