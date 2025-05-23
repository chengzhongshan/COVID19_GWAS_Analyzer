%macro Auto_char2num4dsd( dsdin       /* input dsd              */
                         ,col_num_pct /*such as 0.8, indicating percentage of rows is numberic, used for selection of col to be change it into numeric*/
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
	proc sql noprint;
	select _NAME_ into: tgt_vars_nums separated by ' '
	from _vars_
    order by VARNUM;

   /*Guess the percentage of each char col are actually numbers*/
   data _tmp_;
   set &dsdin end=eof;
   retain &tgt_vars_nums 0;
   tot=_n_;
   patternID = prxparse("/^[\-\s\.]*\d+[\.\d]*\s*$/");
   array C{*} $ &ALL_Char_Vars;
   *Make sure the array not have the same time as the name of any variables included in the input dsta set &dsdin;
   *otherwise, sas would stop the data step; 
   array NX{*} &tgt_vars_nums;

   do i=1 to dim(C);
      if prxmatch(patternID,C{i}) and not prxmatch("/[a-z]/i",C{i}) then do;
	   NX{i}=NX{i}+1;
	  end;
	  if eof then do;
	   NX{i}=NX{i}/tot;
	  end;
   end;
   if not eof then do;
    delete;
   end;
   keep &tgt_vars_nums;
   run;

   proc transpose data=_tmp_ out=_tmp_tr;
   var _numeric_;
   run;
   proc sort data=_tmp_tr;by _NAME_;run;
   proc sort data=_vars_;by _NAME_;run;
   data _combined_(where=(col1>=&col_num_pct and col1<=1));
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

