/*
gwas_names:
such as A1_ALL, B1_ALL, B2_ALL, and C2_ALL;
furthermore, except B1, all others have subpopulation GWASs,
such as B2_AFR, B2_EAS, B2_SAS, B2_EUR;
Note: A2_HIS, C2_HIS and B2_HIS tar gz file was broken
Also include long covid GWASs from locuszoom: LC_W1, LC_N2, LC_W2, and LC_N1;
Long COVID HGI - DF4 W1 => gwas number 91854
Long COVID HGI - DF4 N2 => gwas number 192226
Long COVID HGI - DF4 W2=> gwas number 826733
Long COVID HGI - DF4 N1=> gwas number 793752


chrpos_or_rsids:
hg19 or hg38 position or rsid, such as rs2564978

*/

%macro get_sigs_from_hgi_r7_by_chrpos(
gwas_names=A1_ALL B1_ALL,
chrpos_or_rsids=%str(chr1:10000:20000000),
/*Note: if left EMPTY, it will get all GWAS signals and combined together into a long format dataset;
Ensure the input genomic region format as chrNum:pos1:pos2 with the separator :!*/
dsdout=combined_signals,
dist2each_marker=0 /*extend the region with up/down of a specific distance in bp (>0) to search for all snps*/
);

%local gwas gi;

%let gi=1;
%do %while(%scan(&gwas_names,&gi,%str( )) ne);
 %let gwas=%scan(&gwas_names,&gi,%str( ));

%if %sysfunc(prxmatch(/LC_/,&gwas)) %then %do;
 %let Longcovid_gwasnums=91854 192226 826733 793752;
 %let Longcovid_gwasnames=LC_W1 LC_N2 LC_W2 LC_N1;
 %let Longcovid_gwaslabels=HGI_DF4_W1 HGI_DF4_N2 HGI_DF4_W2 HGI_DF4_N1;
 %match_elements_in_macro_list(
 macro_list=&Longcovid_gwasnames,/*elements should be separated by blank space*/
 rgx4match=&gwas,/*regular expression of prxmatch, such as (rgx1|rgx2)*/
 reversematch=0,/*provide 1 to keep elements not matched with the rgx*/
 output_idx=1, /*Instead of keeping matched or unmatched elements, keep the 1-based
 indices for these elements in the original macro_list, which would be useful
 to be transformed into a sas data set by the macro for further analysis!*/
 new_macro_list_var=LC_idx&gwas /*a new global macro var containing the final output*/
 );
 %put The Long COVID gwas index is &&LC_idx&gwas;
 %put Trying to get Long COVID GWAS &gwas from LocusZoom;
 %get_sigs_from_locuszoom(
 gwas_names=%scan(&Longcovid_gwasnums,&&LC_idx&gwas,%str( )),	/*put multiple gwas numbers and separated with blank space;
 Go to locuszoom to search for gwas and nevigate to specific gwas and obtain its gwas number in the weblink*/
 gwas_labels=%scan(&Longcovid_gwaslabels,&&LC_idx&gwas,%str( )),	
 /*These are labels for the above gwas numbers and will be used to name gwas in the output*/
 chrpos_or_rsids=,	/*Note: X and Y chrs are labeled as 23 and 24 in long covid gwas, respectively;
 the macro will automatically remove the character chr notation in the input chrpos and requires the input gwas using 
 numeric chr notation, so if the input is not, the macro will fail!! It is necessary to update the macro by changing 
 char chr notation as numberic in the importing process at the stage of running the submacro get_locuszoom_GWAS;
 Note: if the macro var is left EMPTY, SNPs from all GWAS will be kept!
 */
 dsdout=hgi_gwas&gwas,
 dist2each_marker=0, /*extend the region with up/down of a specific distance in bp (>0) to search for all snps*/
 use_zcat=0 /*When running the macro in Linux, it is necessary to use zcat, thus the value of 1 is needed here then!*/
 );
/*  %abort 255; */

