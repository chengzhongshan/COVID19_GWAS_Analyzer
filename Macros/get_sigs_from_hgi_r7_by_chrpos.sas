/*
gwas_names:
such as A1_ALL, B1_ALL, B2_ALL, and C2_ALL;
furthermore, except B1, all others have subpopulation GWASs,
such as B2_AFR, B2_EAS, B2_SAS, B2_EUR;
Note: A2_HIS, C2_HIS and B2_HIS tar gz file was broken

chrpos_or_rsids:
hg19 position or rsid, such as rs2564978

*/

%macro get_sigs_from_hgi_r7_by_chrpos(
gwas_names=A1_ALL B1_ALL,
chrpos_or_rsids=%str(chr1:10000-20000000),
dsdout=combined_signals
);
%let gi=1;
%do %while(%scan(&gwas_names,&gi,%str( )) ne);
 %let gwas=%scan(&gwas_names,&gi,%str( ));
 %get_HGI_R7_GWAS(
  gwas_name=&gwas, 
  hgi_gwas=hgi_gwas&gwas
  );
  %let ncnds=%ntokens(&chrpos_or_rsids);
  data hgi_gwas&gwas;
  set hgi_gwas&gwas;
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
  
 %let gi=%eval(&gi+1);
%end;

%put Trying to merge all data sets of GWASs;
%Union_Data_In_Lib_Rgx(lib=work,excluded=,dsd_contain_rgx=hgi_gwas,dsdout=&dsdout);

%mend;

/*such as A2_ALL, B1_ALL, B2_ALL, and C2_ALL;
furthermore, except B1, all others have subpopulation GWASs,
such as B2_AFR, B2_EAS, B2_SAS, B2_EUR;
Note: C2_HIS and B2_EUR tar gz file was broken
query by hg19 position or rsid, such as rs2564978
*/

/*Demo:;

*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

%get_sigs_from_HGI_R7_by_ChrPos(
gwas_names=B1_ALL B2_ALL C2_ALL A2_ALL
A2_AFR A2_EAS A2_SAS A2_EUR
B2_AFR B2_EAS B2_SAS B2_EUR
C2_AFR C2_EAS C2_SAS C2_EUR,
chrpos_or_rsids=%str(chr1:10000-200000 rs16831827 rs2564978),
dsdout=combined_signals
);
*/

