%macro shuffle_rows(dsdin,var,dsdout);
proc sql;
   create table &dsdout as
   select &var from &dsdin
   order by rand('uniform');
quit;
%mend;
