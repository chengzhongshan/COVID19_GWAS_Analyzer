%macro local_gwas_hits_and_nearby_sigs(
/*Note: this macro is only works for top GWAS hits with p < 1e-6, as it 
requires to have the top independent SNPs as input for the var snps;
However, there are still bugs as the output figure is abnormal for the 
center marker of the topest snp;
somethings are wrong with this macro!
*/
GWAS_SAS_DSD=,
Marker_Col_Name=,
Marker_Pos_Col_Name=,
Xaxis_Col_Name=,
Yaxis_Col_Name=,
GWAS_dsdout=,
gwas_thrsd=, /*-log10(P) threshold, such as 5*/
Mb_SNPs_Nearby=,/*this Mb_factor will multiple 1,000,000 when running in the program*/
snps=, /*Multiple top independent SNPs separated by space*/
design_width=1000,
design_height=200,
col_or_row_lattice=1, /*Plot each subplot in a single column or row:
                      1: columnlattice; 0: rowlattice*/
uniscale4lattice=ALL, /*Default is ALL to make all axis in the same format;
                       Alternative values are as follows:
                       column: make column-wide xaxis the same if set col_or_row_lattice=1;
                       row: make row-wide yaxis the same, which is for col_or_row_lattice=0;*/
outputfmt=gif /*Output figure format, such as svg, jpg,gif, and others*/
);
   %let p_thrhd=%sysevalf(10**-&gwas_thrsd);/*get the p threshold*/
   %let Marker_Col_Name=%assign_str4missing(Inval=&Marker_Col_Name,NewVal=SNP);
   %let Xaxis_Col_Name=%assign_str4missing(Inval=&Xaxis_Col_Name,NewVal=Chr);
   %let Yaxis_Col_Name=%assign_str4missing(Inval=&Yaxis_Col_Name,NewVal=P);
   %let Marker_Pos_Col_Name=%assign_str4missing(Inval=&Marker_Pos_Col_Name,NewVal=BP);
   %if &col_or_row_lattice=1 %then %do;
     %let lattice_type=columnlattice;
   %end;
   %else %let lattice_type=rowlattice;
   
   /*Create numeric rank for these snps based on its order and use it to order them in the final plot*/
    %rank4grps(
     grps=&snps,
     dsdout=snp_rank
     );
   /*Remove duplicates*/
    proc sort data=snp_rank nodupkeys;
    by grps;
    run;
    proc sql noprint;
    select grps into: snps separated by ' '
    from snp_rank;
     
     *apply format to sort panel by a;
    %mkfmt4grps_by_var(
    grpdsd=snp_rank,
    grp_var=grps,
    by_var=num_grps,
    outfmt4numgrps=grps2nums,
    outfmt4chargrps=nums2grps
    );
   
/*      
   %char2num_dsd(dsdin=&GWAS,
                 vars=&Yaxis_Col_Name &Marker_Pos_Col_Name,
                 dsdout=&GWAS_dsdout);
*/               
   %put Now we are going to keep SNPs &Mb_SNPs_Nearby Mb up/downstream of GWS hits;
   data _tops_;
   length _grp_ $50.;
   set &GWAS_SAS_DSD;
   *Add a group column and center position column;
   *Note: here we use scaled pos, which it at the center of a window with 1000 bp;
   center_pos=500;
   _grp_=&Marker_Col_Name;
   where &Marker_Col_Name in (%quotelst(&snps));
   run;
   /*make snp grp for ordering it in the final manhanttan plot*/
   
   
   *Merge these top signals and only keep the most significant signals around specific dist;
   *Makse the signal_thrshd as 1e-6 to prevent from excluding all SNPs if no top snps pass the p threshold;
   %get_top_signal_within_dist(dsdin=_tops_
                           ,grp_var=&Xaxis_Col_Name
                           ,signal_var=&Yaxis_Col_Name
                           ,pos_var=&Marker_Pos_Col_Name
                           ,pos_dist_thrshd=&Mb_SNPs_Nearby*1
                           ,dsdout=_tops_
                           ,signal_thrshd=1 /*filter the input dsdin by &signal_val <= &signal_thrshd*/);
%let nobs=%totobsindsd(work._tops_); 
%if &nobs=0 %then %do;
   %put No SNP passed the p threshold 1e-4 in the top SNP dataset _tops_;
   %abort 255;
