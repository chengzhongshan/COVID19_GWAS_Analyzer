%macro import_all_bims(
dirpath=.,
outdsd=all_bims,
debug=0
);
%get_filenames(location=&dirpath,match_rgx=bim);
data &outdsd (drop=fname filepath memname t);
  set filenames;
  filepath = "&dirpath"||"\"||memname;
		*Need to add truncover to infile data successfully;
		%if &debug=1 %then %do;
  infile dummy filevar = filepath length=reclen end=done dsd delimiter='09'x obs=10 truncover;
		%end;
		%else %do;
		infile dummy filevar = filepath length=reclen end=done dsd delimiter='09'x obs=max truncover;
		%end;
  do while(not done);
/*    myfilename = filepath;*/
    input chr rs :$50.t pos A1 :$1. A2 :$1.;
    output;
  end;
run;
%mend;

/*Demo code:

%macroparas(macrorgx=head);
%File_Head(filename="J:\D_Queens\SASGWASDatabase\Important_Analysis_Codes\PExFInS_SAS\Databases\1KG_Phase1\ALL_chr17_OneKG.bim",n=10);
%let path=J:\D_Queens\SASGWASDatabase\Important_Analysis_Codes\PExFInS_SAS\Databases\1KG_Phase1;
%import_all_bims(
dirpath=&dirpath,
outdsd=all_bims,
debug=1
);

*/
