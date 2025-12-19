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
/*proc print;run;*/
/*%abort 255;*/

%let nvars=%TotVarsInDsd(&data,var_type=_numeric_);
/*  %abort 255;*/
  *Now generate adjust positions for these input numbers;
/*
https://www.lexjansen.com/pharmasug/2010/CC/CC05.pdf
It is important to add options nosyntaxcheck here before the data step that is prone to error;
otherwise, other procedures followed the failed data step will be under the environment of 
options obs=0; adding this is the only solution when running sas codes in batch mode!
*/
OPTIONS NOSYNTAXCHECK;  
data &out.new;
        set &data.;
		*Need to make a copy for these input numbers;
        array u(*) u1-u&nvars;
		*The input numbers will be changed during evaluation in the array w;
        array w(*) &goal.;
        eps1000 = 1000*1E-12; /* SAS equivalent for precision */
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
		nmoving=1;
        do while (moving and nmoving<=500);
            moving = 0;
			nmoving+1;

            i = 1;
			*It is important to restrict the i < n;
			*when i=n, the loop will fail;
            do while (i <n);
                /* Find next block */
                b = 0;
                do j = i to n-1;
                    b+1;*It is necessary to put b+1 here before the leave command!;
                    if abs(w[j+1] - w[j] - v) > eps1000 then leave;
                    /*b + 1;*/
                end;

				*Get the last block;
				*Important: assign b=n-1 if b=0;
				if b=0 then b=n-1;

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
			/*Use xi but not i*/

/*Matlab original codes for debugging;
	nloop=0;
    while ~isempty(i) && nloop<500
        k0 = abs(diff(w)-v)>eps1000;
        nloop=nloop+1;
        for i = find(([1 k0] & w>u) | ([k0 1] & w<u))
            if i==1; leftLim  =-inf; else leftLim  = w(i-1)+v; end
            if i==n; rightLim = inf; else rightLim = w(i+1)-v; end
            w(i) = max(min(u(i),rightLim),leftLim);
            moving = true;
        end
    end
end % moving
*The following implements the above matlab codes in SAS;
*/

		k0=1;
		niters=0;
		 do while (k0 and niters<=500);
            do xi = 1 to n;
			 if xi=1 and w[xi]>u[xi] then k0=1;
             if xi=n and w[xi]<u[xi] then k0=1; 
             if xi>1 and xi<n then k0 = abs(w[xi] - w[xi-1] - v) > eps1000;
                if k0 then do;
				   if xi=1 then leftLim=-1E12;
                   else leftLim  = w[xi-1] + v;
                   if xi=n then rightLim=1E12;
                   else rightLim = w[xi+1] - v;
                   w[xi] = max(min(u[xi], rightLim), leftLim);
                    moving = 1;
					*Note: when xi=n, the 1st while loop relying on moving=1 might break;
					*For debugging, comment out the following code to test the scenario;
					*if xi=n then moving=0;
					niters+1;
                end;
            end;
		 end;
        end;
    run;
/*proc print data=_old_;run;*/
/* %abort 255;*/
%if %totobsindsd(&out.new)=0 %then %do;
   %put failed to generate adjusted dataset &out.new;
   %put try to use the original input dataset &data without adjustment;
   OPTIONS NOSYNTAXCHECK;
   data &out;
   set _old_;
   run;
%end;
%else %do;
  data &out;
  set &out.new;
  run;
%end;
/*
proc print data=&out;run;
%abort 255;
*/

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
10 10 101 30 40 32
;
proc sort;by x;
proc transpose data=a out=a1(drop=_name_);
var x;
run;

*Test the macro;
%spaceAdjust(data=a1, out=a2, goal=col:, sep=20, newvar4adjnum=AdjPos);
data a2;
set a2;
diff=Adjpos-lag(Adjpos);
proc print;run;
*Results should be   -15.6000    4.4000   24.4000   44.4000   64.4000  101.0000;

*Test the macro with input as a list;
%spaceAdjust(data=1 4 5 7000 10 101 3000 40 32, out=a2, goal=col1-col9, sep=2000,newvar4adjnum=AdjPos1);

%debug_macro;
%spaceAdjust(data=43057010  43057119  43063342  43091855  43093179 , out=z, goal=COL:, sep=1000, newvar4adjnum=newpos); 


*/
