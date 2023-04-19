%macro ImportGeneLevelASE(filenames,dsdout,Reads4AB);
*Read cutoff of two haplotypes;
%if &Reads4AB eq %then %do;
 %let Reads4AB=20;
%end;

%let i=1;
%let fn=%qscan(&filenames,&i,%str( ));
%do %while (%qscan(&filenames,&i,%str( )) ne);
/*%let outdsd=%sysfunc(prxchange(s/\-/_/,999,&fn));*/
%ImportFilebyScan(file=&fn
                 ,dsdout=__YYY&i
                 ,firstobs=0
                 ,dlm='09'x
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
);
/*Add group id*/
data __YYY&i;
set __YYY&i;
group="&fn";
where input(V5,8.)>=&Reads4AB and
      input(V6,8.)>=&Reads4AB;
run;
/*Combined all __YYY datasets*/
/*Be carefull about >=*/
%if &i >= 2 %then %do;
%let ii=%eval(&i-1);
%union(dsn1=__YYY&ii,     /*Name of the first data set    */
             dsn2=__YYY&i,     /*Name of the second data set   */
             out=__YYY&i       /*Name of combined data set     */);
%end;
%if &i ge 10 %then %do;
options nonotes nosource nosource2 errors=0;
%end;

%let i=%eval(&i+1);
%let fn=%scan(&filenames,&i,%str( ));
%end;

options notes source source2 errors=20;

/*Assign new file name &dsdout to the last __YYY dataset*/
data &dsdout;
set __YYY%eval(&i-1);
run;
/*Delete all __YYY dataset*/
proc datasets nolist;
delete __YYY:;
run;

%mend;
/*

%ImportGeneLevelASE(filenames=&RNA_Seq_IDs,dsdout=All_Gene_ASE,Reads4AB=20);

*/
