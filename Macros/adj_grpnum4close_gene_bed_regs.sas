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
/*Note: the macro can only separate most of the bed regions
for better labeling bed regions, and usually the 1st track will be
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
  _lag_end_1=(lag(end) ^=.) and (abs(st-lag(end))<&gene_dist_thrhd or st-lag(end)<0);
  _lag_end_1= _lag_end_1 >0 or ((lag(st) ^=.) and (abs(st-lag(st))<&gene_dist_thrhd or st-lag(st)<0))>0;
  /*
  lag_end1=lag(end);
  */
  %do ni=2 %to &ngenes;
    /*
    lag_end2=lag2(end);
    lag_end3=lag3(end);
    */
    _lag_end_&ni=(lag&ni.(end) ^=.) and ((abs(st-lag&ni.(end))<&gene_dist_thrhd) or st-lag&ni.(end)<0);
    _lag_end_&ni=_lag_end_&ni>0 or ((lag&ni.(st) ^=.) and (abs(st-lag&ni.(st))<&gene_dist_thrhd or st-lag&ni.(st)<0))>0;
  %end;
  %if &ngenes>1 %then %do;
   *Add one to make it start from 1 for the 1st group;
    _grp_=sum(of _lag_end_1-_lag_end_&ngenes)+1;
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
/*%abort 255;*/


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
/*%abort 255;*/

data &dsdout;
set &dsdout;
*Important to adjust group number by not allowing the new _cgrp_ close to original _grp_;
/* if &mgrp-_cgrp_+3 <= _grp_ then _cgrp_=&newmgrp-_cgrp_+1; */
/* if &mgrp-_cgrp_+2 <= _grp_ then _cgrp_=&newmgrp-_cgrp_+1; */
*Put half of these _cgrp_ with larger numbers started from 1;
*This part is a bug if all grps are indeed not mergable, which means there are the same number of orginal and newly generated groups;
%if &newmgrp>=10 %then %do;
  %put WARNING: the macro adj_grpnum4close_gene_bed_regs will modify the newly created numeric group since it is the same number of groups as the original group;
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
*Note that the macro var &old_dsdout is used here to avoid of potential errors when the gene_bed_dsd is the same as &dsdout;
proc sql;
create table &old_dsdout as 
select a.*,b._cgrp_ as &outnumgrp 
from &gene_bed_dsd as a
left join
&dsdout as b 
on a.&gene_grp=b.&gene_grp;

data &dsdout;
set &old_dsdout;
run;
*When the two vars &dsdout and &old_dsdout have the same name, the original dataset will be overwritten;
*Need to keep a copy for it.;
data &old_dsdout.0;
set &old_dsdout;
run;
/*%abort 255;*/
***It is necessary to further optimize these regions by merging the largest group number with the smallest group numer;
***when any regions in the largest group number are not within the distance threshold;

  *This part might invite issues for separating a gene and its corresponding exons into different groups;
  *To resovle the issue, it is necessary use minmum st and max end for each gene_grp as input;
  *First keep a copy for the above &dsdout, and then later update the &outnumgrp with newly calculated group numbers; 
  proc sql;
  create table &dsdout as 
  select distinct &gene_grp,min(&st_var) as &st_var,max(&end_var) as &end_var,&outnumgrp
  from &dsdout
  group by &gene_grp;
/*  %abort 255;*/

%let nmgrp_0=0; 
%let nmgrp_1=1;
*For debugging the loop;
%let nloop=0;
*Restrict the loop only run maximum of 300 iterations;
%do %while (&nmgrp_0 ne &nmgrp_1 and &nloop<300);
   %let nloop=%eval(&nloop+1);
  *Need to create a new numgrp var and reorder the numgrp based on new &outdsd in the loop;
  proc sql;
  create table _tmp_ as
  select unique(&outnumgrp) as _tmpnumgrp_
  from &dsdout
  order by &outnumgrp;
/*  %abort 255;*/
  data _tmp_;set _tmp_;&outnumgrp=_n_;
  proc sql;
  create table &dsdout as
  select a.*,b.&outnumgrp as new&outnumgrp
  from &dsdout as a
  left join
  _tmp_ as b
  on a.&outnumgrp=b._tmpnumgrp_;
/*  %abort 255;*/
  *Put the newnumgrp into the macro var &nmgrps;
  *This will update the macro var nmgrps in each interation;
  proc sql noprint;
  select put(new&outnumgrp,best12.) into: nmgrps separated by ' '
  from (
    select distinct new&outnumgrp from &dsdout
  );
