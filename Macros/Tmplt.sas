
/*  -----------------------------------------------------------------------
    Program  :  Tmplt.sas
    Purpose  :  Generate a template for multiple plot displays.
                Also embed the TREPLAY macro so that it can be invoked
                as an option to replay plots lockstep through the newly
                generated template.
    Input    :  Macro parameter values
    Output   :  A template catalog entry (i.e. a template)
    Parms    :
            MARGIN  is the border surrounding the group of equal-sized
                    panels on a page. If 2.5 is entered, for example,
                    then a margin of 2.5% will surround the panels.
            SCALEX  Each panel can be scaled along the X axis or the
                    Y axis. To space the panels further apart, enter a
                    value less than one (e.g. 0.9). A value greater than
                    1 is not allowed.
            SCALEY  The panels can also be scaled along the Y-axis.
                    The two axes can be scaled differently.
            XLATEY  Translate-Y. The group of panels can be moved up or
                    down the vertical axis.
            XLATEX  Translate-X. The group of panels can move right or
                    left along the horizontal axis.
            R1...R8 Number of panels in Row1 to Row8
            COLOR   Color=border-color.
            ROTATE  Rotate=degrees. Only internal panels are rotated. The
                    title panel remains fixed.
            CLIP    Regulates graphics display beyond panel borders.
            IGOUT   Name of the Input graphics catalog.
            TC      Name of template catalog. 
            TNAME   Template name i.e. template catalog entry. 
            TREPLAY A switch for invoking the %treplay macro.
    ------------------------------------------------------------------- */
