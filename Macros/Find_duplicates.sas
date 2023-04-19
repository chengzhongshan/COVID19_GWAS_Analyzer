
%macro Find_duplicates(inputdsd,key,outputdsd);
proc sql; 
create table &outputdsd as
 select * from &inputdsd as A1
   where A1.&key in
   (select &key from &inputdsd 
   group by &key having count(*)>1) 
   ; 
quit;
proc sort data=&outputdsd;by &key;run;
proc print data=&outputdsd;run;
%mend Find_duplicates;
/*demo:
%Find_duplicates(com,name,new);
*/

