/* https://en.wikipedia.org/wiki/Quantile_normalization */

%macro Quantile_normalization(data, var, out, ties=LOW);
     %local rn nv i n_obs var_r arr_r ;
     %let rn =zjk79x_;
     %let nv =%sysfunc(countw(&var));
     %do i =1 %to &nv;
           %let var_r =&var_r &rn.r%sysfunc(putn(&i, z3.));
           %let arr_r =&arr_r &rn.&i._[i];
           %end;
 
data _null_;
           call symputx('n_obs',nobs);
           if 0 then set &data nobs =nobs;
           stop;
           run;
proc rank data=&data out=&rn.d1 ties=&ties.;
           var &var.;
           ranks &var_r.;
          run;
 
data &rn.d2;
     set &rn.d1 end =Eof;
     %do i =1 %to &nv;
           array &rn.&i._[&n_obs.] _temporary_;
           %end;
     %do i =1 %to &nv;
           &rn.&i._[_n_] =%scan(&var, &i);
           %end;
     if Eof then do;
           retain fmtname 'NormScr' type 'I';
           %do i =1 %to &nv.;
                call sortn(of &rn.&i._[*]);
                %end;
           do i =1 to &n_obs.;
/*		        z1= zjk79x_1_[i];*/
/*				z2= zjk79x_2_[i];*/
/*				z3= zjk79x_3_[i];*/
/*			    z=mean(of z1 z2 z3);*/
/*              equal to the following*/
                label =mean(of &arr_r);
                start =i; end =start;
                output;
                end;
     end;
     run;
proc format cntlin=work.&rn.d2; run;
 
data &out;
     set &rn.d1;
     %do i =1 %to &nv;
           %scan(&var, &i) =input(%scan(&var_r, &i), NormScr.);
           %end;
     drop &var_r;
     run;
 
proc datasets nolist;    delete &rn.d:; run; quit;
%mend Quantile_normalization;


/*Note: The function will normalize each column variables*/

/* 
options mlogic mprint symbolgen;
data Quantile_normalization;
input gene $ a1-a3;
cards;
A    5    4    3
B    2    1    4
C    3    4    6
D    4    2    8
;
 
%Quantile_normalization(
  Quantile_normalization
, a1 a2 a3
, Normalized
, ties =LOW)
;

data Quantile_normalization;
  call streaminit(12345);
  array a[4];
  do i =1 to 100;
    do j =1 to 4;
      a[j] =rand('normal', 1);
      end;
    a[4-mod(i,4)] =rand('normal', 1*(4-mod(i,4))**1.25);
    output;
    end;
  run;
 
%Quantile_normalization(
  Quantile_normalization
, a1 a2 a3 a4
, Normalized
, ties =LOW
);
 
title "Figure 1: Original Distributions.";
proc sgplot data =Quantile_normalization;
  density a1/type =kernel legendLabel ='1';
  density a2/type =kernel legendLabel ='2';
  density a3/type =kernel legendLabel ='3';
  density a4/type =kernel legendLabel ='4';
  keylegend /location =inside across =1;
  xaxis label ='x';
  run;
title "Figure 2: Quantile Normalized Distributions.";
proc sgplot data =Normalized;
  density a1/type =kernel legendLabel ='1';
  density a2/type =kernel legendLabel ='2';
  density a3/type =kernel legendLabel ='3';
  density a4/type =kernel legendLabel ='4';
  keylegend /location =inside across =1;
  xaxis label ='x';
  run;
title;
*/
