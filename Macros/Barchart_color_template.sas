%macro Barchart_color_template(colors,temp_out);
/*https://support.sas.com/rnd/base/ods/templateFAQ/Template_colors.html*/
/*BLACK	#FFFFFF*/
/*BLUE	#0000FF*/
/*YELLOW	#FFF00*/
/*BLUE VIOLET	#9F5F9F*/
/*BROWN	#A62A2A*/
/*CADET BLUE	#5F9F9F*/
/*DARK BROWN	#5C4033*/
/*DARK PURPLE	#871F78*/
/*DUSTY ROSE	#856363*/
/*GOLD	#CD7F32*/
/*KHAKI	#9F9F5F*/
/*NAVY BLUE	#23238E*/
/*PINK	#BC8F8F*/
/*SILVER	#E6E8FA*/
/*TURQUOISE	#ADEAEA*/
/*RED	#FF0000*/
/*MAGENTA	#FF00FF*/
/*BLACK	#000000*/
/*BRASS	#B5A642*/
/*BRONZE	#8C7853*/
/*COPPER	#B87333*/
/*DARK GREEN	#2F4F2F*/
/*DARK TAN	#97694F*/
/*FIREBRICK	#8E2323*/
/*GREY	#C0COCO*/
/*LIME GREEN	32CD32*/
/*ORANGE	#FF7F00*/
/*PLUM	#EAADEA*/
/*STEEL BLUE	#236B8E*/
/*VIOLET	#4F2F4F*/
/*GREEN	#00FF00*/
/*CYAN	#00FFFF*/
/*AQUAMARINE	#70DB93*/
/*BRIGHT GOLD	#D9D919*/
/*BRONZE II	#A67D3D*/
/*CORAL	#FF7F00*/
/*DARK WOOD	#855E42*/
/*DIM GREY	#545454*/
/*FOREST GREEN	#238E23*/
/*INDIAN RED	#4E2F2F*/
/*MAROON	#8E236B*/
/*ORCHARD	#DB70DB*/
/*SCARLET	#8C1717*/
/*TAN	#DB9370*/
/*WHEAT	#D8D8BF*/

%let n_colors=%numargs(&colors);
/*ODS PATH work.templat(update) sashelp.tmplmst(read);*/
/*default is listing*/
proc template;
 define style &temp_out;
 parent = styles.default;
 %if &colors ne %then %do;
  %do i=1 %to &n_colors;
   %let color=%scan(&colors,&i,%str( ));
   class GRAPHDATA&i /
   color=%upcase(&color);
  %end;
 %end;
 %else %do;
 class GRAPHDATA1 /      
 color=CX445694; /* g1 */
 class GRAPHDATA2 /      
 color=CXa23a2e; /* g2*/ 
 class GRAPHDATA3 /      
 color=CX01665e; /* g3*/ 
 class GRAPHDATA4 /      
 color=CX8CA6CE; /* g4*/ 
                         
 class GRAPHDATA5 /      
 color=CX9d3cdb; /* g5 */
 class GRAPHDATA6 /      
 color=CX7f8e1f; /* g6*/ 
 class GRAPHDATA7 /      
 color=CX2597fa; /* g7*/ 
 class GRAPHDATA8 /      
 color=CXb26084; /* g8*/ 
                         
 class GRAPHDATA9 /      
 color=CXd17800; /* g9 */
 class GRAPHDATA10 /     
 color=CX47a82a; /* g10*/
 class GRAPHDATA11 /     
 color=CXb38ef3; /* g11*/
 class GRAPHDATA12 /     
 color=CXf9da04; /* g12*/
 %end;
 END;
%mend;

/*make sure to use ods _all_ close;*/

/*
options mprint mlogic symbolgen;

*%Barchart_color_template(colors=CX445694 CXa23a2e CX01665e CX8CA6CE CX9d3cdb CX7f8e1f CX2597fa CXb26084 CXd17800 CX47a82a CXb38ef3 CXf9da04,temp_out=blockstyle);

%Barchart_color_template(colors=CX445694 CXdd988f CX01665e CX8da7cd CX9d3cdb CX7f8e1f CX2597fa CXb26084 CXd17800 CX47a82a CXb38ef3 CXf9da04,
                         temp_out=blockstyle);

ODS listing style=blockstyle;

 data a;
 do i=1 to 12;
 x=10;
 output;
 end;
 run;

proc template;
define statgraph Graph;
dynamic _I _X _I2;
begingraph;
   layout lattice / rowdatarange=data columndatarange=data rowgutter=10 columngutter=10;
      layout overlay / walldisplay=none yaxisopts=(reverse=true discreteopts=( tickvaluefitpolicy=none));
         barchart category=_I response=_X / group=_I2 name='bar_h' display=(FILL) stat=mean orient=horizontal outlineattrs=(color=CXFFFFFF) barwidth=1.0 groupdisplay=Cluster clusterwidth=1;
      endlayout;
   endlayout;
endgraph;
end;
run;

options printerpath=svg;
ods listing close;
ods printer style=blockstyle;

proc sgrender data=WORK.A template=Graph;
dynamic _I="I" _X="X" _I2="I";
run;

ods printer close;
ods listing;

*/

