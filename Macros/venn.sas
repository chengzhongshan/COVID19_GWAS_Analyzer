/* The main macro to produce the graphic */

%macro venn( data =
            ,venn_diagram =              /* Select whether you want a 2 Way, 3 Way or 4 Way Venn Diagram
			                                    EG for 2 way enter 2.  Valid values are 2,3 and 4 */
            ,cutoff =              /* Set the P Value cut-off or any other appropriate cut off
			                                    Valid values are the right hand side of an if statement */
            ,GroupA =                      /* Define group name 1, mandatory */
			,GroupB =                   /* Define group name 2, mandatory */
			,GroupC =             /* Define group name 3, mandatory for 3 and 4 way diagrams */
			,GroupD =                 /* Define group name 4, mandatory for 4 way diagrams */
			,out_location = /* Define the path for all output files e.g. C:/Venn Diagrams */
			,outputfilename = Venn diagram   /* Define the filename for the graphic file */
			,drilldownfilename = Drilldown   /* Define the filename for the drill down data file */
            );


/* First specify the GOPTIONS for the diagram */
  goptions RESET=ALL 
          device=png 
         gsfname=outfile 
           FTEXT="Arial" 
         gsfmode=replace 
           hsize=8in
           vsize=6in 
          border
          colors=(black, red, green, yellow, blue, magneta, cyan, orange)
         XPIXELS=800
         ypixels=600 ;

/* Set the graphics file output file name */
filename outfile "&out_location/&outputfilename..png";

/* Specify the output file name for the HTML file containing the image map */
filename html "&out_location/&outputfilename..html";

/* Specify the output file name for the HTML file containinf the drill-down data*/
filename table "&out_location/&drilldownfilename..html";

/* Calculate the category for each observation in the dataset
   This has to be done differently for 2,3 and 4 way diagrams */

data data_reformatted;
  set &data;
