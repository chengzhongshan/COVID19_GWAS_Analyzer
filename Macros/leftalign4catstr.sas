%macro leftalign4catstr(/*Note: the final generated combinedVar can be used by 
proc sgplot with the xaxis valuesrotate=diagonal2 for best visual effect*/
dsdin=,
vars4cat=, /*vars separated by blank spaces in order for catx*/
combinedVar=combined_vars,/*A new variable containing combined vars by catx*/
add_extra_sep_et_end=0,/*Sometimes it is necessary to make the final combinedVar with the same number of chars,
please supply value 1 to add extra separator "." to enable the combined var have the same number of chars*/
dsdout=
);
%local _vi_ nvars;
%let nvars=%ntokens(&vars4cat);
%get_vars_max_length(
dsdin=&dsdin,
vars=&vars4cat,
macrotag4varslen=_max_var,
/*global macro variables containing the length for each variable will be created by adding numeric orders in according to the order of input variables*/
dsdout=_tmp_  /*Output a dsd containing the max length for all input vars*/
);
data &dsdout;
/*merge &dsdin _tmp_;*/
set &dsdin;
run;
data &dsdout;
retain _max_len_ 0;
length &combinedVar $1000.;
set &dsdout end=eof;
%do _vi_=1 %to &nvars;
   nspaces&_vi_=1+&&_max_var&_vi_-length(trim(left(%scan(&vars4cat,&_vi_,%str( )))));
  *Note: also assign "-" or ".." for char4space, which does not have the same length as a typical alphabet;
  *This will ensure the final combined vars have the same length for making better axis in plotting;
   
   %if &add_extra_sep_et_end=0 and &_vi_= &nvars %then %do;
      _new_&_vi_=trim(left(%scan(&vars4cat,&_vi_,%str( ))));
	%end;
	%else %do;
	   _new_&_vi_=resolve('%AddSpaces4str(str='||trim(left(%scan(&vars4cat,&_vi_,%str( ))))||',add2end=1,nspaces='||nspaces&_vi_||',char4space=.)');
	%end;

%end;

*catx will automatically add a leading blank space if the separator is assigned as empty string '';
*So ensure to have the same separator used by the macro AddSpaces4str;
&combinedVar=catx('.', of _new_1-_new_&nvars);
if _max_len_<length(&combinedVar) then _max_len_=length(&combinedVar);
if eof then call symputx('_maxlen4comb_',_max_len_);
drop nspaces: _new_:;
run;

%mend;

/*Demo codes:;

data x;
input Filename :$15. gene :$8. gwas :$8. tissue :$20.;
tissue=upcase(tissue);
gene=upcase(gene);
cards;
rs17078348 LZTFLx HGI_B1 Adipose_Subcutaneous
rs17078348 SLCxAxx HGI_B1 Muscle_Skeletal
IL10RB W1LongCOVID Test1 Tissue1
MUC1 W2LongCOVID Test2 Tissue2
;
proc print;run;
%debug_macro;
%leftalign4catstr(
dsdin=x,
vars4cat=Filename gene gwas tissue,
dsdout=test
);

goptions ftext="Consolas";
proc print;run;
*The above fails to allocate even space for each character;

*The following codes works;
proc print;
%print_nicer(
fontsize=12,
fontcol=dark,
column_font=Consolas);
run;


*/
