%macro boxgrpdisplaysetting(
boxwidth=0.8
);

%str(
groupdisplay=cluster boxwidth=&boxwidth fillattrs=(transparency=0.5) 
whiskerattrs=(pattern=2 thickness=2)
meanattrs=(symbol=circlefilled color=darkgreen size=5)

);

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

*/