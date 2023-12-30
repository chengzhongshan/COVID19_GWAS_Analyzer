%macro get_anno4macro(
macro_rgx=.,
anno_rgx=,
macro_dir=%sysfunc(pathname(HOME))/Macros/
);
%if %length(&anno_rgx)=0 %then %let anno_rgx=&macro_rgx;
proc import 
datafile="&macro_dir/Available_SAS_Macros_and_its_annotations4STAR_PROTOCOL.csv"
dbms=csv out=x replace;
getnames=yes;
guessingrows=max;
run;

proc print data=x noobs;
where prxmatch("/&macro_rgx/i",macro) or prxmatch("/&anno_rgx/i",Annotation);
var _all_/style(column)=[fontsize=12.pt color=dark fontfamily=bold]
          style(header)=[fontsize=12.pt fontfamily=bold];
run;
%mend;

/*Demo:;

%get_anno4macro(
macro_rgx=GetGenesExons4LatticeGscatter,
anno_rgx=
);

*/




