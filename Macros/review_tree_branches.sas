%macro review_tree_branches(
inputdsd=a,
y_name_var=child,
y_parent_var=parent,
y_height_var=hh,
outdsd=out,/*A output dataset would be further used to draw new tree with sgrender template HeatDendrogram1*/
branch_name_dsd=branch_name_dsd /*Ordered branche names for the end leaves in the final cluster from left to right*/
);

data _tmpdsd_;
set &inputdsd;
b=&y_name_var;
all_parents=&y_parent_var;
if prxmatch("/^CL/",&y_parent_var);
run;
/*proc print;run;*/

*Good hash SAS paper:;
*https://support.sas.com/resources/papers/proceedings16/10200-2016.pdf;
*The step tries to match up cluster CLnum with end leave names and save them into a long format dataset.;
data ab_res (keep=all_parents &y_parent_var &y_name_var &y_height_var);
length &y_name_var $200 &y_parent_var $200 v $200 b $200 ;
if _n_=1 then do;
    /* build multidata hash on dataset A: key = c1, data = x */
    declare hash h(dataset:"&inputdsd", multidata:'YES');
    h.defineKey("&y_parent_var"); h.defineData("&y_name_var"); h.defineDone();
    call missing(&y_parent_var,&y_name_var);
end;

set _tmpdsd_; /* keep original b value in b */

&y_parent_var = b;

/* If there is no match for this key, just output the record (unmatched) */
rc = h.find();
if rc ne 0 then do;
    /* no child entries in A for this key */
    output;
end;
else do;
    /* We'll collect CL keys to traverse in a queue, and produce outputs for non-CL leaves */
    array queue[2000] $200 _temporary_;    /* queued CL keys to process */
    array visited[2000] $200 _temporary_;  /* visited CL keys to avoid loops */
    qcount = 0;
    vcount = 0;
    /* process all matches for the initial key (&y_parent_var = b) */
    do while (rc = 0);
        v = &y_name_var;
        if prxmatch('/^CL/', v) then do;
            /* enqueue CL key if not already queued */
            dup = 0;
            do j = 1 to vcount;
                if queue[j] = v then do; dup = 1; leave; end;
            end;
            if dup = 0 then do; vcount + 1; queue[vcount] = v; end;
        end;
        else do;
            /* non-CL leaf: output */
            output;
        end;
        rc = h.find_next();
    end;

    /* process queued CL keys iteratively (BFS/DFS style) */
    i = 1;
    do while (i <= vcount);
        key = queue[i];

        /* skip if we've already fully processed this key (avoid cycles) */
        already = 0;
        do j = 1 to qcount;
            if visited[j] = key then do; already = 1; leave; end;
        end;

        if already = 0 then do;
            qcount + 1; visited[qcount] = key;

            /* set &y_parent_var to the queued CL key and find its matches */
            &y_parent_var = key;
            rc = h.find();
            if rc = 0 then do;
                do while (rc = 0);
                    v = &y_name_var;
                    if prxmatch('/^CL/', v) then do;
                        /* enqueue deeper CL key if not already queued */
                        dup = 0;
                        do j = 1 to vcount;
                            if queue[j] = v then do; dup = 1; leave; end;
                        end;
                        if dup = 0 then do; vcount + 1; queue[vcount] = v; end;
                    end;
                    else do;
                        /* non-CL leaf: output */
                        output;
                    end;
                    rc = h.find_next();
                end;
            end;
        end;

        i + 1;
    end;
end;
run;
/*%abort 255;*/

*Get the tree leave labels in order ranging from left to right in the final cluster and use them to get location of each cluster CL for labeling them later;
*%treeorder(data=&inputdsd, child=&y_name_var, parent=&y_parent_var, hh=&y_height_var, root=CL1, order=ASC, outds=&branch_name_dsd);
*Use a better macro to get branch names as well as relative positions for all parent branches;
 %tree_CL_positions(data=&inputdsd, child=&y_name_var, parent=&y_parent_var, hh=&y_height_var, root=CL1, order=ASC, outds=&branch_name_dsd);
 *Need to remove parents or children not included in the &branch_name_dsd;
 proc sql;
 create table ab_res as
 select a.*
 from ab_res as a
 where a.&y_name_var in (select name from &branch_name_dsd) or 
            a.&y_parent_var in (select name from &branch_name_dsd);
 proc sql;
 create table &inputdsd.tmp as
 select a.*
 from &inputdsd as a
 where a.&y_name_var in (select name from &branch_name_dsd) or 
            a.&y_parent_var in (select name from &branch_name_dsd);
/*%abort 255;*/
data &branch_name_dsd;
/*(keep=&y_name_var left2right_ord);*/
set &branch_name_dsd;
rename order=left2right_ord name=&y_name_var;
run;

/*%abort 255;*/
*Add the label order back into the table ab_res;
proc sql;
create table ab_res as
select a.*,b.left2right_ord
from ab_res as a
left join
&branch_name_dsd as b
on a.&y_name_var=b.&y_name_var
order by all_parents,left2right_ord;
*Also add the relative order for these parent branches;
proc sql;
create table ab_res as
select a.*,b.left2right_ord as parent_ord
from ab_res as a
left join
&branch_name_dsd as b
on a.all_parents=b.&y_name_var
order by all_parents,left2right_ord;

data ab_res;
set ab_res;
end_child_label=&y_name_var;
if 	&y_height_var^=0 then  end_child_label="";
run;
proc sql noprint;
select count(*) into: tot_leaves
from &branch_name_dsd
where not prxmatch("/^CL\d+/",&y_name_var);

