/*
The macro has been changed to read sas dataset directly by Zhongshan Cheng;

A SAS Macro for estimating and testing for the effect of a genetic pathway
on a disease outcome using logistic kernel machine regression via logistic 
mixed models.;
https://content.sph.harvard.edu/xlin/software.html
Liu, D., Ghosh, D. and Lin, X. (2008) Estimation and Testing for the Effect 
of a Genetic Pathway on a Disease Outcome Using 
Logistic Kernel Machine Regression via Logistic Mixed Models. BMC Bioinformatics, 9, 292.

Estimation and testing for the effect of a genetic pathway on a disease 
outcome using logistic kernel machine regression via logistic mixed models

Usage:
This macro has been created to apply the proposed logistic kernel machine 
regression model as described in the Methods section to the analysis of a prostate 
cancer data set. The data came from the Michigan prostate cancer study [15]. 
This study involved 81 patients with 22 diagnosed as non-cancerous and 59 
diagnosed with local or advanced prostate cancer. Besides the clinical and 
demographic covariates such as age, cDNA microarray gene expressions were 
also available for each patient. The early results of Dhanasekaran et al. 
[15] indicate that certain functional genetic pathways seemed dys-regulated 
in prostate cancer relative to non-cancerous tissues. We are interested in 
studying how a genetic pathway is related to the prostate cancer risk, 
controlling for the covariates. We focus in this analysis on the cell 
growth pathway, which contains 5 genes. The pathway we describe was 
annotated by the investigator (A. Chinnaiyan) and is simply used to 
illustrate the methodology. Of course, one could take the pathways 
stored in commercial databases such as Ingenuity Pathway Analysis 
(IPA) and use the proposed methodology based on those gene sets.
*/

/************************************************************************
 * sas_dsd is your data file name in the specified library            *
 *  y is the response variable                                          *
 *  x is the list of covariates who enter the model parametrically      *
 *  z is the list of covariates who enter the model non-parametrically  *
 *  NOTE: covariates must be separated using white space.               *
 *  Example:  %lkm(c:\temp, mydata, y, x1 x2 x3, z1 z2 z3);             *
 *  Estimation and testing for the effect of a genetic pathway on a     *
*   disease outcome using logistic kernel machine regression via        *
*   logistic mixed models												*
 ************************************************************************/

%macro lkm(sas_dsd, y, x, z);
data xdata; set &sas_dsd;
keep &x;
run;

data zdata; set &sas_dsd;
keep &z;
run;

data ydata; set &sas_dsd;
keep &y;
run;

title "Glimmix Procedure Output:";
proc glimmix data=&sas_dsd;
class obs;
model &y.(order=freq)=&x /s dist=binary link=logit ddfm=residual ;
random obs/s type=sp(gau)(&z);
run;

proc printto print=NULL;
proc glimmix data=&sas_dsd ;
model &y.(order=freq)=&x /s dist=binary link=logit ddfm=residual ;
output out=myout pred(ilink)=mu pred=eta;
run;
proc printto print=print;

data myout1; set myout;
keep mu eta;
run;

proc iml;

grid=500;
*the default number of grid points=500. It can be changed to any other large enough value;
*note: scl is corresponding to the sp(gau) parameter rho**2;
start calk(zdat, scl);
  n=nrow(zdat);
  m=ncol(zdat);
  k_gau=I(n); 
  u=J(n,1,0);
  do i=1 to n;
    do j=1 to n;
	  sum=0;
	  do k=1 to m;
        sum=sum+(zdat[i,k]-zdat[j,k])**2;
	  end;
	  k_gau[i,j]=exp(-sum/scl);
	end;
  end;
  return(k_gau);
finish calk;

*Compared to the above function calk;
*The function calk0 does not include the adjustment by rho**2;
start calk0(zdat);
  n=nrow(zdat);
  m=ncol(zdat);
  k_gau=I(n); 
  u=J(n,1,0);
  do i=1 to n;
    do j=1 to n;
	  sum=0;
	  do k=1 to m;
        sum=sum+(zdat[i,k]-zdat[j,k])**2;
	  end;
	  k_gau[i,j]=sum;
	end;
  end;
  return(k_gau);
finish calk0;


use myout1;
read all var {mu} into mu_mat;
read all var {eta} into eta_mat;
use ydata;
read all into ymat;
use xdata;
read all into xmat0;
use zdata;
read all into zmat;


