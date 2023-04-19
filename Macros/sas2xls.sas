/*-----
 * group: Data out
 * purpose: Export SAS datasets and OUTPUT catalog entries as worksheets of an Excel file.<BR>This macro can write to _WEBOUT to deliver binary Excel worksheets from SAS/Intrnet applications
 * notes: Requires Perl and modules XML::Simple, Spreadsheet::WriteExcel and Date::Calc<BR><i>Current versions of Excel read XML files directly and you may not need this macro. Check out <a href="?m=xmlib">xmlib<a> instead</i>.
 */

/**html
 * <PRE STYLE="border:1px solid #888;background-color:#ebe5c9"> Important:
 * Your perl installation may require some encoding files.
 * This is because ENCODING variable output by the SASXML tagset has the value
 * <b>windows-1252</b>
 *
 * On my test system, the perl program initially errored, with the message
 * <i>"Couldn't open encmap windows-1252.enc:"</i>
 * showing in the SAS log
 *
 * I downloaded
 *  http://search.cpan.org/src/MSERGEANT/XML-Parser-2.34
 *                            /Parser/Encodings/<a href="http://search.cpan.org/src/MSERGEANT/XML-Parser-2.34/Parser/Encodings/">windows-1252.enc</a>
 * into my
 *  /perl/site/lib/XML/Parser/Encodings folder
 *
 * and the error went away.</PRE>
 */

