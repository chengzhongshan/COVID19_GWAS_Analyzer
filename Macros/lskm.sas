/*
A SAS Macro for doing semiparametric regression of multi-dimensional 
genetic pathway data, using least squares kernel machines and linear 
mixed models.
https://content.sph.harvard.edu/xlin/software.html
Liu, D., Lin, X. and Ghosh, D. (2007) Semiparametric Regression of Multi-Dimensional Genetic Pathway Data: Least Squares Kernel 
Machines and Linear Mixed Models. Biometrics, 63, 1079-1088.
*/
/************************************************************************
 * path_name is the path where you store all your data files            *
 * file_name is your data file name in the specified library            *
 *  y is the response variable                                          *
 *  x is the list of covariates who enter the model parametrically      *
 *  z is the list of covariates who enter the model non-parametrically  *
 *  NOTE: covariates must be separated using white space.               *
 *  Example:  %lskm(c:\temp, mydata, y, x1 x2 x3, z1 z2 z3);            *
 ************************************************************************/

%macro lskm(path_name, file_name, y, x, z);
libname lskmlib v8 "&path_name";
data xdata; set lskmlib.&file_name;
keep &x;
run;

data zdata; set lskmlib.&file_name;
keep &z;
run;

proc mixed data=lskmlib.&file_name covtest noclprint noprint;
class obs;
model &y.=&x/s ddfm=bw;
random obs/s type=sp(gau)(&z);
ods output solutionf=coeff_gau covparms=cov_gau 
solutionr=h_est;
run;


proc sort data=cov_gau; by covparm; 
run;

data cov1_gau; set cov_gau; by covparm;
drop covparm estimate var_gau stderr zvalue probz;
retain resid_gau resid_gau_se;
if _N_=1 then do; resid_gau=estimate; resid_gau_se=stderr; end;
retain scale_gau;
if _N_=2 then scale_gau=estimate;
if _N_=3 then do; var_gau=estimate; end;
tau_gau=var_gau/resid_gau;
if resid_gau ne . and scale_gau ne . and var_gau ne .;
run;


data _null_; set cov1_gau;
call symput("esigmasq",left(resid_gau));
call symput("erho",left(scale_gau));
call symput("etau",left(tau_gau));
run;

%let rhosq=%sysevalf(&erho**2);

%k_g(zdata,&rhosq);

%freq_se(&esigmasq,&etau,xdata,kk_gau,gau);
%gau_freq_se(&esigmasq,&etau,xdata,kk_gau,gau);
%gau_bays_se(&esigmasq,&etau,xdata,kk_gau,gau);

data gau_bays_se; set coeff_gau;
keep Estimate stderr;
run;

data gau_x_se(rename=(Stderr=Bayesian_STDERR x_gau_freq_se=Freq_STDERR)); merge gau_bays_se gau_freq_se;
run;
title "Regression coefficients estimates and their standard errors";
proc print data=gau_x_se;
run;

data gau_h_se(rename=(estimate=prediction gau_h_bays_se=Bayesian_STDERR gau_h_freq_se=Freq_STDERR)); merge h_est gau_h_bays_se gau_h_freq_se;
drop effect stderrpred df tvalue probt;
run;
title "Prediction of nonparametric function and their standard errors";
proc print data=gau_h_se;

run;
/*data se_gau_bays;  merge se_gau_bays gau_h_bays_se;
run;
*/


%mend lskm;

%macro k_g(zfile,scale);
proc iml;
  scl=&scale;
  
  use &zfile;
  read all into tmp1;
  n=nrow(tmp1);
  m=ncol(tmp1);
  k_gau=I(n); 
  u=J(n,1,0);
  do i=1 to n;
    do j=1 to n;
	  sum=0;
	  do k=1 to m;
        sum=sum+(tmp1[i,k]-tmp1[j,k])**2;
	  end;
	  k_gau[i,j]=exp(-sum/scl);
	end;
  end;

  create kk_gau from k_gau;
  append from k_gau;