run;

  /* Counting the overlap */

  data data_reformatted2;
    set data_reformatted;

	%IF &venn_diagram = 2 %THEN %DO;

      if A ne . and B ne . then do;
	    if A  &cutoff and B  &cutoff then AB = 1;
	    else AB = 0; 
      end;

      if A ne . then do;
	    if A  &cutoff and AB ne 1 then A1 = 1; else A1 = 0;
      end;

      if B ne . then do;
	    if B  &cutoff and AB ne 1 then B1 = 1; else B1 = 0;
      end;

	%end;

	%ELSE %IF &venn_diagram = 3 %THEN %DO;

      if A ne . and B ne . and C ne . then do;
	    if A  &cutoff and B  &cutoff and C  &cutoff then ABC = 1;
	    else ABC = 0;
      end;

      if A ne . and B ne . then do;
	    if A  &cutoff and B  &cutoff and ABC ne 1 then AB = 1;
	    else AB = 0; 
      end;
	 
      if A ne . and C ne . then do;
	    if A  &cutoff and C  &cutoff and ABC ne 1 then AC = 1;
	    else AC = 0; 
      end;

      if B ne . and C ne . then do;
	    if B  &cutoff and C  &cutoff and ABC ne 1 then BC = 1;
	    else BC = 0; 
      end;

      if A ne . then do;
	    if A  &cutoff and AB ne 1 and AC ne 1 and ABC ne 1 then A1 = 1; else A1 = 0;
      end;

      if B ne . then do;
	    if B  &cutoff and AB ne 1 and BC ne 1 and ABC ne 1 then B1 = 1; else B1 = 0;
      end;

      if C ne . then do;
	    if C  &cutoff and AC ne 1 and BC ne 1 and ABC ne 1 then C1 = 1; else C1 = 0;
      end;

	%END;

	%ELSE %IF &venn_diagram=4 %THEN %DO;

      if A ne . and B ne . and C ne . and D ne . then do;
	    if A  &cutoff and B  &cutoff and C  &cutoff and D  &cutoff then ABCD = 1;
	    else ABCD = 0;
      end;

      if A ne . and B ne . and C ne . then do;
	    if A  &cutoff and B  &cutoff and C  &cutoff and ABCD ne 1 then ABC = 1;
	    else ABC = 0;
      end;

      if A ne . and B ne . and D ne . then do;
	    if A  &cutoff and B  &cutoff and D  &cutoff and ABCD ne 1 then ABD = 1;
	    else ABD = 0;
      end;

      if A ne . and C ne . and D ne . then do;
	    if A  &cutoff and C  &cutoff and D  &cutoff and ABCD ne 1 then ACD = 1;
	    else ACD = 0;
      end; 

      if B ne . and C ne . and D ne . then do;
	    if B  &cutoff and C  &cutoff and D  &cutoff and ABCD ne 1 then BCD = 1;
	    else BCD = 0;
      end;

      if A ne . and B ne . then do;
	    if A  &cutoff and B  &cutoff and ABC ne 1 and ABD ne 1 and ABCD ne 1 then AB = 1;
	    else AB = 0; 
      end;

      if A ne . and C ne . then do;
	    if A  &cutoff and C  &cutoff and ABC ne 1 and ACD ne 1 and ABCD ne 1 then AC = 1;
	    else AC = 0; 
      end;

      if A ne . and D ne . then do;
	    if A  &cutoff and D  &cutoff and ABD ne 1 and ACD ne 1 and ABCD ne 1 then AD = 1;
	    else AD = 0; 
      end;

      if B ne . and C ne . then do;
	    if B  &cutoff and C  &cutoff and ABC ne 1 and BCD ne 1 and ABCD ne 1 then BC = 1;
	    else BC = 0; 
      end;

      if B ne . and D ne . then do;
	    if B  &cutoff and D  &cutoff and ABD ne 1 and BCD ne 1 and ABCD ne 1 then BD = 1;
	    else BD = 0; 
      end;

      if C ne . and D ne . then do;
	    if C  &cutoff and D  &cutoff and ACD ne 1 and BCD ne 1 and ABCD ne 1 then CD = 1;
	    else CD = 0; 
      end;

      if A ne . then do;
	    if A  &cutoff and AB ne 1 and AC ne 1 and AD ne 1 and ABC ne 1 and ABD ne 1 and ACD ne 1
	      and ABCD ne 1 then A1 = 1; else A1 = 0;
      end;

      if B ne . then do;
	    if B  &cutoff and AB ne 1 and BC ne 1 and BD ne 1 and ABC ne 1 and ABD ne 1 and BCD ne 1
	      and ABCD ne 1 then B1 = 1; else B1 = 0;
      end;

      if C ne . then do;
	    if C  &cutoff and AC ne 1 and BC ne 1 and CD ne 1 and ABC ne 1 and ACD ne 1 and BCD ne 1
	      and ABCD ne 1 then C1 = 1; else C1 = 0;
      end;

      if D ne . then do;
	    if D  &cutoff and AD ne 1 and BD ne 1 and CD ne 1 and ABD ne 1 and ACD ne 1 and BCD ne 1
	      and ABCD ne 1 then D1 = 1; else D1 = 0;
      end;

	%END;

  run;

  /*
  COUNTING THE ELEMENTS IN EACH GROUP 
  After the Macro identifies the elements in each group it uses PROC UNIVARIATE
  to sum up the number of elements in each group.
  The total number of element within the diagram i.e. the union of Groups A, B, C, 
  and D, and the total number of elements in the dataset i.e. the universal set are 
  then calculated. This is used to identify the number of elements that fall outside the union. 
  */

  proc univariate data = Data_reformatted2 noprint;
    var AB A1 B1
      %if &venn_diagram > 2 %then %do;
         ABC AC BC C1
	  %end;

	  %if &venn_diagram > 3 %then %do;
	     ABCD ABD ACD BCD AD BD CD D1
	  %end;
      ;

    output out = data_sum sum = sum_AB sum = sum_A1 sum = sum_B1
      %if &venn_diagram > 2 %then %do;
	     sum = sum_ABC sum = sum_AC sum = sum_BC sum = sum_C1
	  %end;
      
	  %if &venn_diagram > 3 %then %do;
	     sum = sum_ABCD sum = sum_ABD sum = sum_ACD 
         sum = sum_BCD sum = sum_AD sum = sum_BD 
         sum = sum_CD sum = sum_D1
	  %end;
	  ;
  run;

  /* Counting the number in the universal set */

  proc sql noprint;
    create table id_count as
    select count(id) as count_id
    from data_reformatted;
  quit;

  /* Counting the number inside the union */

  data data_sum2;
    set data_sum;
    totalinside = sum(sum_AB, sum_A1, sum_B1
      %if &venn_diagram > 2 %then %do;
        ,sum_ABC, sum_AC, sum_BC, sum_C1
	  %end;

	  %if &venn_diagram > 3 %then %do;
	    ,sum_ABCD, sum_ABD, sum_ACD, sum_BCD, sum_AD, 
         sum_BD, sum_CD, sum_D1
	  %end;
     );
  run;

    /*
  COUNTING THE ELEMENTS THAT FALL OUTSIDE OF THE UNION
  Using the fetch function the values of the total number of elements within the 
  union and the universal set are fetched from the appropriate datasets and assigned 
  to a macro-variable. The total number of elements that fall outside the diagram is 
  then calculated by using %eval to evaluate the arithmetic expression of the number 
  of elements in the universal set - the number of elements within the union.  
  */

  /* Calculating the total number of unique ids - so that I can calculate
     the number that falls outside of the groups*/

  %let dsid=%sysfunc(open(id_count,i));
  %let num_TN=%sysfunc(varnum(&dsid,count_id));
  %let rc=%sysfunc(fetch(&dsid,1));
  %let TN=%sysfunc(getvarn(&dsid,&num_TN));
  %let rc=%sysfunc(close(&dsid));

  /* Calculating the total number of values that fall within the groups */
  %let dsid=%sysfunc(open(data_sum2,i));
  %let num_TI=%sysfunc(varnum(&dsid,totalinside));
  %let rc=%sysfunc(fetch(&dsid,1));
  %let TI=%sysfunc(getvarn(&dsid,&num_TI));
  %let rc=%sysfunc(close(&dsid));

  /* Calculating the total numbers that fall outside all of the groups */

  %let TO = %eval(&TN - &TI);

  /* Assigning the sums to macro variables */

  %let dsid=%sysfunc(open(data_sum2,i));
  %let num_A1=%sysfunc(varnum(&dsid,sum_A1));
  %let rc=%sysfunc(fetch(&dsid,1));
  %let A=%sysfunc(getvarn(&dsid,&num_A1));
  %let rc=%sysfunc(close(&dsid));

  %let dsid=%sysfunc(open(data_sum2,i));
  %let num_B1=%sysfunc(varnum(&dsid,sum_B1));
  %let rc=%sysfunc(fetch(&dsid,1));
  %let B=%sysfunc(getvarn(&dsid,&num_B1));
  %let rc=%sysfunc(close(&dsid));

  %let dsid=%sysfunc(open(data_sum2,i));
  %let num_AB=%sysfunc(varnum(&dsid,sum_AB));
  %let rc=%sysfunc(fetch(&dsid,1));
  %let AB=%sysfunc(getvarn(&dsid,&num_AB));
  %let rc=%sysfunc(close(&dsid));

  %if &venn_diagram > 2 %then %do;

    %let dsid=%sysfunc(open(data_sum2,i));
    %let num_C1=%sysfunc(varnum(&dsid,sum_C1));
    %let rc=%sysfunc(fetch(&dsid,1));
    %let C=%sysfunc(getvarn(&dsid,&num_C1));
    %let rc=%sysfunc(close(&dsid));

	%let dsid=%sysfunc(open(data_sum2,i));
    %let num_AC=%sysfunc(varnum(&dsid,sum_AC));
    %let rc=%sysfunc(fetch(&dsid,1));
    %let AC=%sysfunc(getvarn(&dsid,&num_AC));
    %let rc=%sysfunc(close(&dsid));

    %let dsid=%sysfunc(open(data_sum2,i));
    %let num_BC=%sysfunc(varnum(&dsid,sum_BC));
    %let rc=%sysfunc(fetch(&dsid,1));
    %let BC=%sysfunc(getvarn(&dsid,&num_BC));
    %let rc=%sysfunc(close(&dsid));

    %let dsid=%sysfunc(open(data_sum2,i));
    %let num_ABC=%sysfunc(varnum(&dsid,sum_ABC));
    %let rc=%sysfunc(fetch(&dsid,1));
    %let ABC=%sysfunc(getvarn(&dsid,&num_ABC));
    %let rc=%sysfunc(close(&dsid));
  %end;

  %if &venn_diagram > 3 %then %do;

    %let dsid=%sysfunc(open(data_sum2,i));
    %let num_D1=%sysfunc(varnum(&dsid,sum_D1));
    %let rc=%sysfunc(fetch(&dsid,1));
    %let D=%sysfunc(getvarn(&dsid,&num_D1));
    %let rc=%sysfunc(close(&dsid));

	%let dsid=%sysfunc(open(data_sum2,i));
    %let num_AD=%sysfunc(varnum(&dsid,sum_AD));
    %let rc=%sysfunc(fetch(&dsid,1));
    %let AD=%sysfunc(getvarn(&dsid,&num_AD));
    %let rc=%sysfunc(close(&dsid));

    %let dsid=%sysfunc(open(data_sum2,i));
    %let num_BD=%sysfunc(varnum(&dsid,sum_BD));
    %let rc=%sysfunc(fetch(&dsid,1));
    %let BD=%sysfunc(getvarn(&dsid,&num_BD));
    %let rc=%sysfunc(close(&dsid));

    %let dsid=%sysfunc(open(data_sum2,i));
    %let num_CD=%sysfunc(varnum(&dsid,sum_CD));
    %let rc=%sysfunc(fetch(&dsid,1));
    %let CD=%sysfunc(getvarn(&dsid,&num_CD));
    %let rc=%sysfunc(close(&dsid));

    %let dsid=%sysfunc(open(data_sum2,i));
    %let num_ABD=%sysfunc(varnum(&dsid,sum_ABD));
    %let rc=%sysfunc(fetch(&dsid,1));
    %let ABD=%sysfunc(getvarn(&dsid,&num_ABD));
    %let rc=%sysfunc(close(&dsid));

    %let dsid=%sysfunc(open(data_sum2,i));
    %let num_ACD=%sysfunc(varnum(&dsid,sum_ACD));
    %let rc=%sysfunc(fetch(&dsid,1));
    %let ACD=%sysfunc(getvarn(&dsid,&num_ACD));
    %let rc=%sysfunc(close(&dsid));

    %let dsid=%sysfunc(open(data_sum2,i));
    %let num_BCD=%sysfunc(varnum(&dsid,sum_BCD));
    %let rc=%sysfunc(fetch(&dsid,1));
    %let BCD=%sysfunc(getvarn(&dsid,&num_BCD));
    %let rc=%sysfunc(close(&dsid));

    %let dsid=%sysfunc(open(data_sum2,i));
    %let num_ABCD=%sysfunc(varnum(&dsid,sum_ABCD));
    %let rc=%sysfunc(fetch(&dsid,1));
    %let ABCD=%sysfunc(getvarn(&dsid,&num_ABCD));
    %let rc=%sysfunc(close(&dsid));

  %end;

  /* The rest of the macro needs to be done seperately for 2, 3 and 4 
     way plots */

  /*************** 2 WAY VENN DIAGRAMS ***************/


  %if &venn_diagram=2 %then %do;

  /*
  DRAWING THE VENN DIAGRAMS
  Data Step Graphics Interface (DSGI) was used to draw the Venn diagrams. 
  The GSET function was used to set the Line Colour and the Line Weight of 
  the Venn Diagram Ellipse. For example the first ellipse is Hollow with a Red 
  Outline. The GDRAW function is used to draw the ellipse. The syntax for the 
  hollow ellipse is: return-code-variable = GDRAW('ELLARC', x, y, major, minor, 
  start, end, angle)

  The argument definitions of the first ellipse are that is has an origin of 
  (80, 50 (+ offset)) with a length of 160 and a width of 60, it is 360 degrees 
  and has an angle of 50 degrees.
  */

  /* Drawing the Ellipse Plots with the Counts */
  /* Offsetting the graphs so that they line up correctly */


    %let xoffset = + 16;
    %let yoffset = + 15;

    DATA _NULL_;
      /*Initialize DSGI*/
      RC = GINIT ();
      /*Open a graphic segment*/
      RC = GRAPH ('CLEAR');

	  /* First Circle */
      RC = GSET ('LINWIDTH', 2);
      /*No. 2 color, Red*/
      RC = GSET ('LINCOLOR', 2);

      /*Draw a Hollow Red Circle, from 0 to 360 degree at coordinate (35, 35) with radius 25*/
      RC = GDRAW ('ARC', 35 &xoffset, 35 &yoffset, 25, 0, 360);

      /* Second Circle */
      /*No. 3 color, Green*/
      RC = GSET ('LINCOLOR', 3);

      /*Draw a Hollow Green, from 0 to 360 degree at coordinate (65, 35) with radius 25*/
      RC = GDRAW ('ARC', 65 &xoffset, 35 &yoffset, 25, 0, 360);

      /* Text */

      RC = GSET ('TEXHEIGHT', 3);
      /*Set up text font as HWPSL009*/
      *RC = GSET('TEXFONT', 'HWPSL009');
      /*Write down text, "&GroupA" starting from coordinate, (28, 60)*/

      RC =GSET('TEXCOLOR', 2);
      RC = GDRAW ('TEXT', 10 &xoffset, 7 &yoffset, "&GroupA"); 
      RC =GSET('TEXCOLOR', 3);
      RC = GDRAW ('TEXT', 75 &xoffset, 7 &yoffset, "&GroupB");
      RC =GSET('TEXCOLOR', 8);
      RC = GDRAW ('TEXT', 48 &xoffset, 3 &yoffset, "&TO  - Outside Union");
      RC =GSET('TEXCOLOR', 1);
      RC = GDRAW ('TEXT', 25 &xoffset, 35 &yoffset, "&A");
      RC = GDRAW ('TEXT', 70 &xoffset, 35 &yoffset, "&B");

	  /* Intersects */
      RC = GSET ('TEXHEIGHT', 3);
      *RC = GSET('TEXFONT', 'Zapf');
      RC = GDRAW ('TEXT', 49 &xoffset, 35 &yoffset, "&AB");
      RC = GRAPH ('UPDATE');

	  /*Terminate DSGI*/
      RC = GTERM ();
    RUN; 

  /*
  CREATING THE AREAS FOR DRILLING DOWN
  Put statements were used to create HTML image maps that specify areas 
  around the numbers in each group of the Venn diagram. When the area is 
  selected it is linked to the elements that make up the group.

  Elaborating on the method it shows that in the BODY of the HTML 
  file the IMG tag is used to reference the output graph file and to define 
  which image map to use, in this case fourvenn. The MAP tag defines the image map, and 
  inside the AREA tag specifies the coordinates of the clickable area and the file to
  link it to once the area is selected.  
  */

    /* Drilling down */
    /* Specifying the regions */

    data _null_;
      file html;
      put '<HTML>';
      put '<BODY>';
      put '<style type="text/css">';
      put 'body{font-family: arial;}';
      put '</style>';
      put '<P align="center"><IMG SRC="'"&out_location/&outputfilename..png"'" usemap = "#twovenn" />' ; 
      put '<map id ="twovenn" name="twovenn">';
      put '<area shape ="rect" coords ="172,353,297,195" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor"'"/>';
      put '<area shape ="rect" coords ="451,341,564,220" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor1"'"/>';
      put '<area shape ="rect" coords ="338,341,408,220" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor2"'"/>';
      put '<area shape ="rect" coords ="341,478,410,447" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor3"'"/>';
	  put '<P align="center"><font face="Arial" size=2>Clicking on an area within the diagram will display a list of elements with that category</font>';
      put '</BODY>';
      put '</HTML>';
    run;

    /*
    CREATING THE DRILL DOWN LISTS
    PROC SQL enclosed in a Macro was used to select the elements that make up a 
    group for each group within the union, using the parameter list.  PROC SQL 
    was then used to list the elements that fall outside the group.
    */

    /* Creating the lists */

    ods html file = table (no_bottom_matter) anchor = "anchor";

	%macro table(list, title);

	  title1 "&title.";

	  proc sql;
	    create table &list as
	    select id 
	    from Data_reformatted2
	    where &list. = 1
	    order by id;
	  quit; 

	%mend table;


    %table(A1, &GroupA only);
    %table(B1, &GroupB only);
    %table(AB, &GroupA and &GroupB );

    %if &TO ^= 0 %then %do;

      title1 "Outside Union";

      proc sql;
	    create table Outsie_union as
        select id
        from Data_reformatted2
        where A1 = B1 = AB = 0;
      quit;
  
	  %end;

    ods html close;

    %END;

  /*************** 3 WAY VENN DIAGRAMS ***************/

  %if &venn_diagram = 3 %then %do;

  /* Drawing the Ellipse Plots with the Counts */
  /* Offsetting the graphs so that they line up correctly */

  %let xoffset = + 16;
  %let yoffset = - 0;

  DATA _NULL_;
    /*Initialize DSGI*/
    RC = GINIT ();

	/*Open a graphic segment*/
    RC = GRAPH ('CLEAR');

    /* First Circle */
    RC = GSET ('LINWIDTH', 2);
    /*No. 2 color, Red*/
    RC = GSET ('LINCOLOR', 2);

    /*Draw a Hollow Red Circle, from 0 to 360 degree at coordinate (35, 35) with radius 25*/
    RC = GDRAW ('ARC', 35 &xoffset, 35 &yoffset, 25, 0, 360);

    /* Second Circle */
    /*No. 3 color, Green*/
    RC = GSET ('LINCOLOR', 3);

    /*Draw a Hollow Green, from 0 to 360 degree at coordinate (65, 35) with radius 25*/
    RC = GDRAW ('ARC', 65 &xoffset, 35 &yoffset, 25, 0, 360);

    /* Third Circle */
    /*No. 4 color, Dark Blue*/
    RC = GSET ('LINCOLOR', 5);
    RC = GDRAW ('ARC', 50 &xoffset, 60 &yoffset, 25, 0, 360);

    /* Text */
    RC = GSET ('TEXHEIGHT', 3);
    /*Set up text font as HWPSL009*/
    *RC = GSET('TEXFONT', 'HWPSL009');

	/*Write down text, "&GroupA" starting from coordinate, (28, 60)*/

    RC =GSET('TEXCOLOR', 2);
    RC = GDRAW ('TEXT', 10 &xoffset, 7 &yoffset, "&GroupA");
    RC =GSET('TEXCOLOR', 3);
    RC = GDRAW ('TEXT', 75 &xoffset, 7 &yoffset, "&GroupB");
    RC =GSET('TEXCOLOR', 5);
    RC = GDRAW ('TEXT', 46 &xoffset, 90 &yoffset, "&GroupC");
    RC =GSET('TEXCOLOR', 8);
    RC =  GDRAW ('TEXT', 48 &xoffset, 3 &yoffset, "&TO  - Outside Union");
    RC =GSET('TEXCOLOR', 1);
    RC = GDRAW ('TEXT', 25 &xoffset, 35 &yoffset, "&A");
    RC = GDRAW ('TEXT', 70 &xoffset, 35 &yoffset, "&B");
    RC = GDRAW ('TEXT', 48 &xoffset, 65 &yoffset, "&C");

    /* Intersects */
    RC = GSET ('TEXHEIGHT', 3);
    *RC = GSET('TEXFONT', 'HWPSL009');
    RC = GDRAW ('TEXT', 50 &xoffset, 30 &yoffset, "&AB");
    RC = GDRAW ('TEXT', 35 &xoffset, 50 &yoffset, "&AC");
    RC = GDRAW ('TEXT', 60 &xoffset, 50 &yoffset, "&BC");
    RC = GDRAW ('TEXT', 50 &xoffset, 45 &yoffset, "&ABC");
    RC = GRAPH ('UPDATE');

	/*Terminate DSGI*/
    RC = GTERM ();

  RUN; 

  /*Display output*/

  /* Drilling down */
  /* Have three put quotes around the quotes so that the outfile location is specified */

  data _null_;
    file html;
    put '<HTML>';
    put '<BODY>';
    put '<style type="text/css">';
    put 'body{font-family: arial;}';
    put '</style>';
    put '<P align="center"><IMG SRC="'"&out_location/&outputfilename..png"'" usemap = "#threevenn" />' ; 
    put '<map id ="threevenn" name="threevenn">';
    put '<area shape ="rect" coords ="239,389,281,365" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor"'"/>';
    put '<area shape ="rect" coords ="493,389,531,365" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor1"'"/>';
    put '<area shape ="rect" coords ="369,219,399,197" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor2"'"/>';
    put '<area shape ="rect" coords ="380,417,412,395" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor3"'"/>';
    put '<area shape ="rect" coords ="289,305,323,278" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor4"'"/>';
    put '<area shape ="rect" coords ="433,305,466,278" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor5"'"/>';
    put '<area shape ="rect" coords ="378,331,410,307" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor6"'"/>';
    put '<area shape ="rect" coords ="363,577,418,545" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor7"'"/>';
    put '<P align="center"><font face="Arial" size=2>Clicking on an area within the diagram will display a list of elements with that category</font>';
    put '</BODY>';
    put '</HTML>';
  run;

