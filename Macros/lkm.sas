/*A SAS Macro for estimating and testing for the effect of a genetic pathway
on a disease outcome using logistic kernel machine regression via logistic 
mixed models.;
https://content.sph.harvard.edu/xlin/software.html
Liu, D., Ghosh, D. and Lin, X. (2008) Estimation and Testing for the Effect of a Genetic Pathway on a Disease Outcome Using 
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
 * path_name is the path where you store all your data files            *
 * file_name is your data file name in the specified library            *
 *  y is the response variable                                          *
 *  x is the list of covariates who enter the model parametrically      *
 *  z is the list of covariates who enter the model non-parametrically  *
 *  NOTE: covariates must be separated using white space.               *
 *  Example:  %lkm(c:\temp, mydata, y, x1 x2 x3, z1 z2 z3);             *
 *  Estimation and testing for the effect of a genetic pathway on a     *
*   disease outcome using logistic kernel machine regression via        *
*   logistic mixed models												*
 ************************************************************************/

%macro lkm(path_name, file_name, y, x, z);
libname lkmlib v8 "&path_name";
data xdata; set lkmlib.&file_name;
keep &x;
run;

data zdata; set lkmlib.&file_name;
keep &z;
run;

data ydata; set lkmlib.&file_name;
keep &y;
run;

title "Glimmix Procedure Output:";
proc glimmix data=lkmlib.&file_name;
class obs;
model &y.(order=freq)=&x /s dist=binary link=logit ddfm=residual ;
random obs/s type=sp(gau)(&z);
run;

proc printto print=NULL;
proc glimmix data=lkmlib.&file_name ;
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

dd=diag(mu_mat*(1-mu_mat)`);
gg=xmat*inv(xmat`*dd*xmat)*xmat`*dd;
sa=dd-dd*gg;
pp=inv(dd)*(ymat-mu_mat)+eta_mat;
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
do ii=1 to grid;
      
   scl=start+(ii-1)*delta;    
   k1=calk(zmat,scl);
   uu=0.5*rr`*dd*k1*dd*rr;
   www=k1*sa;
   ee=0.5*sum(diag(www));
   eee=0.5*sum(diag(www*www));
              
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
p_value=kmresult2[1,3];
test_statistic=m00;
title "Score Test Result:";
print p_value;
quit; 

%mend lkm;

*example:;
*%lkm(C:\Dawei\WorkingPapers\Paper2\Prostate_data, growth_all, dx, age, col2185  col8269 col9114  col971  col1412);