%end;
%else %if &nobs<%ntokens(&snps) %then %do;
   title "Obtained top snps (n=&nobs)";
   proc print data=work._tops_ noobs;
   title "";
   %put The number of target snps %ntokens(&snps) is larger than the number of snps (&nobs) passed the signal threshold of p < 1e-4;
   %put Please make sure all input snps are top independent snps passed the p < 1e-4 threshold;
   %abort 255;
%end;

*No need to merge the above top signals, as we will put the query snps at the center of each window;
*To keep the script simple, we just make the pos_dist_threhd as 1=&Mb_SNPs_Nearby*1, which will not;
*merge these signals;
 *Need to creat a copy of _grp_ as a new var grp, which may be required by other processes;                       
   proc sql;
   create table &GWAS_dsdout(where=(tmp^="")) as
   select a.*,b.&Marker_Col_Name as tmp,b._grp_ as grp,b.center_pos,
          catx(':',b.&Xaxis_Col_Name,b._grp_) as new_chr_tag
   from &GWAS_SAS_DSD as a
   right join
   _tops_ as b
   on    a.&Xaxis_Col_Name=b.&Xaxis_Col_Name and 
         a.&Marker_Pos_Col_Name between 
         (b.&Marker_Pos_Col_Name-&Mb_SNPs_Nearby*1000000*0.5) and (b.&Marker_Pos_Col_Name+&Mb_SNPs_Nearby*1000000*0.5)
   order by a.&Xaxis_Col_Name,
         a.&Marker_Pos_Col_Name;
         
/*    data &GWAS_dsdout; */
/*    set &GWAS_dsdout; */
/*    drop tmp; */
/*    run;                  */
   *Remove duplicates generated by the above codes;
   proc sort data=&GWAS_dsdout nodupkeys;by _all_;run;
   proc sort data=&GWAS_dsdout;by &Xaxis_Col_Name &Marker_Pos_Col_Name;run;
   *Make manhattan plots for regions with top hits;
   *It is necessary to use new chr group for the xaxis label;
   *%manhattan(dsdin=&GWAS_dsdout,pos_var=&Marker_Pos_Col_Name,chr_var=new_chr_tag,P_var=&Yaxis_Col_Name,logP=1,gwas_thrsd=&gwas_thrsd);

   *Use proc sgpanel to make local manhattan plots, which are better;
   *The factor4mult will make the axis start from 0 to 1000;
    %scale4range(
      dsdin=&GWAS_dsdout,
      ids=new_chr_tag,
      vars=&Marker_Pos_Col_Name,
      factor4mult=1000,
      round_or_not=1,
      outdsd=&GWAS_dsdout
      );
     data &GWAS_dsdout;
     set &GWAS_dsdout;
     logP=-log10(&Yaxis_Col_Name);
     label logP='-log10(P)';
     run;
     data &GWAS_dsdout;
     set &GWAS_dsdout;
     top_tag=0;
/*      this will interupted with center_pos */
/*      if logP>=&gwas_thrsd then top_tag=1; */
     if trim(left(new_chr_tag))=catx(':',chr,&Marker_Col_Name) then top_tag=2;
     *Only keep center positon when the marker is the center snp;
     else center_pos=.;

     *Get the x position for the query SNP;
     *As there would be multiple query SNPs, use mean of x positions;
     proc sql noprint;
     select ceil(mean(&Marker_Pos_Col_Name)) into: xpos4topsnp 
     from &GWAS_dsdout
     where &Marker_Col_Name in (%quotelst(&snps));

     *Get the x position for top signal for making refline;
/*     proc sql noprint;
     select &Marker_Pos_Col_Name into: xpos4topsnp
     from &GWAS_dsdout
     having logP=max(logP);
*/
     
