%macro filter_longform_dsd4matrix(
 dsdin=,
 var4matrix_row=, /*target variable that will be put into row-wide for a matrix*/
 var4matrix_col=, /*target variable that will be put into column-wide for a matrix*/
 value_var4matrix=,	/*Numeric value variable for filtering*/
 value_cutoff_fun=min,/*SQL group functions, such as min, max, median*/
 value_cutoff=0.05,	/*numeric value for filtering input dsd*/
 cutoff_condition= <, /* values > value_cutoff or < value_cutoff will be kept*/
 dsdout=out
);

proc sql;

create table &dsdout as
select a.* from &dsdin as a
group by &var4matrix_col
having &value_cutoff_fun(&value_var4matrix) &cutoff_condition &value_cutoff;

create table &dsdout as 
select a.* from &dsdout as a
group by &var4matrix_row
having &value_cutoff_fun(&value_var4matrix) &cutoff_condition &value_cutoff;

%mend;

/*Demo codes:;
*This macro can be used to filter rows in a longform dataset based on two variables;
*Then the longform dataset can be later transformed into a wideform dataset;

%debug_macro;

%filter_longform_dsd4matrix(
 dsdin=tops1,
 var4matrix_row=gene, 
 var4matrix_col=tissue, 
 value_var4matrix=pvalue,
 value_cutoff_fun=min,
 value_cutoff=0.05,
 cutoff_condition= <, 
 dsdout=out
);


*/

