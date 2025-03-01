%macro get_vars_max_length(
dsdin=,
vars=,
macrotag4varslen=_max_var,
/*global macro variables containing the length for each variable will be created by adding numeric orders in according to the order of input variables*/
rm_leading_spaces=1,/*Not count the leading spaces in each var*/
dsdout=_tmp_  /*Output a dsd containing the max length for all input vars*/
);

%local nvars v0 vi;

%do v0=1 %to %ntokens(&vars);
   %global %str(&macrotag4varslen)%str(&v0);
%end;


%let nvars=%ntokens(&vars);;
data &dsdout;
retain 
%do v0=1 %to %ntokens(&vars);
   %scan(&vars,&v0,%str( ))_len 0
%end;
;
keep 
%do v0=1 %to %ntokens(&vars);
   %scan(&vars,&v0,%str( ))_len
%end;
;
set &dsdin end=eof;
%do vi=1 %to %ntokens(&vars);
 %if &rm_leading_spaces=1 %then %do;
 *Note: trim and left is used to remove leading spaces, thus the final length for each var will not include the leading spaces;
  if length(%scan(&vars,&vi,%str( ))) > %scan(&vars,&vi,%str( ))_len then %scan(&vars,&vi,%str( ))_len=length(trim(left(%scan(&vars,&vi,%str( )))));
 %end;
 %else %do;
  if length(%scan(&vars,&vi,%str( ))) > %scan(&vars,&vi,%str( ))_len then %scan(&vars,&vi,%str( ))_len=length(%scan(&vars,&vi,%str( )));
 %end;
  if eof then call symputx("&macrotag4varslen&vi",%scan(&vars,&vi,%str( ))_len);
%end;
if eof then output;
run;

%do v0=1 %to %ntokens(&vars);
   %put Max length for the variable "%scan(&vars,&v0,%str( ))" is &&&macrotag4varslen&v0;
%end;

%mend;
/*Demo codes:;

%get_vars_max_length(
dsdin=final,
vars=Filename rsid_gene,
macrotag4varslen=xxx,
dsdout=
);
%put The max length for the first variable is &xxx1;
%put The max length for the last variable is &xxx2;

*/ 