/* Creating the lists */

  ods html file = table (no_bottom_matter)anchor = "anchor";

  	%macro table(list, title);

	  title1 "&title.";

	  proc sql;
	    create table &list as
	    select id 
	    from Data_reformatted2
	    where &list. = 1
	    order by id;
	  quit; 

	%mend table;


  %table(A1, &GroupA only);
  %table(B1, &GroupB only);
  %table(C1, &GroupC only);
  %table(AB, &GroupA and &GroupB );
  %table(AC, &GroupA and &GroupC );
  %table(BC, &GroupB and &GroupC );
  %table(ABC, &GroupA and &GroupB and &GroupC );

  %if &TO ^= 0 %then %do;

    title1 "Outside Union";

    proc sql;
	  create table Outside_union as
      select id
      from Data_reformatted2
      where A1 = B1 = C1 = AB = AC = BC = ABC = 0;
    quit;

  %end;

  ods html close;

  %END;

   /*************** 4 WAY VENN DIAGRAMS ***************/

  %if &venn_diagram = 4 %then %do;

  /* Drawing the Ellipse Plots with the Counts */
  
  %let offset = -8;

  DATA _NULL_;
    /*Initialize DSGI*/
    RC = GINIT ();
    /*Open a graphic segment*/

    RC = GRAPH ('CLEAR');

    /* First Ellipse */
    /*Set Line Color with No. 2 color, Red*/
    RC = GSET ('LINWIDTH', 2);
    RC = GSET ('LINCOLOR', 2);

    /* Draw a Hollow Red Ellipse, from 0 to 360 degree at coordinate (80, 50) with
       length 100 and width 60 at 50 degrees*/
    RC = GDRAW ('ELLARC', 80, 50 &offset, 80, 30, 0, 360, 50);

    /* Second Ellipse */
    /*No. 3 color, Green*/
    RC = GSET ('LINCOLOR', 3);

    /* Draw a Hollow Red Ellipse, from 0 to 360 degree at coordinate (40, 50) with
       length 100 and width 60 at 130 degrees*/
    RC = GDRAW ('ELLARC', 40, 50 &offset, 80, 30, 0, 360, 130);

    /* Third Ellipse */
    /*No. 4 color, Dark Blue*/
    RC = GSET ('LINCOLOR', 5);
    RC = GDRAW ('ELLARC', 65, 65 &offset, 80, 30, 0, 360, 70);

    /* Fourth Ellipse */
    /*No. 5 color, Light Blue*/
    RC = GSET ('LINCOLOR', 7);
    RC = GDRAW ('ELLARC', 55, 65 &offset, 80, 30, 0, 360, 110);

	/*
    DISPLAYING THE TITLES AND THE SUMS ON THE VENN DIAGRAM
    The GSET function was used to set the font size, text and colour, 
	and the GDRAW function was used to draw the text that was stored 
	in the macro-variables at the appropriate origins.
    */

    /* Text */
    RC = GSET ('TEXHEIGHT', 3);

	/* Set up text font as HWPSL009 */
    *RC = GSET('TEXFONT', 'Arial');
    /* Write down text, "&GroupA" starting from coordinate, (28, 60) */

    RC =GSET('TEXCOLOR', 3);
    RC = GDRAW ('TEXT', 0, 37 &offset, "&GroupA");
    RC =GSET('TEXCOLOR', 7);
    RC = GDRAW ('TEXT', 10, 90 &offset, "&GroupB");
    RC =GSET('TEXCOLOR', 5);
    RC = GDRAW ('TEXT', 86, 90 &offset, "&GroupC");
    RC =GSET('TEXCOLOR', 2);
    RC = GDRAW ('TEXT', 92, 37 &offset, "&GroupD");
    RC =GSET('TEXCOLOR', 8);
    RC = GDRAW ('TEXT', 57, 10 &offset, "&TO  - Outside Union");
    RC =GSET('TEXCOLOR', 1);
    RC = GDRAW ('TEXT', 28, 60 &offset, "&A");
    RC = GDRAW ('TEXT', 43, 90 &offset, "&B");
    RC = GDRAW ('TEXT', 69, 90 &offset, "&C");
    RC = GDRAW ('TEXT', 88, 60 &offset, "&D");

    /* Setting the text size smaller for the intersects */
    RC = GSET ('TEXHEIGHT', 2.8);
    *RC = GSET('TEXFONT', 'HWPSL009');
    RC = GDRAW ('TEXT', 42, 60 &offset, "&AB");
    RC = GDRAW ('TEXT', 48, 33 &offset, "&AC");
    RC = GDRAW ('TEXT', 57, 22 &offset, "&AD");
    RC = GDRAW ('TEXT', 57, 70 &offset, "&BC");
    RC = GDRAW ('TEXT', 68, 33 &offset, "&BD");
    RC = GDRAW ('TEXT', 74, 60 &offset, "&CD");
    RC = GDRAW ('TEXT', 50, 50 &offset, "&ABC");
    RC = GDRAW ('TEXT', 63, 30 &offset, "&ABD");
    RC = GDRAW ('TEXT', 53, 30 &offset, "&ACD");
    RC = GDRAW ('TEXT', 65, 50 &offset, "&BCD");
    RC = GDRAW ('TEXT', 57, 37 &offset, "&ABCD");
    RC = GRAPH ('UPDATE');

	/*Terminate DSGI*/
    RC = GTERM ();

  RUN; 

  /* Drilling down */

  /* Specifying the regions */
  /* Have four put quotes around the quotes so that the outfile location is specified */

  data _null_;
    file html;
    put '<HTML>';
    put '<BODY>';
    put '<style type="text/css">';
    put 'body{font-family: arial;}';
    put '</style>';
    put '<P align="center"><IMG SRC="'"&out_location/&outputfilename..png"'" usemap = "#fourvenn" />' ; 
    put '<map id ="fourvenn" name="fourvenn">';
    put '<area shape ="rect" coords ="165,293,203,269" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor"'"/>';
    put '<area shape ="rect" coords ="251,122,290,97" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor1"'"/>';
    put '<area shape ="rect" coords ="391,122,436,87" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor2"'"/>';
    put '<area shape ="rect" coords ="502,293,545,269" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor3"'"/>';
    put '<area shape ="rect" coords ="247,290,272,269" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor4"'"/>';
    put '<area shape ="rect" coords ="279,444,300,425" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor5"'"/>';
    put '<area shape ="rect" coords ="326,510,355,486" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor6"'"/>';
    put '<area shape ="rect" coords ="329,247,358,210" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor7"'"/>';
    put '<area shape ="rect" coords ="396,441,415,426" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor8"'"/>';
    put '<area shape ="rect" coords ="426,296,452,269" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor9"'"/>';
    put '<area shape ="rect" coords ="286,352,313,327" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor10"'"/>';
    put '<area shape ="rect" coords ="364,461,385,445" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor11"'"/>';
    put '<area shape ="rect" coords ="310,461,328,426" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor12"'"/>';
    put '<area shape ="rect" coords ="378,349,397,330" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor13"'"/>';
    put '<area shape ="rect" coords ="330,424,363,399" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor14"'"/>';
    put '<area shape ="rect" coords ="321,576,370,554" target="_blank" href = "'"&out_location/&drilldownfilename..html#anchor15"'"/>'; 
    put '<P align="center"><font face="Arial" size=2>Clicking on an area within the diagram will display a list of elements with that category</font>';
    put '</BODY>';
    put '</HTML>';
  run;

  /* Creating the lists */

  ods html file = table (no_bottom_matter) anchor = "anchor";

  	%macro table(list, title);

	  title1 "&title.";

	  proc sql;
	    create table &list as
	    select id 
	    from Data_reformatted2
	    where &list. = 1
	    order by id;
	  quit; 

	%mend table;


  %table(A1, &GroupA only);
  %table(B1, &GroupB only);
  %table(C1, &GroupC only);
  %table(D1, &GroupD only);
  %table(AB, &GroupA and &GroupB );
  %table(AC, &GroupA and &GroupC );
  %table(AD, &GroupA and &GroupD );
  %table(BC, &GroupB and &GroupC );
  %table(BD, &GroupB and &GroupD );
  %table(CD, &GroupC and &GroupD );
  %table(ABC, &GroupA and &GroupB and &GroupC );
  %table(ABD, &GroupA and &GroupB and &GroupD );
  %table(ACD, &GroupA and &GroupC and &GroupD );
  %table(BCD, &GroupB and &GroupC and &GroupD );
  %table(ABCD, &GroupA and &GroupB and &GroupC and &GroupD );

  %if &TO ^= 0 %then %do;

    title1 "Outside Union";

    proc sql;
	  create table Outside_union as
      select id
      from Data_reformatted2
      where A1 = B1 = C1 = D1 = AB = AC = AD = BC = BD = CD = 
        ABC = ABD = ACD = BCD = ABCD = 0 ;
    quit;

  %end;

  ods html close;

%END;

%mend venn;



