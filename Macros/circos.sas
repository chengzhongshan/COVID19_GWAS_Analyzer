/*
  data random;
 call streaminit(123);
 do i=1 to 100;
  u=rand("uniform");
  u2=rand("uniform");
  before=1+floor(14*u);
  after=1+floor(14*u2);
  output;
 end;
 drop i u u2;
 run;

*Only two columns in random: before and after;
*Levels of before and after will be used for groups in the final circle plot;
*The link between before and after is determined by their values;
*i.e., before: 4 and after: 5 will be linked with a line in the circle plot;

*If applied for chromosome mutaton plot, need to transform data into the above format;
*by sorting with chr:pos; 

%circos(data=random,before=before,after=after,points=100);

*/


/*------------------------------------------------------------------*
| MACRO NAME  : circos
| SHORT DESC  : Create a CIRCOS plot
*------------------------------------------------------------------*
| CREATED BY  : Meyers, Jeffrey                 (07/28/2016 3:00)
*------------------------------------------------------------------*
| VERSION UPDATES:
| 09/24/2017: Initial Release
*------------------------------------------------------------------*
| PURPOSE
| Creates a CIRCOS graph that displays the paths from a before group to an
| after group.  The graph is built around a circle and is made up of three parts:
|    OUTER CIRCLE: A separate curved rectangle is drawn for each unique group
|                  (both before and after groups).  The length of each 
|                  rectangle is proportionate to that groups population versus
|                  the total population.
|    INNER CIRCLE: A curved rectangle is drawn with each OUTER CIRCLE group. 
|                  The length of these rectangles is proportionate to the 
|                  number of paths leaving the group to the total number of paths
|                  interacting with the group.  For example, if all paths are leaving
|                  a group and no paths are entering a group, the INNER CIRCLE
|                  will be the same length as the OUTER CIRCLE.
|    BEZIER CURVES: Bezier curves are used to show the paths from one group to another 
|                   around the OUTER CIRCLE.  These are Bezier curves based on three
|                   points: the start, end and the center of the circle.  This pulls the 
|                   curve more towards the center of the circle the further apart the 
|                   start and end is.  The width of the Bezier curves is proportionate
|                   to the number of paths within the starting/ending group to the 
|                   total number of paths.
| CIRCOS plots are used to give a visual representation of the change from one group to
| another.
|    
| 1.0: REQUIRED PARAMETERS
|   DATA = Specifies the dataset to be used in the macro
|   BEFORE = Specifies variable that contains the starting group for each path
|   AFTER = Specifies variable that contains the ending group for each path
| 2.0: OPTIONAL PARAMETERS
|    2.1: PLOT OPTIONS
|       2.1.1: FILL COLOR OPTIONS
|          COLOR = A list of colors separated by spaces to color the outer circle
|          UNIQUE_GROUP_COLORS = Causes each value within a group to be considered unique.
|                                Normally each BEFORE/AFTER level is colored the same within
|                                each group, but if this is 1 then the same levels will be 
|                                different colors within different groups.
|                                Options are 1 (yes) and 0 (no).  Default is 0.
|          TRANSPARENCY = Determines the transparency of the Bezier curves.  Optional
|                         values are between 0 and 1.  Default is 0.5.
|       2.1.2: TITLE OPTIONS
|          TITLE = Creates a title for the image.  The | can be used to create line breaks.
|          TITLESIZE = Determines the font size of the title.  Default is 12pt.
|          TITLEWEIGHT = Determines the font weight of the title.  Options are NORMAL and BOLD.
|                        Default is BOLD.
|          TITLEALIGN = Determines the alignment of the title.  Options are LEFT, CENTER, and RIGHT.
|                       Default is CENTER.
|       2.1.3: LABEL OPTIONS
|          LABELWEIGHT = Determines the font weight of the label.  Options are NORMAL and BOLD.
|                        Default is BOLD.
|          LABELALIGN = Determines the alignment of the label.  Options are LEFT, CENTER, and RIGHT.
|                       Default is CENTER.
|       2.1.4: OUTER CIRCLE OPTIONS
|          GROUPGAP = Determines the gap between the outer circle groups as a proportion.  Optional 
|                     values are between 0 and 0.25.  The default is 0.05.  This amount is spread 
|                     out as the separation between all groups.  If GROUPGAP=0.05 then 95% of the 
|                     circle will be used to show the outer cirlce groups.
|          BARWIDTH = Determines the width of the outer circle groups as a proportion of the radius
|                     of the circle.  Optional values are between 0 and 0.25.  The default is 0.05.
|                     Half of this gap is used as the width for the inner circle.
|          INNERGAP = Determines the gap between the outer circle groups and the Bezier curves as a 
|                     proportion of the radius of the circle.  Optional values are between 0 and 0.25.  
|                     The default is 0.025.  Half of this gap is placed between the outer circle groups 
|                     and the inner circle. 
|          START = Determines the starting oint for the outer circle groups.  Units are in degrees 
|                  from the right side of the circle moving counter-clockwise.  Default is 270.
|          DIRECTION = Determines the direction the outer circle groups rotate around the circle.
|                      Options are CCW (counter-clockwise) and CW (clockwise).  Default is CW.  
|          POINTS = Determines how many points are used to graph the sides of the shapes in the plot.
|                   The higher the number the more resolution the curves have but the longer the processing 
|                   time.  Higher than 100 is not recommended.  Default is 10. Minimum is 5.
|          ORDER = A list of numbers separated by spaces that changes the order of the BEFORE/AFTER levels.  By default
|                  values are listed in unformatted values if both BEFORE and AFTER variables have the same type and format.
|                  Otherwise the values are listed in alphabetical order.  Listing a number picks the nth item 
|                  order.  For example, if the groups are Former, Current and Never, then the default order would
|                  be Current then Former then Never.  if ORDER= 3 1 2 then the new order would be Never then
|                  Current then Former. One value per level (before and after combined) must be listed if this
|                  parameter is used.
|          GROUPORDER = A list of numbers separated by spaces that changes the order of the groups.  By default
|                       values are listed in unformatted values if both BEFORE_GROUP and AFTER_GROUP variables have the same type and format.
|                       Otherwise the values are listed in alphabetical order.  Listing a number picks the nth item 
|                       order.  For example, if the groups are Former, Current and Never, then the default order would
|                       be Current then Former then Never.  if ORDER= 3 1 2 then the new order would be Never then
|                       Current then Former. One value per group (before and after combined) must be listed if this
|                       parameter is used.  If only one of the BEFORE_GROUP and AFTER_GROUP variables are provided then
|                       the non-specified group variable will all be grouped into an "Ungrouped" category.
|    2.2: SUBSETTING OPTIONS
|       2.2.1: SUBSET INPUT DATASET
|           WHERE = Allows a where clause to subset the input dataset within the macro.  List exactly as
|                   a where clause within a procedure.  Example: WHERE=arm='A'
|       2.2.2: GROUP BEFORE/AFTER VALUES
|           BEFORE_GROUP = A variable that will subgroup the BEFORE variable levels within the graph
|           AFTER_GROUP = A variable that will subgroup the AFTER variable levels within the graph
|    2.3: IMAGE OPTIONS
|       ANTIALIASMAX = Maximum threshold to keep line smoothing activated.  Optional values are integers greater
|                      than or equal to 1000.  Default is 100000.  Larger numbers create more file size.
|       AXISCOLOR = Sets the color for the axes.  Default is black.
|       BACKGROUND = Sets the color for the background.  Ignored if TRANSPARENT=1.  Default is white.
|       BORDER = Turns the black border in the plot image on (1) or off (0).  Options are
|                1 or 0, default is 0. 
|       DPI = Determines the dots per inch of the image file.  Default=200.  Larger numbers give
|             greater resolution but increased file size.
|       FONTCOLOR = Determines the color for the graph text.  Default is black
|       GPATH = Determines the path that the image is saved to.  Defaults to the path 
|               the SAS session is opened to.
|       HEIGHT = Sets the height of plot window.  Default is 6in.  Set by a
|                numeric constant followed by px or in.  Must be in for TIFF.
|       PLOTNAME = Names the image file.  Plot will be saved per the GPATH parameter.  
|                  Default is _circos.
|       PLOTTYPE = Determines the image type of the plot.  Default is png, options
|                  are png, tiff, jpeg, emf, gif.  
|                  NOTE: There is special code added for TIFF plots in order to make 
|                        appropriately sized image files.  If DPI settings are too high
|                        depending on operating system and SAS version, this may not work.
|       SVG = Turns scalable vector graphics on or off. Default is 0 (off).  options are 1 or 0
|       TIFFDEVICE = Determines the GDEVICE to use when making TIFF plots.  Default is TIFFP.
|                    Options can be found with PROC GDEVICE catalogue=sashelp.devices;run;
|       TRANSPARENT = Determines if the background will be transparent.  Only available in 9.4M3+.
|                     Default is 0 (no).  Options are 1 (yes) and 0 (no).
|       WIDTH = Sets the width of plot window.  Default is 6in.  Set by a
|               numeric constant followed by px or in. Must be in for TIFF.
|    2.4: DOCUMENT OPTIONS
|       DESTINATION = Type of ODS output when creating a document. 
|                     Default is RTF, options are RTF, PDF, HTML, EXCEL and POWERPOINT.
|       OUTDOC = Filepath with name at end to send the output.
|                Example: ~/ibm/example.doc
|       ORIENTATION = Determines the orientation of the page of the document.  Options are PORTRAIT
|                     and LANDSCAPE.  Default is PORTRAIT.
|    2.4: OUTPUT PLOT DATASET
|       OUT = Specifies a dataset to save the plotting dataset after the macro runs.
*------------------------------------------------------------------*
| OPERATING SYSTEM COMPATIBILITY
| SAS v9.4M3 or Higher: Yes
*------------------------------------------------------------------*
| MACRO CALL
|
| %circos (
|            DATA=,
|            BEFORE=,
|            AFTER=
|          );
*------------------------------------------------------------------*
| EXAMPLES
|
| Randomly Generated Dataset:
data random;
    call streaminit(123);
    do i = 1 to 100;
        u = rand("Uniform");     
        u2 = rand("Uniform");     
        before = 1 + floor(7*u);
        after = 4 + floor(7*u2);
        output;
    end;  
    format before after z2.;
    drop i u u2;
run;

| Example 1: Basic Call
    %circos(data=random,before=before,after=after);
*------------------------------------------------------------------*
| This program is free software; you can redistribute it and/or
| modify it under the terms of the GNU General Public License as
| published by the Free Software Foundation; either version 2 of
| the License, or (at your option) any later version.
|
| This program is distributed in the hope that it will be useful,
| but WITHOUT ANY WARRANTY; without even the implied warranty of
| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
| General Public License for more details.
*------------------------------------------------------------------*/
%macro circos(
    /*1.0: Required Parameters*/
    data=,before=,after=,
    
    /*2.0: Optional Parameters*/
        /**2.1: Plot Options**/
            /***2.1.1: Fill Color Options***/
            color=,unique_group_colors=0,transparency=0.5,
            /***2.1.2: Title Options***/
            title=,titlesize=12pt,titleweight=bold,titlealign=center,
            /***2.1.3: Label Options***/
            labelsize=12pt,labelweight=normal,
            /***2.1.4: Outer Circle Options***/
            groupgap=0.05,barwidth=0.05,innergap=0.025,
            start=270,direction=CW,points=10,
            order=,grouporder=,
        /**2.2: Subsetting Options**/
            /***2.2.1: Subset Input Dataset***/
            where=,
            /***2.2.2: Group Before/After Values***/
            before_group=,after_group=,
        /**2.3: Image Options**/
        antialias=100000,axiscolor=black,border=0,gpath=,background=white,dpi=200,
        plotname=_circos,plottype=png,
        height=6in,width=6in,
        fontcolor=black,svg=0,tiffdevice=TIFFP,transparent=0,
        /**2.4: Document Options**/
        destination=rtf,outdoc=,orientation=portrait,    
        /**2.5: Output Plot Data**/
        out=);
    
    
    
    /**Save current options to reset after macro runs**/
    %local _mergenoby _notes _qlm _odspath _starttime _device _gsfname
        _xmax _ymax _xpixels _ypixels _imagestyle _iback _listing _orientation;
    %let _starttime=%sysfunc(time());
    %let _notes=%sysfunc(getoption(notes));
    %let _mergenoby=%sysfunc(getoption(mergenoby));
    %let _qlm=%sysfunc(getoption(quotelenmax)); 
    %let _device=%sysfunc(getoption(device));
    %let _gsfname=%sysfunc(getoption(gsfname));
    %let _xmax=%sysfunc(getoption(xmax));
    %let _ymax=%sysfunc(getoption(ymax));
    %let _xpixels=%sysfunc(getoption(xpixels));
    %let _ypixels=%sysfunc(getoption(ypixels));
    %let _imagestyle=%sysfunc(getoption(imagestyle));
    %let _iback=%sysfunc(getoption(iback));
    %let _orientation=%sysfunc(getoption(orientation));
    %let _odspath=&sysodspath;
    %if %sysevalf(%superq(_odspath)=,boolean) %then %let _odspath=WORK.TEMPLAT(UPDATE) SASHELP.TMPLMST (READ);
    /**Turn off warnings for merging without a by and long quote lengths**/
    /**Turn off notes**/
    options mergenoby=NOWARN nonotes noquotelenmax;
    /**See if the listing output is turned on**/
    proc sql noprint;
        select 1 into :_listing separated by '' from sashelp.vdest where upcase(destination)='LISTING';
    quit;
    
    /*Don't send anything to output window, results window, and set escape character*/
    ods noresults escapechar='^';
    ods select none;
    %let _odspath=&sysodspath;
    
    /**Process Error Handling**/
    %if &sysvlong < 9.04.01M3P062415 %then %do;
        %put ERROR: SAS must be version 9.4M3 or later;
        %goto errhandl;
    %end;       
    %else %if %sysfunc(exist(&data))=0 %then %do;
        %put ERROR: Dataset &data does not exist;
        %put ERROR: Please enter a valid dataset;
        %goto errhandl;
    %end;
    %else %if %sysevalf(%superq(data)=,boolean)=1 %then %do;
        %put ERROR: DATA parameter is required;
        %put ERROR: Please enter a valid dataset;
        %goto errhandl;
    %end;                       
    %local z nerror;
    %let nerror=0;  
      
    /**Error Handling on Global Parameters**/
    %macro _varcheck(parm,require,numeric,dataset=&data,nummsg=);
        %local _z _numcheck;
        /**Check if variable parameter is missing**/
        %if %sysevalf(%superq(&parm.)=,boolean)=0 %then %do;
            %if %sysfunc(notdigit(%superq(&parm.))) > 0 %then
                %do _z = 1 %to %sysfunc(countw(%superq(&parm.),%str( )));
                /**Check to make sure variable names are not just numbers**/    
                %local datid;
                /**Open up dataset to check for variables**/
                %let datid = %sysfunc(open(&dataset));
                /**Check if variable exists in dataset**/
                %if %sysfunc(varnum(&datid,%scan(%superq(&parm.),&_z,%str( )))) = 0 %then %do;
                    %put ERROR: (Global: %qupcase(&parm)) Variable %qupcase(%scan(%superq(&parm.),&_z,%str( ))) does not exist in dataset &dataset;
                    %local closedatid;
                    /**Close dataset**/
                    %let closedatid=%sysfunc(close(&datid));
                    %let nerror=%eval(&nerror+1);
                %end;
                %else %do;
                    %local closedatid;
                    %let closedatid=%sysfunc(close(&datid));
                    %if &numeric=1 %then %do;
                        data _null_;
                            set &dataset (obs=1);
                            call symput('_numcheck',strip(vtype(%qupcase(%scan(%superq(&parm.),&_z,%str( ))))));
                        run;
                        %if %sysevalf(%superq(_numcheck)^=N,boolean) %then %do;
                            %put ERROR: (Global: %qupcase(%scan(%superq(&parm.),&_z,%str( )))) variable must be numeric &nummsg;
                            %let nerror=%eval(&nerror+1);
                        %end;   
                    %end;                         
                %end;
            %end;
            %else %do;
                /**Give error message if variable name is number**/
                %put ERROR: (Global: %qupcase(&parm)) variable is not a valid SAS variable name (%superq(&parm.));
                %let nerror=%eval(&nerror+1);
            %end;
        %end;
        %else %if &require=1 %then %do;
            /**Give error if required variable is missing**/
            %put ERROR: (Global: %qupcase(&parm)) variable is a required variable but has no value;
            %let nerror=%eval(&nerror+1);
        %end;
    %mend;
    %macro _gparmcheck(parm, parmlist);          
        %local _test _z;
        /**Check if values are in approved list**/
        %do _z=1 %to %sysfunc(countw(&parmlist,|,m));
            %if %qupcase(%superq(&parm))=%qupcase(%scan(&parmlist,&_z,|,m)) %then %let _test=1;
        %end;
        %if &_test ^= 1 %then %do;
            /**If not then throw error**/
            %put ERROR: (Global: %qupcase(&parm)): %superq(&parm) is not a valid value;
            %put ERROR: (Global: %qupcase(&parm)): Possible values are &parmlist;
            %let nerror=%eval(&nerror+1);
        %end;
    %mend;
    /**Error Handling on Individual Model Numeric Variables**/
    %macro _gnumcheck(parm,min,max,contain,default);
        /**Check if missing**/
        %if %sysevalf(%superq(&parm.)=,boolean)=0 %then %do;
            %if %sysfunc(notdigit(%sysfunc(compress(%superq(&parm.),.)))) > 0 %then %do;
                /**Check if character values are present**/
                %put ERROR: (Global: %qupcase(&parm)) Must be numeric.  %qupcase(%superq(&parm.)) is not valid.;
                %let nerror=%eval(&nerror+1);
            %end;  
            %else %do;
                %if %sysevalf(%superq(min)^=,boolean) %then %do;
                    %if %superq(&parm.) le &min and &contain=0 %then %do;
                        /**Check if value is below minimum threshold**/
                        %put ERROR: (Global: %qupcase(&parm)) Must be greater than &min.. %qupcase(%superq(&parm.)) is not valid.;
                        %let nerror=%eval(&nerror+1);
                    %end;  
                    %else %if %superq(&parm.) lt &min and &contain=1 %then %do;
                        /**Check if value is below minimum threshold**/
                        %put ERROR: (Global: %qupcase(&parm)) Must be greater than or equal to &min.. %qupcase(%superq(&parm.)) is not valid.;
                        %let nerror=%eval(&nerror+1);
                    %end; 
                %end;
                %if %sysevalf(%superq(max)^=,boolean) %then %do;
                    %if %superq(&parm.) ge &max and &contain=0 %then %do;
                        /**Check if value is above max threshold**/
                        %put ERROR: (Global: %qupcase(&parm)) Must be less than &max.. %qupcase(%superq(&parm.)) is not valid.;
                        %let nerror=%eval(&nerror+1);
                    %end;  
                    %else %if %superq(&parm.) gt &max and &contain=1 %then %do;
                        /**Check if value is below minimum threshold**/
                        %put ERROR: (Global: %qupcase(&parm)) Must be less than or equal to &max.. %qupcase(%superq(&parm.)) is not valid.;
                        %let nerror=%eval(&nerror+1);
                    %end; 
                %end;
            %end;
        %end;   
        %else %let &parm.=&default;      
    %mend;  
    /**Error Handling on Global Parameters Involving units**/
    %macro _gunitcheck(parm,allowmissing);
        %if %sysevalf(%superq(&parm)=,boolean)=1 %then %do;
                %if %sysevalf(&allowmissing^=1,boolean) %then %do;
                    /**Check if missing**/
                    %put ERROR: (Global: %qupcase(&parm)) Cannot be set to missing;
                    %let nerror=%eval(&nerror+1);
                %end;
        %end;
        %else %if %sysfunc(compress(%superq(&parm),ABCDEFGHIJKLMNOPQRSTUVWXYZ,i)) lt 0 %then %do;
            /**Throw error**/
            %put ERROR: (Global: %qupcase(&parm)) Cannot be less than zero (%qupcase(%superq(&parm)));
            %let nerror=%eval(&nerror+1);
        %end;
    %mend;
    /**Line Pattern Variables**/
    %macro _listcheck(var=,_patternlist=,lbl=,msg=);
        %local _z _z2 _test;
        %if %sysevalf(%superq(lbl)=,boolean) %then %let lbl=%qupcase(&var.);
        /**Check for missing values**/
        %if %sysevalf(%superq(&var.)=,boolean)=0 %then %do _z2=1 %to %sysfunc(countw(%superq(&var.),%str( )));
            %let _test=;
            /**Check if values are either in the approved list**/
            %do _z = 1 %to %sysfunc(countw(&_patternlist,|));
                %if %qupcase(%scan(%superq(&var.),&_z2,%str( )))=%scan(%qupcase(%sysfunc(compress(&_patternlist))),&_z,|,m) %then %let _test=1;
            %end;
            %if &_test ^= 1 %then %do;
                /**Throw error**/
                %put ERROR: (Global: &lbl): %qupcase(%scan(%superq(&var.),&_z2,%str( ))) is not in the list of valid values &msg;
                %put ERROR: (Global: &lbl): Possible values are %qupcase(&_patternlist);
                %let nerror=%eval(&nerror+1);
            %end;
        %end;
        %else %do;
            /**Throw error**/
            %put ERROR: (Global: &lbl): %qupcase(%superq(&var.)) is not in the list of valid values &msg;         
            %put ERROR: (Global: &lbl): Possible values are %qupcase(&_patternlist);
            %let nerror=%eval(&nerror+1);       
        %end;
    %mend;
    /**Check variables**/
    %_varcheck(before,1)
    %_varcheck(after,1)
    %_varcheck(before_group,0)
    %_varcheck(after_group,0)
    /**Check list parameters**/
    
    /**Parameter error checks**/
    %_gparmcheck(titleweight,BOLD|NORMAL)
    %_gparmcheck(labelweight,BOLD|NORMAL)
    %_gparmcheck(titlealign,LEFT|CENTER|RIGHT)
    %_gparmcheck(direction,CW|CCW)
    %_gparmcheck(plottype,STATIC|BMP|DIB|EMF|EPSI|GIF|JFIF|JPEG|PBM|PCD|PCL|PDF|PICT|PNG|PS|SVG|TIFF|WMF|XBM|XPM)
    %if &sysvlong >= 9.04.01M3P062415 %then %do;
        %_gparmcheck(destination,RTF|PDF|HTML|EXCEL|POWERPOINT)
    %end;
    %else %do;        
        %_gparmcheck(destination,RTF|PDF|HTML)
    %end;
    %_gparmcheck(orientation,PORTRAIT|LANDSCAPE)
    %_gparmcheck(border,0|1)
    %_gparmcheck(svg,0|1)
    %_gparmcheck(transparent,0|1)
    %_gparmcheck(unique_group_colors,0|1)
    
    /**Number error checks**/
    %_gnumcheck(transparency,0,1,1,0.5)
    %_gnumcheck(groupgap,0,0.25,1,0.05)
    %_gnumcheck(barwidth,0,0.25,1,0.05)
    %_gnumcheck(innergap,0,0.25,1,0.025)
    %_gnumcheck(points,5,,1,100)
    %_gnumcheck(start,0,360,1,270)
    %_gnumcheck(antialias,1000,,1,100000)
    %_gnumcheck(dpi,100,,1,150)
    
    /*Numbers with units error checks**/
    %_gunitcheck(titlesize,0)
    %_gunitcheck(labelsize,0)
    %_gunitcheck(height,0)
    %_gunitcheck(width,0)
    /*** If any errors exist, stop macro and send to end ***/
    %if &nerror > 0 %then %do;
        %put ERROR: &nerror pre-run errors listed;
        %put ERROR: Macro CIRCOS will cease;
        %goto errhandl;
    %end;  
    
    /**Convert starting degrees to radians**/
    %let start=(&start/180)*constant("pi");
    %local nerror_run;
    %let nerror_run=0; 
    %local smbl;
    %if %sysevalf(%qupcase(%superq(direction))=CCW,boolean) %then %let smbl=+;
    %else %let smbl=-;
    /**Create a temporary dataset**/
    data _temp;
        set &data;
        where &where;
    run;
    
    %local _typematch1 _typematch2;
    data _temp;
        merge _temp (rename=(%superq(before)=_before_t) keep=%superq(before))
              _temp (rename=(%superq(after)=_after_t) keep=%superq(after)) 
              %if %sysevalf(%superq(before_group)^=,boolean) %then %do; _temp (rename=(%superq(before_group)=_before_group_t) keep=%superq(before_group)) %end;
              %if %sysevalf(%superq(after_group)^=,boolean) %then %do; _temp (rename=(%superq(after_group)=_after_group_t) keep=%superq(after_group)) %end;;
        
        length  _before_ _after_ _before_group_ _after_group_ $300.;
        _before_=strip(vvalue(_before_t));
        _before_lvl=.;
        _after_=strip(vvalue(_after_t));
        _after_lvl=.;
        if ^missing(_before_) and ^missing(_after_);
        %if %sysevalf(%superq(before_group)^=,boolean) %then %do;
            _before_group_=strip(vvalue(_before_group_t));_before_group_lvl=.;
            if ^missing(_before_group_);
        %end;
        %else %if %sysevalf(%superq(after_group)^=,boolean) %then %do;
            _before_group_='Ungrouped';_before_group_lvl=0;
        %end;
        %else %do;
            _before_group_='';_before_group_lvl=1;
        %end;
        %if %sysevalf(%superq(after_group)^=,boolean) %then %do;
            _after_group_=strip(vvalue(_after_group_t));_after_group_lvl=.;
            if ^missing(_after_group_);
        %end;
        %else %if %sysevalf(%superq(before_group)^=,boolean) %then %do;
            _after_group_='Ungrouped';_after_group_lvl=0;
        %end;
        %else %do;
            _after_group_='';_after_group_lvl=1;
        %end;
        if _n_=1 then do;
            if vtype(_before_t)=vtype(_after_t) and upcase(vformat(_before_t))=upcase(vformat(_after_t)) then call symput('_typematch1','1');
            else call symput('_typematch1','0');
            %if %sysevalf(%superq(before_group)^=,boolean) and %sysevalf(%superq(after_group)^=,boolean) %then %do;
                if vtype(_before_group_t)=vtype(_after_group_t) and upcase(vformat(_before_group_t))=upcase(vformat(_after_group_t)) then 
                    call symput('_typematch2','1');
                else call symput('_typematch2','0');
            %end;
            %else %if %sysevalf(%superq(before_group)^=,boolean) or %sysevalf(%superq(after_group)^=,boolean) %then %do;
                call symput('_typematch2','1');
            %end;
            %else %do;
                call symput('_typematch2','0');
            %end;   
        end;
    run;
    
    /**Sort values**/
    data _levels;
        %if &_typematch1=1 %then %do;
            set _temp (keep=_before_ _before_t rename=(_before_=_levels_ _before_t=_levels_t))
                _temp (keep=_after_ _after_t rename=(_after_=_levels_ _after_t=_levels_t));
            format _levels_t; 
        %end;
        %else %do;
            set _temp (keep=_before_ rename=(_before_=_levels_))
                _temp (keep=_after_ rename=(_after_=_levels_));
        %end;
    run;
    proc sort data=_levels nodupkey;
        by _levels_;
    run;
    %if &_typematch1=1 %then %do;
        proc sort data=_levels;
            by _levels_t;
        run;
    %end;
    proc sql;
        %local nlevels prelevels;
        select count(distinct _levels_) into :nlevels separated by '' 
            from _levels;
        select _levels_ into :prelevels separated by '|' 
            from _levels;
        
        %if %sysevalf(%superq(order)^=,boolean) %then %do;
            /**Pull largest value in order list**/
            %local _maxord;
            %let _maxord = %sysfunc(max(0,%sysfunc(tranwrd(%sysfunc(compbl(%superq(grouporder))),%str( ),%str(,)))));
            /**Pull number of items in order list**/
            %local _nord;
            %let _nord = %sysfunc(countw(%superq(order),%str( )));
            /**Check if there are too many levels given**/
            %if &_nord ^= &nlevels %then %do;
                /**Throw errors**/
                %put ERROR: (Global: %qupcase(order)): Number in order list (&_nord) does not equal the number of combined values in before and after variables (&nlevels);
                %let nerror_run=%eval(&nerror_run+1);
            %end;
            /**Check if the largest value is larger than the number of levels in the by variable**/
            %else %if &_maxord > &nlevels %then %do;
                /**Throw errors**/
                %put ERROR: (Global: %qupcase(order)): Largest number in order list (&_maxord) is larger than the number of combined values in before and after variables (&nlevels);
                %let nerror_run=%eval(&nerror_run+1);
            %end;
            /**Check if all values from 1 to max are represented in the order list**/
            %else %do _z2=1 %to &nlevels;
                %local _test;
                %let _test=;
                %do z = 1 %to &_maxord;
                    %if %scan(%superq(order),&z,%str( )) = &_z2 %then %let _test=1;
                %end;
                %if &_test ^=1 %then %do;
                    /**Throw errors**/
                    %put ERROR: (Global: %qupcase(order)): Number &_z2 was not found in the order list;
                    %put ERROR: (Global: %qupcase(order)): Each number from 1 to maximum number of combined values in before and after variables (&_maxord) must be represented;
                    %let nerror_run=%eval(&nerror_run+1);
                %end;                                   
            %end;
        %end;
        /*** If any errors exist, stop macro and send to end ***/
        %if &nerror_run > 0 %then %do;
            %put ERROR: &nerror_run run-time errors listed;
            %put ERROR: Macro CIRCOS will cease;
            %goto errhandl;
        %end;  
        
        update _temp
            set _before_lvl=case(_before_)
                    %do i=1 %to &nlevels;
                        %if %sysevalf(%superq(order)^=,boolean) %then %do;
                            when "%qscan(%superq(prelevels),%scan(%superq(order),&i,%str( )),|,m)" then &i
                        %end;
                        %else %do;
                            when "%qscan(%superq(prelevels),&i,|,m)" then &i
                        %end;
                    %end; 
                    else . end,
                _after_lvl=case(_after_)
                    %do i=1 %to &nlevels;
                        %if %sysevalf(%superq(order)^=,boolean) %then %do;
                            when "%qscan(%superq(prelevels),%scan(%superq(order),&i,%str( )),|,m)" then &i
                        %end;
                        %else %do;
                            when "%qscan(%superq(prelevels),&i,|,m)" then &i
                        %end;
                    %end;
                    else . end;
                
        /**Sort by Group levels**/
        %local i;
        %if %sysevalf(%superq(before_group)^=,boolean) or %sysevalf(%superq(after_group)^=,boolean) %then %do;
            /**Sort values**/
            data _glevels;
                %if &_typematch1=1 %then %do;
                    set %if %sysevalf(%superq(before_group)^=,boolean) %then %do;
                            _temp (keep=_before_group_ _before_group_t rename=(_before_group_=_levels_ _before_group_t=_levels_t))
                        %end;
                        %if %sysevalf(%superq(after_group)^=,boolean) %then %do;
                            _temp (keep=_after_group_ _after_group_t rename=(_after_group_=_levels_ _after_group_t=_levels_t))
                        %end;;
                    format _levels_t; 
                %end;
                %else %do;
                    set 
                        %if %sysevalf(%superq(before_group)^=,boolean) %then %do;
                            _temp (keep=_before_group_ rename=(_before_group_=_levels_))
                        %end;
                        %if %sysevalf(%superq(after_group)^=,boolean) %then %do;
                            _temp (keep=_after_group_ rename=(_after_group_=_levels_))
                        %end;;
                %end;
            run;
            data blah;set _glevels;run;
            proc sort data=_glevels nodupkey;
                by _levels_;
            run;
            %if &_typematch1=1 %then %do;
                proc sort data=_glevels;
                    by _levels_t;
                run;
            %end;
            proc sql;
                %local _grouplvls _ngroups _grouplength;
                select _levels_ into :_grouplvls separated by '|' 
                    from _glevels;
                %let _ngroups=%sysfunc(countw(%superq(_grouplvls),|));
                select max(length(_group_)) into :_grouplength separated by ''
                    from (select _before_group_ as _group_ from _temp where ^missing(_before_group_)
                          outer union corr
                          select _after_group_ as _group_ from _temp where ^missing(_after_group_));
                          
                
                %if %sysevalf(%superq(grouporder)^=,boolean) %then %do;
                    /**Pull largest value in grouporder list**/
                    %local _maxord;
                    %let _maxord = %sysfunc(max(0,%sysfunc(tranwrd(%sysfunc(compbl(%superq(grouporder))),%str( ),%str(,)))));
                    /**Pull number of items in grouporder list**/
                    %local _nord;
                    %let _nord = %sysfunc(countw(%superq(grouporder),%str( )));
                    /**Check if there are too many levels given**/
                    %if &_nord ^= &_ngroups %then %do;
                        /**Throw errors**/
                        %put ERROR: (Global: %qupcase(grouporder)): Number in order list (&_nord) does not equal the number of combined values in before and/or after group variables (&_ngroups);
                        %let nerror_run=%eval(&nerror_run+1);
                    %end;
                    /**Check if the largest value is larger than the number of levels in the by variable**/
                    %else %if &_maxord > &_ngroups %then %do;
                        /**Throw errors**/
                        %put ERROR: (Global: %qupcase(grouporder)): Largest number in grouporder list (&_maxord) is larger than the number of combined values in before and/or after group variables (&_ngroups);
                        %let nerror_run=%eval(&nerror_run+1);
                    %end;
                    /**Check if all values from 1 to max are represented in the grouporder list**/
                    %else %do _z2=1 %to &_ngroups;
                        %local _test;
                        %let _test=;
                        %do z = 1 %to &_maxord;
                            %if %scan(%superq(grouporder),&z,%str( )) = &_z2 %then %let _test=1;
                        %end;
                        %if &_test ^=1 %then %do;
                            /**Throw errors**/
                            %put ERROR: (Global: %qupcase(grouporder)): Number &_z2 was not found in the grouporder list;
                            %put ERROR: (Global: %qupcase(grouporder)): Each number from 1 to maximum number of combined values in before and/or after group variables (&_maxord) must be represented;
                            %let nerror_run=%eval(&nerror_run+1);
                        %end;                                   
                    %end;
                %end;
                /*** If any errors exist, stop macro and send to end ***/
                %if &nerror_run > 0 %then %do;
                    %put ERROR: &nerror_run run-time errors listed;
                    %put ERROR: Macro CIRCOS will cease;
                    %goto errhandl;
                %end;  
                      
                      
            alter table _temp
                modify %if %sysevalf(%superq(before_group)^=,boolean) %then %do; _before_group_ char(&_grouplength) %end;
                    %if %sysevalf(%superq(before_group)^=,boolean) and %sysevalf(%superq(after_group)^=,boolean) %then %do; , %end;
                    %if %sysevalf(%superq(after_group)^=,boolean) %then %do; _after_group_ char(&_grouplength) %end;;
            %if %sysevalf(%superq(grouporder)^=,boolean) %then %do;
                update _temp
                    set 
                        %if %sysevalf(%superq(before_group)^=,boolean) %then %do; 
                             _before_group_lvl=case(_before_group_)
                                %do i = 1 %to %sysfunc(countw(%superq(_grouplvls),|,m));
                                    when "%scan(%superq(_grouplvls),%scan(%superq(grouporder),&i,%str( )),|,m)" then &i
                                %end;
                                else _before_group_lvl end
                        %end;
                        %if %sysevalf(%superq(before_group)^=,boolean) and %sysevalf(%superq(after_group)^=,boolean) %then %do; , %end;
                        %if %sysevalf(%superq(after_group)^=,boolean) %then %do; 
                            _after_group_lvl=case(_after_group_)
                                %do i = 1 %to %sysfunc(countw(%superq(_grouplvls),|,m));
                                    when "%scan(%superq(_grouplvls),%scan(%superq(grouporder),&i,%str( )),|,m)" then &i
                                %end;
                                else _after_group_lvl end
                        %end;;                
            %end;
            %else %do;
                update _temp
                    set
                        %if %sysevalf(%superq(before_group)^=,boolean) %then %do; 
                             _before_group_lvl=case(_before_group_)
                                %do i = 1 %to %sysfunc(countw(%superq(_grouplvls),|,m));
                                    when "%scan(%superq(_grouplvls),&i,|,m)" then &i
                                %end;
                                else _before_group_lvl end
                        %end;
                        %if %sysevalf(%superq(before_group)^=,boolean) and %sysevalf(%superq(after_group)^=,boolean) %then %do; , %end;
                        %if %sysevalf(%superq(after_group)^=,boolean) %then %do; 
                            _after_group_lvl=case(_after_group_)
                                %do i = 1 %to %sysfunc(countw(%superq(_grouplvls),|,m));
                                    when "%scan(%superq(_grouplvls),&i,|,m)" then &i
                                %end;
                                else _after_group_lvl end
                        %end;;
            %end;
            update _temp
                set _before_group_lvl=&_ngroups 
                where _before_group_lvl=0;
            update _temp
                set _after_group_lvl=&_ngroups 
                where _after_group_lvl=0;
        %end;
        %else %let _ngroups=1;
    quit;                
    
    data _temp;
        set _temp;
        length _before2_ _after2_ $300.;
        _before2_=_before_;
        _after2_=_after_;
        _before_=strip(put(_before_group_lvl,z12.0))||'-'||strip(put(_before_lvl,z12.));
        _after_=strip(put(_after_group_lvl,z12.0))||'-'||strip(put(_after_lvl,z12.));
    run;
        
    /*Calculate number of unique _before_ values and save to macro variable nid*/
    proc sql noprint;
        %local nid nbfr naft i ratio;
        create table _cross as
            select _levels_,_before_,_after_, n_cross,n_total,100*n_total/sum(n_total/n_circle) as pct_total,
                n_start,pct_start,n_end,pct_end
                from (
                  select _levels_,_before_,_after_,count as n_cross,sum(count) as n_total,count(*) as n_circle,
                    sum(ifn(_before_=_levels_ and _before_^=_after_,count,ifn(_before_=_levels_ and _before_=_after_,count/2,0))) as n_start,
                    100*sum(ifn(_before_=_levels_ and _before_^=_after_,count,ifn(_before_=_levels_ and _before_=_after_,count/2,0)))/sum(count) as pct_start,
                    sum(ifn(_after_=_levels_ and _before_^=_after_,count,ifn(_after_=_levels_ and _before_=_after_,count/2,0))) as n_end,
                    100*sum(ifn(_after_=_levels_ and _before_^=_after_,count,ifn(_after_=_levels_ and _before_=_after_,count/2,0)))/sum(count) as pct_end
                    from 
                    (select _before_ as _levels_,_before_,_after_,count(*) as count from _temp where _before_^=_after_ group by _levels_,_before_,_after_
                    OUTER UNION CORR
                    select _after_ as _levels_,_before_,_after_,count(*) as count from _temp where _before_^=_after_ group by _levels_,_before_,_after_
                    OUTER UNION CORR
                    select _before_ as _levels_,_before_,_after_,count(*) as count from _temp where _before_=_after_ group by _levels_,_before_,_after_)
                    group by _levels_)
                order by _levels_,_before_,_after_;
                
        %local ratio nid levels;
        select strip(put(sum(n_total)/sum(pct_total),best12.4))||' paths per percent' into :ratio separated by '' from _cross;
        select count(distinct _levels_) into :nid separated by '' from _cross;
        select distinct _levels_ into :levels separated by '|' from _cross;
        
        create table _circle as
            select distinct a._levels_,coalesce(b._before_lvl,c._before_lvl) as _before_lvl,
                case (a._levels_)
                    %do i=1 %to &nid;
                        when "%qscan(%superq(levels),&i,|,m)" then &i
                    %end;
                else . end as _lvl_,a.pct_total as percent,a.pct_start*a.pct_total/100 as pct_start from _cross a
                left join (select distinct _before_ as _level_,_before_lvl from _temp) as b
                on a._levels_=b._level_
                left join (select distinct _after_ as _level_,_after_lvl as _before_lvl from _temp) as c
                on a._levels_=c._level_
             order by _lvl_;
    quit;
    
    /*Create data to plot the outer circle*/
    data _circle2;
        set _circle;
        by _lvl_;
        /*Removes 95 percent of the percentages to give gaps between groups in circle*/
        percent=percent*%sysevalf(1-%superq(groupgap))/100;
        pct_start=pct_start*%sysevalf(1-%superq(groupgap))/100;
        bfr_id=ifn(&unique_group_colors,_lvl_,_before_lvl);
        /*Calculates different ID groups and saves each group into a macro variable value*/
        length id $200.;
        id='c-'||strip(put(_lvl_,12.0));
        /*Saves the cumulative distance around the circle*/
        if _n_=1 then _cum=0;
        /**Creates x/y coordinate pairs for drawing the sloping rectangles around the circle**/
        /*Draws the outer part of the rectangle*/
        do i=_cum*2 to (_cum+percent)*2 by percent/%superq(points); 
            outline=1;outer=1;inner=0;           
            x=cos(&start %superq(smbl) constant("pi")*i);
            y=sin(&start %superq(smbl) constant("pi")*i);
            output;
        end;
        outline=0;           
        /*Draws the inner part of the rectangle.  Drawn at X% of the distance from the center compared to outer circle*/
        do i=(_cum+percent)*2 to _cum *2 by -percent/%superq(points);  
            outer=1;inner=0;            
            x=%sysevalf(1-%superq(barwidth))*cos(&start %superq(smbl) constant("pi")*i);
            y=%sysevalf(1-%superq(barwidth))*sin(&start %superq(smbl) constant("pi")*i);
            output;
        end;
        
        /**Creates x/y coordinate pairs for drawing the sloping rectangles around the circle**/
        /*Draws the outer part of the rectangle*/
        if pct_start>0 then do i=_cum*2 to (_cum+pct_start)*2 by pct_start/%superq(points);  
            outer=0;inner=1;            
            x=(1-%superq(barwidth)-%superq(innergap)/2)*cos(&start %superq(smbl) constant("pi")*i);
            y=(1-%superq(barwidth)-%superq(innergap)/2)*sin(&start %superq(smbl) constant("pi")*i);
            output;
        end;
        /*Draws the inner part of the rectangle.  Drawn at X% of the distance from the center compared to outer circle*/
        if pct_start>0 then do i=(_cum+pct_start)*2 to _cum *2 by -pct_start/%superq(points);  
            outer=0;inner=1;                      
            x=(1-%superq(barwidth)-%superq(innergap)/2-%superq(barwidth)/2)*cos(&start %superq(smbl) constant("pi")*i);
            y=(1-%superq(barwidth)-%superq(innergap)/2-%superq(barwidth)/2)*sin(&start %superq(smbl) constant("pi")*i);
            output;
        end;
        /*Markes the distance covered around the circle so far*/
        _cum+percent+%superq(groupgap)/&nid;
    run;
    
    %if &_ngroups>1 %then %do;
        proc sql;
            create table _grouplines as
                select distinct _levels_,input(scan(_levels_,1,'-','m'),12.) as _group_lvl,percent,pct_start,_cum from _circle2
                order by _group_lvl,_levels_,_cum;
        quit;
        data _grouplines2;
            set _grouplines;
            by _group_lvl _levels_ _cum;
            if _n_=1 then do;
                x=0;y=0;output;
                x=%sysevalf(1+%superq(barwidth)*4)*cos(&start %superq(smbl) constant("pi")*2*(0 %superq(smbl) (%superq(groupgap)/&nid)/2));
                y=%sysevalf(1+%superq(barwidth)*4)*sin(&start %superq(smbl) constant("pi")*2*(0 %superq(smbl) (%superq(groupgap)/&nid)/2));
                output;
            end;
            else if first._group_lvl then do;
                x=0;y=0;output;
                x=%sysevalf(1+%superq(barwidth)*4)*cos(&start %superq(smbl) constant("pi")*2*(_cum %superq(smbl) (%superq(groupgap)/&nid)/2));
                y=%sysevalf(1+%superq(barwidth)*4)*sin(&start %superq(smbl) constant("pi")*2*(_cum %superq(smbl) (%superq(groupgap)/&nid)/2));
                output;
            end;
            else delete;
            keep _group_lvl x y _cum;
        run;
        data _grouptext;
            set _grouplines2 end=last;
            where ^(x=0 and y=0);
            array cm {&_ngroups} _temporary_;
            length _group_ $300.;
            cm(_group_lvl)=_cum;
            if last then do;
                do i = 1 to dim(cm);
                    _group_lvl=i;
                    if i < dim(cm) then do;
                        x=cos(&start %superq(smbl) constant("pi")*(cm(i+1)+cm(i)));
                        y=sin(&start %superq(smbl) constant("pi")*(cm(i+1)+cm(i)));
                    end;
                    else do;
                        x=cos(&start %superq(smbl) constant("pi")*(1+cm(i)));
                        y=sin(&start %superq(smbl) constant("pi")*(1+cm(i)));
                    end;
                    if x=1 then rotate= 270;
                    else if x=-1 then rotate= 90;
                    else if y=1 then rotate= 0;
                    else if y=-1 then rotate= 180;
                    else if x >0 then rotate= 0-arcos(y)*360/(2*constant("pi"));
                    else if x <0 then rotate= 90-arsin(y)*360/(2*constant("pi"));
                    x=x*%sysevalf(1+%superq(barwidth)*4);
                    y=y*%sysevalf(1+%superq(barwidth)*4);
                    %if %sysevalf(%superq(grouporder)^=,boolean) %then %do i = 1 %to %sysfunc(countw(%superq(_grouplvls),|,m));
                        %if &i>1 %then %do; else %end; 
                        if _group_lvl=&i then _group_="%scan(%superq(_grouplvls),%scan(%superq(grouporder),&i,%str( )),|,m)"; 
                    %end;
                    %else %do i = 1 %to %sysfunc(countw(%superq(_grouplvls),|,m));
                        %if &i>1 %then %do; else %end; 
                        if _group_lvl=&i then _group_="%scan(%superq(_grouplvls),&i,|,m)";
                    %end;
                    output;
                end;
            end;
            keep _group_lvl _group_ rotate x y;
        run;
    %end;
    
    proc sql;       
        /*Creates the dataset used for the text plot.  Plots the labels 8% beyond circle*/
        create table _text (drop=x y) as   
            select distinct a._levels_,
            ifc(a._levels_=b._before_,b._before2_,c._after2_) as text,_cum,percent,
             cos(&start %superq(smbl) constant("pi")*2*(_cum+percent/2)) as x,
             sin(&start %superq(smbl) constant("pi")*2*(_cum+percent/2)) as y,
             %sysevalf(1+%superq(barwidth)/2)*calculated x as x_text,
             %sysevalf(1+%superq(barwidth)/2)*calculated y as y_text,
             case
                when calculated x=1 then 270
                when calculated x=-1 then 90
                when calculated y=1 then 0
                when calculated y=-1 then 180
                when calculated x >0 then 0-arcos(calculated y)*360/(2*constant("pi"))
                when calculated x <0 then 90-arsin(calculated y)*360/(2*constant("pi"))
            else . end as rotate 
            from _circle2 a left join 
             (select distinct _before_,_before2_ from _temp) b on a._levels_=b._before_ left join 
             (select distinct _after_,_after2_ from _temp) c on a._levels_=c._after_;        
                
        /*Prepares cross tabulation dataset to create the bezier curve dataset. Pulls in start/stop data from outer circle*/
        create table _cross2 as
            select a._levels_ as _before_,c._lvl_ as _before_lvl_,e._before_lvl,c._cum as bfr_cum,                  
                (a.n_cross/a.n_start)*(a.pct_start/(100*ifn(a._before_^=a._after_,1,2)))*(a.pct_total)*(1-%superq(groupgap)) as bfr_pct,
                a.pct_total*(1-%superq(groupgap)) as bfr_circle,
                b._levels_ as _after_,d._lvl_ as _after_lvl_,d._cum as aft_cum,       
                (b.n_cross/b.n_end)*(b.pct_end/(100*ifn(b._before_^=b._after_,1,2)))*(b.pct_total)*(1-%superq(groupgap)) as aft_pct,
                b.pct_total*(1-%superq(groupgap)) as aft_circle
                from (select * from _cross where _levels_=_before_) a left join 
                    (select * from _cross where _levels_=_after_) b
                    on a._before_=b._before_ and a._after_=b._after_
                    left join (select distinct _levels_,_lvl_,_cum from _circle2) c 
                    on a._levels_=c._levels_ 
                    left join (select distinct _levels_,_lvl_,_cum from _circle2) d 
                    on b._levels_=d._levels_ 
                    left join (select distinct _before_ as _level_,_before_lvl from _temp) as e
                    on a._levels_=e._level_
            order by (_before_lvl_=_after_lvl_),_before_lvl_,
                      ifn(_before_lvl_>_after_lvl_,_before_lvl_-_after_lvl_,(_before_lvl_-_after_lvl_)+&nid),
                      _before_lvl_;
        /*Prepares dataset for tick marks*/
        create table _tickmarks as
            select distinct _lvl_,percent,_cum from _circle2;
    quit;
    /*Creates the plot dataset for the tick marks*/
    data _tickmarks2;
        set _tickmarks;
        by _lvl_;
        length tickmark $200.;
        if first._lvl_ then tick=0;
        do i=(_cum*2+0.02) to (_cum+percent)*2 by 0.02; 
            tick+1;
            tickmark=': '||strip(put(_lvl_,12.0))||'-'||strip(put(tick,12.0));
            xtick=cos(&start %superq(smbl) constant("pi")*i);
            ytick=sin(&start %superq(smbl) constant("pi")*i);
            output;
            if mod(tick,5)=0 then do;
                xtick=(1.025)*cos(&start %superq(smbl) constant("pi")*i);
                ytick=(1.025)*sin(&start %superq(smbl) constant("pi")*i);
            end;
            else do;
                xtick=(1.0125)*cos(&start %superq(smbl) constant("pi")*i);
                ytick=(1.0125)*sin(&start %superq(smbl) constant("pi")*i);
            end;
            output;
        end;
        keep xtick ytick tickmark;
    run;
    /*Creates the plot dataset for the bezier curves*/
    data _cross3;
        set _cross2 end=last;
        /**Arrays to keep track of how much of each group's outer circle segment is used**/
        array _circle {%superq(nid)} _temporary_;
        array _circle2 {%superq(nid)} _temporary_;
        
        /**Assigns a unique ID number for each bezier curve**/
        length id $200.;
        id='b, '||strip(put(_before_lvl_,12.0))||'-'||strip(put(_after_lvl_,12.0));
        /**Uses the ID assigned to _before_ group when assigning colors later**/
        bfr_id=ifn(&unique_group_colors,_before_lvl_,_before_lvl);
        
        /**Starts at maximum percentage for that group**/
        if _circle(_before_lvl_)=. then _circle(_before_lvl_)=0/100;   
        /**Finds the starting and stopping percentage around the circle for start of bezier curve**/
        start2=_circle(_before_lvl_);
        start1=_circle(_before_lvl_) + bfr_pct/100;
        /**Subtracts used up percentage from available group percentage**/
        _circle(_before_lvl_)+ bfr_pct/100;
        
        
        /**Starts at maximum percentage for that group**/
        if _circle2(_after_lvl_)=. then _circle2(_after_lvl_)=aft_circle/100;
        /**Finds the starting and stopping percentage around the circle for end of bezier curve**/
        end1=_circle2(_after_lvl_);
        end2=_circle2(_after_lvl_) - aft_pct/100;
        /**Subtracts used up percentage from available group percentage**/
        _circle2(_after_lvl_)+ -aft_pct/100;
        
        /**Finds the x/y coordinates for the start/end of the bezier curves**/
        /**Circle starts at 270 degrees or 3pi/2 radians and goes clockwise**/
        /*Starting x/y for start of bezier curve*/
        i=(bfr_cum+start1)*2;          
        bx1a=(1-%superq(innergap)-3*%superq(barwidth)/2)*%sysevalf(1-%superq(innergap))*cos(&start %superq(smbl) constant("pi")*i);
        by1a=(1-%superq(innergap)-3*%superq(barwidth)/2)*%sysevalf(1-%superq(innergap))*sin(&start %superq(smbl) constant("pi")*i);
        /*Ending x/y for start of bezier curve*/
        i=(bfr_cum+start2)*2;          
        bx1b=(1-%superq(innergap)-3*%superq(barwidth)/2)*%sysevalf(1-%superq(innergap))*cos(&start %superq(smbl) constant("pi")*i);
        by1b=(1-%superq(innergap)-3*%superq(barwidth)/2)*%sysevalf(1-%superq(innergap))*sin(&start %superq(smbl) constant("pi")*i);
        /*Starting x/y for end of bezier curve*/
        i= (aft_cum+end1)*2;   
        bx2a=(1-%superq(innergap)-3*%superq(barwidth)/2)*%sysevalf(1-%superq(innergap))*cos(&start %superq(smbl) constant("pi")*i);
        by2a=(1-%superq(innergap)-3*%superq(barwidth)/2)*%sysevalf(1-%superq(innergap))*sin(&start %superq(smbl) constant("pi")*i);
        /*Ending x/y for end of bezier curve*/
        i= (aft_cum+end2)*2;   
        bx2b=(1-%superq(innergap)-3*%superq(barwidth)/2)*%sysevalf(1-%superq(innergap))*cos(&start %superq(smbl) constant("pi")*i);
        by2b=(1-%superq(innergap)-3*%superq(barwidth)/2)*%sysevalf(1-%superq(innergap))*sin(&start %superq(smbl) constant("pi")*i);
            
        /***Create x/y coordinates to draw bezier curve polygons***/        
        /**Base of start of polygon**/
        do i=(bfr_cum+start1)*2 to (bfr_cum+start2)*2 by (start2-start1)/%superq(points);            
            x=(1-%superq(innergap)-3*%superq(barwidth)/2)*cos(&start %superq(smbl) constant("pi")*i);
            y=(1-%superq(innergap)-3*%superq(barwidth)/2)*sin(&start %superq(smbl) constant("pi")*i);
            output;
        end;
        /**Draw one side of connecting bezier curve**/   
        do i = 0 to 1 by 1/%superq(points);
            x=(1-i)**2*bx1b + 2*(1-i)*i*0 + i**2*bx2a;
            y=(1-i)**2*by1b + 2*(1-i)*i*0 + i**2*by2a;
            output;
        end;   
        /**Draw end of polygon**/
        do i=(aft_cum+end1)*2 to (aft_cum+end2)*2 by (end2-end1)/%superq(points);            
            x=(1-%superq(innergap)-3*%superq(barwidth)/2)*cos(&start %superq(smbl) constant("pi")*i);
            y=(1-%superq(innergap)-3*%superq(barwidth)/2)*sin(&start %superq(smbl) constant("pi")*i);
            output;
        end;
        /**Draw remaining side of bezier curve**/
        do i = 0 to 1 by 1/%superq(points);
            x=(1-i)**2*bx2b + 2*(1-i)*i*0 + i**2*bx1a;
            y=(1-i)**2*by2b + 2*(1-i)*i*0 + i**2*by1a;
            output;
        end;
        keep _before_ _after_ bfr_id id x y start1 start2 end1 end2 bfr_pct bfr_cum aft_pct aft_cum bfr_circle aft_circle;
    run;
      
    /*Merge plot components together into a single dataset*/     
    data _plot;
        set _circle2 (keep=id bfr_id x y outline outer inner) _cross3 (in=b keep=id bfr_id x y );
        if b then bezier=1;
    run;  
    data _plot;
        merge _plot _text (keep=x_text y_text text rotate) _tickmarks2            
        %if &_ngroups>1 %then %do; 
            _grouplines2 (drop=_cum rename=(x=_glx y=_gly)) 
            _grouptext (drop=_group_lvl rename=(x=_gtx y=_gty _group_=_gttext rotate=_gtrotate)) 
        %end;;
    run;        
             
    /**Creates document to save**/
    %if %sysevalf(%superq(outdoc)=,boolean)=0 %then %do;
        ods escapechar='^';
        /**Sets up DPI and ODS generated file**/
        ods &destination 
            %if %qupcase(&destination)=RTF %then %do; 
                file="&outdoc"
                image_dpi=&dpi startpage=NO 
            %end;
            %else %if %qupcase(&destination)=HTML %then %do; 
                image_dpi=&dpi 
                %if %upcase(&sysscpl)=LINUX or %upcase(&sysscpl)=UNIX %then %do;
                    path="%substr(&outdoc,1,%sysfunc(find(&outdoc,/,-%sysfunc(length(&outdoc)))))"
                    file="%scan(&outdoc,1,/,b)"
                %end;
                %else %do;
                    path="%substr(&outdoc,1,%sysfunc(find(&outdoc,\,-%sysfunc(length(&outdoc)))))"
                    file="%scan(&outdoc,1,\,b)"
                %end;
                %if %sysevalf(%superq(gpath)=,boolean)=0 %then %do;
                    gpath="&gpath" (url=none)
                %end;
            %end;
            %else %if %qupcase(&destination)=PDF %then %do; 
                dpi=&dpi startpage=NO bookmarkgen=off notoc
                file="&outdoc"
            %end;
            %else %if %qupcase(&destination)=EXCEL %then %do; 
                file="&outdoc"
                dpi=&dpi options(sheet_interval='none') 
            %end;
            %else %if %qupcase(&destination)=POWERPOINT %then %do; 
                file="&outdoc"
                dpi=&dpi 
            %end;;
    %end;
    %else %do;
        ods listing close image_dpi=&dpi;
    %end;     
    /*Save plot template to work directory*/  
    ods path WORK.TEMPLAT(UPDATE) SASHELP.TMPLMST (READ); 
    /*Define plot template to render*/
    proc template;
        define statgraph _circos;
        /*Sets size of plot*/
        begingraph /  designheight=%superq(height) designwidth=%superq(width)
                backgroundcolor=&background        
                %if %superq(transparent)=1 %then %do;
                    opaque=false 
                %end;
                /**Turns the border around the plot off if border=0**/
                %if %superq(border)=0 %then %do;
                    border=false 
                    %if %superq(transparent)=1 %then %do;
                        pad=0px    
                    %end;
                %end;;
            /*Set up attribute map for colors*/
            discreteattrmap name="attrs" / ignorecase=false;
                %do i = 1 %to &nid;                    
                    value "&i" /   
                        %if %sysevalf(%qscan(&color,&i,%str( ))^=,boolean) %then %do;                    
                            fillattrs=(color=%qscan(&color,&i,%str( )))
                        %end;    ;    
                %end;
            enddiscreteattrmap;
            discreteattrvar attrvar=_attrvar_ var=bfr_id attrmap="attrs" ; 
            /*Adds and formats the title*/
            %if %sysevalf(%superq(title)^=,boolean) %then %do i = 1 %to %sysfunc(countw(%superq(title),|,m));
                entrytitle halign=%superq(titlealign) "%scan(%superq(title),&i,|,m)" /
                    textattrs=(color=&fontcolor weight=%superq(titleweight) size=%superq(titlesize));
            %end;
            entryfootnote halign=right "&ratio" /
                textattrs=(color=&fontcolor weight=normal size=8pt);
            /*Sets up graph space*/
            layout overlay / walldisplay=none
                %if %sysevalf(%superq(before_group)^=,boolean) or %sysevalf(%superq(after_group)^=,boolean) %then %do;
                    xaxisopts=(type=linear linearopts=(viewmin=-1.2 viewmax=1.2) display=none)
                    yaxisopts=(type=linear linearopts=(viewmin=-1.2 viewmax=1.2) display=none)
                %end;
                %else %do;
                    xaxisopts=(type=linear linearopts=(viewmin=-1.1 viewmax=1.1) display=none)
                    yaxisopts=(type=linear linearopts=(viewmin=-1.1 viewmax=1.1) display=none)
                %end;;
                 
                 /**Colors are taken from list during macro call**/
                 /*Draws the Bezier curves*/
                 polygonplot x=eval(ifn(bezier=1,x,.)) y=y id=id / display=(fill) group=_attrvar_
                    fillattrs=(transparency=%superq(transparency));
                 /*Draws the outer circle.  Each outer rectangle around the circle has its own polygon plot*/
                 polygonplot x=eval(ifn(bezier^=1,x,.)) y=y id=id / display=(fill) group=_attrvar_;
                 /*Draws the axis lines*/
                 seriesplot x=eval(ifn(outline =1,x,.)) y=y / lineattrs=(color=&axiscolor pattern=1 thickness=2) group=id;
                 /*Draws the axis tick-marks*/
                 seriesplot x=xtick y=ytick / lineattrs=(color=&axiscolor pattern=1 thickness=2) group=tickmark;  
                /*Plots the labels around the circle*/
                textplot x=x_text y=y_text text=text / 
                    textattrs=(color=&fontcolor size=%superq(labelsize) weight=%superq(labelweight))
                    rotate=rotate
                    position=top vcenter=bbox;
                /*Group Lines*/
                %if &_ngroups>1 %then %do;
                    seriesplot x=_glx y=_gly / lineattrs=(color=&axiscolor pattern=1 thickness=2) group=_group_lvl; 
                    /*Plots the labels around the circle*/
                    textplot x=_gtx y=_gty text=_gttext / 
                        textattrs=(color=&fontcolor size=%superq(labelsize) weight=%superq(labelweight))
                        rotate=_gtrotate
                        position=top vcenter=bbox;
                %end;
             endlayout;
        endgraph;
        end;
    run;
    
    /*creates the graph.  Anti-aliasing is increased due to number of plot points*/
    %if %sysevalf(%superq(gpath)^=,boolean) %then %do;
        ods listing gpath="%superq(gpath)";
    %end;
    ods results;
    ods select all;
    %local workdir;
    %let workdir=%trim(%sysfunc(pathname(work))); 
    /**Names and formats the image**/
    %if %sysevalf(%superq(plottype)^=,boolean) %then %do; 
        %if %qupcase(&plottype)=TIFF or %qupcase(&plottype)=TIF %then %do;
            ods graphics / outputfmt=png;    
        %end;
        %else %do;
            ods graphics / outputfmt=&plottype;  
        %end;          
    %end;
    %if %sysevalf(%superq(plotname)^=,boolean) %then %do; 
        ods graphics / reset=index imagename="&plotname";
    %end;  
    /**Turns on Scalable-Vector-Graphics**/
    %if &svg = 1 %then %do;
        %if %qupcase(&destination) = RTF or %qupcase(&destination) = EXCEL or %qupcase(&destination) = POWERPOINT %then %do;
            ods graphics / OUTPUTFMT=EMF;
        %end;
        %else %if %qupcase(&destination) = HTML %then %do;
            ods graphics / OUTPUTFMT=SVG;
        %end;
        %else %do;
            ods graphics / OUTPUTFMT=STATIC;
        %end;
    %end;
    /**Sets plot options**/
    options notes;
    ods graphics / antialiasmax=%superq(antialias) scale=off imagename="%superq(plotname)" height=&height width=&width;
    proc sgrender data=_plot template=_circos ;
    run;
    /**Creates the TIFF file from the PNG file created earlier**/
    %if %qupcase(&plottype)=TIFF or %qupcase(&plottype)=TIF %then %do;
        %local _fncheck _fncheck2;
        options nonotes;
        %if %sysevalf(%superq(gpath)=,boolean) %then %do;
            filename cirpng "./&plotname..png"; 
            filename cirtif "./&plotname..tiff";
            data _null_;
                x=fexist('cirpng');
                x2=fdelete('cirtif');
                call symput('_fncheck',strip(put(x,12.)));
                call symput('_fncheck2',strip(put(x2,12.)));
            run;
            %if %sysevalf(%superq(_fncheck)^=1,boolean) %then %do;
                filename cirpng "./&plotname.1.png"; 
            %end;
        %end;
        %else %do;
            filename cirpng "%sysfunc(tranwrd(&gpath./&plotname..png,//,/))"; 
            filename cirtif "%sysfunc(tranwrd(&gpath./&plotname..tiff,//,/))"; 
            data _null_;
                x=fexist('cirpng');
                x2=fdelete('cirtif');
                call symput('_fncheck',strip(put(x,12.)));
                call symput('_fncheck2',strip(put(x2,12.)));
            run;
            %if %sysevalf(%superq(_fncheck)^=1,boolean) %then %do;
                filename cirpng "%sysfunc(tranwrd(&gpath./&plotname.1.png,//,/))"; 
            %end;
        %end;
        options notes;
        goptions device=&tiffdevice gsfname=cirtif 
            xmax=&width ymax=&height 
            xpixels=%sysevalf(%sysfunc(compress(&width,abcdefghijklmnopqrstuvwxyz,i))*&dpi) 
            ypixels=%sysevalf(%sysfunc(compress(&height,abcdefghijklmnopqrstuvwxyz,i))*&dpi)
            imagestyle=fit iback=cirpng;
        proc gslide;
        run;
        quit; 
        data _null_;
            x=fdelete('cirpng');
        run;
        filename cirpng clear;
        filename cirtif clear;
    %end;
    /**Closes the ODS file**/
    %if %sysevalf(%superq(outdoc)=,boolean)=0 %then %do;
        ods &destination close;
    %end;
    /*Saves out dataset*/
    %if %sysevalf(%superq(out)^=,boolean) %then %do;
        data &out;
            set _plot;
        run;
    %end;
    options nonotes;   
    %errhandl:
    /*Deletes temporary datasets*/
    proc datasets nolist nodetails;
        delete _temp _stacked _cross _cross2 _cross3 _plot _levels
            _circle _circle2 _text _anno1 _anno2 _anno _tickmarks _tickmarks2
            _grouplines _grouplines2 _grouptext _glevels;
    quit;
    /**Reload previous Options**/ 
    %if &_listing=1 %then %do;
        ods Listing;
    %end;
    ods path &_odspath;
    options mergenoby=&_mergenoby &_notes &_qlm;
    %put CIRCOS has finished processing, runtime: %sysfunc(putn(%sysevalf(%sysfunc(TIME())-&_starttime.),mmss.)); 
%mend;
