%macro AddNullData2SeparateDsd(dsd,FrtSrtVar,SecSrtVar,Num4AddedNullLines,AddVar4output,Value4AddVar,dsdout);
proc sort data=&dsd;by &FrtSrtVar &SecSrtVar;
data &dsdout;
set &dsd;
if not last.&FrtSrtVar then output;
else do;
 do i=1 to &Num4AddedNullLines;
  if i=1 then output;
  else do;
   &AddVar4output=&Value4AddVar;output;
  end;
 end;
end;
by &FrtSrtVar &SecSrtVar;
run;

data &dsdout;
set &dsdout;
n=_n_;
run;

%mend;




/*
*It is OK not to provide SecSrtVar or provide multiple vars for SecSrtVar;
*The order of FrtSrtVar can be order number generated by using %number_rows_by_grp;
*Pay attention to other vars, which will output with values of the last.&FrtSrtVar;

%AddNullData2SeparateDsd(dsd=dsd_sort1,
                         FrtSrtVar=t,
                         SecSrtVar=logWGS_mut_num,
                         Num4AddedNullLines=10,
                         AddVar4output=logWGS_mut_num,
                         Value4AddVar=0,
                         dsdout=X);


*/