%macro Tmplt(Margin=0,ScaleX=1,ScaleY=1,XLateX=0,XLateY=0,
             R1= ,R2= ,R3= ,R4= ,R5= ,R6= ,R7= ,R8= ,
             color=NONE,rotate=0,clip=OFF,
             igout=work.gseg,tc=tempcat,tname=TmpMac,Treplay=N);

  /* THE TREPLAY MACRO USES MACRO VARIABLES IGOUT AND NPANELS FROM %TMPLT */
  %macro treplay;

  /* OBTAIN NUMBER OF PLOTS */
    %let indexL=%eval(%index(&igout,.)-1); /*INDEXLIBNAME -- EG WORK.GSEG = 4 */
    %let indexM=%eval(&indexL.+2);         /*INDEXMEMNAME */
    %let libname=%upcase(%substr(&igout,1,&indexL));
    %let memname=%upcase(%substr(&igout,&indexM));

     proc sql noprint;
       select left(trim(put(count(*),2.))) into :nplots
       from dictionary.catalogs
       where upcase(libname) eq "&libname"
         and upcase(memname) eq "&memname"
         and substr(objname,1,1) eq 'G';
     quit;

  /* WRITE THE TREPLAY COMMAND */
     proc greplay nofs igout=&igout tc=&tc;
     template &tname;

    %let numgrafs=%sysfunc(ceil(&nplots./&npanels.) );
    %let plot=1;
    %do i= 1 %to &numgrafs;
       treplay
      %do panel=1 %to &npanels;
         /* LAST PANEL IS ALWAYS THE GRAND TITLE GSLIDE */
          %if &panel eq &npanels %then
            %do;        
              &panel.:&nplots.  
            %end;
         /*****
          PUTS ALL NON GRAND-TITLE PLOTS ON A GRAPH. 
          FEWER THAN &NPANELS-1 OF THEM MAY APPEAR ON ONE
          PAGE IN A MULTIPLE-PAGE GRAPHICS DISPLAY.
         *****/
          %else %if &plot lt &nplots %then %do;
             &panel.:&plot.
             %let plot=%eval(&plot + 1);
          %end;
      %end;
    ;
   %end;
   run;
  %mend treplay;

  /* BACK TO TMPLT*/

  %let margin2 = %sysevalf(2.0 * &margin); 
  /*****
   CALCULATE MACRO VARIABLES:
     MAXNCOL IS THE MAXIMUM NUMBER OF PLOTS IN A ROW OF PLOTS
     NROWS   IS THE TOTAL NUMBER OF ROWS IN A GRAPH
     NPANELS IS THE SUM OF N1 ... N8
  *****/
  %let MaxNCol= 0;
  %let NRows= 0;
  %let NPanels=0;
  %do i=1 %to 8;
    %if &&r&i ne %then 
      %do;
        %let NROWS = &i; 
        %if &&r&i gt &MaxNCol %then %let maxncol=&&r&i;
        %let NPanels = %eval(&NPanels + &&r&i);
      %end;
  %end;
  %let Npanels = %eval(&NPanels +1); /*FOR GRAND TITLE*/

   proc greplay tc=&tc igout=&igout nofs;
     tdef &TName
     /* CORRECT PARAMETER ERRORS */
     %if %sysevalf(&ScaleX gt 1.0,boolean) %then
       %do;
         %put ==>Maximum ScaleX factor is 1.0;
         %let ScaleX=1.0;
       %end;
     %if %sysevalf(&ScaleY gt 1.0,boolean) %then
       %do;
         %put ==>Maximum ScaleY factor is 1.0;
         %let ScaleY=1.0;
       %end;

     /* WANT XLATES TO BE WITHIN THE BOUNDS OF THE MARGIN */
     /* X */
     %if %sysevalf(%sysevalf(-1.0 * &XLateX) gt &Margin , boolean) %then
       %do;
         %put ==>Maximum Abs(XLateX) is the Margin: &margin;
         %let XLateX = %sysevalf(-1.0 * &Margin );
       %end;
     %if %sysevalf(&XLateX gt &Margin , boolean) %then 
       %do;
         %put ==>Maximum XLateX is the Margin: &margin;
         %let XLateX = %sysevalf(&Margin );
       %end;
     /* Y */
     %if %sysevalf(%sysevalf(-1.0 * &XLateY) gt &Margin , boolean) %then
       %do;
         %put ==>Maximum Abs(XLateY) is the Margin: &Margin;
         %let XLateY = %sysevalf(-1.0 * &Margin );
       %end;
     %if %sysevalf(&XLateY gt &Margin, boolean) %then
       %do;
         %put ==>Maximum XLateY is the Margin: &margin;
         %let XLateY = %sysevalf(&Margin );
       %end;
     %if %sysevalf(&NRows gt 8, boolean) %then
       %do;
         %put Maximum Number of Rows of panels is 8;
         %let NRows=8;
       %end;

     /* CALCULATE PANEL COORDINATES */

     /*****
      HEIGHT AND WIDTH ARE CALCULATED FOR THE INDIVIDUAL PANELS.
      THE WIDTH OF EACH PANEL IS DETERMINED BY THE ROW CONTAINING
      THE GREATEST NUMBER OF PANELS. (MAXNCOL)  
     *****/
     %let height=%sysevalf((100-&Margin2.)/&NRows);
     %let width=%sysevalf((100-&Margin2.)/&MaxNCol);

     %let PanelNum=1;                
     %do row = 1 %to &NRows;        /* FOR Y COORDINATES */
       %do column = 1 %to &&R&row;  /* FOR X COORDINATES */ 
        /*****
         CALCULATE Y COORDINATES BY WORKING FROM TOP OF GRAPH 
         DOWNWARDS. THIS MAKES Y1 GREATER IN VALUE THAN Y2.
         CALCULATE Y1, Y2 ONCE PER ROW OF PANELS (WHEN &COLUMN=1)  
        *****/
         %if &column eq 1 %then
           %do;  
             %if &row eq 1 %then
               %do;             /*ROW1,COL1=PANEL1 UPPER LEFT */
                 %let y1=%sysevalf(100.0-(&margin ));   
               %end;
             %else 
               %do;
                 %let y1 = &y2;     /* NEXT ROW UPPER Y = PREVIOUS ROW LOWER Y */
               %end;
             %let y2=%sysevalf(&y1-&height);
           %end; /* CALCULATING Y COORDS */

           /*****
            CALCULATE X COORDINATES. THE NUMBER OF COLUMNS (PANELS PER ROW)
            CAN BE DIFFERENT. TEMPLATES ARE ALWAYS CENTERED LIKE THIS
                   |--||--||--|  (3 PANELS)
                     |--||--|    (2 PANELS)
            THEREFORE, GET COORDS FOR 1ST TEMPLATE TO THE FAR LEFT BY
            CALCULATING FROM THE MIDDLE (50%). WIDTH ALLOWS FOR MARGIN.
            E.G. THREE PANELS NO MARGIN: WIDTH=33.3. X1 = 50-(1.5*33.3) = 0. 
                 TWO PANELS,  2% MARGIN : WIDTH=48   X1 = 50-(1*48)     = 2.
           *****/
           %if &column=1 %then
             %do;
               %let x1 = %sysevalf(50-(&&R&row./2 * &width));
             %end;
           %else
             %do;
               %let x1=&x2;    /*Next col left-X = current col right-X */
             %end;
           %let x2=%sysevalf(&x1+&width);

           /* WRITE OUT A PANEL */
           &PanelNum / llx=&x1 ulx=&x1 urx=&x2 lrx=&x2
                       lly=&y2 uly=&y1 ury=&y1 lry=&y2
                       ScaleX=&ScaleX ScaleY=&ScaleY
                       XLateX=&XLateX XLateY=&XLateY
                       Rotate=&Rotate
                      %if %upcase(&color) ne NONE %then Color=&Color;
                      %if %upcase(&clip) ne OFF %then %str(clip);

           %let PanelNum=%eval(&PanelNum+1);

       %end; /* COLUMN */
     %end;   /* ROW */

    /* FOR THE GRAND TITLE */
    &PanelNum / llx=0 ulx=0 urx=100 lrx=100
               lly=0 uly=100 ury=100 lry=0;

   /* ASSIGN TEMPLATE */
   Template &TName;

   run;

   /* CONDITIONALLY INVOKE %TREPLAY -- FOR LOCK-STEP PANEL|PLOT ASSIGNMENTS */
  %if %upcase(&treplay) eq Y %then %do;
    %treplay;
  %end;
%mend Tmplt;