%macro Scaleup_nrow_ncol(dsdin,row_var4row,row_var4col,value_var,dsdout);
%if "&value_var"="" %then %do;
 %let value_var=*;
%end;

data tmp;
set &dsdin;
proc sort data=tmp nodupkeys;
by &row_var4row &row_var4col;
run;

/*Important to get unique values for row and col individually*/
proc sql;
create table tmprow as
select unique(&row_var4row)
from tmp;
create table tmpcol as 
select unique(&row_var4col)
from tmp;
create table rowcolcombio as
select a.&row_var4row,
       b.&row_var4col
from tmprow as a,
     tmpcol as b;

create table &dsdout as
select a.*,b.&value_var
from rowcolcombio as a
left join 
tmp as b
on a.&row_var4row=b.&row_var4row and
   a.&row_var4col=b.&row_var4col;
quit;

%mend;

/*Demo: 

*scale up the longformat data by adding all combination of row_var and col_var;
*The row_var and col_var is exchangable!;

%Scaleup_nrow_ncol(dsdin=forheatmap,row_var4row=gwas,row_var4col=gene_name,value_var=logP,dsdout=newdata);

*If value_var is empty, this macro will keep all vars from dsdin in the final out dsd;
%Scaleup_nrow_ncol(dsdin=forheatmap,row_var4row=gwas,row_var4col=gene_name,value_var=,dsdout=newdata);


*/


