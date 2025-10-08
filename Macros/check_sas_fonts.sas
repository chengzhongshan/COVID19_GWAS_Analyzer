%macro check_sas_fonts(font_rgx=.);
proc catalog catalog=sashelp.fonts entrytype=font;
contents out=work.fontlist(keep=name);
run;
data fontlist;
set fontlist;
if prxmatch("/&font_rgx/i",name);
run; 
proc print data=work.fontlist;
 run;
%mend;
/*Demo codes:;

%check_sas_fonts(font_rgx=SIMPLEX);

*the following fonts are similar to consolas that put each char with the same width;
If you want something that looks closest to Consolas aesthetically while being monospaced, SIMPLEX or DUPLEX are usually the cleanest choices.

SIMPLEX (142)

SIMPLEX2 (143)

SIMPLEXU (144)

DUPLEX (28)

DUPLEX2 (29)

DUPLEXU (30)

COMPLEX (20)

COMPLEX2 (21)

COMPLEXU (22)

*/

