%macro mkfmt4grpsindsd(
targetdsd,
grpvarintarget,
name4newfmtvar,
fmtdsd,
grpvarinfmtdsd,
byvarinfmtdsd,
finaloutdsd
);

*apply informat and format to sort panel by a;
*see differences between informat and format:;
*https://documentation.sas.com/doc/en/pgmsascdc/v_010/proc/p06ciqes4eaqo6n0zyqtz9p21nfb.htm;
*informat is actually change how data are stored and read.;
*format modify how data are printed;
*Add random num to format name to avoid of crushing of formats;
%local rnd;
%let rnd=%randombetween(1, 100);
%mkfmt4grps_by_var(
grpdsd=&fmtdsd,
grp_var=&grpvarinfmtdsd,
by_var=&byvarinfmtdsd,
outfmt4numgrps=nums2grps&rnd._,
outfmt4chargrps=grps2nums&rnd._
);

data &finaloutdsd;
set &targetdsd;
*format char grps to numeric grps;
&name4newfmtvar=input(&grpvarintarget,nums2grps&rnd._.);
run;

data &finaloutdsd;
set &finaloutdsd;
attrib &name4newfmtvar format=grps2nums&rnd._.;
run;

%mend;

/*Demo:
data g;
input x $ y;
cards;
a 1
d 2
c 3
b 4
e 5
;
data x;
input a $ b c;
cards;
a 10 1
b 40 2
c 100 3
d 10 4
e 40 5
a 10 1
b 50 2
c 100 3
d 10 4
e 40 5
;

proc sgpanel data=x;
panelby a/rows=1 onepanel novarname;
scatter x=b y=c;
run;

*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

*apply format to sort panel by a;
%mkfmt4grpsindsd(
targetdsd=x,
grpvarintarget=a,
name4newfmtvar=new_a,
fmtdsd=g,
grpvarinfmtdsd=x,
byvarinfmtdsd=y,
finaloutdsd=x1
);

*Note: CAN apply format for the same dataset, targetdsd and fmtdsd;
%mkfmt4grpsindsd(
targetdsd=x,
grpvarintarget=a,
name4newfmtvar=new_a,
fmtdsd=x,
grpvarinfmtdsd=a,
byvarinfmtdsd=c,
finaloutdsd=x1
);

proc sgpanel data=x1;
*format back numeric grps back to characters;
panelby new_a/rows=1 onepanel novarname;
scatter x=b y=c;
run;

%heatmap4longformatdsd(
dsdin=x1,
xvar=b,
yvar=new_a,
colorvar=c,
fig_height=400,
fig_width=400,
outline_thickness=4,
user_yvarfmt=,
user_xvarfmt=
);


*/


