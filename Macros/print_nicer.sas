%macro print_nicer(
fontsize=12,
fontcol=dark
);

%str(
var _all_/style(column)=[fontsize=&fontsize.pt color=&fontcol fontfamily=bold]
style(header)=[fontsize=&fontsize.pt];
);

%mend;

/*Demo:;
proc print data=D.hgi_jak2_signals noobs;
where rsid contains ('rs17425819');
%print_nicer;
* the above macro will insert the following codes;
* var _all_/style(column)=[fontsize=12pt color=darkred fontfamily=bold] style(header)=[fontsize=12pt];
run;
*/