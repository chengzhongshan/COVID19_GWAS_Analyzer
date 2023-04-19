%macro ImportVarscanRst(filenames,dsdout,Reads4tumor);
*Read cutoff of tumor reads;
*Only applied to snp but not indel;
%if &Reads4tumor eq %then %do;
 %let Reads4tumor=10;
%end;

%let i=1;
%let fn=%qscan(&filenames,&i,%str( ));
%do %while (%qscan(&filenames,&i,%str( )) ne);
/*%let outdsd=%sysfunc(prxchange(s/\-/_/,999,&fn));*/
%ImportFilebyScan(file=&fn..snp
                 ,dsdout=ZZZ&i._snp
                 ,firstobs=1
                 ,dlm='09'x
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
);
%ImportFilebyScan(file=&fn..indel
                 ,dsdout=ZZZ&i._indel
                 ,firstobs=1
                 ,dlm='09'x
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
);
data ZZZ&i._snp;
length type $5. gp $100.;
set ZZZ&i._snp;
type="snp";
gp="&fn";
run;
data ZZZ&i._indel;
length type $5. gp $100.;
set ZZZ&i._indel;
type="indel";
gp="&fn";
run;
/*Union two dsd*/
%union(dsn1=ZZZ&i._snp,     /*Name of the first data set    */
             dsn2=ZZZ&i._indel,     /*Name of the second data set   */
             out=__ZZZ&i       /*Name of combined data set     */);
/*Be careful about >= */
%if &i >= 2 %then %do;
%let ii=%eval(&i-1);
%union(dsn1=__ZZZ&ii,     /*Name of the first data set    */
             dsn2=__ZZZ&i,     /*Name of the second data set   */
             out=__ZZZ&i       /*Name of combined data set     */);
%end;

%if &i ge 10 %then %do;
options nonotes nosource nosource2 errors=0;
%end;

%let i=%eval(&i+1);
%let fn=%scan(&filenames,&i,%str( ));
%end;

options notes source source2 errors=20;

data &dsdout;
set __ZZZ%eval(&i-1);
run;
%add chr column;
data &dsdout(where=(chr^=.));
set &dsdout;
if (upcase(chrom)="X") then do;
 chr=23;
end;
else if ( upcase(chrom)="Y") then do;
 chr=24;
end;
else do;
chr=chrom-0;
end;
st=position-0;
where (input(tumor_reads1,8.)+input(tumor_reads2,8.) >= $Reads4tumor and type='snp') or
       type='indel';
run;

proc datasets nolist;
delete ZZZ: __ZZZ:;
run;

%mend;

/*

%ImportVarscanRst(filenames=&barcodes,dsdout=&dsdout,Reads4tumor=10);

*/
