%macro Query_Large_File_With_Idx(idx_var,rownames,dsdin,dsdout);
options nonotes nosource;
%put Query_Large_File_With_Idx(idx_var,rownames,dsdin,dsdout);
%put 'Query rownames are: ' &rownames;
%let num=1;
%let rowname=%qscan(&rownames,&num,%str( ));
%do %while(&rowname ne);
 %if (&num=1) %then %do;
/* Pay attention to three conditions*/
 proc sql noprint;
 	create table &dsdout as
 	select * from &dsdin
 	where (&idx_var=%sysfunc(upcase("&rowname"))  or
           &idx_var=%sysfunc(lowcase("&rowname")) or 
		   &idx_var="&rowname"
 );
 %end;
 %else %do;
 /* Pay attention to three conditions*/
  proc sql noprint;
 	create table base&num as
 	select * from &dsdin
 	where (&idx_var=%sysfunc(upcase("&rowname"))  or
           &idx_var=%sysfunc(lowcase("&rowname")) or
		   &idx_var="&rowname"
  );
  proc append base=&dsdout data=base&num;
  run;
  proc datasets lib=work nolist;
  delete base&num;
  run;
 %end;
 %let num=%eval(&num+1);
 %let rowname=%qscan(&rownames,&num,%str( ));
%end;
%put 'JOB FINISHED';
%let dsd_in=&dsdout;
%delete_empty_dsd(&dsd_in);
options notes source;
%mend Query_Large_File_With_Idx;

/*Demo;
%Query_Large_File_With_Idx(
idx_var=variant_name,
rownames=RS383510 RS2564978,
dsdin=gwas.Lung_eQTL_Database_new,
dsdout=query);
*/