%macro sas2xls (
  file=
, fileref=
, sheet1=,  sheet2=,  sheet3=,  sheet4=,  sheet5=
, sheet6=,  sheet7=,  sheet8=,  sheet9=,  sheet10=
, sheet11=, sheet12=, sheet13=, sheet14=, sheet15=
, sheet16=, sheet17=, sheet18=, sheet19=, sheet20=
, sheet21=, sheet22=, sheet23=, sheet24=, sheet25=
, sheet26=, sheet27=, sheet28=, sheet29=, sheet30=
, sheet31=, sheet32=, sheet33=, sheet34=, sheet35=
, sheet36=, sheet37=, sheet38=, sheet39=, sheet40=
, sheet41=, sheet42=, sheet43=, sheet44=, sheet45=
, sheet46=, sheet47=, sheet48=, sheet49=, sheet50=
, perl= perl -w
, deleteXML = 1
);

  %*
  %* sas2xls - Create an excel file containing one worksheet per SAS dataset
  %*            Requires Perl and some perl modules.
  %*
  %* Richard A. DeVenezia
  %* 11/18/03 adapted from sas2xls
  %* 11/23/03 handle time, date and datetime values
  %* 11/25/03 add translate to xmlappend invocations
  %*
  %* Does this:
  %*   Use XML library engine to write SAS data sets to
  %*   an xml file.  This file is read by a Perl program
  %*   which creates a multi-sheet workbook from it.
  %*
  %* Does not:
  %*   Handle formatting issues. We will have to wait for SAS to get
  %*   off their duff and write an ODS EXCEL destination.
  %*
  %* Perl Host requirements:
  %*   Perl 5.005 (or later)
  %*   Spreadsheet::WriteExcel
  %*   Parse::RecDescent
  %*   File::Temp
  %*
  %* Assumptions:
  %*   Perl and SAS are installed on same host
  %*
  %* Argument categories and special considerations:
  %*
  %*-----
  %* Excel output
  %*
  %*   FILE=<host-path>         or
  %*   FILEREF=<SAS-fileref>
  %*
  %*   If fileref _WEBOUT is passed, the proper content-type will be prepended
  %*   to the generated excel file
  %*
  %*-----
  %* Worksheet names and content source
  %*
  %*  Form1: SHEET<n>=[~][<SheetName>]:[<Heading>]:<Dataset>|<CatalogEntry>
  %*  Form2: SHEET<n>=<Dataset>|<CatalogEntry>
  %*
  %*  <n> can range from 1 to 50
  %*
  %*  Caveat: Due to the use of : as a specification delimiter, a SHEET<n>
  %*          parameter should not have a : in it (such as in a data set
  %*          where clause). Use a SQL or Data Step view to get around
  %*          this restriction.
  %*
  %*  Form 1:
  %*
  %*   [~][<SheetName>]:[<Heading>]:<Dataset>|<CatalogEntry>
  %*
  %*     ~ is optional
  %*
  %*       A special formatting indicator
  %*       If SheetName starts with tilde (~) the worksheet is formatted
  %*       to hide grid lines and all cells are Courier New font
  %*       Use this feature when transferring a PROCs text output to Excel.
  %*       A PROCs text output can be captured to a catalog using Proc PRINTTO.
  %*
  %*     <SheetName> is optional
  %*
  %*       The worksheet name.
  %*       If not present, the dataset label of <Dataset> will be used
  %*       If <Dataset> is unlabelled, then <Dataset> will be used
  %*
  %*     <Heading> is optional
  %*
  %*       Heading controls what appears in Row 1 of the Excel worksheet.
  %*       Heading may be:
  %*         LABEL - Column label, name is used if unlabelled column
  %*         NAME  - Column name
  %*         NONE  - No column heading row
  %*       Heading defaults to NAME.
  %*
  %*     <Dataset>
  %*
  %*       A SAS data set or view to be placed in a Excel worksheet.
  %*       <Dataset> may contain any valid dataset options such as where=,
  %*       keep= and drop=.
  %*
  %*     <CatalogEntry>
  %*
  %*       A SOURCE catalog entry. Use either three-level or four-level.
  %*       If catalog entry is captured PROC text output the argument
  %*       should use the ~ prefix for best results.
  %*
  %*  Form 2:
  %*
  %*   <Dataset>|<CatalogEntry>
  %*
  %*     <Dataset>
  %*
  %*       A SAS data set or view to be placed in a Excel worksheet.
  %*       <Dataset> may contain any valid dataset options such as where=,
  %*       keep= and drop=.
  %*       The sheet will be named according to the dataset label.
  %*       If <Dataset> is unlabelled, then <Dataset> will be used.
  %*       There will be a header row of variable names.
  %*
  %*     <CatalogEntry>
  %*
  %*       A SOURCE catalog entry. Use either three-level or four-level name.
  %*       The worksheet name is the memname.entry part of the resolved
  %*       four-level name and will be ~ formatted.
  %*
  %*-----
  %* Perl executable
  %*
  %*   PERL=<host-path>
  %*
  %*-----
  %* Example, see bottom comment
  %*
  %*-----
  %* Caveats:
  %* Extraneous tables (layout and contents) needed by the Perl program
  %* are placed in the XML file.  If you try to use the XML generated
  %* by this macro in other XML processors, you will have some confusion.
  %* Some 'non-printable' characters in SAS character variables are
  %* translated to spaces.
  %*;

  %local NOTES SOURCE SOURCE2 MPRINT;

  %let NOTES   = %sysfunc (getoption(NOTES));
  %let SOURCE  = %sysfunc (getoption(SOURCE));
  %let SOURCE2 = %sysfunc (getoption(SOURCE2));
  %let MPRINT  = %sysfunc (getoption(MPRINT));

