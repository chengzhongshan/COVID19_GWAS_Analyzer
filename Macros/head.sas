%macro head(file=,dbms=tab,getnames=yes,datarow=2,nobs=15,out=_tmp_);
options obs=&nobs; 
 
proc import out=&out
            datafile="&file"
            dbms=&dbms replace; 
            getnames=&getnames; 
            datarow=&datarow; 
run; 
proc print;run;

options obs=max;

%mend;

/*Demo:;
*Simplified;
%head(file=Combined_exp4driver_and_random_genes.txt);

*Comprehensive checking file;
%head(file=Combined_exp4driver_and_random_genes.txt,dbms=tab,getnames=yes,datarow=2,nobs=15,out=_tmp_);
*/
