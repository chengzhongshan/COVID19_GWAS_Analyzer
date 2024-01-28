%macro boxgrpdisplaysetting(
boxwidth=0.8,
by_cluster=1 /*If boxplots are not plotted in sgpanel by subgrps, such proc sgplot, please provide value 0 to draw boxplot not in cluster*/
);
%if &by_cluster=1 %then %do;

%str(
groupdisplay=cluster boxwidth=&boxwidth fillattrs=(transparency=0.5) 
whiskerattrs=(pattern=2 thickness=2)
meanattrs=(symbol=circlefilled color=darkgreen size=5)
);

%end;
%else %do;

%str(
boxwidth=&boxwidth fillattrs=(transparency=0.5) 
whiskerattrs=(pattern=2 thickness=2)
meanattrs=(symbol=circlefilled color=darkgreen size=5)
);

%end;

%mend;
/*Demo:;

*Note: sort=ASCMEAN will sort the boxplot grps by mean;

ods graphics on/ reset=all width=500 height=800 noborder;

proc sgpanel data=exp;
where prxmatch("/(Apobec3|gapdh)/i",genesymbol);
panelby grp/columns=2 onepanel novarname uniscale=column 
headerattrs=(size=8 family=arial style=normal) sort=ASCMEAN ;

vbox exp/group=pop %boxgrpdisplaysetting;

run;

*For dataset without subgrps;
*Need to add category for labeling boxplots!;

ods graphics on/ reset=all width=1000 height=600 noborder;
proc sgplot data=uniq_snps_cnts;
vbox count/group=celltype category=celltype %boxgrpdisplaysetting(by_cluster=0);
run;


*/
