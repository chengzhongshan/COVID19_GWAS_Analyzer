%macro exportds2gz(dsdin,outgz,outdir=/home/cheng.zhong.shan/data);
filename outgz zip "&outdir/&outgz..gz" gzip;
%let tmpfile=&outdir/&outgz..txt;
proc export data=&dsdin outfile="&tmpfile" dbms=tab replace;
run;
filename indsd "&tmpfile";
data _null_;
infile indsd;
file outgz;
input;
put _infile_;
run;
data _null_;
*Here use filehandle by fdelete;
rc=fdelete("indsd");
run;
filename outgz indsd clear;
%mend;

/*Demo:

libname FM '/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp';
options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

%exportds2gz(
dsdin=FM.ukb_fm_mixed,
outgz=outname4test,
outdir=/home/cheng.zhong.shan/data
);

*/
