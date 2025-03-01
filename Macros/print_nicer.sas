%macro print_nicer(
fontsize=12,
fontcol=dark,
column_font=Bold /*When requiring for monospaced font, 
use Courier, or Consolas, among which Consolas is the best!*/
);

%str(
var _all_/style(column)=[fontsize=&fontsize.pt color=&fontcol fontfamily=&column_font]
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
