%macro Only_Keep_noduplicates(inputdsd,key,outputdsd);
proc sql noprint; 
create table &outputdsd as
 select * from &inputdsd
   group by &key having count(*)=1; 
quit;
%mend;
/*
%Only_Keep_noduplicates(inputdsd,key,outputdsd);
*/
