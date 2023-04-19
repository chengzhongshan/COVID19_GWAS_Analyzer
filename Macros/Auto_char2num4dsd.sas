%macro Auto_char2num4dsd( dsdin       /* input dsd              */
                         ,col_num_pct /*Percent of rows is numberic, used for selection of col to be change it into numeric*/
				         ,dsdout      /* Output dsd             */
                 ) ;

   /* PURPOSE: automatically change character into numeric in dataset by applying regexpression to guess
    * NOTE:    The above macro will use another SAS macro %char2num_dsd(dsdin=dsd,vars=var1 var2 var3,dsdout=tmp);
    */

   /*Count how many characteric variables in the input dataset*/
   proc contents data=&dsdin noprint out=_vars_(keep=NAME TYPE VARNUM where=(TYPE=2));
   run;
   /*Creat macro var for n_char_vars*/
   proc sql noprint;
   select count(NAME) into: tot_charvars
   from _vars_;
   select catx("",'n',put(count(NAME),best12.)) into: n_char_vars
   from _vars_
   order by NAME;
   select NAME into: ALL_Char_Vars separated by ' '
   from _vars_
   order by VARNUM;
   /*Make sure to order it, which will be matched with n1-nx in _vars_*/
   	data _vars_;
	length _NAME_ $8.;
	set _vars_;
	_NAME_=compress('n'||VARNUM);
	run;

   /*Guess the percentage of each char col are actually numbers*/
   data _tmp_;
   set &dsdin end=eof;
   retain n1-&n_char_vars 0;
   tot=_n_;
   patternID = prxparse("/^[\s\.]*\d+[\.\d]*\s*$/");
   array C{*} $ &ALL_Char_Vars;
   array N{*} n1-&n_char_vars;

   do i=1 to dim(C);
      if prxmatch(patternID,C{i}) and not prxmatch("/[a-z]/i",C{i}) then do;
	   N{i}=N{i}+1;
	   if eof then do;
	   N{i}=N{i}/tot;
	   end;
	  end;
   end;
   if not eof then do;
    delete;
   end;
   keep n1-&n_char_vars;
   run;

   proc transpose data=_tmp_ out=_tmp_tr;
   var _numeric_;
   run;
   proc sort data=_tmp_tr;by _NAME_;run;
   proc sort data=_vars_;by _NAME_;run;
   data _combined_(where=(col1>=&col_num_pct));
   merge _tmp_tr _vars_;
   by _name_;
   run;
   
   /*Create macro vars for these cols*/
   proc sql noprint;
   select NAME into: cols4num separated by ' '
   from _combined_;

  %char2num_dsd(dsdin=&dsdin,vars=&cols4num,dsdout=&dsdout);

%mend Auto_char2num4dsd;

/*


%ImportPartialFilebyScan(file=E:\Yale_GWAS\COC_GWAS\Cocaine_Overdose\ZMAT4_GEO_KD\GSE79586_rawcounts_WALSH.txt\GSE79586_rawcounts_WALSH.txt
                 ,dsdout=dsd
                 ,firstobs=1
                 ,rows=10000
                 ,dlm='09'x
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
);

options mprint mlogic symbolgen;

%Auto_char2num4dsd( dsdin=dsd
                   ,col_num_pct=0.8 
				   ,dsdout=x
                 ) ;

*/

