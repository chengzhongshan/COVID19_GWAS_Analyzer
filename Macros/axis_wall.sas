%macro axis_wall;

proc template ;
 define style axis_wall;
 parent=styles.journal2;
 style graphwalls from graphwalls /
   frameborder=off
   linestyle=1
   linethickness=2px
   backgroundcolor=GraphColors("gwalls")
   contrastcolor= black;
 style graphaxislines from graphaxislines /
   linestyle=1
   linethickness=2px
   contrastcolor=black;

 /*change fonts, need further revision*/
/* replace GraphFonts /*/
/*  'GraphDataFont' = ("sans-serif",12pt);*/

 end;
run; 

ods html style=axis_wall;

%mend;
