*https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/sqlproc/p1tbuxpz7oo8hgn1nf807fqgi5xc.htm;
%macro countm(col);
*When running the macro for proc sql;
*it is necessary to add proc sql; 
*select before %countm;

    count(&col) "Valid Responses for &col",
nmiss(&col) "Missing or NOT VALID Responses for &col",
count(case
            when &col=.n  then "count me"
            end) "Coded as NO ANSWER for &col",
   count(case
            when &col=.x  then "count me"
            end) "Coded as NOT VALID answers for &col",
   count(case
            when &col=.  then "count me"
            end) "Data Entry Errors for &col"
%mend;

/*Demo codes:;

*Note: it is necessary to add select before %countm;

proc sql;
   title 'Counts for Each Type of Missing Response';
   select count(*)  "Total No. of Rows",
          %countm(MPG_City)
      from sashelp.cars;

*/

