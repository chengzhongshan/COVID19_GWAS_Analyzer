%macro countm(col);
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