*The trick part is to estimate the right x-axis % for each CLnum;
*it is necessary to increase the % of 5/(&tot_leaves-1)*(floor((count(left2right_ord)-1)/2)-1) by half of branches for each CLnum;
proc sql;
create table ab_res1 as
select a.*,ceil(mean(left2right_ord)) as tgt_note, 
         (99/(&tot_leaves-1)) * ( 
           (max(left2right_ord) - min(left2right_ord))/2+
		   min(left2right_ord)-1 + 5/(&tot_leaves-1)*(floor((max(left2right_ord)-1)/2)-1)
		   )  as right_xpos,
                 case 
                 when left2right_ord=calculated tgt_note then  &y_name_var
				 else ""
				 end as all_parents_label
from ab_res as a
group by all_parents
order by all_parents,left2right_ord;
*Use better positions for these parent branches;
data ab_res1;
set ab_res1;
if end_child_label="" then do;
right_xpos=(100/(&tot_leaves-1))*(parent_ord-1);
end;
run;
/*%abort 255;*/
*Now only keep essential vars for labeling tree branches;
*Need to update the right height again, as previously matched height is not from y_name_var;
proc sql;
create table _right_height_dsd_ as
select a.&y_name_var as new_child, a.all_parents,a.right_xpos,b.&y_height_var as right_height, a.&y_height_var 
from ab_res1 as a
left join 
(select distinct &y_name_var, &y_height_var
from _tmpdsd_
) as b
on a.all_parents=b.&y_name_var;

proc sql noprint;
select &y_height_var into: topheight
from &inputdsd.tmp
where &y_name_var="CL1";

data _right_height_dsd_ (drop=right_height rename=(&y_height_var=new_height));
set _right_height_dsd_ ;
if &y_height_var^=0 then &y_height_var=right_height;
*Manually put the CL1 in the middle of the top of the final dendrogram;
*if all_parents="CL1" then &y_height_var=&topheight;
run;

data _right_height_dsd_ ;
set _right_height_dsd_ ;
if new_height>0 or all_parents="CL1";
run;
*Only keep unique parent CL and height;
proc sort data=_right_height_dsd_ nodupkeys;
by all_parents;
run;
/*%abort 255;*/
proc sql;
create table &outdsd as
select a.*,b.new_child,b.new_height,b.all_parents,b.right_xpos
from &inputdsd.tmp as a
left join
_right_height_dsd_ as b
on a.&y_name_var=b.all_parents;
/*%abort 255;*/
data &outdsd;
set &outdsd;
if new_child="" and not prxmatch("/^CL/",&y_name_var) then do;
 new_child=&y_name_var; 
 all_parents=&y_parent_var;
 new_height=0;
end;
_all_parents=all_parents;
if right_xpos^=. then do;
   *enable to only draw end note branche names with textplot;
   all_parents="";
end;
else do;
   *These higher tree branches will be annotated using drawtext based on right_xpos;
   _all_parents="";
end;
run;
/*%abort 255;*/
*Prepare macro vars for drawtext;
proc sql noprint;
select left(put(count(*),best12.)) into: tot_higher_branches 
from &outdsd
where _all_parents^="";
select _all_parents  into:hblabel1-:hblabel&tot_higher_branches
from &outdsd
where _all_parents^="";
select right_xpos into: rx1-:rx&tot_higher_branches
from &outdsd
where _all_parents^="";
select new_height into: rh1-:rh&tot_higher_branches
from &outdsd
where _all_parents^="";

/*proc print data=ab_res; run;*/
proc template;
   define statgraph HeatDendrogram1;
    begingraph;
            layout overlay / walldisplay=none;
               dendrogram nodeID=&y_name_var parentID=&y_parent_var clusterheight=&y_height_var;
/*This does not work well, and try to use drawtext statement;*/
               textplot x=new_child y=eval(new_height*1.02) text=all_parents/;
			   %do _di_=1 %to &tot_higher_branches;
			       /*%if &_di_=1 %then %let rx&_di_=43;*/
				   /*As CL1 will be always in the middle, substracting 5 pct offset on left and righ of the figure*/ 
				   drawtext "&&hblabel&_di_" / XSPACE=DATAPERCENT YSPACE=DATAVALUE
                                  x=&&rx&_di_ y=&&rh&_di_;
			   %end;
			 endlayout;
	endgraph;
end;
run;

/*proc print;run;*/
proc sgrender data=&outdsd template=HeatDendrogram1;
run;

proc datasets nolist;
/*delete Ab_res Ab_res1 _tmpdsd_ _right_height_dsd_;*/
run;

%mend;
/*Demo codes:;
data a;
input child :$200. parent :$200. hh;
cards;
NG_MYH11__CBFB	CL7	0
NTU_MYH11__CBFB	CL7	0
NG_KMT2Ar	CL6	0
NTU_KMT2Ar	CL6	0
NG_APL	CL5	0
NTU_APL	CL5	0
NG_RUNX1__RUNX1T1	CL4	0
NTU_RUNX1__RUNX1T1	CL4	0
NTU_fake	CL100 0
CL5	CL3	0.48486
CL6	CL3	0.36378
CL3	CL2	0.90933
CL4	CL2	0.50744
CL2	CL1	1.12322
CL7	CL1	0.25102
CL1	 .	1.60468
;
ods graphics on/reset=all width=1000 height=600;
%review_tree_branches(
inputdsd=a,
y_name_var=child,
y_parent_var=parent,
y_height_var=hh,
outdsd=out,
branch_name_dsd=branch_name_dsd 
);

%subbranches(
    data=a,  
	y_name_var=child,
	y_parent_var=parent,
	y_height_var=hh,
    out=work.sub,  
    height=,  
    parent=CL2, 
    render=YES 
    );

%review_tree_branches(
inputdsd=sub,
y_name_var=child,
y_parent_var=parent,
y_height_var=hh,
outdsd=out1,
branch_name_dsd=branch_name_dsd1 
);

*/

