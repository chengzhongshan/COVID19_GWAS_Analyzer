%macro AddRowNumber4Com_Vars(dsdin,Com_Vars,desending_or_not,dsdout);

%let vars=%sysfunc(prxchange(s/ +/%str(,)/,-1,&Com_Vars));
%put Your input Com_Vars are &vars;

proc sort data=&dsdin;
by &Com_Vars;
run;

data &dsdout(drop=tag);
length tag $200;
retain tag '' ord 0;
set &dsdin;
if _n_=1 then do;
 tag=catx(':',&vars);
 ord=1;
end;
else do;
 if tag^=catx(':',&vars) then do;
  ord=ord+1;
 end;
end;
run;


%if &desending_or_not %then %do;
proc sort data=&dsdout;
by descending ord;
run;
%end;
%else %do;
proc sort data=&dsdout;
by ord;
run;
%end;

%mend;


/*Demo

data Mut;
input chr $ st sample $;
cards;
chr7 11 a
chr7 20 a
chr7 30 b
chr7 40 a
chr7 14 a
chr7 400 c
chr7 100 d
chr7 1000 e
chr7 500 a
chr7 800 f
chr7 900 a
;

%AddRowNumber4Com_Vars(dsdin=Mut
                      ,Com_Vars=chr sample
                      ,desending_or_not=1
                      ,dsdout=z);
*/
