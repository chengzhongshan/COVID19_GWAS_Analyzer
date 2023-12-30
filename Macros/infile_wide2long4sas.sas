%macro infile_wide2long4sas(
file,/*The first column contain char value, with other columns are numeric*/
dlm,
dsdout
);
filename dsd_hd "&file";
*The best way to infile wide format data into long format data for sas;
data &dsdout;
retain ncols 0;
infile dsd_hd delimiter="&dlm" firstobs=1 obs=max truncover;

*get column nums;
if _n_=1 then do;
 input @;*This will remain at the start of the first line;
 ncols=countc(_infile_,"&dlm",'st')+1;
end;

*This will read the first line and other lines;
input g $ @@; *Read the 1st column but tell sas to go to next column;
 *There are only only ncols-1 to be read here;
 do i=1 to ncols-1;
  input exp @;*Tell sas to read the numeric colum and keep reading at the same line;
  *Note: can not use @@ here, as it will keeping reading even to the next line;
  output;
 end;

*No need to run this block in an else do clause, as the above works for the first and other lines;
/*else do;*/
/**Important here: it will release the 1st line and read the 1st and other lines;*/
/* input g $ @@;*/
/* *There are only only ncols-1 to be read here;*/
/* do i=1 to ncols-1;*/
/*  input exp @;*/
/*  output;*/
/* end;*/
/*end;*/

drop i ncols;
run;

title "First 10 records";
proc print data=&dsdout(obs=10);run;
title;

%mend;
/*Demo codes:;

%let file=E:/test.txt;
%debug_macro;

%infile_wide2long4sas(
file=&file,
dlm=' ',
dsdout=x
);
proc print data=x;run;

*contents of test.txt;
x1 0 1 2 3 4
x2 2 3 4 5 6
x3 3 4 5 6 7
x4 3 4 5 6 7


*/

