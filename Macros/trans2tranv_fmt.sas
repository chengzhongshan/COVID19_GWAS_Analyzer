%macro trans2tranv_fmt(dsd,mut_var,new_mut_var,mult_types);
%put Only focus on single site but not indel site;
%put ref_alt should be separated by |,i.e., A|B and mut_var should be chrnum:pos-A|B;
/*Only single mutation*/
%if &mult_types=1 %then %do;
proc format;
value $ trs 'A->C','C->A'='A>C'
            'A->G','G->A'='A>G'
			'A->T','T->A'='A>T'
			'C->G','G->C'='C>G'
			'C->T','T->C'='C>T'
			'G->T','T->G'='G>T'
			Other="";
run;
%end;
/*include indel*/
%else %if &mult_types=2 %then %do;
proc format;
value $ trs 'A->C','C->A'='A>C'
            'A->G','G->A'='A>G'
			'A->T','T->A'='A>T'
			'C->G','G->C'='C>G'
			'C->T','T->C'='C>T'
			'G->T','T->G'='G>T'
			Other='Indel';
run;
%end;
/*assemble mutation into 2 groups*/
%else %do;
proc format;
value $ trs 'A->G','G->A','C->T','T->C'='Transition'
            'A->C','C->A','C->G','G->C','A->T','T->A','G->T','T->G'='Tranversion'
			Other='Indel';
run;
%end;

data &dsd(drop=ref_alt);
length ref_alt $5. &new_mut_var $12.;
set &dsd;
if (prxmatch('/\(/',&mut_var)) then do;
 ref_alt=compress(scan(&mut_var,2,'()'));
end;
else do;
ref_alt=compress(scan(&mut_var,3,'-:'));
ref_alt=prxchange('s/\|/->/',-1,ref_alt);
end;
&new_mut_var=put(ref_alt,$trs.);

/*where (&mut_var not contains '>+' and*/
/*   &mut_var not contains '>-' and*/
/*   &mut_var not contains '|-' and */
/*   &mut_var not contains '|+');*/
run;

%mend;

/*mult_types=0 for 2 groups,trans and transv;*/
/*mult_types=1 for 6 groups of mutations, plus other as empty;*/
/*mult_types=2 for 6 groups of mutations, plus other as Indel;*/
/*
%trans2tranv_fmt(dsd=dsd1,mut_var=mut,new_mut_var=x,mult_types=0);
*/

