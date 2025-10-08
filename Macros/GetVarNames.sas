/* MACRO %GetVarNames
Version: 1.01
Author: Daniel Mastropietro
Created: 15-Jul-03
Modified: 23-Sep-03

DESCRIPTION:
Devuelve en una macro variable la lista de variables de un cierto
tipo (numéricas, caracter o todas) presentes en un dataset.

USAGE:
%GetVarNames(data , var=_ALL_);

REQUIRED PARAMETERS:
- data:			Dataset de interés.
				Puede recibir cualquier opción adicional como en cualquier
				opción data= de SAS. Sin embargo, las opciones keep= y drop=
				son ignoradas al obtener la lista de variables del dataset.

OPTIONAL PARAMETERS:
- var:			Tipo de variables que se quiere leer.
				Valores posibles son: _ALL_, _NUMERIC_, _CHAR_,
				para indicar respectivamente todas las variables, sólo las
				variables  numéricas, o sólo las variables caracter.
				No es case sensitive.

RETURNED VALUES:
Lista separadas por blancos con los nombres de las variables presentes en el
dataset 'data'. 

OTHER MACROS AND MODULES USED IN THIS MACRO:
None

SEE ALSO:
- %GetVarList

APPLICATIONS:
- Puede ser de utilidad usar esta macro cuando es de interés conocer las
variables que originalmente están presentes en un dataset A.
Por ejemplo, si en el transcurso de un proceso, más variables son agregadas
al dataset A y luego se desea recuperar sus variables originales, bastaría
con tener la lista de variables presentes en A antes de comenzar el proceso,
y luego usar el comando u opción KEEP con dicha lista de variables.

Para ejemplificar, considerése el siguiente caso.
Se tiene el dataset A con las variables x1 x2 z1 z2,

*** En una macro variable se guarda la lista de variables presentes en A;
%let var_orig = %GetVarNames(A);
%put &var_orig;		*** &var_orig vale 'x1 x2 z1 z2';

<... procesos que agregan nuevas variables al dataset A ...>

*** Recuperacion de las variables originalmente presentes en A;
data A;
	set A(keep=&var_orig);
run;
*/
%MACRO GetVarNames(data , var=_ALL_);
%local data_name dsid i nvars rc varnames vartype;

%let data_name = %scan(&data , 1 , '(');

%let dsid = %sysfunc(open(&data_name));				%*** Open dataset &data;
%if ~&dsid %then
   	%put GETVARNAMES: %sysfunc(sysmsg());
%else %do;
 	%let nvars = %sysfunc(attrn(&dsid,NVARS));
	%let varnames = ;
	%do i = 1 %to &nvars;
		%let vartype = %sysfunc(vartype(&dsid , &i));	%*** Type of variable in column &i. Either C or N;
		%if (%upcase(&vartype) = C and %quote(%upcase(&var)) = _CHAR_) or
			(%upcase(&vartype) = N and %quote(%upcase(&var)) = _NUMERIC_) or
			(%quote(%upcase(&var)) = _ALL_) %then
			%let varnames = &varnames %sysfunc(varname(&dsid , &i));
	%end;
	%let rc = %sysfunc(close(&dsid));
%end;
&varnames
%MEND GetVarNames;
