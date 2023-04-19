%macro get_filenames(location=,dsd_out=filenames,match_rgx=);      
filename _dir_ "%bquote(&location.)";
data &dsd_out(keep=memname); 
  length memname $1000.;  
  handle=dopen( '_dir_' );           
  if handle > 0 then do;             
    count=dnum(handle);              
    do i=1 to count;                 
      memname=dread(handle,i);       
      %str(output &dsd_out;);              
    end;                             
  end;                               
  rc=dclose(handle);                 
run; 

%if "&match_rgx" ne ""  %then %do;
proc sql;
create table &dsd_out as
select memname 
from &dsd_out
where prxmatch("/&match_rgx/i",memname);
%end;
 
filename _dir_ clear;  
 
%mend;

*%get_filenames(location=E:\IndelLDplot_SAS,dsd_out=filenames);                                                        
*%get_filenames(location=C:\temp\with space,dsd_out=filenames);               
*%get_filenames(location=%bquote(C:\temp\with'singlequote),dsd_out=filenames,match_rgx);
