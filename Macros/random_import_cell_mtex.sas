%macro random_import_cell_mtex(
/*Funcational annotation: this macro is suitable for columns more than 1 million, which is relative faster than other similar macros;
For subsetting smaller % of columns, the macro seems to be not better than the macro random_import_cell_mtex4smalldsd!*/
gzfile=,/*the fullpath to compressed or plain file, such as gz, txt, zip, and others.*/
max_colnum= ,/*Default is empty for using the total number of numeric columns in the file;
provide a smaller number than the total number of numberic columns to only import first number of numeric columns;*/
totrandom_cols=100000,
random_seed=2718,
outdsd=subset_cell_exp,
rowname_len=100, /*The length of the 1st rowname length*/
V_max_len=8, /*The length for all numeric cell expression value*/
deletefile=0, /*Delete input gzfile*/
extra_cmd4infile= /*extra filters for infile*/
);

*Try to generate dummay vars to exclude non-selected variable;
*Initially, this failed as the length of string for a macro var is too long;
*After update the macro ImportFileHeadersFromZip to accept multiple macro;
*variables that include these variables, the issue is resolved!;
%ImportFileHeadersFromZIP(
zip=&gzfile,
filename_rgx=.,
obs=max,
sasdsdout=dsdout4headers,
deleteZIP=0,
infile_command=%str(
delimiter='09'x firstobs=1 obs=1 truncover lrecl=1000000000;
input gene :$&rowname_len.. @@;
do i=1 to 1000000000;
 input colnames :$&rowname_len.. @;
 if colnames^="" then do;
  output;
 end;
 else do;

  stop;
 end;
end;
drop gene;
)
);

*output select columns and generate sas codes that will be stored into multiple macro variables;
%let ncells=%totobsindsd(work.dsdout4headers);
%if %length(&max_colnum)=0 %then %let max_colnum=&ncells;
%if &max_colnum>&ncells %then %do;
  %put You input max number of columns are &max_colnum, which is larger than the total numeric columns (n=&ncells);
  %put The macro var max_colnum will be asigned with the value of total number of cells, which is &ncells;
  %let max_colnum=&ncells;
%end;

*In case the value of macro var max_column is less than the total number of numeric columns;
data dsdout4headers;
set dsdout4headers;
if _n_<=&max_colnum;
run;

/*%let subtot=%sysevalf(0.3*&ncells,ceil);*/
%let subtot=&totrandom_cols;
%Sampling(indsd=dsdout4headers,n=&subtot,nperm=1,dsdout=sampled_cells,seed_value=&random_seed);
data sampled_cells;
set sampled_cells(drop=gp_perm);
_i_=_n_;
run;

proc sql;
create table dsdout4headers as
select a.*,cat('V',left(put(a.i,8.))) as var_name,
           b.i as selected
from dsdout4headers as a
left join
sampled_cells as b
on a.i=b.i;

data dsdout4headers;
length code4input $400.;
set dsdout4headers end=eof;
code4input="input "||trim(left(var_name))||' @;';
if selected=. then code4input='input (1*d)(:3.) @;';
*Need to  put these extra command at the end of these put statments;
if eof then do;
 code4input=trim(left(code4input))||"&extra_cmd4infile;";
end;
run;

*Create macro vars for these extra commands;
proc sql noprint;
select code4input into: _vname_1 -: _vname_&max_colnum
from dsdout4headers;
%put The last input command for the macro ImportFileHeaderFromZIP is: ;
%put &&_vname_&max_colnum;

%ImportFileHeadersFromZIP(
zip=&file,
filename_rgx=.,
obs=max,
sasdsdout=&outdsd,
deleteZIP=0,
infile_command=%bquote(
delimiter='09'x firstobs=2 obs=max truncover lrecl=1000000000;
/*drop the dummy variables included in the extra_infile_macrovars*/
drop d;
input rownames :$&rowname_len.. @;
),
extra_infile_macrovar_prefix=_vname_,/*To prevent the crash of sas when the length of the macro var infile_command is too long,
it is better to assign different parts of infile commands into multiple global macro vars with similar prefix, such as infile_cmd;
it is better to use bquote or nrbquote to excape each extra infile command!*/
num_infile_macro_vars=&max_colnum /*Provide positve number to work with the global macro var of extra_infile_macrovar_prefix*/
);