* options NONOTES NOSOURCE NOSOURCE2 NOMPRINT;

  %local THIS VERSION;
  %local RC DSID I N SHEET TYPE STYLE;
  %local PART1 PART2 PART3 PART4 DS WN HD;
  %local LIB MEM OBJ TYP;

  %*---------------------------------------------------------------------------
  %*;

  %let THIS = sas2xls;
  %let VERSION = 2003.11.18;

  %*---------------------------------------------------------------------------
  %* Check for xmlappend macro;

  %if (not %sysfunc(exist(WORK.SASMACR.XMLAPPEND.MACRO, CATALOG))) %then %do;
    %put ERROR: &THIS: The required macro XMLAPPEND was not found.;
    %goto EndMacro;
  %end;

  %*---------------------------------------------------------------------------
  %* Check for perlpgm data;

  %if (not %sysfunc(exist(WORK.PERLPGM))) %then %do;
    %put ERROR: &THIS: The required data WORK.PERLPGM was not found.;
    %goto EndMacro;
  %end;

  %*---------------------------------------------------------------------------
  %* Check for XLS destination;

  %if (%superq(FILEREF) eq ) and (%superq(FILE) eq ) %then %do;
    %put ERROR: &THIS: FILEREF or FILE must be specified;
    %goto EndMacro;
  %end;

  %if (%superq(FILEREF) ne ) and (%superq(FILE) ne ) %then %do;
    %put ERROR: &THIS: Specify FILEREF or FILE, not both;
    %goto EndMacro;
  %end;

  %*---------------------------------------------------------------------------
  %* Make sure that FILEREF specified has been previously assigned;

  %if (%superq(FILEREF) ne ) %then %do;
    %let FILE= ;
    %if (%sysfunc (fileref(&FILEREF)) > 0) %then
      %put ERROR: &THIS: Fileref &FILEREF is not assigned;
  %end;

  %*---------------------------------------------------------------------------
  %* Prepare to examine each parameter;

  %let I = 1;
  %let N = 0;

  %*---------------------------------------------------------------------------
  %* Examine each value of each sheet<n> parameter;

  %do %while (&I <= 50);

    %if (%superq(SHEET&I) eq ) %then %goto NxtSheet;

    %* slip in a leading : so that a leading :
    %* is recognized as a blank;

    %let SHEET = :&&SHEET&I;
    %let SHEET = %sysfunc(tranwrd(&SHEET,::,: :));
    %let SHEET = %sysfunc(tranwrd(&SHEET,::,: :));

    %let PART1 = %scan (&SHEET,1,:);
    %let PART2 = %scan (&SHEET,2,:);
    %let PART3 = %scan (&SHEET,3,:);

    %if (%qsubstr (&PART1%str( ),1,1) eq %str(~)) %then %do;
      %let PART1 = %substr(&PART1%str( ),2);
      %let STYLE = MONO;
    %end;
    %else
      %let STYLE = NORMAL;

    %if (%superq(PART1) eq) and
        (%superq(PART2) eq) and
        (%superq(PART3) eq)
    %then %do;
      %put ERROR: &THIS: SHEET&I=&&SHEET&I can not be parsed.;
      %put ERROR: &THIS: Continuing to next sheet;
      %goto NxtSheet;
    %end;

    %if (%superq(PART2) ne ) and (%superq(PART3) eq ) %then %do;
      %put ERROR: &THIS: SHEET&I=&&SHEET&I can not be parsed.;
      %put ERROR: &THIS: Continuing to next sheet;
      %goto NxtSheet;
    %end;

    %if (%superq(PART2) eq ) and (%superq(PART3) eq ) %then %do;
      %let DS = &PART1;
      %let HD = NAME;
      %let WN =;
    %end;
    %else %do;
      %let WN = &PART1;
      %let HD = &PART2;
      %let DS = &PART3;
    %end;

    %let dsid = %sysfunc (open (&DS));
    %if &dsid = 0 %then %do;
      %* not an openable dataset, check if its a catalog entry;
      %let LIB = %scan (&DS,1,.);
      %let MEM = %scan (&DS,2,.);
      %let OBJ = %scan (&DS,3,.);
      %let TYP = %scan (&DS,4,.);
      %if (%superq(OBJ) eq ) %then %let OBJ = ########;
      %if (%superq(TYP) eq ) %then %let TYP = OUTPUT;
      %let DS = &LIB..&MEM..&OBJ..&TYP;

      %if (not %sysfunc(exist(&DS, CATALOG))) %then %do;
        %put ERROR: &THIS: SHEET&I=&&SHEET&I does not appear to be;
        %put ERROR: &THIS:  an existing dataset or a catalog entry.;
        %put ERROR: &THIS: Continuing to next sheet;
        %goto NxtSheet;
      %end;

      %let type = CATA;

      %if (%superq(WN) eq ) %then %let WN = &DS;

      %if (%superq(PART2) eq and %superq(PART3) eq ) %then %do;
        %let STYLE=MONO;
        %let HD = NONE;
      %end;
    %end;
    %else %do;
      %if (%superq(WN) eq ) %then
        %let WN = %sysfunc(attrc(&dsid,LIB)).%sysfunc(attrc(&dsid,MEM));

      %let dsid = %sysfunc (close (&dsid));
      %let type = DATA;
    %end;

    %if (%superq(HD) eq ) %then %let HD = NAME;

    %let HD = %upcase (&HD);

    %if %sysfunc(index(|LABEL|NAME|NONE|,|&HD.|)) = 0 %then %do;
      %put ERROR: &THIS: SHEET&I=&&SHEET&I has invalid header row type;
      %put ERROR: &THIS: Continuing to next sheet;
      %goto NxtSheet;
    %end;

    %let N = %eval (&N + 1);

    %* DS - Data Set, WN - Worksheet Name, HD - Header row type;
    %local DS&N WN&N HD&N TYPE&N STYLE&N;

    %let WN&N = &WN;
    %let HD&N = &HD;
    %let DS&N = &DS;
    %let TYPE&N = &TYPE;
    %let STYLE&N = &STYLE;

