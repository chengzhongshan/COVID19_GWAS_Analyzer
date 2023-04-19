*options macrogen mprint symbolgen mlogic;
*Be caution about the use of _str_, if it used two times in a line,some unknown errors always occure!!!!!!!!;
%macro Append_All_Data_in_Lib(lib,excluded,dsdout);
%let re=%sysfunc(prxparse(s/ /" "/oi));
%let rm_list=%sysfunc(prxchange(&re,-1,&excluded));
%syscall prxfree(re);
proc sql noprint;
select memname into: names separated by ' '
 from dictionary.tables
 where (libname=upper("&lib") and memname not in %str(%("&rm_list"%)));

data &dsdout(compress=yes);
set %str(&names);
run;

%mend;


/*
proc datasets lib=work kill nolist;run;
%macro Make_cis_eQTL_LD_Database(Path,Population);
%get_filenames(&Path\&population);
data LD_Data_&Population (drop=memname myfilename);
  set filenames;
  filepath = "&Path\&population"||"\"||memname;
  infile dummy filevar = filepath length=reclen end=done dsd delimiter='09'x firstobs=1 obs=10;
  do while(not done);
    myfilename = filepath;
	length SNP $30. rsID_A $15. rsID_B $15.;
    input SNP $ A_Pos B_Pos rsID_A $ rsID_B $ Rsq;
    output;
  end;
run;
%mend;
%Make_cis_eQTL_LD_Database(Path=I:\SASGWASDatabase\OneKGSNPEXP_PloS_One_Indel_Enrichment_Test\OneKGPlinkBfiles,population=CHB);
%Make_cis_eQTL_LD_Database(Path=I:\SASGWASDatabase\OneKGSNPEXP_PloS_One_Indel_Enrichment_Test\OneKGPlinkBfiles,population=JPT);
%Make_cis_eQTL_LD_Database(Path=I:\SASGWASDatabase\OneKGSNPEXP_PloS_One_Indel_Enrichment_Test\OneKGPlinkBfiles,population=CEU);
%Make_cis_eQTL_LD_Database(Path=I:\SASGWASDatabase\OneKGSNPEXP_PloS_One_Indel_Enrichment_Test\OneKGPlinkBfiles,population=YRI);
%Make_cis_eQTL_LD_Database(Path=I:\SASGWASDatabase\OneKGSNPEXP_PloS_One_Indel_Enrichment_Test\OneKGPlinkBfiles,population=LWK);
%Make_cis_eQTL_LD_Database(Path=I:\SASGWASDatabase\OneKGSNPEXP_PloS_One_Indel_Enrichment_Test\OneKGPlinkBfiles,population=MEX);

%Append_All_Data_in_Lib(lib=work,excluded=Filenames All,dsdout=X);
*/



