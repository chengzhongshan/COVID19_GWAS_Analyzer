/*  -----------------------------------------------------------------------
    Program  :  SizeIt.sas
    Purpose  :  Generates GOPTION HSIZE and VSIZE lengths given
                XMAX and YMAX from PROC GDEVICE. This macro
                corrects text and shape distortion that occurs when
                graphs are displayed through panels that do not conform
                to the aspect ratio defined by the relationship between
                XMAX and YMAX.
    Input    :  macro parameter values
    Output   :  GOPTIONS HSIZE and VSIZE statement
    Parms    :
            MARGIN  is the border surrounding the group of equal-sized
                    plots on a page. If 2.5 is entered, for example,
                    then a margin of 2.5% will surround the plots.
                    Horizontal and vertical margins have the same values.
            SCALEX  Each plot can be scaled along the X axis or the
                    Y axis. To get space between the plots enter a
                    value less than one (e.g. 0.9). Values greater
                    than 1 are not allowed. 
            SCALEY  The plots can also be scaled along the Y-axis.
                    The two axes can have different scales.
            NROWS   Number of rows containing plots 
            MAXNCOL Maximum number of plots in a row of plots 
            XMAX    used for calculating HSIZE
            YMAX    used for calculating VSIZE
     ------------------------------------------------------------------- */
 
%macro SizeIt(Margin=0,ScaleX=1,ScaleY=1,NRows=,MaxNCol=,XMax=,YMax=);

  %let margin2 = %sysevalf(2.0 * &margin);
  /* CORRECT PARM ERRORS */
  %if %sysevalf(&ScaleX gt 1.0,boolean) %then
    %do;
      %put Maximum ScaleX factor is 1.0;
      %let ScaleX=1.0;
    %end;
  %if %sysevalf(&ScaleY gt 1.0,boolean) %then 
    %do;
      %put Maximum ScaleY factor is 1.0;
      %let ScaleY=1.0;
    %end;
  %if %sysevalf(&NRows gt 8, boolean)  %then
    %do;
      %put Maximum Number of Rows of panels is 8;
      %let NRows=8;
    %end;

  /* CALCULATE VSIZE AND HSIZE. */
  %let VSize=%sysevalf(((100-&Margin2)/&NRows) * &ScaleY * &YMax *0.01);
  %let HSize=%sysevalf(((100-&Margin2)/&MaxNCol) * &ScaleX * &XMax *0.01);

  /*THE OUTPUT */
  goptions vsize=&VSize in hsize=&HSize in;
%mend SizeIt;
