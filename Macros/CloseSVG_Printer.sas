%macro CloseSVG_Printer;

ods printer close;
filename out clear;
ods listing;

%mend;

/*Demo:

*Demo1:;

%OpenSVG_Printer;
*default svg figure will be saved into the $HOME dir with the name mysvgfilename.svg;
*It will recursively add numeric appendix to the svg filename;
*to avoid overwritting previous svg files;

*Put your codes drawing figures;

%CloseSVG_Printer;



*/
