/* MACRO %GetVarLabel --> Calls %GetVarAttrib with specific parameter values
Version: 		1.00
Author: 		Daniel Mastropietro
Created: 		04-Sep-2015
Modified: 		04-Sep-2015

DESCRIPTION:
Returns the label of a given variable in a dataset.
For more information see the macro %GetVarAttrib.

USAGE:
%GetVarLabel(data, var);

RETURNED VALUES:
The unquoted label of the variable.

EXAMPLES:
%let xlabel = %GetVarLabel(test, x);
Macro variable 'xlabel' will contain the unquoted label of variable x in dataset test.

NOTES:
This macro calls %GetVarAttrib with the third parameter FUN=varlabel.
See that macro for more information.
*/
%MACRO GetVarLabel(data, var);
%local varlabel;
%let varlabel = %GetVarAttrib(&data, &var, varlabel);
&varlabel
%MEND GetVarLabel;
