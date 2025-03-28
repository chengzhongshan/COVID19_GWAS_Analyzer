%macro File_Head(filename,n=10);
data _temp_;
  length Line $32767.;
   infile &filename dsd obs=&n length=varlen;
   line=_infile_;
   *SNP=prxchange("s/.*(rs\d+).*/$1/",-1,_infile_);
   input line $varying32767. varlen;
run;
proc print data=_temp_;
%print_nicer;
run;
%mend;
/*usage demo:
 *for spaces separated file, the dsd in the infile statment is needed;
%File_Head(filename="I:\SASGWASDatabase\Important_Analysis_Codes\Step 1 ensembl SQL data\variation_feature.txt",n=10);
*/
