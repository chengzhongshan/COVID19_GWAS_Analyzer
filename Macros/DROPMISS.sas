%macro DROPMISS( DSNIN /* name of input SAS dataset */
, DSNOUT   /* name of output SAS dataset                       */
, NODROP= /* [optional] variables to be omitted from dropping
even if they have only missing values                    */
);

*Read the original paper for detail;
*https://www.lexjansen.com/nesug/nesug06/io/io18.pdf;

/* PURPOSE: To find both Character and Numeric the variables that have only
*  missing values and drop them if they are not in &NONDROP
* EXAMPLE OF USE:
 *          %DROP1( DSNIN, DSNOUT )
 *          %DROP1( DSNIN, DSNOUT, NODROP=A B C D--H X1-X100 )
 *          %DROP1( DSNIN, DSNOUT, NODROP=_numeric_          )
 *          %DROP1( DSNIN, DSNOUT, NOdrop=_character_        )
 */
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
 /*###############################################################################*/
 /* begin executable code*/
 /*###############################################################################*/
 /*===============================================================================*/
/* create dataset of variable names that have only missing values*/
/* exclude from the computation all names in &NODROP*/
/*===============================================================================*/
proc contents data=&DSNIN( drop=&NODROP ) memtype=data noprint out=_cntnts_( keep= name type ) ; run ;
%let N_CHAR = 0 ;
%let N_NUM =0;
data _null_ ;
set _cntnts_ end=lastobs nobs=nobs ;
 
if nobs = 0 then stop ;
/* create macro vars containing final # of char, numeric variables */
n_char + ( type = 2 ) ; n_num +(type=1);
if lastobs then do ;
end ;
call symput( 'N_CHAR', left( put( n_char, 5. ))) ; call symput( 'N_NUM' , left( put( n_num , 5. ))) ;
run ;
 /*===============================================================================*/
 /* if there are NO numeric or character vars in dataset, stop further */
 /*===============================================================================*/
  %if %eval( &N_NUM + &N_CHAR ) = 0 %then %do ;
%put /----------------------------------\ ;
 %put | ERROR from DROP1:              | ;
 %put | No variables in dataset.         | ;
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
 Proc sql ;
 select 
 %IF &N_NUM >1 %THEN %DO;
  %do I= 1 %to &N_NUM_1; 
   max(&&NUM&I),
  %END;
%END;
%IF &N_NUM > 0 %THEN %DO;
  MAX(&&NUM&N_NUM)
%END;
%IF &N_CHAR >0 AND &N_NUM>0 %THEN %DO; 
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
 %END ;
%END;

%if &N_NUM > 0 %THEN %DO; 
  %do I = 1 %to &N_NUM ;
  %IF &&NUMMAX&I = . %THEN %DO;
    %let DROP_NUM = &DROP_NUM %qtrim( &&NUM&I ) ;
  %END;
 %END ;
%END;
/*===============================================================================*/
/* apply SQZ_* to incoming data, create output dataset    */
/*===============================================================================*/
data &DSNOUT ;
%if &DROP_CHAR ^= %then %str( DROP &DROP_CHAR ; ) ; /* drop char variables that have only missing values  */
%if &DROP_NUM ^=  %then %str( DROP &DROP_NUM ;  ) ; /* drop num variables that have only missing values */
set &DSNIN ;
run ;
%L9999:
%mend DROPMISS ;


/*Demo code:

%importallmacros;
data a;
set sashelp.cars;
run;
options mprint mlogic symbolgen;
%dropmiss(dsnin=a,
dsnout=b);

*/

