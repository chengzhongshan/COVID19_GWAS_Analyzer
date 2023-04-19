%macro dsd2matrix(dsd,row_var,col_var,data_var,matrix_out);
/*make sure to sort it*/
proc sort data=&dsd;
by &row_var &col_var &data_var;
run;
proc transpose data=&dsd out=&matrix_out(drop=_name_);
var &data_var;
by &row_var notsorted;
id &col_var;
run;

%mend;
/*%dsd2matrix(dsd=All_drivers_matched_sum,*/
/*            row_var=Chip_ID,*/
/*			col_var=cancer,*/
/*			data_var=total,*/
/*			matrix_out=x*/
/**/
/*);*/
