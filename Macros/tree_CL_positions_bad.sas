%macro tree_CL_positions_bad(
 /*The macro will get avg positions of all end leaves of each brach, which is not what is used by SAS
to draw dendrogram. In fact, the two 1st degree sub-branches of each non-end-leaf branches are used
to draw the middle position for each non-end-leaf branches! Please use a better macro, called
tree_CL_positions to get relation postions based on the order of end-leaf branches
But the macro uses do while to recursively search for parent-leaf branches, which is useful
for learning SAS codes*/
     data=,    /* input hierarchical cluster output */
     child=child,
     parent=parent,
     hh=hh,
     root=CL1,
     order=ASC,
     outds=CL_Positions,    /* output: CL node positions (name, pos) */
     parent_ds=parent_list   /* output: parent -> children list (strings) */
);

     /* 0) local names */
     %local changed n_combined n_desc;

     /* 1) copy input and get leaf order using your treeorder macro
                    use a temporary name for the leaf-order output to avoid clobbering &outds */
     data _tmpdsd_;
          set &data;
     run;

     %treeorder(
          data=_tmpdsd_,
          child=&child,
          parent=&parent,
          hh=&hh,
          root=&root,
          order=&order,
          outds=_leaf_order
     );

     /* 2) build edges (parent-child) and initial descendant table from leaves */
     proc sql noprint;
          create table _edges as
          select strip(&parent) as parent, strip(&child) as child
          from _tmpdsd_
          ;
          create table _desc as
          select strip(name) as node, strip(name) as leaf, order as pos
          from _leaf_order
          ;
     quit;

     /* 3) iteratively propagate descendant-leaf membership up the tree
                until no more (parent,leaf) pairs are added */
     %let changed = 1;
     %do %while(&changed);
          proc sql noprint;
               /* new parent->leaf rows by joining edges to already-known node->leaf mappings */
               create table _new as
               select strip(e.parent) as node, d.leaf, d.pos
               from _edges e
               inner join _desc d
               on strip(e.child)=strip(d.node)
               ;
               /* combine distinct rows */
               create table _combined as
               select distinct node, leaf, pos
               from _desc
               union
               select distinct node, leaf, pos
               from _new
               ;
               select count(*) into :n_combined trimmed from _combined;
               select count(*) into :n_desc trimmed from _desc;
          quit;

          %if %eval(&n_combined > &n_desc) %then %do;
               data _desc; set _combined; run;
               %let changed = 1;
          %end;
          %else %let changed = 0;
     %end;
/*	 %abort 255;*/
     /* 4) compute numeric position for every node as midpoint of its leftmost and rightmost leaf positions
                (this gives the branch position determined from its two sub-branch extents) */
     proc sql noprint;
          create table _positions as
          select node as name,
                          min(pos) as minpos,
                          max(pos) as maxpos,
                          (calculated minpos + calculated maxpos)/2 as pos
          from _desc
          group by node
          ;
     quit;

     /* 5) output only nodes that act as parents in the original tree (internal nodes),
                but also include leaves if desired (here we include all nodes that appear as parent) */
     proc sql;
          create table &outds as
          select p.name, p.pos
          from _positions p
          inner join (select distinct parent from _edges where parent is not null and strip(parent) ne '') e
          on strip(p.name)=strip(e.parent)
          order by p.pos
          ;
     quit;


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
CL5	CL3	0.48486
CL6	CL3	0.36378
CL3	CL2	0.90933
CL4	CL2	0.50744
CL2	CL1	1.12322
CL7	CL1	0.25102
CL1	 .	1.60468
;

%tree_CL_positions_bad(
data=a, 	
child=child, 
parent=parent, 
hh=hh, 
root=CL1, 
order=ASC, 
outds=CL_Positions, 
parent_ds=parent_list
);
*/