/*  %abort 255;*/
  *Use the newnumgrp to replace older numgrp;
  data &dsdout(rename=(new&outnumgrp=&outnumgrp));
  set &dsdout(drop=&outnumgrp);
  run;

 %if %ntokens(&nmgrps)>=3 %then %do;

   proc sql noprint;
   select put(&outnumgrp,best12.) into: nmgrp_0 separated by ':'
   from &dsdout
   order by &gene_grp, &st_var, &end_var; 
   *Important to only consider the comparision between regions from i and i+2 groups;
   *since the consecutive groups, i and i+1 do not have potential non-overlapped regions based on the distance threshold;

   %do nmg_i=%ntokens(&nmgrps) %to 3 %by -1; 
         *%let start_num=%eval(1+%ntokens(&nmgrps)-&nmg_i);
          %let start_num=1;
		 *Note: only compare 3 pairs, and the following can not be uncommented as SAS will fail to parse the macro contents due to it is use of pcts;
		 %let end_num=%sysfunc(ifc(%eval(&nmg_i-2)>%eval(&start_num+6),%eval(&start_num+6),%eval(&nmg_i-2)));
/*		  %let end_num=%eval(&nmg_i-2);*/
		 %put Your start and end number for the loop is &start_num and &end_num;
	     %do nmg_ii= &start_num %to &end_num %by 2; 
/*		      %let nloop=%eval(&nloop+1);*/
		       %put Running the n=&nloop loop: comparison for the group &nmg_i with group &nmg_ii;
			 data p1;set &dsdout;where &outnumgrp=&nmg_ii;
			 data p2;set &dsdout;where &outnumgrp=&nmg_i;
			 run;
/*			 %if %totobsindsd(work.p2)=0 %then %do;*/
/*						%put No obs in the dataset p2 for the numgrp &nmg_i;*/
/*						%abort 255;*/
/*			 %end;*/
			%if %totobsindsd(work.p2)>0 %then %do;

			 %if %ntokens(&nmgrps)>=3 %then %do;
				 data left;set &dsdout;where &outnumgrp^=&nmg_ii and &outnumgrp^=&nmg_i;
			 %end;
			  run;
/*			  %abort 255;*/
			  *It is important to use distinct to remove duplicate records due to the where condition leads to potential multiple matches;
			  proc sql;
			  create table p1_p2 as
			  select distinct b.*
			  from p1 as a,
			           p2 as b
			  where (b.&st_var between  (a.&st_var-&gene_dist_thrhd) and (a.&end_var+&gene_dist_thrhd)) or 
                         (b.&end_var between  (a.&st_var-&gene_dist_thrhd) and (a.&end_var+&gene_dist_thrhd)); 
/*			   proc print;run;*/
			   %if %totobsindsd(work.p1_p2)>0 %then %do;;			      
					 proc sql;
					 create table p1p2_except as 
					 select * from p2
					 except 
					 select * from p1_p2;
					   data p1p2_except;set p1p2_except;&outnumgrp=&nmg_ii;
					   *Update data set p2, which have different outnumgrp for p1_p2 and p1p2_except;
					   data p2;set p1_p2 p1p2_except;run;
			   %end;
			   %else %do;
			   	  *Merge all records with the largest group &nmg_i as that of &nmg_ii;
			      data p2;set p2;&outnumgrp=&nmg_ii;
			   %end;
			    data &dsdout;
				set p1 p2 
                %if %ntokens(&nmgrps)>=3 %then %do;
				  left
				%end;
                ;
				run;

				proc sql;
				drop table left;
				drop table p1;
				drop table p2;
				drop table p1_p2;
				drop  table p1p2_except;
/*				%abort 255;*/
	      %end;
         %end;
   %end;
  *Capture these new group numbers and order them by positions;
  *The macro var will be used to compare with previous numbers &nmgrp_0;
   proc sql noprint;
   select put(&outnumgrp,best12.) into: nmgrp_1 separated by ':'
   from &dsdout
   order by &gene_grp, &st_var, &end_var; 
%end;
 %else %do;
	 %let nmgrp_0=1; 
     %let nmgrp_1=1;
 %end;

%end;

  *It is necessary to rename the &dsdout as &old_dsdout;
*&old_dsdout contains the target output data set name, in case that it is the same as input data set name;
*Update the newly generated grp number to the &old_dsdout;
/*%put old_dsdout is &old_dsdout and dsdout is &dsdout;*/
proc sql;
create table &old_dsdout as 
select a.*,b.&outnumgrp 
from &old_dsdout.0(drop=&outnumgrp) as a
left join
&dsdout as b
on a.&gene_grp=b.&gene_grp;
/*%abort 255;*/
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
*%let macrodir=/home/cheng.zhong.shan/Macros;
*%include "&macrodir/importallmacros_ue.sas";
*%importallmacros_ue;
*%debug_macro;

*Make sure these gene bed regions are from the same chromosome;
%adj_grpnum4close_gene_bed_regs(
gene_bed_dsd=a,
st_var=st,
end_var=end,
reg_type=type,
focused_reg_type4grouping=gene,
gene_grp=grp,
gene_dist_thrhd=0.2,
dsdout=xxx,
outnumgrp=numgrp
);
****************************************************************************************************;
*Assign negative value for these bed regions;
data xxx;
set xxx;
numgrp=-1*numgrp;
run;
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
fig_fmt=png,
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


 
