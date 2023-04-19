%macro ClearLib(Libname);

proc datasets lib=&Libname kill nolist memtype=data;
quit;

%mend ClearLib;

/*
%ClearLib(work);
*/