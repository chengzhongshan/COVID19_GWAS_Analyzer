%macro SQ_DROPMISS( DSNIN /* name of input SAS dataset */
, DSNOUT      /* name of output SAS dataset                       */
, NOCOMPRESS= /* [optional] variables to be omitted from the minimum-length computation process           */
, NODROP= /* [optional] variables to be omitted from droping even if they have only missing values */

);
/* PURPOSE: Squeeze a data set to have minimum lengths required for the
*  variables excluding the variables in &NOCOMPRESS applying %SQUEEZE_1 and
*  then DROP the variables  that have always missing values in a more
*  efficient way.
*
* EXAMPLE OF USE:
*   %SQ_DROPMISS( DSNIN, DSNOUT, NOCOMPRESS= )
*   %SQ_DROPMISS( DSNIN, DSNOUT, NOCOMPRESS=A B C D--H X1-X100 )
*   %SQ_DROPMISS( DSNIN, DSNOUT, NOCOMPRESS=_numeric_ )
*   %SQ_DROPMISS DSNIN, DSNOUT, NOCOMPRESS=_character_
*   %SQ_DROPMISS DSNIN, DSNOUT, NOCOMPRESS=_character_, NONDROP= A C D)
*/
/*###############################################################################*/
 /* begin executable code
 /*###############################################################################*/
 /*===============================================================================*/
 /* Squeezing part
 /*===============================================================================*/
 /*===============================================================================*/
  /* Include the code for the macro %SQUEEZE_1 here           */
 /*===============================================================================*/
  %SQUEEZE_1 (&DSNIN, DSNSQUEEZED, &NOCOMPRESS);

 /* Dropping part
 /*===============================================================================*/
 %global DROP1 ;
 %local I ;
 %if "&DSNIN" = "&DSNOUT" %then %do ;
%put /------------------------------------------------\ ;
%put | ERROR from DROPMISS:                            | ;
%put | Input Dataset has same name as Output Dataset. | ;
%put | Execution terminating forthwith.               | ;
%put \------------------------------------------------/ ;
%goto L9999 ;
%end ;
/*===============================================================================*/
/* create dataset of variable names that have only missing values
/* exclude from the computation all names in &NODROP
/*===============================================================================*/
proc contents data=DSNSQUEEZED( drop=&NODROP ) memtype=data noprint out=
_cntnts_( keep= name type length) ; run ;

%let N_CHAR = 0 ;
%let N_NUM  = 0 ;
data _null_ ;
 set _cntnts_ end=lastobs nobs=nobs ;
  where (type =1 and length =3) or (type=2 and length =1);
 if nobs = 0 then stop ;
 n_char + ( type = 2 ) ; n_num +(type=1);
/* create macro vars containing final # of char, numeric variables */
if lastobs then do ;
 call symput( 'N_CHAR', left( put( n_char, 5. ))) ; 
 call symput( 'N_NUM' , left( put( n_num , 5. ))) ;
end ;
run ;

/*===============================================================================*/
/* if there are NO numeric or character vars in dataset, stop further */
/*===============================================================================*/
%if %eval( &N_NUM + &N_CHAR ) = 0 %then %do ;
%put /----------------------------------\ ;
%put | ERROR from DROP1:              | ;
%put | No variables in dataset to drop.         | ;
%put | Execution terminating forthwith. | ;
%put \----------------------------------/ ;
%goto L9999 ;
%end ;
/*===============================================================================*/
/* put global macro names into global symbol table for later retrieval   */
/*===============================================================================*/
%do I = 1 %to &N_NUM ;
 %global NUM&I  ;
%end ;
%do I = 1 %to &N_CHAR ;
 %global CHAR&I  ;
%end ;
/*===============================================================================*/
/* create macro vars containing variable names
/* efficiency note: could compute n_char, n_num here, but must declare macro
/* names to be global b4 stuffing them
/* note: if no char vars in data, do not create macro vars
/*===============================================================================*/
proc sql noprint ;
%if &N_CHAR > 0 %then %str( select name into :CHAR1 - :CHAR&N_CHAR from
_cntnts_ where type = 2 ; ) ;
%if &N_NUM > 0 %then %str( select name into :NUM1 - :NUM&N_NUM from
_cntnts_ where type = 1 ; ) ;
quit ;
/*===============================================================================*/
/* put MAXIMUM values of the variables into macro variables
/*===============================================================================*/
%IF &N_CHAR > 1 %THEN
%let N_CHAR_1 = %EVAL(&N_CHAR - 1);
%IF &N_NUM > 1 %THEN
%let N_NUM_1 = %EVAL(&N_NUM - 1);

proc sql;
 select
  %IF &N_NUM >1 %THEN %DO;
   %do I= 1 %to &N_NUM_1; max (&&NUM&I),
   %END;
 %END;
 
%IF &N_NUM > 0 %THEN %DO;
  MAX(&&NUM&N_NUM)
%END;
%IF &N_CHAR >0 AND &N_NUM >0 %THEN %DO; 
  ,
%END;
%IF &N_CHAR > 1 %THEN %DO;
  %do I= 1 %to &N_CHAR_1; 
    max(&&CHAR&I),
  %END;
%END;
%IF &N_CHAR >0 %THEN %DO;
   MAX(&&CHAR&N_CHAR)
%END; 
   into 
%IF &N_NUM > 1 %THEN %DO; 
  %do I= 1 %to &N_NUM_1; 
    :NUMMAX&I,
  %END;
%END;
%IF &N_NUM > 0 %THEN %DO;
    :NUMMAX&N_NUM
%END;
%IF &N_CHAR> 0 AND &N_NUM >0 %THEN %DO; 
    ,
%END;
%IF &N_CHAR > 1 %THEN %DO;
   %do I= 1 %to &N_CHAR_1; 
     :CHARMAX&I,
   %END;
%END;
%IF &N_CHAR > 0 %THEN %DO;
    :CHARMAX&N_CHAR
%END;
from &DSNIN;
quit;

/*===============================================================================*/
 /* initialize DROP_NUM, DROP_CHAR global macro vars
 /*===============================================================================*/
 %let DROP_NUM      =  ;
 %let DROP_CHAR     =  ;
%if &N_CHAR > 0 %THEN %DO; 
 %do I = 1 %to &N_CHAR ;
  %IF &&CHARMAX&I =   %THEN %DO;
    %let DROP_CHAR     = &DROP_CHAR %qtrim( &&CHAR&I )  ;
  %END;
 %END;
%END;

%if &N_NUM > 0 %THEN %DO;
 %do I = 1 %to &N_NUM ;
  %IF &&NUMMAX&I = . %THEN %DO;
   %let DROP_NUM = &DROP_NUM %qtrim( &&NUM&I ) ;
  %END;
 %END;
%END;
 /*===============================================================================*/
 /* apply Drop_* to incoming data, create output dataset    */
 /*===============================================================================*/
 data &DSNOUT ;
 %if &DROP_CHAR ^= %then %str( DROP &DROP_CHAR ; ) ; /* drop char variables that have only missing values  */
   %if &DROP_NUM ^=  %then %str( DROP &DROP_NUM ;) ; /* drop num variables that have only missing values */
 set DSNSQUEEZED ;
 run ;

 %L9999:
%mend;

/*Demo codes:
%importallmacros;
data a;
set sashelp.cars;
run;
options mprint mlogic symbolgen;
%SQ_DROPMISS(
dsnin=a,
dsnout=b
);

*/

  
