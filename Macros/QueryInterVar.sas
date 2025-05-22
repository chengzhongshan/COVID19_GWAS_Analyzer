%macro QueryInterVar(
chr=1,
pos=115828756,
ref=G,
alt=A,
build=hg19,
dsdout=results
);
%let query_url=%nrstr(http://wintervar.wglab.org/api_new.php?queryType=position&chr=)&chr.%nrstr(&pos=)&pos%nrstr(&ref=)&ref%nrstr(&alt=)&alt%nrstr(&build=)&build;
filename J temp;
/* proc http url='http://wintervar.wglab.org/api_new.php?queryType=position&chr=1&pos=115828756&ref=G&alt=A&build=hg19' */
proc http url=%str("&query_url") 
out=J;
run;
/* data _x_; */
/* infile J lrecl=32767; */
/* input; */
/* info=_infile_; */
/* run; */
/* proc print;run; */
%if %sysfunc(fexist(J)) %then %do;
libname V Json fileref=J;
/* proc datasets lib=V; */
/* run; */
/* proc print data=V.root; */
/* run; */
data &dsdout;
set V.root;
attrib gene format=$30.;
attrib intervar format=$50.;
attrib position format=best32.;
drop ordinal_root;
run;
data &dsdout(rename=(Tag=Tag4AMCG));
set &dsdout;
length Tag $200.;
array T{*} PVS1--BS4;
do i=1 to dim(T);
  *Tag=trim(left(vname(T{i})))||"+"||Tag;
  *The above works when adding vanmes together, but the following fails to generate expected strings;
  *Tag=Tag||"+"||trim(left(vname(T{i})));
  *Explaination for the above failure is described as follows:;
  *If the trim and left functions are not used here, sas will output the variable Tag with empty element;
  *this is because of the Tag is designated with 200 chars and padded with blank spaces initially;
  *Without of using the two functions, there would be no room to add vnames, resulting in the empty variable for Tag.;
  if T{i}=1 then do;
    if length(Tag)=. then Tag=trim(left(vname(T{i})));
    else Tag=trim(left(Tag))||"+"||trim(left(vname(T{i})));
  end;
end;
Tag=prxchange('s/^\+//',-1,Tag);
drop i;
run;

filename J clear;
libname V clear;
%end;
%else %do;
 %put No results for the query: &chr:&pos:&ref:&alt;
 %return;
%end;
%mend;

/*Demo codes:;

*chr22	20994710 C T hg38;

option mprint mlogic symbolgen;
%QueryInterVar(
chr=10,
pos=43119548,
ref=G,
alt=A,
build=hg38,
dsdout=results
);
proc print data=results;
run;

*/






