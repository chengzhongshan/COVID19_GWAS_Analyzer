%macro random_import_cell_mtex_slow(
gzfile=,/*the fullpath to compressed or plain file, such as gz, txt, zip, and others.*/
max_colnum=1000000,/*If the max number of cells to read from each line >10000, it will take too much time*/
totrandom_cols=10000,
random_seed=2718,
outdsd=subset_cell_exp,
rowname_len=100, /*The length of the 1st rowname length*/
V_max_len=8, /*The length for all numeric cell expression value*/
deletefile=1 /*Delete input gzfile*/
);

*Randomly select columns and output dataset in wide format;
%ImportFileHeadersFromZIP(
zip=&gzfile,
filename_rgx=.,
obs=max,
sasdsdout=&outdsd,
deleteZIP=&deletefile,
infile_command=%bquote(
delimiter='09'x firstobs=2 obs=max truncover lrecl=100000000;
retain ai 0;
*Need to specify the number of elements for temporary array;
 array H{&max_colnum} _temporary_ (1:&max_colnum);
 *Set a array with subset number of the above array;
 *Use this array to select elements from permutated arrah H;
 array S{&totrandom_cols} _temporary_ (1:&totrandom_cols);
*Create an array to contain these excluded columns;
*it will be used to filter columns as the number of excluded columns are much less;
array E{%eval(&max_colnum-&totrandom_cols)} _temporary_ (1:%eval(&max_colnum-&totrandom_cols));
if _n_=1 then do;
 _iorc_=&random_seed;/*random seed*/
   call ranperm(_iorc_,of H{*});
  do _si_=1 to &totrandom_cols;
    S{_si_}=H{_si_};
    *Create global macro vars for rename column names later;
    call symputx('Cell_V'||left(put(_si_,8.)),H{_si_},'G');
  end;
 do _ei_= 1 to %eval(&max_colnum-&totrandom_cols);
    E{_ei_}=H{_ei_+&totrandom_cols};
 end;
end;
*Include the rownames into the length command will position it at the 1st column;
length rownames $&rowname_len.. V1-V&totrandom_cols &V_max_len..;
input rownames :$&rowname_len.. @;
*Generate an array to hold these randomly selected columns;
*No need to use output here for exp, as its value will be assigned to the array X;
array X{&totrandom_cols} V1-V&totrandom_cols;
do i=1 to &max_colnum;
    if i not in E then do;
      *Increase ai if i is in array S;
      ai=ai+1;
      input exp @;
      X{ai}=exp;
    end;
    else do;
    input exp @;
    end;
  *Asign 0 to ai again;
  if i=&max_colnum then ai=0;
end;
drop i ai _si_  exp;
;
)
);
*Note: in the above code, the value of ai need to be restrict using retain function;
*Need to put these column number into macro variables and rename the column names later;
*Alternatively, use file statement to output the columns into a file and read the file into sas again for renaming column names of the exp dataset;
*the best way is to create global macro variable names for these columns and use the macro rename_cols_with_macro_vars to rename columns;
%rename_cols_with_macro_vars(totcols=&totrandom_cols,dsd=&outdsd,colvar_prefix=V,macro_var_prefix=Cell_V);
%mend;

/*Demo codes:;

x cd "E:\LongCOVID_HGI_GWAS\SASR_Airway_Infection_SC";
%let file=E:\LongCOVID_HGI_GWAS\SASR_Airway_Infection_SC\exprMatrix.tsv.gz;
%random_import_cell_mtex(
gzfile=&file,
max_colnum=10000,
totrandom_cols=10,
random_seed=2718,
outdsd=subset_cell_exp
);

*The above macro is included in the macro ucsc_cell_matrix2wideformatdsd:

%ucsc_cell_matrix2wideformatdsd(
gzfile_or_url=&file,
dsdout4headers=headers,
dsdout4data=exp,
extra_cmd4infile=
);

*/
