
/* VMACRO is a SASHELP view that contains information about currently */
/* defined macros.  Create a data set from SASHELP.VMACRO to avoid a  */
/* macro symbol table lock.                                           */

%macro delvars;
  data vars;
    set sashelp.vmacro;
  run;

  data _null_;
    set vars;
    temp=lag(name);
    if scope='GLOBAL' and substr(name,1,3) ne 'SYS' and temp ne name then
      call execute('%symdel '||trim(left(name))||';');
  run;

%mend;

*%delvars;

/* Write macro variable values to the log to show they no longer have values. */

/* Change for EG 4.3 users if wanting to preserve the SASWORKLOCATION macro variable */
/* if scope='GLOBAL' and substr(name,1,3) ne 'SYS' and temp ne name and upcase(name) 
   ne SASWORKLOCATION then call execute('%symdel '||trim(left(name))||';');          */