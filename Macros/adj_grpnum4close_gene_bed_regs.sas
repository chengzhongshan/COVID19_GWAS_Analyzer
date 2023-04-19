/* data a; */
/* input chr $ st end type $ grp $; */
/* cards; */
/* chr1 1 100 gene a */
/* chr1 10 20 exon a */
/* chr1 50 70 exon a */
/* chr1 200 800 gene b */
/* chr1 300 500 exon b */
/* chr1 600 700 exon b */
/* chr1 1100 3000 gene c */
/* chr1 1200 2000 exon c */
/* chr1 2200 2800 exon c */
/* chr1 3100 5000 gene d */
/* chr1 3200 3500 exon d */
/* chr1 4000 4800 exon d */
/* chr1 3100 7000 gene e */
/* chr1 4200 5500 exon e */
/* chr1 6000 6800 exon e */
/* ; */

/* proc sort  */
/* data=a(where=(type="gene")) */
/* out=_gene_regions_ */
/* nodupkeys; */
/* by st end grp; */
/* run; */
/* proc sql noprint; */
/* select count(grp) into: ngenes */
/* from _gene_regions_; */
/* run; */
/* data _gene_regions_(drop=_lag_end:); */
/* retain _grp_ 1; */
/* set _gene_regions_; */
/* dist=200; */
/*  */
/* lag_end1=lag(end); */
/* lag_end2=lag2(end); */
/* lag_end3=lag3(end); */
/*  */
/* _lag_end_1=lag(end) ^=. and st-lag(end)<dist; */
/* _lag_end_2=lag2(end) ^=. and st-lag2(end)<dist; */
/* _lag_end_3=lag3(end) ^=. and st-lag3(end)<dist; */
/* _grp_=sum(of _lag_end_1--_lag_end_3); */
/* run; */
/* proc print;run; */

%macro adj_grpnum4close_gene_bed_regs(
/*NOte: the macro can only separate most of the bed regions into
for better labeling bed regions, and usually the 1st tract will be
good, with genes included in other tracks may not be well separated!*/
gene_bed_dsd=a,
st_var=st,
end_var=end,
reg_type=type,/*if empty, it will use the longest region as gene and 
               other shorter region from the same group as exons*/
focused_reg_type4grouping=gene,
gene_grp=grp,
gene_dist_thrhd=0.1,/*(1) give 0 or negative value to incluce all genes into a single group;
                      (2) given value in bp > 1 to separate genes by absolute distance in bp;
                      (3) if given value ranging from 0 to 1, it will use the pct of the whole region
                          to separate genes into different groups!
                          This option would be most useful to enable enough space for adding text on each
                          gene, as it will consider the length of gene as well as the distance between genes*/
dsdout=_gene_regions_,/*dsdout can be the same as gene_bed_dsd*/
outnumgrp=numgrp /*the var name for outnumgrp can not be same as other vars in gene_bed_dsd*/
);

%if "&gene_bed_dsd"="&dsdout" %then %do;
    %put Your input dsd name is the same as the output dsd name;
    %put we will temporarily change the &dsdout as: &dsdout._;
    %let old_dsdout=&dsdout;
    %let dsdout=&dsdout._;
%end;
%else %do;
    %let old_dsdout=&dsdout;
%end;

%if &reg_type ne %then %do;
  proc sort 
  data=&gene_bed_dsd(where=(&reg_type="&focused_reg_type4grouping"))
  out=&dsdout
  nodupkeys;
  by &st_var &end_var &gene_grp;
  run;
%end;
%else %do;
 data &dsdout;
 set &gene_bed_dsd;
 dist=&end_var - &st_var;
 run;
 proc sql;
 create table &dsdout(drop=dist) as 
 select &st_var,&end_var, &gene_grp, dist 
 from &dsdout
 group by &gene_grp
 having dist=max(dist);
%end;

*It is important to sort the start position again!;
*otherwise, the _grp_ number would not be the best!;
proc sort data=&dsdout;by &st_var;run;

