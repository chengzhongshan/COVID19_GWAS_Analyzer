%macro get_sigs_from_locuszoom(
gwas_names=91854 192226 826733 793752,	/*put multiple gwas numbers and separated with blank space;
Go to locuszoom to search for gwas and nevigate to specific gwas and obtain its gwas number in the weblink*/
gwas_labels=HGI_DF4_W1 HGI_DF4_N2 HGI_DF4_W2 HGI_DF4_N1,	
/*These are labels for the above gwas numbers and will be used to name gwas in the output*/
chrpos_or_rsids=%str(1:10000-20000000),	/*Note: X and Y chrs are labeled as 23 and 24 in long covid gwas, respectively;
the macro will automatically remove the character chr notation in the input chrpos and requires the input gwas using 
numeric chr notation, so if the input is not, the macro will fail!! It is necessary to update the macro by changing 
char chr notation as numberic in the importing process at the stage of running the submacro get_locuszoom_GWAS*/
dsdout=combined_signals,
dist2each_marker=0, /*extend the region with up/down of a specific distance in bp (>0) to search for all snps*/
use_zcat=0 /*When running the macro in Linux, it is necessary to use zcat, thus the value of 1 is needed here then!*/
);
%let gi=1;
%do %while(%scan(&gwas_names,&gi,%str( )) ne);
 %let gwas=%scan(&gwas_names,&gi,%str( ));

	%get_locuszoom_GWAS(
  gwas_num=&gwas, 
  gwasout=locuszoom_gwas&gwas,
	use_zcat=&use_zcat,
	deleteZIP=1,/*Delete downloaded gz file after running the macro*/
	customized_infile_cmd=%str(
firstobs=2 obs=max lrecl=32767 truncover delimiter='09'x;
input chr pos rsid :$20. ref :$1. alt :$1. neg_log_p beta se AF;
p=10**(-neg_log_p);
drop neg_log_p;
) /*In cases of the gwas has different headers, it is necessary to supply customized 
	infile command for the sas macro*/
  );

  %let ncnds=%ntokens(&chrpos_or_rsids);
  data tmp4&gwas;
  set locuszoom_gwas&gwas;
  where 
  %do _mi_=1 %to &ncnds;
      %let tgt=%scan(&chrpos_or_rsids,&_mi_,%str( ));
      %if %sysfunc(prxmatch(/rs\d+/,&tgt)) %then %do;
       %*For rsid;
        upcase(rsid)=upcase("&tgt")   
      %end;
      %else %do;
       %*For chr:pos1-pos2;
       %if %sysfunc(prxmatch(/(chr)*(\d+|X|x|Y|y):\d+/,&tgt)) %then %do;
          %let _chr_=%scan(&tgt,1,%str(:-));
          %let _chr_=%sysfunc(prxchange(s/chr//,-1,&_chr_));
          %let _st_=%scan(&tgt,2,%str(:-));
          %let _end_=%scan(&tgt,3,%str(:-));
          %if %length(&_end_)=0 or &_end_<&_st_ %then %do;
             %let _end_=&_st_;
             %put Manually use the same positions for start and end positions for the input &tgt;
          %end;
          (chr=&_chr_ and (pos between &_st_ and &_end_))
       %end;
       %else %do; 
          %put Unknown chrpos input: &tgt;
          %abort 255;
       %end;
      %end;
      %*Add or condition when there are more than 1 chrpos or rsids;
      %if &ncnds>1 and &_mi_>=1 and &_mi_<&ncnds %then %do;
        or
      %end;
  %end;
  ;
  run;
  %if %sysfunc(prxmatch(/rs\d+/,&tgt)) and &dist2each_marker>0 %then %do;
          proc sql;
          create table locuszoom_gwas&gwas as
          select a.*
          from locuszoom_gwas&gwas as a,
               tmp4&gwas as b
          where a.chr=b.chr and (
          a.pos between (b.pos-&dist2each_marker) and (b.pos+&dist2each_marker)
          );
  %end;
  %else %do;
         proc sql noprint;
         drop table locuszoom_gwas&gwas;
         proc datasets nolist;
         change tmp4&gwas=locuszoom_gwas&gwas;
         run;
  %end;
  
 %let gi=%eval(&gi+1);
%end;

%put Trying to merge all data sets of GWASs;
%Union_Data_In_Lib_Rgx(lib=work,excluded=,dsd_contain_rgx=locuszoom_gwas,dsdout=&dsdout);
*Update the gwas labels;
data &dsdout;
set &dsdout;
%do gwas_i=1 %to %ntokens(&gwas_labels);
	if dsd="work.LOCUSZOOM_GWAS%left(%scan(&gwas_names,&gwas_i,%str( )))" then dsd="%scan(&gwas_labels,&gwas_i,%str( ))"; 
%end;
run;

%mend;
 /*
gwas_names:
such as A1_ALL, B1_ALL, B2_ALL, and C2_ALL;
Long COVID HGI - DF4 W1 => gwas number 91854
Long COVID HGI - DF4 N2 => gwas number 192226
Long COVID HGI - DF4 W2=> gwas number 826733
Long COVID HGI - DF4 N1=> gwas number 793752

chrpos_or_rsids:
hg38 position or rsid, such as rs2564978

*/


/*Demo:;

*options mprint mlogic symbolgen;
*%let macrodir=/home/cheng.zhong.shan/Macros;
*%include "&macrodir/importallmacros_ue.sas";
*%importallmacros_ue;

%get_sigs_from_locuszoom(
gwas_names=826733 793752,
gwas_labels=HGI_DF4_W2 HGI_DF4_N1,	
chrpos_or_rsids=%str(1:10000-20000000),
dsdout=combined_signals,
dist2each_marker=0,
use_zcat=0
);

%get_sigs_from_locuszoom(
gwas_names=91854 192226 826733 793752,
gwas_labels=HGI_DF4_W1 HGI_DF4_N2 HGI_DF4_W2 HGI_DF4_N1,	
chrpos_or_rsids=%str(1:10000-20000000),
dsdout=combined_signals,
dist2each_marker=0,
use_zcat=0
);

*/

