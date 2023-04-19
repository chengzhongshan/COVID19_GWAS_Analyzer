%macro curdir;
/*----------------------------------------------------------------------
Returns the current SAS directory physical name.
----------------------------------------------------------------------*/
/*----------------------------------------------------------------------
Originally developed by Tom Hoffman.
Posted in memory of Tom and Fan.
-----------------------------------------------------------------------
Usage:

%put %curdir is the current directory.;
------------------------------------------------------------------------
Notes:

-----------------------------------------------------------------------
History:

11MAR99 TRHoffman Creation - with help from Tom Abernathy.
06DEC00 TRHoffman Used . notation to refernece current directory as
                  suggested by Fan Zhou.
----------------------------------------------------------------------*/
%local fr rc curdir;

%let rc = %sysfunc(filename(fr,.));
%let curdir = %sysfunc(pathname(&fr));
%let rc = %sysfunc(filename(fr));

&curdir

%mend;

/*Use it in macro:

%let curdir=%curdir;

*CAN NOT use in data step with dosubl;
data x;
path=dosubl('%curdir');
run;

*/

