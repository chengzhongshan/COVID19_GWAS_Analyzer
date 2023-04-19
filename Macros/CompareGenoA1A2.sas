%macro CompareGenoA1A2(dsdin,Avarname1,Avarname2,Bvarname1,Bvarname2,dsdout);
data &dsdout (drop=g1_ g2_ gg1_ gg2_ g1__tr g2__tr);
set &dsdin;
g1_=compress(&Avarname1);
g2_=compress(&Avarname2);
gg1_=compress(&Bvarname1);
gg2_=compress(&Bvarname2);
g1__tr=translate(g1_,"ACGTacgt","TGCAtgca");
g1__tr=reverse(g1_tr);
g2__tr=translate(g2_,"ACGTacgt","TGCAtgca");
g2__tr=reverse(g2__tr);
tag=0;
if catx(g1_,g2_)=catx(gg1_,gg2_) or
   catx(g1_,g2_)=catx(gg2_,gg1_) or
   catx(g1__tr,g2__tr)=catx(gg1_,gg2_) or
   catx(g1__tr,g2__tr)=catx(gg2_,gg1_) then tag=1;
run;

%mend CompareGenoA1A2;

/*Demo:

data a;
input A1 $ A2 $ B1 $ B2 $;
cards;
A G x T
A T A T
C C G G
;


options mprint mlogic symbolgen;

*Note:A1 and A2 will be combined and compared with the ALL combination of B1 and B2;

%CompareGenoA1A2(a,A1,A2,B1,B2,b);

*/
