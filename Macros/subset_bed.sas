%macro subset_bed(bed_dsd,bed_chr_var,bed_st_var,bed_end_var,query_chr,query_st,query_end,subbed_out,numeric_chr_in_bed_dsd);
 %let chr_tag=%substr(&query_chr,1,3);
 %put your query chr is in the format of &chr_tag;

 %if (&numeric_chr_in_bed_dsd=1) %then %do;
   %if "&chr_tag"="chr" %then %do;
      %put Request query chr in the format of '\d', but you query chr is &query_chr;
      %abort 255;
   %end;
   %else %do;
   proc sql;
   create table &subbed_out as
   select *
   from &bed_dsd
   where &bed_chr_var=&query_chr and 
        ( (&bed_st_var >= &query_st and &bed_end_var <= &query_end) or
		  (&bed_st_var <= &query_st and &bed_end_var >= &query_st and &bed_end_var <= &query_end) or
		  (&bed_st_var >= &query_st and &bed_st_var <= &query_end and &bed_end_var >= &query_end) or
		  (&bed_st_var <= &query_st and &bed_end_var >= &query_end)

		);
	%end;
 %end;

 %else %do;  
  %if "&chr_tag"^="chr" %then %do;
      %put Request query chr in the format of 'chr\d', but you query chr is &query_chr;
      %abort 255;
   %end;
   %else %do;
   proc sql;
   create table &subbed_out as
   select *
   from &bed_dsd
   where &bed_chr_var="&query_chr" and 
        ( (&bed_st_var >= &query_st and &bed_end_var <= &query_end) or
		  (&bed_st_var <= &query_st and &bed_end_var >= &query_st and &bed_end_var <= &query_end) or
		  (&bed_st_var >= &query_st and &bed_st_var <= &query_end and &bed_end_var >= &query_end) or
		  (&bed_st_var <= &query_st and &bed_end_var >= &query_end)

		);
   %end;
%end;

%mend;

/*Demo:;

options mprint mlogic symbolgen;
data bed_base;
input chr $ st end;
cards;
chr1 1 1000
chr1 2000 40000
chr1 50000 100000
;
%subset_bed(bed_dsd=bed_base,
            bed_chr_var=chr,
            bed_st_var=st,
            bed_end_var=end,
            query_chr=chr1,
            query_st=2100,
            query_end=40000,
            subbed_out=x,
            numeric_chr_in_bed_dsd=0
);

*/

