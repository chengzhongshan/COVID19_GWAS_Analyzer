%macro chr_format_exchanger(dsdin,char2num,chr_var,dsdout);
 
data &dsdout(drop=_chr_);
set &dsdin(rename=(&chr_var=_chr_));
 %if &char2num %then %do;
   if lowcase(_chr_) in ("chrx","x") then do;
     &chr_var=23;
   end;
   else if lowcase(_chr_) in ("chry","y") then do;
     &chr_var=24;
   end;
   else do;
/*      &chr_var=put(prxchange('s/chr//',-1,_chr_),4.); */
        &chr_var=left(input(scan(_chr_,1,'chr'),4.));
   end;
   if &chr_var ^ =. then output;
 %end;
 %else %do;
    length &chr_var $5.;
    if _chr_ eq 23 then do;
     &chr_var="chrX";
   end;
   else if _chr_ eq 24 then do;
     &chr_var="chrY";
   end;
   else do;
     &chr_var=trim(left("chr"||left(put(_chr_,2.))));
   end;
   output;
 %end;
run;
%mend;

/*Demo:
data a;
input chr $;
cards;
chr10
chr1
chr3
chrX
chrY
;
run;

options mprint mlogic symbolgen;

%chr_format_exchanger(
dsdin=a,
char2num=1,
chr_var=chr,
dsdout=a1);

data b;
input chr;
cards;
10
1
3
23
24
;
run;

options mprint mlogic symbolgen;

%chr_format_exchanger(
dsdin=b,
char2num=0,
chr_var=chr,
dsdout=b1);

*/