%NxtSheet:
    %let I = %eval (&I+1);
  %end;

  %*---------------------------------------------------------------------------
  %* Check if any sheets indicated ;

  %if (&N = 0) %then %do;
    %put WARNING: &THIS: No sheets were indicated.;
    %goto EndMacro;
  %end;

  %*---------------------------------------------------------------------------
  %* Output the data as XML, a Perl program will read this XML and write an
  %* multisheet xls file based on the data
  %* Note: extraneous info (layout and contents) needed by the Perl program
  %* is placed in the XML file, and said file if used by other XML processors
  %* will result in confusion.;

  %local workpath dirsepp dirsep;
  %local random random2 random3;
  %local xmlfile pl_file xlsfile xmlfref;
  %local start finish;
  %local perlpgm perlrun;
  %local translate;

  %*---------------------------------------------------------------------------
  %* directory separator;

  %let workpath = %sysfunc(pathname(WORK));
  %let dirsepp = %sysfunc(indexc(&workpath,\/));
  %let dirsep = %substr(&workpath, &dirsepp, 1);

  %*-----;

  %let random  = %substr (%sysfunc (ranuni(0), 9.7), 3);
  %let random2 = %sysfunc(mod(%sysevalf(&random+1),1e7),z7.);
  %let random3 = %sysfunc(mod(%sysevalf(&random+2),1e7),z7.);

  %*let random  = sas2xls;
  %*let random2 = sas2xlx;
  %*let random3 = sas2xly;

  %*-----;

  %let xmlfile = &workpath.&dirsep._&random..xml;
  %let pl_file = &workpath.&dirsep._&random..pl;
  %let xlsfile = &workpath.&dirsep._&random..xls;

  %if (%superq(file) ne ) %then
    %let xlsfile = &file;

  %*---------------------------------------------------------------------------
  %* if any of these characters are present in an xml file,
  %* then Perl module XML::Simple will complain.
  %* the characters will be translated to spaces by the xmlappend macro.
  %*;

  %let translate = &translate.010204050607080B0C0E0F;
  %let translate = &translate.101112131415161718191A1B1C1D1E1F;
  %let translate = &translate.808182838485868788898A8B8C8D8E8F;
  %let translate = &translate.909192939495969798999A9B9C9D9E9F;

  %*----- create the xml file for the Perl program;

  %do i = 1 %to &N;

    %let start = 0;
    %let finish = 0;

    %if &i = 1 %then %let start=1;

    data _&random;
      data   = %sysfunc(quote(&&DS&i%str( )));
      sheet  = %sysfunc(quote(&&WN&i%str( )));
      header = %sysfunc(quote(&&HD&i%str( )));
      type   = %sysfunc(quote(&&TYPE&i%str( )));
      style  = %sysfunc(quote(&&STYLE&i%str( )));
    run;

    %* some layout meta data for the Perl program;

    %xmlappend (
      file=&xmlfile
    , data=_&random
    , out=_layout_&i
    , start=&start
    , finish=&finish
    )

    %let start = 0;
    %let finish = 0;

    %* output the table or catalog entry as xml;

    %if &&type&i = DATA %then %do;

      proc contents noprint
        data=&&DS&i
        out=_&random(keep=name label varnum format);
      run;

      %xmlappend (
        file=&xmlfile
      , data=_&random
      , out=_contents_&i
      , start=&start
      , finish=&finish
      , translate=&translate
      )

      %if &i = &N %then %let finish=1;

      %xmlappend (
        file=&xmlfile
      , data=&&DS&i
      , out=_data_&i
      , start=&start
      , finish=&finish
      , translate=&translate
      )
    %end;
    %else %do;
      filename _&random catalog "&&DS&i";
      data _&random;
        infile _&random;
        input;
        length line $1000;
        line = _infile_;
      run;
      filename _&random;

      proc contents noprint
        data=_&random
        out=_&random2(keep=name label varnum);
      run;

      %xmlappend (
        file=&xmlfile
      , data=_&random2
      , out=_contents_&i
      , start=&start
      , finish=&finish
      , translate=&translate
      )

      %if &i = &N %then %let finish=1;
      %xmlappend (
        file=&xmlfile
      , data=_&random
      , out=_data_&i
      , start=&start
      , finish=&finish
      , translate=&translate
      )

      proc delete data=_&random2;
      run;
    %end;

    proc delete data=_&random;
    run;
  %end;

  %*----- write and run the Perl program;

  %let perlpgm = _&random;
  %let perlrun = _&random2;
  %let xmlfref = _&random3;

  filename &xmlfref "&xmlfile";
  filename &perlpgm "&pl_file";
  filename &perlrun PIPE "&PERL &pl_file &xmlfile &xlsfile";

  data _null_;
    set perlpgm;
    file &perlpgm ;
    len = length(source);
    put source $varying. len;
  run;

  data _null_;
    infile &perlrun;
    input;
    put _infile_;
  run;

  %if &deleteXML %then
  %let rc = %sysfunc (fdelete (&xmlfref));
  %let rc = %sysfunc (fdelete (&perlpgm));

  filename &xmlfref;
  filename &perlpgm;
  filename &perlrun;