/*
     proc sort data=&GWAS_dsdout;by tmp logP;
     data &GWAS_dsdout;
     set &GWAS_dsdout;
     if last.tmp then do;
        top_tag=2;
     end;
     by tmp;
*/
     
     *Add snp rank into the dataset for ordering the subplots;
     %let norefline=0;
     proc sql;
     create table &GWAS_dsdout as
     select * 
     from &GWAS_dsdout as a
     left join
     snp_rank as b
     on a.tmp=b.grps;  
     data &GWAS_dsdout;
     set &GWAS_dsdout;
     new_num_grps=input(grps,grps2nums.);
     *When the center is not align with the top marker snp, adjust the center_pos;
     *This is why we will not draw the center reline when drawing scatterplot in rowlattice mode;
     if center_pos=500 and pos^=500 then do;
       center_pos=pos;
       *Let not draw vertical reference line if the center_pos is not at 500;
       call symputx('norefline',1);
     end;
     run;
     
    *Make a panel of plots with the same xaxis;
    *https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/grstatproc/p1dt33l6a6epk6n1chtynsgsjgit.htm;
    *https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/grstatproc/p0qva1ws6twy5xn0zdl3nslyynvp.htm;
    *https://blogs.sas.com/content/iml/2018/06/13/attrpriority-cycleattrs-styleattrs-ods-graphics.html;
    title "Scatterplots for &snps";
    ods graphics /reset=all height=&design_height.px width=&design_width.px
    antialiasmax=50000000 attrpriority=none noborder
    imagename="TopSig%RandBetween(min=1, max=100)"  outputfmt=&outputfmt;
/*     Need to make attrpriority as none to use the combination of color and symbol */
     proc sgpanel data=&GWAS_dsdout noautolegend;
/*   panelby num_grps/layout=columnlattice onepanel novarname noheader; */
*Remove header, as the order of subplots are according to the input snp order;
     format new_num_grps nums2grps.;
/*      panelby new_num_grps/layout=columnlattice onepanel novarname; */
     panelby new_num_grps/layout=&lattice_type onepanel novarname uniscale=&uniscale4lattice;
     styleattrs datacolors=(darkred darkorange darkblue) 
     datacontrastcolors=(lightblue darkred SteelBlue)
     datasymbols=(circlefilled diamondfilled circlefilled);
     refline &gwas_thrsd/axis=y lineattrs=(color=darkred pattern=thindot);
*It seems that the &xpos4topsnp is not correct sometimes;
*Just use 500 for the x refline;
     %if (&lattice_type=columnlattice and &norefline=0) %then %do;
        refline 500/axis=x lineattrs=(color=darkgreen pattern=dot thickness=2); 
     %end;
/*      refline &xpos4topsnp/axis=x lineattrs=(color=darkgreen pattern=dot thickness=2);      */
/*      Note: datasymbols option will be overwritten by markerattrs option symbol; */
/*      scatter x=&Marker_Pos_Col_Name y=logP/group=top_tag markerattrs=(symbol=circlefilled size=6) name="sc"; */
     scatter x=&Marker_Pos_Col_Name y=logP/group=top_tag markerattrs=(size=10) name="sc";
     *Also add the label for the center snp;
     scatter x=center_pos y=logP/markerattrs=(size=15 symbol=diamondfilled color=lightred) name="center_snp";     
     rowaxis display=all label='-log10(association P)';
     colaxis display=(noticks novalues nolabel);
     run;   

%mend;

/*Demo:

*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

libname FM '/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp';
*options mprint mlogic symbolgen;

%local_gwas_hits_and_nearby_sigs(
GWAS_SAS_DSD=FM.f_vs_m_mixedpop,
Marker_Col_Name=rsid,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chr,
Yaxis_Col_Name=gwas2_p,
GWAS_dsdout=xxx,
gwas_thrsd=5.5,
Mb_SNPs_Nearby=1,
snps=rs16831827,
design_width=500,
design_height=200
);
*Need to add quit to only show one figure;
quit;


%local_gwas_hits_and_nearby_sigs(
GWAS_SAS_DSD=FM.f_vs_m_mixedpop,
Marker_Col_Name=rsid,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chr,
Yaxis_Col_Name=pval,
GWAS_dsdout=xxx,
gwas_thrsd=5.5,
Mb_SNPs_Nearby=1,
snps=rs8116534 rs472481 rs555336963 rs148143613 rs2924725 rs5927942,
design_width=500,
design_height=300
);
*Need to add quit to only show one figure;
quit;

%local_gwas_hits_and_nearby_sigs(
GWAS_SAS_DSD=FM.f_vs_m_mixedpop,
Marker_Col_Name=rsid,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chr,
Yaxis_Col_Name=pval,
GWAS_dsdout=xxx,
gwas_thrsd=5.5,
Mb_SNPs_Nearby=1,
snps=rs8116534 rs472481 rs555336963 rs148143613 rs2924725 rs5927942 rs2443615 rs1965385 rs1134004 rs35239301 rs140657166 rs200808810,
design_width=800,
design_height=300
);
quit;

*/