proc sql noprint;
select left(put(count(&gene_grp),3.)) into: ngenes
from &dsdout;
run;

%if &gene_dist_thrhd > 0 %then %do;

 %if &gene_dist_thrhd<1 %then %do;
     proc sql noprint;
     select min(st),max(end) into: st_min,:end_max
     from &dsdout;
     %put Now we will use the relative distance based on the percent &gene_dist_thrhd of whole region;
     %put from &st_min to &end_max to separate genes into different groups!;
     %let gene_dist_thrhd=%sysevalf((&end_max-&st_min)*&gene_dist_thrhd);
 %end;
/*  data &dsdout(drop=_lag_end:);*/
 data &dsdout;
  retain _grp_ 1;
  set &dsdout;
  _lag_end_1=(lag(end) ^=.) and (abs(st-lag(end))<&gene_dist_thrhd);
  _lag_end_1= _lag_end_1 >0 and ((lag(st) ^=.) and (abs(st-lag(st))<&gene_dist_thrhd));
  /*
  lag_end1=lag(end);
  */
  %do ni=2 %to &ngenes;
    /*
    lag_end2=lag2(end);
    lag_end3=lag3(end);
    */
    _lag_end_&ni=(lag&ni.(end) ^=.) and (abs(st-lag&ni.(end))<&gene_dist_thrhd);
    _lag_end_&ni=_lag_end_&ni>0 and ((lag&ni.(st) ^=.) and (abs(st-lag&ni.(st))<&gene_dist_thrhd));
  %end;
  %if &ngenes>1 %then %do;
   *Add one to make it start from 1 for the 1st group;
    _grp_=sum(of _lag_end_1--_lag_end_&ngenes)+1;
  %end;
  run;
 %end;
 
%else %do;
 *Include all genes into one group;
 data &dsdout;
 set &dsdout;
 _grp_=1;
 run;
%end;

*exclude records with the same consecutive _grp_;
data &dsdout(drop=_consect_grp_tag) 
     &dsdout._bad(drop=_consect_grp_tag);
set &dsdout;
_consect_grp_tag=lag(_grp_);
if (_consect_grp_tag=_grp_ and _grp_>1) then output &dsdout._bad;
else output &dsdout;
run;
/*for debugging*/
/* %abort 255; */

*make consective numeric groups for _grp_;
*The limitation of this part is that only element in the _grp_=1 can be separated well;
proc sort data=&dsdout;by _grp_ st end;
data &dsdout;
retain _cgrp_ 0;
set &dsdout;
if first._grp_ then _cgrp_=_cgrp_+1;
by _grp_;
run;

*Combine the grps, such as n+1 and n+3, with n=0,1,2,3;
*An easy way to combine them would be as follows:;
*Make these grps with reverse order;
*Note: use _grp_ to get max;
proc sql noprint;
select max(_grp_) into: mgrp
from &dsdout;

*Add back these bad groups and assign _cgrp_=&mgrp+_n_;
data &dsdout._bad;
retain init_num 1;
set &dsdout._bad;
_cgrp_=&mgrp+_n_;

/*Assume it is better but it is not!;
*Better to group regions with different _cgrp_ together;
*which will aggregate these regions in a single track;
if first._grp_ then do;
  _cgrp_=&mgrp+1;
  init_num=1;
end;
else do;
  init_num=init_num+1;
  _cgrp_=init_num+&mgrp;
end;
by _grp_;
*/
run;


data &dsdout;
set &dsdout &dsdout._bad;
run;

*Note: use _cgrp_ but not _grp_ to get max;
proc sql noprint;
select max(_cgrp_) into: newmgrp
from &dsdout;