%EndMacro:

  options &NOTES &SOURCE &SOURCE2 &MPRINT;

%mend;





/**html
 * <p>* Create data set that holds perl program (required) ;</p>
 */




/*
data perlpgm;
  input;
  source = _infile_;
cards4;

use strict;
use XML::Simple;
use Spreadsheet::WriteExcel;
use Spreadsheet::WriteExcel::Utility;
use Data::Dumper;
use Cwd;

my $dir = cwd();
my $xmlfile = $ARGV[0];
my $xlsfile = $ARGV[1];

my $lib = XMLin($xmlfile,ForceArray=>[qr/^_(DATA|CONTENTS)_\d+$/]);

# Note: empty tags, <tag></tag>, become an empty hash, {}, when read by XMLin
# Thus, ref() tests are needed to determine this situation

#print Dumper($lib);
#exit;

my $sheet_num = 1;

my $workbook  = Spreadsheet::WriteExcel->new($xlsfile);

while ($lib->{"_DATA_$sheet_num"}) {

    my $layout  = $lib->{"_LAYOUT_$sheet_num"};
    my ($format, $tformat, $dformat, $dtformat);
    my $R = 0;
    my $C = 0;
    my ($i,$j);

    my $worksheet = $workbook->add_worksheet ($layout->{sheet});

    if ($layout->{style} eq 'MONO') {
      $worksheet->hide_gridlines(2);
      $format   = $workbook->add_format(font=>"Courier New");
      $tformat  = $workbook->add_format(font=>"Courier New");
      $dformat  = $workbook->add_format(font=>"Courier New");
      $dtformat = $workbook->add_format(font=>"Courier New");
    }
    else {
      $tformat  = $workbook->add_format();
      $dformat  = $workbook->add_format();
      $dtformat = $workbook->add_format();
    }
    $tformat->set_num_format('h:mm:ss');
    $dformat->set_num_format('dd-mmm-yyyy');
    $dtformat->set_num_format('dd-mmm-yyyy hh:mm:ss');

    my $vars = $lib->{"_CONTENTS_$sheet_num"};
    my ($varname, $varnum);
    my @columns;

    for ($i=0;$i<@$vars;$i++) {
      $varname = $vars->[$i]->{NAME};
      $varnum  = $vars->[$i]->{VARNUM};
      $columns[$varnum] = $i;
    }

    # output header row of requested type

    if ($layout->{header} eq 'NAME') {
      for ($i=1;$i<@columns;$i++) {
        $worksheet->write($R,$C++,$vars->[$columns[$i]]->{NAME}, $format);
      }
      $worksheet->freeze_panes(1,0);
    }
    elsif ($layout->{header} eq 'LABEL') {
      for ($i=1;$i<@columns;$i++) {
        my $value = !ref($vars->[$columns[$i]]->{LABEL})
                  ? $vars->[$columns[$i]]->{LABEL}
                  : $vars->[$columns[$i]]->{NAME}
                  ;
        $worksheet->write($R,$C++,$value,$format);
      }
      $worksheet->freeze_panes(1,0);
    }

    my $data = $lib->{"_DATA_$sheet_num"};

    for ($i=0;$i<@$data;$i++) {
      $C=0;
      $R++;
      for ($j=1;$j<@columns;$j++) {
        my $colname = $vars->[$columns[$j]]->{NAME};
        my $colvalue
        = !ref($data->[$i]->{$colname})
             ? $data->[$i]->{$colname}
             : ''
             ;

        $_ = $colvalue;

        if ( /^(\d\d):(\d\d):(\d\d)(\.\d*)$/ ) {
          $colvalue = (($1*60 + $2)*60 + $3 + $4) / 86400 ;
          $worksheet->write($R,$C++,$colvalue,$tformat);
          $worksheet->set_column ($C-1,$C-1,7.5);
        }
        elsif ( /^(\d\d\d\d)-(\d\d)-(\d\d)$/ ) {
          $colvalue = xl_date_list($1,$2,$3);
          $worksheet->write($R,$C++,$colvalue,$dformat);
          $worksheet->set_column ($C-1,$C-1,11);
        }
        elsif ( /^(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(\.\d*)$/ ) {
          $colvalue = xl_date_list($1,$2,$3,$4,$5,$6+$7);
          $worksheet->write($R,$C++,$colvalue,$dtformat);
          $worksheet->set_column ($C-1,$C-1,18.5);
        }
        else {
          $worksheet->write($R,$C++,$colvalue,$format);
        }
      }
    }

    $sheet_num++;
}

$workbook->close();
;;;;
run;

*/