nn=nrow(ymat);
xmat=J(nn,1,1)||xmat0;
*note: mu*(1-mu) is the error variance for binomial model;
dd=diag(mu_mat*(1-mu_mat)`);
*In the context of GLMs, the projection matrix typically refers to a matrix that projects the observed responses Y onto the predicted values Y_bar based on the model.;
*Note: H*Y=Y_bar;
*gg is the projection matrix H, with dd equivalent to W, representing the diagonal matrix of weights (often representing the variance structure).;
gg=xmat*inv(xmat`*dd*xmat)*xmat`*dd;
*sa is like the remain variance after removal of covar x variance from the total variance dd;
*see page 11 of the BMC bioinformatics paper;
*Constructs the matrix sa as the residual variance after removing the covariate x contribution from the total variance dd;
sa=dd-dd*gg;
*pp seems to be predicted probability;
pp=inv(dd)*(ymat-mu_mat)+eta_mat;
*rr is residue;
rr=pp-gg*pp;

k01=calk0(zmat);
maxk=max(k01);
k011=k01;
* the following operation is to get rid of 0 values of the k01 matrix so that the minimam is always bigger than 0;
do i=1 to nn;
  do j=1 to nn;
    if k011[i,j]<0.00000001 then k011[i,j]=100;
  end;
end;
mink=min(k011);
start=mink/10;
end=maxk*10;
delta=(end-start)/grid;

kmresult1=J(grid,2,0);
kmresult2=J(1,3,0);
*Score test for rho;
do ii=1 to grid;
      
   scl=start+(ii-1)*delta;    
   k1=calk(zmat,scl);
	 *Q_tau_beta_rho=(r - xbeta)_trans*D*K(rho)*D*(r-xbeta);
   uu=0.5*rr`*dd*k1*dd*rr;
   www=k1*sa;
   ee=0.5*sum(diag(www));
   eee=0.5*sum(diag(www*www));
   *ss is S(rho), see formula 11 at page 11 of the lkm BMC bioinformatics paper;           
   ss=(uu-ee)/sqrt(eee);
              
   kmresult1[ii,1]=scl;
   kmresult1[ii,2]=ss;
              
end;      

m0=kmresult1[1,2];
m00=max(kmresult1[,2]);
kmnew=m0//kmresult1[1:(grid-1),2];
b0=sum(abs(kmresult1[,2]-kmnew));
kmresult2[1,1]=m00;
kmresult2[1,2]=b0;
kmresult2[1,3]=probnorm(-m00)+b0*exp(-0.5*m00**2)/sqrt(8*3.141592654);

*get the rhosq for the max S_rho value;
mridx=kmresult1[<:>,2];
rhosqr4maxS=kmresult1[mridx,1];

create kmresult2_dsd from kmresult2[colname={"max_Srho4score_test" "W4score_test" "score_test_pvalue"}];
append from kmresult2;
create kmresult1_dsd from kmresult1[colname={"rhosq" "S_rho4score_test"}];
append from kmresult1; 

p_value=kmresult2[1,3];
test_statistic=m00;
title "Score Test Result:";
print p_value;
*Print other parameters, added by zhongshan;
*m00 is the maximum of S(rho) over the range of rho in the score test;
print m00;
*W = |S(rho1) – S(L)| + | S(rho2) – S(rho1) | + ... + | S(U) – S(rhom) |;
*L and U are the lower and upper bound of rho respectively and rhol, l = 1, ..., m are the m grid points between L and U.;
*W value for the score test;
print b0;
print rhosqr4maxS;
quit; 

%mend lkm;

/*Demo codes:;

data a;
call streaminit(123);
do i=1 to 100;
  array z{10} z1-z10;
  do ri=1 to dim(z);
    z{ri}=rand('norm');
   end;
   a=0.2;
   h_z=2*(z1-z2)**2+z2*z3+3*sin(2*z3)*z4+z5**2+2*cos(z4)*z5;
   x=z1+rand('normal')/2;
	 eta=exp(x+a*h_z);
   *avoid of using mu for eta/(1+eta), as it is an internal var used by the lkm macro;
   if eta/(1+eta)>0.6 then r=1;
   else r=0;
   output;
end;
drop eta ri a i h_z;
run;

data a;
set a;
obs=_n_;
run;

*When a=0, get the size parameter;
proc glimmix data=a;
class obs;
model r(order=freq)=x /s dist=binary link=logit ddfm=residual ;
random obs/s type=sp(gau)(z1 z2 z3 z4 z5);
run;

*Known enriched gene set;
%lkm(sas_dsd=a,y=r, x=x, z=z1 z2 z3 z4 z5);
*By only focus on specific z vars, it is possible to get which z var is the most important one to explain the variance model;
%lkm(sas_dsd=a,y=r, x=x, z=z2 z3 z4 z5);

*Negative gene set without association;
%lkm(sas_dsd=a,y=r, x=x, z=z6 z7 z8 z9 z10);

*/


