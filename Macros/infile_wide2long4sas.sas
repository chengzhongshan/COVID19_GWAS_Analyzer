%macro infile_wide2long4sas(file,dlm,dsdout);
filename dsd_hd "&file";
*The best way to infile wide format data into long format data for sas;
data &dsdout;
retain ncols 0;
infile &dsd_hd delimiter="&dlm" firstobs=1 obs=max truncover;
*get column nums;
if _n_=1 then do;
 input;*This will read the first line;
 ncols=countc(_infile_,"&dlm",'st')+1;
end;
else do;
*Important here: it will release the 1st line and read the 1st and other lines;
 input g $ @@;
 *There are only only ncols-1 to be read here;
 do i=1 to ncols-1;
  input exp @;
  output;
 end;
end;
drop i ncols;
run;
proc print data=&dsdout(obs=10);run;
%mend;
/*Demo:


*/

