%macro spaceAdjust(
/*
 This macro can generate new numbers by adjusting its distance space
 in the sorted numbers, so please ensure the input dataset containing
numbers that are sorted in ascending order; if the input is a list, the macro
will generate a sorted dataset and generate adjust numbers automatically.
*/
data=, /*Input dsd with long format with vars like col1-coln
or a list containing blank space separated elements*/
out=, /*out dsd in long format but only contains one column AdjPos*/
goal=COL:,/*Target column vars in the input data set, such as col1-coln*/ 
sep=, /*Minimum distance to separate numbers in the input data set and 
adjust the number by ensuring its distances to left and right numbers
at least greater than the minimum distance*/
newvar4adjnum=AdjPos /*Create a new variable to contain these
position adjusted numers*/);

%if %ntokens(&data)>=1 and %sysfunc(prxmatch(/^\d[\.E\d\s]+/,&data/)) %then %do;
   %put The macro will transform the input list: &data;
   %put into a sas dataset in wide-format that all vars col1-coln containing these input elements;
   %rank4grps(
    grps=&data,
    dsdout=&out);
    data &out;
    set &out;
    value=grps+0;
    *Need to sort these numeric values;
    proc sort data=&out;by value;run;
    proc transpose data=&out(keep=value) out=&out(drop=_name_);
    var value;
    run;
    %let goal=col:;
    %let data=&out;
%end;

  *First save a copy of input dataset for later merging with adjust positions;
  data _old_;
  set &data;
  run;
/*  %abort 255;*/

%let nvars=%TotVarsInDsd(&data,var_type=_numeric_);
/*  %abort 255;*/
  *Now generate adjust positions for these input numbers;
  data &out.;
        set &data.;
		*Need to make a copy for these input numbers;
        array u(*) u1-u&nvars;
		*The input numbers will be changed during evaluation in the array w;
        array w(*) &goal.;
        eps1000 = 1E-12; /* SAS equivalent for precision */
        n = dim(w);
        v = &sep.;
        
        /* Initialize output */
		*Ensure these _i_ and _ii_ will not interupt other similar loop vars;
		do _i_=1 to n;
          u[_i_] = w[_i_];
		end;
        do _ii_ = 2 to n;
            w[_ii_] = max(w[_ii_-1] + v, u[_ii_]);
        end;
        
        moving = 1;
		*Only try 500 times optimization, which would prevent the macro run forever;
		nmoving=500;
        do while (moving and nmoving<=500);
            moving = 0;
			nmoving+1;

            i = 1;
            do while (i <=n);
                /* Find next block */
                b = 0;
                do j = i to n-1;
                    if abs(w[j+1] - w[j] - v) > eps1000 then leave;
                    b + 1;
                end;
                sum_u=0;
                sum_w=0;
                do jj=i to i+b;
                  sum_u+u[jj];
                  sum_w+w[jj];
                end;
                
                sh = sum_u/(1+b) - sum_w/(1+b);
                if abs(sh) > eps1000 then do;
				   if i=1 then leftLim=-1E12;
				   else leftLim=w[i-1]+v;
				   if i+b=n then rightLim=1E12;
				   else rightLim=w[i+b+1]-v;
/*				   The following will fail, as ifn will evaluate w[i-1] even when i=1;*/
/*                    leftLim  = ifn(i=1, -1E12, w[i-1] + v);*/
/*                    rightLim = ifn(i+b=n, 1E12, w[i+b+1] - v);*/
                    if w[i] + sh < leftLim then sh = leftLim - w[i];
                    if w[i+b] + sh > rightLim then sh = rightLim - w[i+b];
                    
                    do jjj = i to i+b;
                        w[jjj] = w[jjj] + sh;
                    end;
                    moving = 1;
                end;
                i = i + b + 1;
            end;
            
            /* Move singles */
            do i = 2 to n-1;
                k0 = abs(w[i] - w[i-1] - v) > eps1000;
                if k0 then do;
                    leftLim  = w[i-1] + v;
                    rightLim = w[i+1] - v;
                    w[i] = max(min(u[i], rightLim), leftLim);
                    moving = 1;
                end;
            end;
        end;
    run;

data &out;
set &out;
keep Col:;
proc transpose data=&out out=&out(rename=(col1=&newvar4adjnum) drop=_name_);
var Col:;
run;

*Now combine the adjust and original numbers;
proc transpose data=_old_ out=_old_(drop=_name_ rename=(col1=orig_num));
var _numeric_;
run;
data &out;
merge _old_ &out;
run;
proc datasets nolist;
delete _old_;
run;
%mend spaceAdjust;
/*Demo codes:
filename M url "https://raw.githubusercontent.com/chengzhongshan/COVID19_GWAS_Analyzer/main/Macros/importallmacros_ue.sas";
%include M;
Filename M clear;
%importallmacros_ue(MacroDir=%sysfunc(pathname(HOME))/Macros,fileRgx=.,verbose=0);  

*Prepare data for the macro;
data a;
input x @@;
ord=_n_;
cards;
1 4 5 7 10 101 30 40 32
;
proc sort;by x;
proc transpose data=a out=a1(drop=_name_);
var x;
run;

*Test the macro;
%spaceAdjust(data=a1, out=a2, goal=col1-col9, sep=20, newvar4adjnum=AdjPos);

*Test the macro with input as a list;
%spaceAdjust(data=1 4 5 7000 10 101 3000 40 32, out=a2, goal=col1-col9, sep=2000,newvar4adjnum=AdjPos1);

%debug_macro;
%spaceAdjust(data=43057010  43057119  43063342  43091855  43093179 , out=z, goal=COL:, sep=1000, newvar4adjnum=newpos); 


*/