*************************************************Older macro: which is slow for large tables with >1 million colums************************;
**************Juse for backup and leanring purpose!;

/**Randomly select columns and output dataset in wide format;*/
/*data _null_;*/
/**Need to specify the number of elements for temporary array;*/
/* array H{&max_colnum} _temporary_ (1:&max_colnum);*/
/* *Set a array with subset number of the above array;*/
/* *Use this array to select elements from permutated arrah H;*/
/*/* array S{&totrandom_cols} _temporary_ (1:&totrandom_cols);*/*/
/**Create an array to contain these excluded columns;*/
/**it will be used to filter columns as the number of excluded columns are much less;*/
/*%if %eval(&max_colnum-&totrandom_cols)>0 %then %do;*/
/*array E{%eval(&max_colnum-&totrandom_cols)} _temporary_ (1:%eval(&max_colnum-&totrandom_cols));*/
/*%end;*/
/*if _n_=1 then do;*/
/* _iorc_=&random_seed;/*random seed*/*/
/*   call ranperm(_iorc_,of H{*});*/
/*/*  do _si_=1 to &totrandom_cols;*/*/
/*/*    S{_si_}=H{_si_};*/*/
/*/*    *Create global macro vars for rename column names later;*/*/
/*/*    call symputx('Cell_V'||left(put(_si_,8.)),H{_si_},'G');*/*/
/*/*  end;*/*/
/*%if %eval(&max_colnum-&totrandom_cols)>0 %then %do;*/
/* do _ei_= 1 to %eval(&max_colnum-&totrandom_cols);*/
/*    E{_ei_}=H{_ei_+&totrandom_cols};*/
/*    call symputx('var2drop'||left(put(_ei_,8.)),'V'||left(put(E{_ei_},8.)),'G');*/
/* end;*/
/*%end;*/
/*end;*/
/*run;*/
/**/
/**Randomly select columns and output dataset in wide format;*/
/*%ImportFileHeadersFromZIP(*/
/*zip=&gzfile,*/
/*filename_rgx=.,*/
/*obs=max,*/
/*sasdsdout=&outdsd,*/
/*deleteZIP=&deletefile,*/
/*infile_command=%bquote(*/
/*delimiter='09'x firstobs=2 obs=max truncover lrecl=100000000;*/
/*length V1-V&max_colnum &V_max_len.;*/
/*input rownames :$&rowname_len.. V1-V&max_colnum;*/
/*&extra_cmd4infile;*/
/*),*/
/*global_var_prefix4vars2drop=var2drop,/*To handle the issue of trunction of macro var infile_command if there are too many variables to be dropped in the infile procedure;*/
/*it is feasible to create global macro variables with the same prefix, such as drop_var, to exclude them*/*/
/*num_vars2drop=%eval(&max_colnum-&totrandom_cols) /*Provide postive number to work with the macro var global_var_prefix4vars2drop to resolve these variables to be excluded*/*/
/*);*/
/**Note: in the above code, the value of ai need to be restrict using retain function;*/
/**Need to put these column number into macro variables and rename the column names later;*/
/**Alternatively, use file statement to output the columns into a file and read the file into sas again for renaming column names of the exp dataset;*/
/**the best way is to create global macro variable names for these columns and use the macro rename_cols_with_macro_vars to rename columns;*/
/*/*%rename_cols_with_macro_vars(totcols=&totrandom_cols,dsd=&outdsd,colvar_prefix=V,macro_var_prefix=Cell_V);*/*/;

%mend;

/*Demo codes:;
*If the total number of columns exceed 1 million in the original matrix file,;
*the macro will take too much time to output data for randomly selected cells;
*the optimized number of columns would be 100k for the input matrix file!;

*Note: it takes about 1 hour to import 1 million randomly selected cells into SAS;

*%debug_macro;

%let file=E:\sas_testing\exprMatrix.tsv\exprMatrix.tsv;
%random_import_cell_mtex(
gzfile=&file,
max_colnum=,
totrandom_cols=1000000,
random_seed=2718,
outdsd=subset_cell_exp,
extra_cmd4infile=%bquote(if mean(of V:)>0.01;)
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
