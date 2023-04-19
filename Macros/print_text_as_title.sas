%macro print_text_as_title(
text=%str(Put your text here to print.)
);

proc odstext;
p "&text" /style=[color=darkred fontsize=14pt 
                  just=center fontfamily=arial];
run;

*The following codes do not work very well;
/* data _tmp_; */
/* length _line_ $32767; */
/* _line_="&text"; */
/* output; */
/* proc print data=_tmp_ noobs; */
/* var _line_/ */
/* style=[width=15in frame=void] */
/* style(data)=[font_face=arial font_weight=bold */
/*              foreground=darkblue backgroundcolor=cxedf2f9 */
/*              font_size=12pt frame=void] */
/* style(header)=[color=white];  */
/* run; */

/* proc report data=_tmp_ style=powerpointlight */
/* style(report)={rules=none frame=void cellspacing=0 bordercolor=white} */
/* style(column)={ bordercolor=white width=15in just=center fontsize=12pt frame=void rules=none fontfamily=arial frame=void}  */
/* style(header)={color=white backgroundcolor=white bordercolor=white} */
/* ; */
/* run; */
%mend;
/*Demo:;
%print_text_as_title(
text=%str(Figure title: figurename)
);

*/