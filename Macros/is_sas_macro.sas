%macro is_sas_macro(file=, bytes=8192, mv=IS_SASMACRO);
    %if "%sysfunc(strip(&file))" ="" %then %do;
        %put ERROR: (is_sas_macro) FILE= must be specified.;
        %return;
    %end;
    %global &mv;
    %let _exists = %sysfunc(fileexist(%sysfunc(dequote(&file))));
    %if &_exists = 0 %then %do;
        %let &mv = 0;
        %put ERROR: (is_sas_macro) File &file does not exist.;
        %return;
    %end;

    %let _ext = %sysfunc(lowcase(%sysfunc(scan(%sysfunc(dequote(&file)),-1,.))));
    %if &_ext ^= sas %then %do;
        %let &mv = 0;
        %return;
    %end;

%*https://www.mwsug.org/proceedings/2017/BB/MWSUG-2017-BB142.pdf;
%*Note: using %sysfunc with bsubl enables the input commands without using quote;
%*In contrary, in data step, the using of bsubl is required to be with quoted strings;
%*the filename should be included in dosubl if the supplied commands include the filehandle;
%*It is very important to put these codes used by dosubl into the macro str but not nrbquote;
%*This is mainly because these codes should be geneated as string during compilation stage;
%let my_codes=%str(
filename _file "&file";
 data b;
        length line $32767;
		retain found 0;
        bytesread = 0;
        infile _file lrecl=32767 recfm=v length=reclen end=eof;
		do while(not eof and found=0 and bytesread < &bytes);
            input line $varying32767. reclen;
            bytesread + reclen;
            if index(lowcase(line),'%macro ') > 0 then found = 1;
        end;
        call symputx("&mv",found,'G');
    run;
filename _file clear;	
 );
%*It is necessary to put the string into a variable for the function dosubl;
%*No line separations are allowed for codes supplied to the function dosubl;
%let y=%sysfunc(dosubl(&my_codes));
%*Note: this will output the value as a sas function;
&&&mv

%mend is_sas_macro;

/*Demo codes:;
%debug_macro;
%let my_file_path = H:\F_Queens\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros\is_sas_macro.sas; 
%let my_is_sasmacro=%is_sas_macro(file=&my_file_path);
%put &IS_SASMACRO;
%put &my_is_sasmacro;

%let my_file_path =xxxx;
%is_sas_macro(file=&my_file_path);
%put &IS_SASMACRO;
data a;
b=resolve('&IS_SASMACRO');
proc print;run;

*The following will fail if using dosubl but not resolve;
*due to the mask of global macro variable is_sasmacro by dosubl preventing it from accessing it outside;
%let my_file_path = H:\F_Queens\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros\is_sas_macro.sas; 
data b;
*Do not use dosubl here;
y=resolve('%is_sas_macro(file='||"&my_file_path"||')');
b=resolve('&IS_SASMACRO');
proc print;run;
%put &IS_SASMACRO;

***Other useful functions for data step;
data _null_;
   length opt $100 optval $100;
   rc=FILENAME('myfile',&my_file_path);
   fid=FOPEN('myfile');
   infocnt=FOPTNUM(fid);
   put @1 'Information for a UNIX System Services File:';
   do j=1 to infocnt;
      opt=FOPTNAME(fid,j);
      optval=FINFO(fid,upcase(opt));
      put @1 opt @20 optval;
   end;
   rc=FCLOSE(fid);
   rc=FILENAME('myfile');
run;

*/