data &dsdout;
set &dsdout;
*Important to adjust group number by not allowing the new _cgrp_ close to original _grp_;
/* if &mgrp-_cgrp_+3 <= _grp_ then _cgrp_=&newmgrp-_cgrp_+1; */
/* if &mgrp-_cgrp_+2 <= _grp_ then _cgrp_=&newmgrp-_cgrp_+1; */
*Put half of these _cgrp_ with larger numbers started from 1;
%if &newmgrp>=3 %then %do;
  if _cgrp_>ceil(0.5*&newmgrp) then _cgrp_=_cgrp_-ceil(0.5*&newmgrp);
%end;
run;

/*
proc sql noprint;
select max(_cgrp_) into: mgrp
from &dsdout;
*Add back these bad groups and assign _cgrp_=&mgrp+1;
data &dsdout._bad;
set &dsdout._bad;
_cgrp_=&mgrp+1;
data &dsdout;
set &dsdout &dsdout._bad;
run;
*/

proc sort data=&dsdout;by _grp_ st end;
proc sql;
create table &old_dsdout as 
select a.*,b._cgrp_ as &outnumgrp 
from &gene_bed_dsd as a
left join
&dsdout as b 
on a.&gene_grp=b.&gene_grp;

/* proc print;run; */
%mend;


/*Demo code:

data a;
*ensure exons of its corresponding gene have the same grp name;
input chr $ st end type $ grp $;
tag=-1;
cards;
chr1 1 100 gene a
chr1 10 20 exon a
chr1 50 70 exon a
chr1 200 800 gene b
chr1 300 500 exon b
chr1 600 700 exon b
chr1 1100 3000 gene c
chr1 1200 2000 exon c
chr1 2200 2800 exon c
chr1 3100 5000 gene d
chr1 3200 3500 exon d
chr1 4000 4800 exon d
chr1 3100 7000 gene e
chr1 4200 5500 exon e
chr1 6000 6800 exon e
chr1 11100 31000 gene f
chr1 11200 21000 exon f
chr1 22000 28000 exon f
chr1 41000 50000 gene g
chr1 42000 55000 exon g
chr1 81000 170000 gene h
chr1 82000 85000 exon h
chr1 90000 108000 exon h
chr1 70000 80000 gene i
;

data a;
*ensure exons of its corresponding gene have the same grp name;
input chr $ st end type $ grp $;
tag=-1;
cards;
chr1 10 100 gene a
chr1 200 300 gene b
chr1 350 500 gene c
chr1 450 600 gene d
chr1 700 850 gene e 
chr1 880 900 gene f
;
****************************************************************************************************;
*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;
%debug_macro;

*Make sure these gene bed regions are from the same chromosome;
%adj_grpnum4close_gene_bed_regs(
gene_bed_dsd=a,
st_var=st,
end_var=end,
reg_type=type,
focused_reg_type4grouping=gene,
gene_grp=grp,
gene_dist_thrhd=0.1,
dsdout=xxx,
outnumgrp=numgrp
);
****************************************************************************************************;
*Assign negative value for these bed regions;
data xxx;set xxx;numgrp=-1*numgrp;
****************************************************************************************************;
*This will only draw bed regions without scatter plot;
*Note: the var tag need to be nagative to only draw bed regions;
%Lattice_gscatter_over_bed_track(
bed_dsd=xxx,
chr_var=chr,
st_var=st,
end_var=end,
grp_var=grp,
scatter_grp_var=tag,
lattice_subgrp_var=numgrp,
yval_var=numgrp,
yaxis_label=%str(-log10%(P%)),
linethickness=20,
track_width=800,
track_height=400,
dist2st_and_end=0,
dotsize=8,
debug=1
);

%debug_macro(undebug=1);

****************************************************************************************************;
*reg_type and focused_reg_type4grouping can be omitted if wanting to use the longest region as gene;
%adj_grpnum4close_gene_bed_regs(
gene_bed_dsd=a,
st_var=st,
end_var=end,
reg_type=,
focused_reg_type4grouping=,
gene_grp=grp,
gene_dist_thrhd=200,
dsdout=xxx,
outnumgrp=numgrp
);


*/


 
