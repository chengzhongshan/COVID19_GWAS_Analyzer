
%macro LinkDupWithHash(dsd,keys,values,out_var_names,linker,outdsd,rmdups);
*Link the duplicates for the key in a dsd;
*Will output unique key and its values (linked with specific separator) into outdsd;

*Change all empty cells into NaN;
%RepRegx2ValueInDsd(&dsd,&dsd,s/^\s*$/NaN/,0);

%let new_keys=%quotelst(&keys,quote=%str(%"),delim=%str(, ));
%let nvars=%numargs(&values);
%put &nvars values: &values;
%let nouts=%numargs(&out_var_names);
%put &nouts values: &out_var_names;
%if (&nouts^=&nvars) %then %do;
  %put Please make sure to input the same number of VALUES and OUT_VAR_NAMES;
  %abort 255;
%end;
*Add custermized variable n for keeping order of data;
*Make sure to put it before &values;
%if &rmdups eq %then %let rmdups=0;
%put rmdup is set to be 0 and we will keep all dups;
%if &rmdups eq 1 %then %do;
proc sort data=&dsd out=_dsd_ nodupkeys;
by &keys &values;
run;
%end;
%else %do;
proc sort data=&dsd out=_dsd_;
by &keys &values;
run;
%end;

%let new_values=%quotelst(&values,quote=%str(%"),delim=%str(, ));
%let value_list=%quotelst(&values,quote=%str(),delim=%str(, ));



proc sort data=&dsd out=Uniqu_dsd nodupkeys;
by &keys;
run;

data &outdsd(keep=&keys &out_var_names);
if _n_=1 then do;
 if 0 then set _dsd_;
   declare hash Item_Hash(dataset:"_dsd_",multidata:"Y");
   rc=Item_Hash.definekey(&new_keys);
   rc=Item_Hash.definedata(&new_values);
   Item_Hash.definedone();
 end;
 set Uniqu_dsd;

 %let nv=1;
 %do %while(%scan(&values,&nv) ne);
   length value&nv $%eval(32767/&nvars).;
   value&nv="";
   %let nv=%eval(&nv+1);
 %end;

 do _iorc_=Item_Hash.find() by 0 while (_iorc_=0);
  %let nv1=1;
   %do %while(%scan(&values,&nv1) ne );
    value&nv1=catx("&linker",value&nv1,%scan(&values,&nv1));
	%let nv1=%eval(&nv1+1);
   %end; 
    _iorc_=Item_Hash.find_next();
 end;
 rename %let nv2=1;
        %do %while(%scan(&values,&nv2) ne );
         value&nv2=%scan(&out_var_names,&nv2) 
		 %let nv2=%eval(&nv2+1);
		 %if &nv2 gt &nvars %then %str(;);
		%end;
 output;
run;

proc datasets lib=work noprint;
delete Uniqu_dsd _dsd_;
run;
*For easy downstream merge!;
proc sort data=&outdsd;
by &keys &&out_var_names;
run;
%mend;
/*
data a;
input x $ y	$ ord $;
cards;
z a TCGA3
z a TCGA2
x b TCGA2
w c TCGA3
z a 1
z a 3
z a 2
x b 2
w c 3
d d 4
z a 1
z a 3
z a 2
x b 2
w c 3
d d 4
z a 1
z a 3
z a 2
x b 2
w c 3
d d 4
z a TCGA1
z a TCGA3
d d TCGA4
;
run;

*options mprint mlogic symbolgen;

*Note: the macro will sort data with keys and values;

%LinkDupWithHash(dsd=a,
                 keys=x y,
                 values=x ord y,
                 out_var_names=new1 new2 new3,
				 linker=%str(, ),
                 outdsd=z,
                 rmdups=1);
*/
