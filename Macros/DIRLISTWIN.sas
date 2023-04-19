%macro DIRLISTWIN( PATH      /* Windows path of directory to examine                             */
                 , MAXDATE=  /* [optional] maximum date/time of file to report                   */
                 , MINDATE=  /* [optional] minimum date/time of file to report                   */
                 , MAXSIZE=  /* [optional] maximum size of file to report (bytes)                */
                 , MINSIZE=  /* [optional] minimum size of file to report (bytes)                */
                 , OUT=      /* [optional] name of output file containing results of %DIRLISTWIN */
                 , REPORT=Y  /* [optional] flag controlling report creation                      */
                 , REPORT1=N /* [optional] flag controlling 1-line report creation               */
                 , SUBDIR=Y  /* [optional] include subdirectories in directory processing        */
                 ) ;

   /* PURPOSE: create listing of files in specified directory to make evident
    *
    * NOTE:    %DIRLISTWIN is designed to be run on SAS installations using the Windows O/S
    *
    * NOTE:    &PATH must contain valid Windows path, e.g., 'c:' or 'c:\documents and settings'
    *
    * NOTE:    &MAXDATE and &MINDATE must be SAS date/time constants in one of the following formats:
    *             'ddMONyy:HH:MM'dt *** datetime constant ***
    *             'ddMONyy'd        *** date     constant ***
    *             'HH:MM't          *** time     constant ***
    *
    * NOTE:    if &SUBDIR = Y then all subdirectories of &PATH will be searched
    *          otherwise, only the path named in &PATH will be searched
    *
    * NOTE:    uses Windows pipe option on file reference
    *
    * NOTE:    if %DIRLISTWIN is used successively in the same job, then
    *             the report will contain the cumulative directory listing of all directories searched
    *             a separate &OUT dataset will be created for each %DIRLISTWIN invocation
    *
    * USAGE:
    *  %DIRLISTWIN( c:/data1 )
    *  %DIRLISTWIN( c:/data1, MINDATE='01JAN04:00:00:00'dt, MAXDATE='16MAR04:23:59:59'dt )
    *  %DIRLISTWIN( c:/data1, MINDATE='00:00:00't, MAXDATE='23:59:59't, MINSIZE=1000000 )
    *  %DIRLISTWIN( d:/data2, REPORT=Y )
    *  %DIRLISTWIN( d:, OUT=LIBNAME.DSNAME, REPORT=N )
    *  %DIRLISTWIN( d:/documents and settings/robett/my documents/my sas files/v8 )
    *
    * ALGORITHM:
    *  use Windows pipe with file reference to execute 'dir' command to obtain directory contents
    *  parse pipe output as if it were a file to extract file names, other info
    *  [optional] select files that are within the time interval [ &MINDATE, &MAXDATE ]
    *  [optional] select files that are at least as large as &MINSIZE bytes and no larger than &MAXSIZE
    *  sort records by owner, path, filename
    *  [optional] create report of files per owner/path if requested
    *  [optional] create 1-line report of files per owner/path if requested
    */

   %let DELIM   = ' ' ;
   %let REPORT  = %eval( %upcase( &REPORT ) = Y ) ;
   %let REPORT1 = %eval( %upcase( &REPORT1 ) = Y ) ;

   %if %upcase( &SUBDIR ) = Y %then %let SUBDIR = /s ; %else %let SUBDIR = ;

   /*============================================================================*/
   /* external storage references
   /*============================================================================*/

   /* run Windows "dir" DOS command as pipe to get contents of data directory */

   filename DIRLIST pipe "dir /-c /q &SUBDIR /t:c ""&PATH""" ;

   /*############################################################################*/
   /* begin executable code
   /*############################################################################*/

   /* use Windows pipe to recursively find all files in &PATH
    * parse out extraneous data, including unreadable directory paths
    * process files >= &MINSIZE in size
    *
    * directory list structure:
    *    "Directory of" record precedes listing of contents of directory:
    *    
    *    Directory of <volume:> \ <dir1> [ \ <dir2>\... ]
    *    mm/dd/yy hh:mm:ss [AM|PM] ['<DIR>' | size ] filename.type
    *
    *    example:
    *
    *       Volume in drive C is WXP
    *       Volume Serial Number is 18C2-3BAA
    *
    *       Directory of C:\Documents and Settings\robett\My Documents\My SAS Files\V8\Test
    *
    *       05/21/03  10:58 AM    <DIR>          CARYNT\robett          .
    *       05/21/03  10:58 AM    <DIR>          CARYNT\robett          ..
    *       12/24/03  10:22 AM    <DIR>          CARYNT\robett          Codebook
    *       04/23/01  02:42 PM               387 CARYNT\robett          printCharMat.sas
    *       10/09/03  11:35 AM             20582 CARYNT\robett          test.log
    *       10/28/03  08:02 AM             58682 CARYNT\robett          test.lst
    *       10/09/03  11:35 AM              1575 CARYNT\robett          test.sas
    */

   data dirlist ;
      length path filename $255 line $1024 owner $17 temp $16 ;
      retain path ;

      infile DIRLIST length=reclen ;
      input line $varying1024. reclen ;

      if reclen = 0 then delete ;

      if scan( line, 1, &DELIM ) = 'Volume'  | /* beginning of listing */
         scan( line, 1, &DELIM ) = 'Total'   | /* antepenultimate line */
         scan( line, 2, &DELIM ) = 'File(s)' | /* penultimate line     */
         scan( line, 2, &DELIM ) = 'Dir(s)'    /* ultimate    line     */
      then delete ;

      dir_rec = upcase( scan( line, 1, &DELIM )) = 'DIRECTORY' ;

      /* parse directory     record for directory path
       * parse non-directory record for filename, associated information
       */

      if dir_rec
      then
         path = left( substr( line, length( "Directory of" ) + 2 )) ;
      else do ;
         date = input( scan( line, 1, &DELIM ), mmddyy8. ) ;

         time = input( scan( line, 2, &DELIM ), time5. ) ;

         post_meridian = ( scan( line, 3, &DELIM ) = 'PM' ) ;

         if post_meridian then time = time + '12:00:00'T ; /* add 12 hours to represent on 24-hour clock */

         temp = scan( line, 4, &DELIM ) ;

         if temp = '<DIR>' then size = 0 ; else size = input( temp, best. ) ;

         owner = scan( line, 5, &DELIM ) ;

         /* scan delimiters cause filename parsing to require special treatment */

         filename = scan( line, 6, &DELIM ) ;

         if filename in ( '.' '..' ) then delete ;

         ndx = index( line, scan( filename, 1 )) ;

         filename = substr( line, ndx ) ;
      end ;

      /* date/time filter */

      %if %eval( %length( &MAXDATE ) + %length( &MINDATE ) > 0 )
      %then %do ;
         if not dir_rec
         then do ;
            datetime = input( put( date, date7. ) || ':' || put( time, time5. ), datetime13. )  ;

            %if %length( &MAXDATE ) > 0 %then %str( if datetime <= &MAXDATE ; ) ;
            %if %length( &MINDATE ) > 0 %then %str( if datetime >= &MINDATE ; ) ;
         end ;
      %end ;

      /* size filter */

      %if %length( &MAXSIZE ) > 0 %then %str( if size <= &MAXSIZE ; ) ;
      %if %length( &MINSIZE ) > 0 %then %str( if size >= &MINSIZE ; ) ;
    
      drop dir_rec line ndx post_meridian temp ;
   run ;

   proc sort data=dirlist out=dirlist ; by owner path filename ; run ;

   /*============================================================================*/
   /* create output dataset if requested
   /*============================================================================*/

   %if %length( &OUT ) > 0 %then %str( data &OUT ; set dirlist ; run ; ) ;

   /*============================================================================*/
   /* add data for current directory path to cumulative report dataset
   /*============================================================================*/

   proc append base=report data=dirlist ; run ;

   /*============================================================================*/
   /* break association to previous path prior to next %DIRLISTWIN invocation
   /*============================================================================*/

   filename DIRLIST clear ;

   /*============================================================================*/
   /* create report of files by owner, if requested
   /*============================================================================*/

  %if &REPORT
  %then %do ;
      title "Directory Listing" ;
      title1 "Path: &PATH" ;
      proc report center data=report headskip nowindows spacing=1 split='\' ;
         column owner path size date time filename ;

         define owner    / order   width=17        'Owner' ;
         define path     / order   width=32 flow   'Path' ;
         define size     / display format=comma19. 'Size/(bytes)' ;
         define date     / display format=mmddyy8. 'Date' ;
         define time     / display format=time5.   'Time' ;
         define filename / display width=32 flow   'File Name' ;
      run ;
      title ;

   %end ;

  %if &REPORT1
  %then %do ;
      /* create 1-line report: truncate path to fit landscape layout */

      data report1( keep= owner path1 size ) ;
         length path1 $287 ; /* 255 chars from above + 32 chars max filename */
         set report ;

         path1 = catx( '\', path, filename ) ;

         path1 = left( reverse( substr( left( reverse( path1 )), 1, 80 ))) ;
      run ;

      title "Directory Listing" ;
      title1 "Path: &PATH" ;
      proc report nocenter data=report1 headskip nowindows spacing=1 split='/' ;
         column owner path1 size ;

         define owner / order width=17 'Owner' ;
         define path1 / order width=80 'Path' ;
         define size  / display format=comma19. 'Size/(bytes)' ;
      run ;
      title ;

   %end ;
%mend DIRLISTWIN ;