/**html
 * <p>Sample code</p>
 */





/*;

%include "\\extreme\macros\xmlib.sas";

options nomprint;
%xmlib;

options mprint notes;

filename pgm catalog 'work.test.rptprog.source';

data _null_;
  input;
  file pgm;
  put _infile_;
  cards4;
filename output catalog 'work.text.report.output';
proc printto print=output new;
run;
options nocenter nodate nonumber;
title;
footnote;
proc print data=sashelp.class;
run;
proc printto print=print;
run;
filename output;
;;;;

run;

%include pgm;
filename pgm;

options mprint;

data foo;
  attrib
    date format=date9. label='Todays Date'
    dt format=datetime16.
    x length=8 format=8.4
    y length=$200 label='Why is the question'
  ;
  do x = 0 to 255;
  y = put(x,3.)||byte(x)||'ABC';
  output;
  end;
  stop;
run;

proc sql;
  create table table
  as select
    datepart (crdate) as cr_date format=date9.
  , timepart (crdate) as cr_time format=time8.
  , *
  from dictionary.tables;
quit;

%sas2xls (
     FILE=c:\temp\_WEBOUT.xls
   , SHEET1=SASHELP.CLASS
   , SHEET2=Libraries::SASHELP.VSLIB
   , SHEET3=A list of the A tables:Label:SASHELP.VSTABLE
            (WHERE=(MEMNAME LIKE 'A%'))
   , SHEET4=work.test.rptprog.source
   , SHEET5=work.text.report
   , SHEET6=:Label:WORK.FOO
   , SHEET7=:label:TABLE
   , deleteXML = 0
);

options noxwait noxsync;
x "c:\temp\_WEBOUT.xls";
options xwait xsync;

*/;
