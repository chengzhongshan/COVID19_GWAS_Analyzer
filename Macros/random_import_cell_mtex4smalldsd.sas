%macro random_import_cell_mtex4smalldsd(
/*Funcational annotation: this macro is suitable for columns no more than 1 million, otherwise, it will be very slow, too*/
gzfile=,/*the fullpath to compressed or plain file, such as gz, txt, zip, and others.*/
max_colnum=1000000,/*If the max number of cells to read from each line >10000, it will take too much time*/
totrandom_cols=100000,
random_seed=2718,
outdsd=subset_cell_exp,
rowname_len=100, /*The length of the 1st rowname length*/
V_max_len=8, /*The length for all numeric cell expression value*/
deletefile=0, /*Delete input gzfile*/
extra_cmd4infile= /*extra filters for infile*/
);

*Randomly select columns and output dataset in wide format;
data _null_;
*Need to specify the number of elements for temporary array;
 array H{&max_colnum} _temporary_ (1:&max_colnum);
 *Set a array with subset number of the above array;
 *Use this array to select elements from permutated arrah H;
/* array S{&totrandom_cols} _temporary_ (1:&totrandom_cols);*/
*Create an array to contain these excluded columns;
*it will be used to filter columns as the number of excluded columns are much less;
%if %eval(&max_colnum-&totrandom_cols)>0 %then %do;
array E{%eval(&max_colnum-&totrandom_cols)} _temporary_ (1:%eval(&max_colnum-&totrandom_cols));
%end;
if _n_=1 then do;
 _iorc_=&random_seed;/*random seed*/
   call ranperm(_iorc_,of H{*});
/*  do _si_=1 to &totrandom_cols;*/
/*    S{_si_}=H{_si_};*/
/*    *Create global macro vars for rename column names later;*/
/*    call symputx('Cell_V'||left(put(_si_,8.)),H{_si_},'G');*/
/*  end;*/
%if %eval(&max_colnum-&totrandom_cols)>0 %then %do;
 do _ei_= 1 to %eval(&max_colnum-&totrandom_cols);
    E{_ei_}=H{_ei_+&totrandom_cols};
    call symputx('var2drop'||left(put(_ei_,8.)),'V'||left(put(E{_ei_},8.)),'G');
 end;
%end;
end;
run;

*Randomly select columns and output dataset in wide format;
%ImportFileHeadersFromZIP(
zip=&gzfile,
filename_rgx=.,
obs=max,
sasdsdout=&outdsd,
deleteZIP=&deletefile,
infile_command=%bquote(
delimiter='09'x firstobs=2 obs=max truncover lrecl=100000000;
length V1-V&max_colnum &V_max_len.;
input rownames :$&rowname_len.. V1-V&max_colnum;
&extra_cmd4infile;
),
global_var_prefix4vars2drop=var2drop,/*To handle the issue of trunction of macro var infile_command if there are too many variables to be dropped in the infile procedure;
it is feasible to create global macro variables with the same prefix, such as drop_var, to exclude them*/
num_vars2drop=%eval(&max_colnum-&totrandom_cols) /*Provide postive number to work with the macro var global_var_prefix4vars2drop to resolve these variables to be excluded*/
);
*Note: in the above code, the value of ai need to be restrict using retain function;
*Need to put these column number into macro variables and rename the column names later;
*Alternatively, use file statement to output the columns into a file and read the file into sas again for renaming column names of the exp dataset;
*the best way is to create global macro variable names for these columns and use the macro rename_cols_with_macro_vars to rename columns;
/*%rename_cols_with_macro_vars(totcols=&totrandom_cols,dsd=&outdsd,colvar_prefix=V,macro_var_prefix=Cell_V);*/

%mend;

/*Demo codes:;
*If the total number of columns exceed 1 million in the original matrix file,;
*the macro will take too much time to output data for randomly selected cells;
*the optimized number of columns would be 100k for the input matrix file!;

x cd "E:\LongCOVID_HGI_GWAS\SASR_Airway_Infection_SC";
%let file=E:\sas_testing\exprMatrix.tsv\exprMatrix.tsv;
%random_import_cell_mtex4smalldsd(
gzfile=&file,
max_colnum=1000000,
totrandom_cols=100000,
random_seed=2718,
outdsd=subset_cell_exp,
extra_cmd4infile=%bquote(if mean(of V:)>0.01)
);
proc print data=subset_cell_exp(obs=10);
run;

*The above macro is included in the macro ucsc_cell_matrix2wideformatdsd:

%ucsc_cell_matrix2wideformatdsd(
gzfile_or_url=&file,
dsdout4headers=headers,
dsdout4data=exp,
extra_cmd4infile=
);

*/
