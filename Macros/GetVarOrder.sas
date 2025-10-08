/* MACRO %GetVarOrder
Version: 1.01
Author: Daniel Mastropietro
Created: 10-Mar-01
Modified: 15-Jan-03

DESCRIPTION:
This macro returns the order in which the variables appear in a dataset.

USAGE:
%GetVarOrder(data , _order_);

REQUESTED PARAMETERS:
- _data_:		Input dataset. It can contain additional options as in any
				data= option in SAS (such as keep=, where=, etc.).

- _order_:		Name of the macro variable to store the order of the
				variables in '_data_'. It can be any name, EXCEPT
				_order_, _i_, _nro_vars_, __order__.
				IMPORTANT: This variable needs to exist prior to
				calling the macro. This can be done with a %let
				statement before calling the macro, such as:
				'%let order=;'.

NOTES:
1.- The macro variable whose name is specified in parameter '_order_'
must exist prior to calling the macro. This can be done with a %let statement
before calling the macro, such as: '%let varlist=;'. See examples below.

2.- Do not use '_list_' as the name for the macro variable to store the list.
This will cause an error in the program.

3.- This macro is much faster than running %GetVarList with no keywords to
search for.

OTHER MACROS USED IN THIS MACRO:
- %SetSASOptions
- %ResetSASOptions

SEE ALSO:
- %GetVarNames
- %GetVarList (to search variables with SAS keywords, but it is slower than
this macro to simply retrieve the list of all variables in the dataset)

EXAMPLES:
Assuming the dataset A has the variables x1, x2, x3 and they are stored in the
second, first and third column of the dataset, then if we do:
%let varOrder =;
%GetVarOrder(data , varOrder);
we will get a macro variable named 'varOrder' whose value is:
x2 x1 x3.
*/
%MACRO GetVarOrder(_data_ , _order_); 
%local _i_ _nro_vars_ __order__;
%SetSASOptions;
proc contents data=&_data_ out=_GetVarOrder_pc_(keep=name varnum) noprint;
run;
proc sort data=_GetVarOrder_pc_;
by varnum;			%*** varnum da la posicion (columna) de la variable en el dataset;
run;
data _NULL_;
	set _GetVarOrder_pc_ end=lastobs;
	call symput('__order__' || trim(left(_N_)) , name);
	if lastobs then
		call symput('_nro_vars_' , _N_);
run;
%do _i_ = 1 %to &_nro_vars_;
	%let __order__ = &__order__ &&__order__&_i_;
%end;
%let &_order_ = &__order__;

proc datasets nolist;
	delete _GetVarOrder_pc_;
quit;
%ResetSASOptions;
%MEND GetVarOrder;