quit;
%mend k_g;


%macro freq_se(sigma,tau,xx,kk,mark);
proc iml;
tau_est=&tau;
sigma_est=&sigma;
lambda=1/tau_est;

use &xx;
read all into xx_mat0;
sample=nrow(xx_mat0);
i_mat=I(sample);
inter=J(sample,1,1);
xx_mat=inter||xx_mat0;
use &kk;
read all into kk_mat;
vv_mat=kk_mat+lambda*i_mat;
vv_mat_inv=inv(vv_mat);
x_vv=xx_mat`*vv_mat_inv;
mid_xv=x_vv*x_vv`;
x_vv_x=inv(xx_mat`*vv_mat_inv*xx_mat);
var_x=sigma_est*x_vv_x*mid_xv*x_vv_x;
se_x0=sqrt(vecdiag(var_x));
create &mark._freq_se from se_x0[colname="x_&mark._freq_se"];
append from se_x0;
quit;
%mend freq_se;


%macro gau_freq_se(sigma,tau,xx,kk,mark);
proc iml;
tau_est=&tau;
lambda=1/tau_est;
sigma_est=&sigma;

use &xx;
read all into xx_mat0;
sample=nrow(xx_mat0);
x_num=ncol(xx_mat0);

i_mat=I(sample);
inter=J(sample,1,1);
xx_mat=inter||xx_mat0;
zero=J(sample,x_num,0);
tt_mat=inter||zero;
big_t=tt_mat||i_mat;

use &kk;
read all into kk_mat;
vv_mat=kk_mat+lambda*i_mat;
vv_mat_inv=inv(vv_mat);
x_vv=xx_mat`*vv_mat_inv;
x_vv_x=inv(xx_mat`*vv_mat_inv*xx_mat);
a_mat=i_mat-xx_mat*x_vv_x*x_vv;
p_mat=vv_mat_inv*a_mat;
mid_mat=(-1)*kk_mat*vv_mat_inv*xx_mat*x_vv_x;
rand_mat=kk_mat-kk_mat*p_mat*kk_mat;

top_mat=x_vv_x||mid_mat`;
bot_mat=mid_mat||rand_mat;
cov_mat=top_mat//bot_mat;
c_top=xx_mat`*xx_mat||xx_mat`;
c_bot=xx_mat||i_mat;
c_mat=c_top//c_bot;
var_x=sigma_est*tau_est**2*big_t*cov_mat*c_mat*cov_mat*big_t`;
se_x=sqrt(vecdiag(var_x));
create &mark._h_freq_se from se_x[colname="&mark._h_freq_se"];
append from se_x;
quit;
%mend gau_freq_se;

%macro gau_bays_se(sigma,tau,xx,kk,mark);
proc iml;
tau_est=&tau;
lambda=1/tau_est;
sigma_est=&sigma;

use &xx;
read all into xx_mat0;
sample=nrow(xx_mat0);
x_num=ncol(xx_mat0);

i_mat=I(sample);
inter=J(sample,1,1);
xx_mat=inter||xx_mat0;
zero=J(sample,x_num,0);
tt_mat=inter||zero;

use &kk;
read all into kk_mat;
vv_mat=kk_mat+lambda*i_mat;
vv_mat_inv=inv(vv_mat);
x_vv=xx_mat`*vv_mat_inv;
x_vv_x=inv(xx_mat`*vv_mat_inv*xx_mat);
a_mat=i_mat-xx_mat*x_vv_x*x_vv;
p_mat=vv_mat_inv*a_mat;
mid_mat=kk_mat*vv_mat_inv*xx_mat*x_vv_x*tt_mat`;
var_x=sigma_est*tau_est*(tt_mat*x_vv_x*tt_mat`-mid_mat+kk_mat-kk_mat*p_mat*kk_mat-mid_mat`);
se_x=sqrt(vecdiag(var_x));
create &mark._h_bays_se from se_x[colname="&mark._h_bays_se"];
append from se_x;
quit;
%mend gau_bays_se;








 
