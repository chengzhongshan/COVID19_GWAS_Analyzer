%macro long_line_dsd_exporter(dsdin,outfile);
*Note: the export procedure failed to export all vars when the ling length >32767;
/* proc export data=b outfile="&outdir/test.txt" dbms=tab replace; */
/* run; */

*https://communities.sas.com/t5/SAS-Programming/Exporting-data-to-excel/m-p/124791#M10407;
*export headers only;
proc export data=&dsdin (obs=0) outfile="&outfile" dbms=tab replace;
putnames=yes;
run;
*append data;
data _null_;
set &dsdin;
*Append data into a existing file with mod parameter;
file "&outfile" mod dsd dlm='09'x lrecl=100000000;
put (_all_) (:);
run;

%mend;

/*Demo:

%let outdir=%sysfunc(getoption(work));

%long_line_dsd_exporter(
dsdin=a,
outfile=&outdir/test.txt
);

*Check the data by importing it again;
*Add : before $10. to read variable with maximum length of 10;
data final;
infile "&outdir/test.txt" dsd dlm='09'x truncover lrecl=10000000 obs=max firstobs=2;
input rownames :$10. V1-V50000;
run;

*/

