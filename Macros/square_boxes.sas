%macro square_boxes(
inputdsd=_last_,
x=x, /*x-axis variable*/
y1=y1, /*y position 1 with the same x position as y position 2*/
y2= ,/*y position 2; if y2 is empty, y1+width will be used as y2*/ 
width=0.5, /*width for the square from (x,y1) to (x,y2)*/
outdsd=out,/*output dsd for making square with proc sgplot polygon statement*/
plot_it=0 /*Evaluate the squares using proc sgplot in current macro*/
);
     /* build polygon points for one square per observation
           Use vertical distance between &y1 and &y2 as the base side length;
           &width is treated as a multiplier (use 1 to keep the raw y-distance) */
	data _boxes_;
	set &inputdsd;
	%if %length(&y2)=0 %then %let y2=y2;
    %if  %varexist(ds=&inputdsd,var=&y2)=0 %then %do;
     &y2=&y1+&width;
     %end;
     data _boxes_;
          set _boxes_;
          id = _n_;
          length polyid $32;
          len = abs(&y2 - &y1) * (&width);
          half = len / 2;

          polyid = cats(id,'_sq');
          cx = &x;
          cy = (&y1 + &y2) / 2;

          /* four corners (closed polygon) */
          _x_ = cx - half; _y_ = cy - half; order = 1; output;
          _x_ = cx + half; _y_ = cy - half; order = 2; output;
         _x_ = cx + half; _y_ = cy + half; order = 3; output;
         _x_ = cx - half; _y_ = cy + half; order = 4; output;
          _x_ = cx - half; _y_ = cy - half; order = 5; output;

          keep polyid _x_ _y_ order id;
     run;

     proc sort data=_boxes_ out=&outdsd; by polyid order; run;
	 %if &plot_it=1 %then %do;
     proc sgplot data=_boxes_;
          polygon x=_x_ y=_y_ id=id / fill fillattrs=(transparency=0.25 color=lightred) lineattrs=(color=black);
          keylegend;
     run;
	 %end;
%mend square_boxes;

/*Demo codes:;

data have;
  input x y1 y2;
  datalines;
3 1  3
5 4  2
;
run;
%debug_macro;

%square_boxes(
inputdsd=have,
x=x, 
y1=y1, 
y2= , 
width=0.25,
outdsd=out,
plot_it=1
);

*/