%end;
%else %do;
%put Trying to get GWAS &gwas from HGI;
 %get_HGI_R7_GWAS(
  gwas_name=&gwas, 
  hgi_gwas=hgi_gwas&gwas
  );
%end;

%if not %sysfunc(exist(hgi_gwas&gwas)) %then %do;
		 %put GWAS dataset 	hgi_gwas&gwas does not exist for the GWAS &gwas;
		 %abort 255;
%end;


 *for debugging;   
/* data hgi_gwas&gwas; */
/* set hgi_gwas&gwas(obs=100); */
/* run; */

%if %length(&chrpos_or_rsids)^=0 %then %do;
  %let ncnds=%ntokens(&chrpos_or_rsids);
  data tmp4&gwas;
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
  %if %sysfunc(prxmatch(/rs\d+/,&tgt)) and &dist2each_marker>0 %then %do;
          proc sql;
          create table hgi_gwas&gwas as
          select a.*
          from hgi_gwas&gwas as a,
               tmp4&gwas as b
          where a.chr=b.chr and (
          a.pos between (b.pos-&dist2each_marker) and (b.pos+&dist2each_marker)
          );
  %end;
  %else %do;
         proc sql noprint;
         drop table hgi_gwas&gwas;
         proc datasets nolist;
         change tmp4&gwas=hgi_gwas&gwas;
         run;
  %end;
 %end;
/*  %abort 255; */
 %let gi=%eval(&gi+1);
%end;

%put Trying to merge all data sets of GWASs;

%Union_Data_In_Lib_Rgx(lib=work,excluded=,dsd_contain_rgx=hgi_gwas,dsdout=&dsdout);

proc datasets lib=work nolist;
delete 	hgi_gwas:;
run;

%mend;

/*such as A2_ALL, B1_ALL, B2_ALL, and C2_ALL;
furthermore, except B1, all others have subpopulation GWASs,
such as B2_AFR, B2_EAS, B2_SAS, B2_EUR;
Note: C2_HIS and B2_EUR tar gz file was broken
query by hg19/hg38 position or rsid, such as rs2564978
Also include long covid GWASs from locuszoom: LC_W1, LC_N2, LC_W2, and LC_N1;
Long COVID HGI - DF4 W1 => gwas number 91854
Long COVID HGI - DF4 N2 => gwas number 192226
Long COVID HGI - DF4 W2=> gwas number 826733
Long COVID HGI - DF4 N1=> gwas number 793752
*/

/*Demo:;

*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

*Get SNP association signals from HGI R7;
%get_sigs_from_HGI_R7_by_ChrPos(
gwas_names=B1_ALL B2_ALL C2_ALL A2_ALL
A2_AFR A2_EAS A2_SAS A2_EUR
B2_AFR B2_EAS B2_SAS B2_EUR
C2_AFR C2_EAS C2_SAS C2_EUR
LC_N1 LC_N2 LC_W1 LC_W2,
chrpos_or_rsids=%str(chr1:10000:2000000 rs16831827 rs2564978),
dsdout=combined_signals
);

*Get all HGI GWAS data;
%get_sigs_from_HGI_R7_by_ChrPos(
gwas_names=B1_ALL A2_AFR,
chrpos_or_rsids=,
dsdout=combined_signals
);

%get_sigs_from_HGI_R7_by_ChrPos(
gwas_names=B1_ALL B2_ALL C2_ALL A2_ALL
A2_AFR A2_EAS A2_SAS A2_EUR
B2_AFR B2_EAS B2_SAS B2_EUR
C2_AFR C2_EAS C2_SAS C2_EUR,
chrpos_or_rsids=,
dsdout=combined_signals
);

libname LG "E:\LongCOVID_HGI_GWAS";
proc datasets;
copy in=work out=LG memtype=data move;
select 	combined_signals;
run;
proc datasets lib=LG;
change combined_signals=HGI_R7_GWAS_Combined;
run;



*/

