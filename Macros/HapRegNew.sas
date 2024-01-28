/*
Updated by Zhongshan Cheng Jan-14-2024;
If the haplotype data is not supplied, the macro will estimate the haplotypes among the input genotype data;
and provide an initimation of haplotype frequencies;

The SAS macro HapRegNew implements the haplotype-based genetic association analysis 
for case-control studies, using a flexible model for gene-environment association 
allowing haplotypes to be potentially related with environmental exposures. 

Typical code for running the macro:

*Use supplied haplotypes;
%HapReg(data=a, hdata=h, d=1, zsel=2 3 10 11, zgsel=10 11, zzsel=10 11, snp=4 5 6
7 8 9, rare=5 7, hsel=2 3 4 6, hselg=6, mode=a pr1=0);

*Use input data to estimate haplotypes;
%HapReg(data=a, hdata= , d=1, zsel=2 3 10 11, zgsel=10 11, zzsel=10 11, snp=4 5 6
7 8 9, rare=5 7, hsel=2 3 4 6, hselg=6, mode=a pr1=0);

*/

%Macro HapRegNew(
data, /*a SAS dataset containing the data to be analyzed, containing columns such as
d gender age g1 g2 g5 g6 g7 g8 smk1 smk2 smkyn*/
hdata, /*sas dataset for haplotypes, with the 1st one treated as the most frequently appeared one;
default is empty to use the above input genotype dataset to estimate initial haplotypes;
each row of the dataset would be for one haplotype like this: 1 0 0 0 1*/
d,/*column number for phenotype under study*/
zsel=2,  /*specify the k1,k2,…th variables (can be more than one) in dataset specified
in data as the environmental covariates to be included in the disease risk model*/
zgsel=2, /*specify the g1,g2…th variables (can be more than one) in dataset specified
in data as the environmental covariates in the disease risk model that have
interactions with haplotypes specified in hselg*/
zzsel=2, /*specify the l1,l2…th variables (can be more than one) in dataset specified in data 
as the environmental covariates to be included in the model for the haplotype distribution in the control population*/
snp=, /*snp column numbers separated by comma or - with %bquote if with comma;
specify the s1,s2,…th variables (can be more than one) in dataset specified
in data that contain the SNP genotype data to be analyzed*/
rare=, /*specify the r1,r2,…th rows (haplotypes) in dataset specified in hdata as the
haplotypes that have smaller (e.g., <1%) frequency and need to be grouped
into the baseline haplotype; if no such haplotype it is set to “.” (dot)*/
hsel=2,/*specify the h1,h2,…th rows (haplotypes) in dataset specified in hdata as
the haplotypes to be considered in the disease risk model (not including the
reference haplotype and the haplotypes grouped into the reference)*/ 
hselg=2, /*specify the t1,t2,…th rows (haplotypes) in dataset specified in hdata as the
haplotypes in the disease risk model that have interactions with
environmental covariates specified in zgsel*/
mode=a, /*two models, including a for Additive, and d for dominant; recessive model is not implemented due to uncertainty*/
pr1=0.2, /*specify a quantity between 0 and 1 that corresponds to the true population disease prevalence rate; when pr1=0 
is specified, a rare-disease approximation is performed*/
rare_frq_cutoff=0.05 /*Rare haplotype frequency threshold used to select rare haplotypes for the macro variable rare!
Note: this is only used when the haplotype frequencies are estimated based on the input sas dataset*/
); 

%get_consecutive_num4linker(nums_with_linker=&snp, global_macro_out=numbers, linker=-);
%let snp=&numbers;
%put snp column numbers are &snp;

 *If the haplotype data is empty, it will use a simple method to get the initial haplotypes internally;
%if %length(&hdata)=0 %then %do;

%put We will use the input geno-pheno dataset to estimate haplotypes and;
%put its corresponding frequencies will be used to selected the reference and rare haplotypes for HapRegNew.;

%pull_column(dsd=&data,dsdout=genopheno4haps,cols2pull=&d &snp);

%geno2allelecolumns(
dsd=genopheno4haps,
cols4genos=2-%eval(1+%ntokens(&snp)),
outdsd=_geno_pheno_
);

%InitEstHapFrq(
gen_pheno_sasdsd=_geno_pheno_,
numSNPsInDsd=%ntokens(&snp),
maxMissingGenos=1, 
verbose=0,
Hapfrq_outdsd=Hapfrq	
);

proc sort data=Hapfrq;
*COL1 is for initial estimates of haplotype frequencies;
by descending COL1;
run;

%let rare=.;

data _hapfrq_;
set Hapfrq;
n=_n_;
run;
proc sql noprint;
select n into: rare separated by ' '
from _hapfrq_
where col1<&rare_frq_cutoff;

%if %length(&rare)=0 %then %do;
   %put No haplotypes identified using the input sas dataset with rare haplotype frequency threshold of &rare_frq_cutoff;
	 %abort 255;
%end;

%put Now the rare haplotype row numbers are updated as &rare using the input sas dataset;

data Hapfrq4backup;
set Hapfrq;
rename COL1=HapFrq;
run;
data Hapfrq;
set Hapfrq;
drop COL1;
run;
%let hdata=Hapfrq;

%end;

*Need to change the input char geno labels in the sas dataset &data, such as 00 01/10 11 into 0 1 2 for proc iml;
data updated_data;
 set &data;
 array X{*} $2. _character_;
 do xi=1 to dim(X);
    X{xi}=prxchange('s/\b00\b/0/',-1,X{xi});
		X{xi}=prxchange('s/\b(01|10)\b/1/',-1,X{xi});
		X{xi}=prxchange('s/\b(11)\b/2/',-1,X{xi});
 end;
 drop xi;
 run;

 %Auto_char2num4dsd( dsdin=updated_data,col_num_pct=0.9 ,dsdout=updated_data) ;

 %let data=updated_data;

proc iml worksize=100 symsize=100;
option ps=1010;
/*reset nolog;*/

use &data;
read all /*var{d gender age g1 g2 g5 g6 g7 g8 smk1 smk2 smkyn}*/  into data;

hs=data[,{&snp}];

if ncol(loc(hs=.))>0 then hs[loc(hs=.)]=9;

data[,{&snp}]=hs;

nt=nrow(data);
nc=ncol(data);
mis=j(1,nc,.);
nobs=0;
do i=1 to nt;
  datai=data[i,];
  if all(datai^=mis) then do;
    nobs=nobs+1;
    if nobs=1 then da=datai;
	else da=da//datai;
  end;
end;
data=da;



zsel={&zsel}`;
zgsel={&zgsel}`;
zzsel={&zzsel}`;



use &hdata;
read all into hn;

/*
hn={1 0 0 0 1 1,
    0 0 1 1 0 0,
    1 0 1 1 0 0,
	1 1 0 0 1 0,
	0 0 1 0 1 0,
	1 0 1 0 1 0,
	0 0 1 1 1 0
	};
*/



mode={&mode}; /*a=additive; d=dominant */

vname=(contents(&data))`;/*{d gender age snp1 snp2 snp3 snp4 snp5 snp6 smk1 smk2 smkyn};*/


nv=ncol(vname);
vgname=vname`||j(nv,1,"*");
vgname=(rowcatc(vgname))`;
vvname=vname`||j(nv,1,"#");
vvname=(rowcatc(vvname))`;
/*
vgname={"d*" "gender*" "age*" "snp1*" "snp2*" "snp3*" "snp4*" "snp5*" "snp6*" "smk1*" "smk2*" "smkyn*"};
vvname={"d#" "gender#" "age#" "snp1#" "snp2#" "snp3#" "snp4#" "snp5#" "snp6#" "smk1#" "smk2#" "smkyn#"};
*/

d=data[,&d];
case=loc(d=1);
control=loc(d=0);

data1=data[case,];
data0=data[control,];
data=data1//data0;

hs=data[,{&snp}];
d=data[,&d];
z=data[,zsel];
zg=data[,zgsel];
zgname=vgname[zgsel];
dimzg=ncol(zg);

zname=vname[zsel];
dimz=ncol(z);


pr1=&pr1;
pr0=1-pr1;

nt=nrow(d);
n1=(d=1)[+];
n0=(d=0)[+];
nu=0;
if pr1>0 then
nu=log(n1/n0)+log(pr0/pr1);

if zzsel^=. then do;
   
   zz=data[,zzsel];
   zzname=vvname[zzsel];
   dimzz=ncol(zz);


z1=z[1:n1,];
z0=z[n1+1:nt,];
zz1=zz[1:n1,];
zz0=zz[n1+1:nt,];

zg1=zg[1:n1,];
zg0=zg[n1+1:nt,];






nsnp=ncol(hn);
k=nrow(hn);


hc=char(hn);
hc=rowcat(hc);



/*ncf=(inifq>=rf)[+];
kz=ncf;*/
hsel={&hsel};
rare={&rare};
hsel=(setdif(hsel,rare))`;
dh=nrow(hsel);

hselg={&hselg}`;
dhg=nrow(hselg);

do i=1 to dhg;
   hselggg=loc(hsel=hselg[i]);
   if i=1 then hselgg=hselggg;
   else hselgg=hselgg//hselggg;
end;



all=loc(j(k,1,1)>0);
common=(setdif(all, rare))`;
kz=nrow(common);
indexz=common[2:kz];

group=j(kz,k,0);
group[1,]=j(1,k,1);
group[,common]=i(kz);

/*print group;*/


dexx=group[,hsel];
do i=1 to dh;
  dexi=dexx[,i];
  dexi=loc(dexi=1);
  if i=1 then dex=dexi;
  else dex=dex||dexi;
end;


dimp=k-1;
dimpz=kz-1;


do i=1 to k;
  if i=1 then sym=1;
  else sym=sym||i;
end;
sym=char(sym,1);






do hf=1 to k;
     do hm=1 to k;

	    

	     
        hmz=group[,hm];hmz=loc(hmz=1);
		hfz=group[,hf];hfz=loc(hfz=1);

/*
        hmz= 1*(hm=1 | hm=5 | hm=7)+2*(hm=2)+3*(hm=3)+4*(hm=4)+
		          5*(hm=6);
		hfz= 1*(hf=1 | hf=5 | hf=7)+2*(hf=2)+3*(hf=3)+4*(hf=4)+
		          5*(hf=6);
*/

	do i=1 to dh;
          
	     dexi=dex[i];
         xxfii= (hfz=dexi)+ (hmz=dexi);

		 if (mode="a" | mode="A") then xxfii=xxfii;
		 if (mode="d" | mode="D") then xxfii=(xxfii>0);
	
		 if i=1 then xxfi=xxfii;
		 else xxfi=xxfi||xxfii;
   
     end; 


		dlp1i=j(1,dimpz,0);dlp2i=j(1,dimpz,0);
		if hmz>1 then dlp1i[hmz-1]=1;
		if hfz>1 then dlp2i[hfz-1]=1;
		dlpi=dlp1i+dlp2i;
		
        if (hf=1 & hm=1) then do; 
		      xxf=xxfi;
			  dlp=dlpi;
        end;
		else do; 
		     xxf=xxf//xxfi;
			 dlp=dlp//dlpi;
        end;
    end;
end;
xxg=xxf[,hselgg];


hname=j(dh, 1, "hap");
hname1=sym[hsel];
hname1g=sym[hselg];
zname1=sym[indexz];


do dd=1 to dimzg;
  zgnamed=j(dhg,1,zgname[dd]);
  if dd=1 then do;
     zgn=zgnamed;
	 zgn1=hname1g;
  end;
  else do;
     zgn=zgn//zgnamed;
	 zgn1=zgn1//hname1g;
  end;
end;
do dd=1 to dimzz;
  zznamed=j(dimpz,1,zzname[dd]);
  if dd=1 then do;
     zzn=zznamed;
	 zzn1=zname1;
  end;
  else do;
     zzn=zzn//zznamed;
	 zzn1=zzn1//zname1;
  end;
end;
tname=j(dimp,1,"theta");
tname1=sym[2:k];
fname=j(k,1,"hap.freq");
fname1=sym[1:k];

bname="int"//hname//zgn//zname;
name=bname//tname//zzn//fname;
bname1=" "//hname1//zgn1//j(dimz,1," ");
name1=bname1//tname1//zzn1//fname1;
name=name||name1;
name=rowcat(name);



start weight;


th00=0//theta00;
th00=j(nt,1,1)*th00`;
 /*freqe=(phi0n>-10)#exp(phi0n+zz*phi1`)+(phi0n=-10)*0;*/


do hf=1 to k;
   do hm=1 to k;

        hh=(hf-1)*k+hm;
        xxi=xxf[hh,];xxgi=xxg[hh,];

		betahh=beta[2:dh+1];
		betazgw=beta[dh+2:dh+1+dhg*dimzg];
		betaz=beta[dh+2+dhg*dimzg:dh+1+dhg*dimzg+dimz];

		betazgw=(shape(betazgw,dimzg))`;

		do dd=1 to dimzg;
		   zg1d=zg1[,dd];
		   zg0d=zg0[,dd];
		   betazgd=betazgw[,dd];
		   itd1=xxgi*betazgd*zg1d;
		   itd0=xxgi*betazgd*zg0d;
   		   if dd=1 then do;
               intera1=itd1;
			   intera0=itd0;
           end;
   		   else do;
               intera1=intera1+itd1;
			   intera0=intera0+itd0;
		   end;
		end; 

        eta1=xxi*betahh+intera1+z1*betaz;

		th00i=th00[,hh];
		
        hmz=group[,hm];hmz=loc(hmz=1);
		hfz=group[,hf];hfz=loc(hfz=1);
        
        phi1w=b[dim+dimp+1:dim+dimp+dimpz*dimzz];
		phi1=(shape(phi1w,dimzz))`;

        if hfz=1 then phi21=j(1,dimzz,0);
		else phi21=phi1[hfz-1,];

		if hmz=1 then phi22=j(1,dimzz,0);
		else phi22=phi1[hmz-1,]; 
            
		freqe=exp(th00i+zz*(phi21+phi22)`);
        freqe1=freqe[1:n1,];
        freqe0=freqe[n1+1:nt,];


        if pr1=0 then do;
           pyp1i=exp(eta1)#freqe1;
		   pyp0i=freqe0;
		end;
		if pr1>0 then do;
		   eta1=beta[1]+xxi*betahh+intera1+z1*betaz;
           py1=1/(1+exp(-eta1));
		   eta0=beta[1]+xxi*betahh+intera0+z0*betaz;
		   py0=1/(1+exp(eta0));
		   pyp1i=py1#freqe1;
		   pyp0i=py0#freqe0;
		end;
        if (hf=1 & hm=1) then do; 
			  pyp1=pyp1i;
			  pyp0=pyp0i;
        end;
		else do; 
			 pyp1=pyp1||pyp1i;
			 pyp0=pyp0||pyp0i;
        end;
	end;
end;


finish;








do tt=1 to k-1;
		   dlpt1=j(k*k,1,0);
		   dlpt1[tt*k+1:(tt+1)*k]=1;
           dlpt2=j(k,1,0);dlpt2[tt+1]=1;
		   dlpt2=repeat(dlpt2,k,1);
		   dlpt=dlpt1+dlpt2;

		   if tt=1 then do; 
              dlpo=dlpt;
          end;
		   else do;
              dlpo=dlpo||dlpt;
           end;
end;


start calpair;

  do hf=1 to k;
     do hm=1 to k;

        hai=hfreq[hf]*hfreq[hm];
		
        if (hf=1 & hm=1) then do; 
			  ha=hai;
        end;
		else do; 
			 ha=ha//hai;
        end;
    end;
end;
ha0=ha[1];
ha=ha[2:k*k];
theta0=log(ha/ha0);

finish;



start estf;

  oldfr=fr+1;
  do it=1 to 20 while  (max(abs(oldfr-fr))>0.0001); 
    df=max(abs(oldfr-fr));
    oldfr=fr;

    do hf=1 to k;
	  do hm=1 to k;
          we0i=fr[hf]*fr[hm];
		  if (hf=1 & hm=1) then we00=we0i;
		  else we00=we00||we0i;
	  end;
	end;
	we00=sg0#we00;
	we00s=we00[,+];we00s=(we00s>0)#(we00s)+(we00s=0)*1E5;
    we00=we00#(1/we00s);


    bf=((we00*dlpo)[+,])`;
    bf=bf/(2*n0);
	fr0=1-bf[+];
	fr=fr0//bf;


  end;

finish;





start newton;
  
  cc=loc(b>-10);
  run estsc;/*print b es;*/
  do iter=1 to 20 while (max(abs(es[cc]))>0.0001 & max(abs(es))<1E10);
    run estjac;
	
	 cc=loc(b>-10);   
	Ht=Ht[cc,cc]; /*dh=abs(det(Ht)); print dh;*/
    if abs(det(Ht))>1E-100 then do;

	   dimc=ncol(cc);
	   es=es[cc];
       delta=-solve(Ht,es);
       deltac=j(dimt,1,0);
       deltac[cc]=delta;
	   bb=(b+deltac);
       b=(bb<=-10)*(-10)+(bb>-10)#(bb); 
	
       cc=loc(b>-10);
       run estsc; /*print b es iter ite;*/
   end;
   else es=j(dimt,1,1E10);

  end;


finish;

start estsc;
     
      if (max(abs(b))<50) then do;
          beta=b[1:dim]; phi=b[dim+1:dim+dimp];phi1w=b[dim+dimp+1:dim+dimp+dimpz*dimzz];
		  phi1=(shape(phi1w,dimzz))`;

        do hf=1 to k;
		   do hm=1 to k;

		   hmz=group[,hm];hmz=loc(hmz=1);
		   hfz=group[,hf];hfz=loc(hfz=1);

		   if hfz=1 then phi21=j(1,dimzz,0);
		   else phi21=phi1[hfz-1,];

		   if hmz=1 then phi22=j(1,dimzz,0);
		   else phi22=phi1[hmz-1,]; 

		   lpti=phi21+phi22;

		

		   if (hf=1 & hm=1) then do; 
              lpt=lpti;
          end;
		   else do;
              lpt=lpt//lpti;
           end;
		end;
	  end;

	    /* za=z*j(1,k*k,1);
		 lpt=zz*lpt`;
		 */

	    lpt=zz*lpt`;
		

        hfreq=exp(phi)/(1+(exp(phi)[+]));
		hfreq0=1-hfreq[+];
	    hfreq=hfreq0//hfreq;
		if hfreq0<1E-20 then es=j(dimt,1,1E10);
        else do; 
           run calpair;

		   haa=diag(ha)-ha*ha`;
	       theta00=theta0; 
           run estth0; /*print theta00 est iterr;*/

		  if max(est[cc1])>10 then es=j(dimt,1,1E10);
		  else do;
       
	      th00=0//theta00;
		  th00=j(nt,1,1)*th00`;
    
		

	    
		  cw=inv(ephx)*haa;
		 /* cwx=-inv(ephx)*ephxx;*/

          ivtt=inv(ephx);
         

       
         betahh=beta[2:dh+1];
		 betazgw=beta[dh+2:dh+1+dhg*dimzg];
		 betaz=beta[dh+2+dhg*dimzg:dh+1+dhg*dimzg+dimz];

		 betazgw=(shape(betazgw,dimzg))`;

         
		  do dd=1 to dimzg;
		   zg1d=zg[,dd];
		   betazgd=betazgw[,dd];
		   itd=zg1d*(xxg*betazgd)`;
		   if dd=1 then intera=itd;
   		   else intera=intera+itd;
		  end;




		
	     lam11=beta[1]+j(nt,1,1)*(xxf*betahh)`+intera+z*betaz*j(1,k*k,1);

		 if pr1=0 then do;
            lam1=lam11+th00+lpt; 
            lam0=th00+lpt;
		 end;

		 if pr1>0 then do;
		    eta0=beta[1]+z*betaz*j(1,k*k,1);
		    tau=log(1+exp(eta0))-log(1+exp(lam11));
            lam1=nu+lam11+th00+lpt+tau; 
            lam0=th00+lpt+tau;
		 end;
		    
		 ewp1=exp(lam1); ewp0=exp(lam0);
		

        ewps=(ewp1[,+]+ewp0[,+]);
		iewp=(1/ewps);
		ewp1=ewp1#iewp;
		ewp0=ewp0#iewp;

          

		do tt=1 to k*k;
            
            

            if tt=1 then do;
                cwt=j(1,k*k,0);cwxt=j(dimzz,k*k,0);
			end;

			else do;
			     
			    ivt=ivtt[tt-1,];
			    cwt=cw[tt-1,];cwt=0||cwt;


		        do dd=1 to dimzz;
			       zzd=zz[,dd];
		           mphxx=(phx`*(zzd#de));
                   vphxx=phx`*(zzd#de#phx);
	               ephxx=(diag(mphxx)-vphxx);

			       cwxtd=-ivt*ephxx;
			       cwxtd=0||cwxtd;

			       if dd=1 then cwxt=cwxtd;
			       else cwxt=cwxt//cwxtd;
				end;
		    end;
		   
		      cdt=cwxt*dlp;
			  cdt=shape(cdt,1);
			  
			  

              xxt=xxf[tt,];wet=we[,tt];xxgt=xxg[tt,];

			  xh0=j(nt,1,1)||j(nt,dh,0)||j(nt,dhg*dimzg,0)||z;
			  xht=j(nt,1,1)||j(nt,1,1)*xxt||(zg@xxgt)||z;

			  

  	          db1=j(n1,1,1)||j(n1,1,1)*xxt||zg1@xxgt||z1; 
              db0=j(n0,dim,0);

			  dbt=(db1//db0);
			  if pr1>0 then do;
                      prt0=1/(1+exp(-xh0*beta));
			          prt=1/(1+exp(-xht*beta));
                      dtau=xh0#prt0-xht#prt;
					  dbt=dbt+dtau;
			  end;


			  dlpt=dlp[tt,];dlptz=j(nt,1,1)*cdt+zz@dlpt;
			  dlptt=j(nt,1,1)*(cwt*dlpo);
			  dlpttt=dlptt||dlptz;

			 
     		  dtt=dbt||dlpttt;


			  dtt=wet#dtt;

		      ewp1t=ewp1[,tt]; ewp0t=ewp0[,tt];
			  edb1t=xht; 
              edb0t=j(nt,dim,0);
			  if pr1>0 then do;
                      edb1t=xht+dtau;
					  edb0t=dtau;
              end;
			  edlptz=j(nt,1,1)*(cdt)+zz@dlpt;
			  edlpt=j(nt,1,1)*(cwt*dlpo);
			  ed1t=edb1t||edlpt||edlptz; ed0t=edb0t||edlpt||edlptz;

              edt=ewp1t#ed1t+ewp0t#ed0t;

              if tt=1 then do; 
				 dt=dtt;
				 ed=edt;
                 vd=ed1t`*(ewp1t#wes#ed1t)+ed0t`*(ewp0t#wes#ed0t);
			 end;
             else do;
                 dt=dt+dtt;
				 ed=ed+edt;
				 vd=vd+ed1t`*(ewp1t#wes#ed1t)+ed0t`*(ewp0t#wes#ed0t);
            end;
		end;

		vdd=vd-ed`*(wes#ed);

            
        esc=(dt-wes#ed);
        es=(esc[+,])`;

		end;
     end;
	 end;

	 else es=j(dimt,1,1E10);
        
finish;



start estjac;
     Ht=-vdd;
finish;


start estth0;
  
  cc1=loc(theta00>-20);
  run estscth0;/*print est;dht=abs(det(hht));print dht;msc=max(abs(est[cc1]));print msc;*/
  do iterr=1 to 20 while (max(abs(est[cc1]))>10 & max(abs(est))<1E10);
    
    cc1=loc(theta00>-20);   
	hht=hht[cc1,cc1]; dht=abs(det(hht));/*print dht;*/
    if dht>1E-500 then do;

	   dimc=ncol(cc1);
	   est=est[cc1];
       delta=-solve(hht,est);
       deltac=j(k*k-1,1,0);
       deltac[cc1]=delta;
	   tt0=(theta00+deltac);/*print tt0;*/
       theta00=(tt0<=-20)*(-20)+(tt0>-20)#(tt0); 
	
	  
       cc1=loc(theta00>-20);
       run estscth0; /*print theta00 est iterr ite;*/
   end;
   else est=j(k*k-1,1,1E10);

  end;

finish;

start estscth0;
    
     if (max(abs(theta00))>40 |  max(abs(phi1))>40) then est=j(k*k-1,1,1E10);
    else do; 
    
     th00=0//theta00;
	 th00=j(nt,1,1)*th00`;
     phx=exp(th00+lpt);
	 phx=phx[,2:k*k];
	 phxs=phx[,+];
	 phx=phx#(1/(1+phxs));
	 mphx=phx`*de;
     vphx=phx`*(de#phx);
    

	 
	 ephx=(diag(mphx)-vphx);
	
	 


	  est=10000*(ha-mphx);

	 hht=-10000*(diag(mphx)-vphx);
	 end;
finish;

   



do i=1 to nt;

hsi=hs[i,];
obs=loc(hsi^=9);
hsi=(hsi[obs])`; 
hns=hn[,obs];
hcs=rowcat(char(hns));


sgi=j(1,k*k,0);


do j=0 to 2##nsnp-1;
  a=j(1,nsnp,0);
  cite=1;
  r=mod(j,2);
  a[cite]=r;
  m=(j-r)/2;
  do while (m>=2);
     cite=cite+1;
	 r=mod(m,2);
	 a[cite]=r;
	 m=(m-r)/2;
  end;
  if m>0 then a[cite+1]=m;

  a=(a[obs])`;
  ac=rowcat(char(a));
  if nrow(xsect(ac,hcs))^=0 then do;
	 bc=(hsi-a);
	 bc=rowcat(char(bc));
	 if nrow(xsect(bc,hcs))^=0 then do;
		nn1=(hcs=ac)[+];nn2=(hcs=bc)[+];
	    hh1=loc(hcs=ac);hh2=loc(hcs=bc);
	    do ii=1 to nn1;
		  do jj=1 to nn2;
			  h1i=hh1[ii];;h2i=hh2[jj];
			  hi=(h1i-1)*k+h2i;
			  sgi[hi]=1;
		  end;
		end;
	 end;
  end;
end;
if i=1 then sg=sgi;
else sg=sg//sgi;

end;




   sg1=sg[1:n1,];
   sg0=sg[n1+1:nt,];
   
   int0=0;
   if pr1>0 then int0=log(pr1/pr0);
   beta=int0//j(dh,1,0)//j(dhg*dimzg,1,0)//j(dimz,1,0);
   phi=j(k-1,1,0);
   fr=exp(phi);
   fr=fr/(1+fr[+]);
   fr=(1-fr[+])//fr;
   /*fr=hp0;*/

   
 
   run estf;/*print it fr;*/
   fr=(fr<1E-5)*(1E-5)+(fr>=1E-5)#fr;
   phi=log(fr/fr[1]);
   phi=(phi<-10)*(-10)+(phi>=-10)#phi;
   phi=phi[2:k];/*print phi;*/

   fre=exp(phi);
   fre=fre/(1+fre[+]);
   fre=(1-fre[+])//fre;
 
  
   hfreq=fr;
   run calpair;
  
   /*print theta0 thetat;*/
   theta00=theta0;


  dim=nrow(beta);
  dimp=k-1;
  
  phi=log(fr/fr[1]);
  phi=(phi<-20)*(-20)+(phi>=-20)#phi;
  phi=phi[2:k];
  
  phi0=phi;

  dimpz=kz-1;
  dimzz=ncol(zz);
  phi1=j(dimpz*dimzz,1,0);
  b=beta//phi//phi1;
  dimt=dim+dimp+dimpz*dimzz;
  
 
  
  oldb=b+1;
  es=20;est=20;
  de=(d=0)#j(nt,1,1/n0)*pr0+(d=1)#j(nt,1,1/n1)*pr1;
  theta00=theta0;
  
  do ite=1 to 100 while  (max(abs(oldb-b))>0.001& max(abs(es))<1E10 & max(abs(est))<1E10 );
     oldb=b;

     run weight;

    we1=sg1#pyp1;we1s=we1[,+];we1s=(we1s>0)#(we1s)+(we1s=0)*1E5;we1=we1#(1/we1s);
	we0=sg0#pyp0;we0s=we0[,+];we0s=(we0s>0)#(we0s)+(we0s=0)*1E5;we0=we0#(1/we0s);

	we=(we1//we0);
	wes=we[,+];

    
    run newton;diff=((oldb-b));/*print  b diff es ite;*/

   

  
end;


/*print de;*/


if ( max(abs(es[cc]))<=0.0001 & max(abs(est[cc1]))<=10  & max(abs(oldb-b))<=0.001  &
max(abs(b))<150) then do;

  bm=b[cc];

  if nrow(bm)=dimt then do;

     bp=bm[dim+1:dim+dimp];
 

     fre=exp(bp);
     fre=fre/(fre[+]+1);
     fre=(1-fre[+])//fre;
  
        

     esc=esc[,cc];
     vsc=esc`*esc;
     ivsc=inv(vsc);  

     sc1=esc[1:n1,];sc1=sc1[:,];
     sc0=esc[n1+1:nt,];sc0=sc0[:,];

	 esc=esc-(j(n1,1,1)*sc1//j(n0,1,1)*sc0);

     phxy=phx-j(nt,1,1)*mphx`;
     cws=-ivtt*(phxy`#(de`));
     do tt=1 to k*k;

            if tt=1 then do;
                cwt=j(1,k*k,0);cwxt=j(dimzz,k*k,0);cwst=j(1,nt,0);
			end;

			else do;
			     
			    ivt=ivtt[tt-1,];
			    cwt=cw[tt-1,];cwt=0||cwt;
                cwst=cws[tt-1,];

		        do dd=1 to dimzz;
			       zzd=zz[,dd];
		           mphxx=(phx`*(zzd#de));
                   vphxx=phx`*(zzd#de#phx);
	               ephxx=(diag(mphxx)-vphxx);

			       cwxtd=-ivt*ephxx;
			       cwxtd=0||cwxtd;

			       if dd=1 then cwxt=cwxtd;
			       else cwxt=cwxt//cwxtd;
				end;
		    end;
		   
		      cdt=cwxt*dlp;
			  cdt=shape(cdt,1);
			  
			  

              xxt=xxf[tt,];wet=we[,tt];xxgt=xxg[tt,];

			  xh0=j(nt,1,1)||j(nt,dh,0)||j(nt,dhg*dimzg,0)||z;
			  xht=j(nt,1,1)||j(nt,1,1)*xxt||(zg@xxgt)||z;


  	          db1=j(n1,1,1)||j(n1,1,1)*xxt||zg1@xxgt||z1; 
              db0=j(n0,dim,0);

			  dbt=(db1//db0);
			  if pr1>0 then do;
                      prt0=1/(1+exp(-xh0*beta));
			          prt=1/(1+exp(-xht*beta));
                      dtau=xh0#prt0-xht#prt;
					  dbt=dbt+dtau;
			  end;


			  dlpt=dlp[tt,];dlptz=j(nt,1,1)*cdt+zz@dlpt;
			  dlptt=j(nt,1,1)*(cwt*dlpo);
			  dlpttt=dlptt||dlptz;

			 
     		  dtt=dbt||dlpttt;

			  dtt=wet#dtt;

		      ewp1t=ewp1[,tt]; ewp0t=ewp0[,tt];
			  edb1t=j(nt,1,1)||j(nt,1,1)*xxt||zg@xxgt||z; 
              edb0t=j(nt,dim,0);
			   if pr1>0 then do;
                      edb1t=xht+dtau;
					  edb0t=dtau;
              end;
			  edlptz=j(nt,1,1)*(cdt)+zz@dlpt;
			  edlpt=j(nt,1,1)*(cwt*dlpo);
			  ed1t=edb1t||edlpt||edlptz; ed0t=edb0t||edlpt||edlptz;

              edt=ewp1t#ed1t+ewp0t#ed0t;

			  dst=j(nt,1,1)*cwst;
			  edst=ewp1t#dst+ewp0t#dst;

              if tt=1 then do; 
				 
				 ed=edt;
                 vd=ed1t`*(ewp1t#wes#ed1t)+ed0t`*(ewp0t#wes#ed0t);
				 eds=edst;
				 vds=ed1t`*(ewp1t#wes#dst)+ed0t`*(ewp0t#wes#dst);
			 end;
             else do;
                 dt=dt+dtt;
				 ed=ed+edt;
				 vd=vd+ed1t`*(ewp1t#wes#ed1t)+ed0t`*(ewp0t#wes#ed0t);
				 eds=eds+edst;
				 vds=vds+ed1t`*(ewp1t#wes#dst)+ed0t`*(ewp0t#wes#dst);
            end;
		end;

       vdss=vds-ed`*(wes#eds);


  
       vdss=vdss`;
       vds1=(vdss[1:n1,])[:,];
       vds0=(vdss[n1+1:nt,])[:,];
       yy=j(n1,1,1)//j(n0,1,0);
       escc=vdss-((yy=1)*vds1+(yy=0)*vds0);
       esc=esc-escc;

   

  /*var1=ih*(vsc-omega)*ih; vb1=vecdiag(var1);*/
     var2=ivsc*(esc`*esc)*ivsc`;
     vb2=vecdiag(var2);

     var=j(dimt,1,.);
     var[cc]=vb2;
     se=sqrt(var);


  
     f0=fre[1];
     f=fre[2:k];
     fv=diag(f)-f*f`;
     fc=-f0*f`;
     fc=fc//fv;

     varp=var2[dim+1:dim+dimp,dim+1:dim+dimp];
     varf=fc*varp*fc`;


     vf=vecdiag(varf);
     sef=sqrt(vf);

end;

  
 
  



    else do;
	    bm=j(dimt,1,.);
        var=j(dimt,1,.);
		vf=j(dimp+1,1,.);
		se=j(dimt,1,.);
		sef=j(dimp+1,1,.);
		fre=j(dimp+1,1,.);
    end;
       

end;
else do;
         bm=j(dimt,1,.);
        var=j(dimt,1,.);
		vf=j(dimp+1,1,.);
		se=j(dimt,1,.);
		sef=j(dimp+1,1,.);
		fre=j(dimp+1,1,.);

end;

end;

if zzsel=. then do;

 
z1=z[1:n1,];
z0=z[n1+1:nt,];


zg1=zg[1:n1,];
zg0=zg[n1+1:nt,];






nsnp=ncol(hn);
k=nrow(hn);


hc=char(hn);
hc=rowcat(hc);



/*ncf=(inifq>=rf)[+];
kz=ncf;*/
hsel={&hsel};
rare={&rare};
hsel=(setdif(hsel,rare))`;
dh=nrow(hsel);

hselg={&hselg}`;
dhg=nrow(hselg);

do i=1 to dhg;
   hselggg=loc(hsel=hselg[i]);
   if i=1 then hselgg=hselggg;
   else hselgg=hselgg//hselggg;
end;



all=loc(j(k,1,1)>0);
common=(setdif(all, rare))`;
kz=nrow(common);
indexz=common[2:kz];

group=j(kz,k,0);
group[1,]=j(1,k,1);
group[,common]=i(kz);




dexx=group[,hsel];
do i=1 to dh;
  dexi=dexx[,i];
  dexi=loc(dexi=1);
  if i=1 then dex=dexi;
  else dex=dex||dexi;
end;


dimp=k-1;
dimpz=kz-1;


do i=1 to k;
  if i=1 then sym=1;
  else sym=sym||i;
end;
sym=char(sym,1);






do hf=1 to k;
     do hm=1 to k;

	    

	     
        hmz=group[,hm];hmz=loc(hmz=1);
		hfz=group[,hf];hfz=loc(hfz=1);

/*
        hmz= 1*(hm=1 | hm=5 | hm=7)+2*(hm=2)+3*(hm=3)+4*(hm=4)+
		          5*(hm=6);
		hfz= 1*(hf=1 | hf=5 | hf=7)+2*(hf=2)+3*(hf=3)+4*(hf=4)+
		          5*(hf=6);
*/

	do i=1 to dh;
          
	     dexi=dex[i];
         xxfii= (hfz=dexi)+ (hmz=dexi);

		 if (mode="a" | mode="A") then xxfii=xxfii;
		 if (mode="d" | mode="D") then xxfii=(xxfii>0);
	
		 if i=1 then xxfi=xxfii;
		 else xxfi=xxfi||xxfii;
   
     end; 

/*
		dlp1i=j(1,dimpz,0);dlp2i=j(1,dimpz,0);
		if hmz>1 then dlp1i[hmz-1]=1;
		if hfz>1 then dlp2i[hfz-1]=1;
		dlpi=dlp1i+dlp2i;
*/		
        if (hf=1 & hm=1) then do; 
		      xxf=xxfi;
		/*	  dlp=dlpi;*/
        end;
		else do; 
		     xxf=xxf//xxfi;
		/*	 dlp=dlp//dlpi;*/
        end;
    end;
end;
xxg=xxf[,hselgg];


hname=j(dh, 1, "hap");
hname1=sym[hsel];
hname1g=sym[hselg];
zname1=sym[indexz];


do dd=1 to dimzg;
  zgnamed=j(dhg,1,zgname[dd]);
  if dd=1 then do;
     zgn=zgnamed;
	 zgn1=hname1g;
  end;
  else do;
     zgn=zgn//zgnamed;
	 zgn1=zgn1//hname1g;
  end;
end;
/*
do dd=1 to dimzz;
  zznamed=j(dimpz,1,zzname[dd]);
  if dd=1 then do;
     zzn=zznamed;
	 zzn1=zname1;
  end;
  else do;
     zzn=zzn//zznamed;
	 zzn1=zzn1//zname1;
  end;
end;
*/
tname=j(dimp,1,"theta");
tname1=sym[2:k];
fname=j(k,1,"hap.freq");
fname1=sym[1:k];

bname="int"//hname//zgn//zname;
name=bname//tname/* //zzn */ //fname;
bname1=" "//hname1//zgn1//j(dimz,1," ");
name1=bname1//tname1 /* //zzn1 */ //fname1;
name=name||name1;
name=rowcat(name);



start weightx;




do hf=1 to k;
   do hm=1 to k;

        hh=(hf-1)*k+hm;
        xxi=xxf[hh,];xxgi=xxg[hh,];

		betahh=beta[2:dh+1];
		betazgw=beta[dh+2:dh+1+dhg*dimzg];
		betaz=beta[dh+2+dhg*dimzg:dh+1+dhg*dimzg+dimz];

		betazgw=(shape(betazgw,dimzg))`;

		do dd=1 to dimzg;
		   zg1d=zg1[,dd];
		   betazgd=betazgw[,dd];
		   itd=xxgi*betazgd*zg1d;
   		   if dd=1 then intera=itd;
   		   else intera=intera+itd;
		end;

        eta=xxi*betahh+intera+z1*betaz;

		
        hmz=group[,hm];hmz=loc(hmz=1);
		hfz=group[,hf];hfz=loc(hfz=1);
        
		phi0=b[dim+1:dim+dimp];

       

        if hf=1 then do; phi11=0;end;
		else do;phi11=phi0[hf-1];end;

		if hm=1 then do; phi12=0;end;
		else do; phi12=phi0[hm-1]; end;

		th00i=phi11+phi12;
            
		freqe=exp(th00i);
        freqe1=freqe;
        freqe0=freqe;


       if pr1=0 then do;
           pyp1i=exp(eta)#freqe1;
		   pyp0i=freqe0;
		end;
		if pr1>0 then do;
		   eta1=beta[1]+xxi*betahh+intera1+z1*betaz;
           py1=1/(1+exp(-eta1));
		   eta0=beta[1]+xxi*betahh+intera0+z0*betaz;
		   py0=1/(1+exp(eta0));
		   pyp1i=py1#freqe1;
		   pyp0i=py0#freqe0;
		end;

       
        if (hf=1 & hm=1) then do; 
			  pyp1=pyp1i;
			  pyp0=pyp0i;
        end;
		else do; 
			 pyp1=pyp1||pyp1i;
			 pyp0=pyp0||pyp0i;
        end;
	end;
end;


finish;








do tt=1 to k-1;
		   dlpt1=j(k*k,1,0);
		   dlpt1[tt*k+1:(tt+1)*k]=1;
           dlpt2=j(k,1,0);dlpt2[tt+1]=1;
		   dlpt2=repeat(dlpt2,k,1);
		   dlpt=dlpt1+dlpt2;

		   if tt=1 then do; 
              dlpo=dlpt;
          end;
		   else do;
              dlpo=dlpo||dlpt;
           end;
end;





start estfx;

  oldfr=fr+1;
  do it=1 to 20 while  (max(abs(oldfr-fr))>0.0001); 
    df=max(abs(oldfr-fr));
    oldfr=fr;

    do hf=1 to k;
	  do hm=1 to k;
          we0i=fr[hf]*fr[hm];
		  if (hf=1 & hm=1) then we00=we0i;
		  else we00=we00||we0i;
	  end;
	end;
	
	we00=sg0#we00;
	we00s=we00[,+];we00s=(we00s>0)#(we00s)+(we00s=0)*1E5;
    we00=we00#(1/we00s);


    bf=((we00*dlpo)[+,])`;
    bf=bf/(2*n0);
	fr0=1-bf[+];
	fr=fr0//bf;


  end;

finish;





start newtonx;
  
  cc=loc(b>-10);
  run estscx;/*print b es;*/
  do iter=1 to 20 while (max(abs(es[cc]))>0.0001 & max(abs(es))<1E10);
    run estjacx;
	
	 cc=loc(b>-10);   
	Ht=Ht[cc,cc]; /*dh=abs(det(Ht)); print dh;*/
    if abs(det(Ht))>1E-100 then do;

	   dimc=ncol(cc);
	   es=es[cc];
       delta=-solve(Ht,es);
       deltac=j(dimt,1,0);
       deltac[cc]=delta;
	   bb=(b+deltac);
       b=(bb<=-10)*(-10)+(bb>-10)#(bb); 
	
       cc=loc(b>-10);
       run estscx; /*print b es iter ite;*/
   end;
   else es=j(dimt,1,1E10);

  end;


finish;

start estscx;
     
      if (max(abs(b))<50) then do;
          beta=b[1:dim]; phi=b[dim+1:dim+dimp];

		  phi0=b[dim+1:dim+dimp];

        do hf=1 to k;
		   do hm=1 to k;

		   hmz=group[,hm];hmz=loc(hmz=1);
		   hfz=group[,hf];hfz=loc(hfz=1);

		

          if hf=1 then do; phi11=0;end;
		  else do;phi11=phi0[hf-1];end;

		  if hm=1 then do; phi12=0;end;
		  else do; phi12=phi0[hm-1];end;

		  th00i=phi11+phi12;


		   if (hf=1 & hm=1) then do; 
			  th00=th00i;
          end;
		   else do;
			  th00=th00//th00i;
           end;
		end;
	  end;

	    /* za=z*j(1,k*k,1);
		 lpt=zz*lpt`;
		 */

	   th00=j(nt,1,1)*th00`;
       
	    

      
    
		/*
	    cwn=j(k*k-1,1,1)-ha;
	    cwd=j(k*k-1,1,1)-ephx;
	    cw=cwn/cwd;
	    cw=0//cw;
        */

	  

       
         betahh=beta[2:dh+1];
		 betazgw=beta[dh+2:dh+1+dhg*dimzg];
		 betaz=beta[dh+2+dhg*dimzg:dh+1+dhg*dimzg+dimz];

		 betazgw=(shape(betazgw,dimzg))`;

         
		  do dd=1 to dimzg;
		   zg1d=zg[,dd];
		   betazgd=betazgw[,dd];
		   itd=zg1d*(xxg*betazgd)`;
		   if dd=1 then intera=itd;
   		   else intera=intera+itd;
		  end;

		 
          lam11=beta[1]+j(nt,1,1)*(xxf*betahh)`+intera+z*betaz*j(1,k*k,1);
          if pr1=0 then do;
            lam1=lam11+th00; 
            lam0=th00;
		 end;

		 if pr1>0 then do;
		    eta0=beta[1]+z*betaz*j(1,k*k,1);
		    tau=log(1+exp(eta0))-log(1+exp(lam11));
            lam1=nu+lam11+th00+tau; 
            lam0=th00+tau;
		 end;


		
	   
      
		 ewp1=exp(lam1); ewp0=exp(lam0);
		

        ewps=(ewp1[,+]+ewp0[,+]);
		iewp=(1/ewps);
		ewp1=ewp1#iewp;
		ewp0=ewp0#iewp;

          

		do tt=1 to k*k;
            
			  
			  

              xxt=xxf[tt,];wet=we[,tt];xxgt=xxg[tt,];

  	          db1=j(n1,1,1)||j(n1,1,1)*xxt||zg1@xxgt||z1; 
              db0=j(n0,dim,0);

			  dlpot=dlpo[tt,];
/*
			  dlpt1=j(n1,1,1)*(dlpot);
			  dlpt0=j(n0,1,1)*(dlpot);
			 
     		  d1=db1||dlpt1;
		      d0=db0||dlpt0;
*/
			   xh0=j(nt,1,1)||j(nt,dh,0)||j(nt,dhg*dimzg,0)||z;
			  xht=j(nt,1,1)||j(nt,1,1)*xxt||(zg@xxgt)||z;
              dbt=db1//db0;
			  if pr1>0 then do;
                      prt0=1/(1+exp(-xh0*beta));
			          prt=1/(1+exp(-xht*beta));
                      dtau=xh0#prt0-xht#prt;
					  dbt=dbt+dtau;
			  end;

              dtt=dbt||j(nt,1,1)*dlpot;

			  dtt=wet#(dtt);

		      ewp1t=ewp1[,tt]; ewp0t=ewp0[,tt];
			  edb1t=j(nt,1,1)||j(nt,1,1)*xxt||zg@xxgt||z; 
              edb0t=j(nt,dim,0);
			  if pr1>0 then do;
                      edb1t=edb1t+dtau;
					  edb0t=dtau;
              end;
			 
			  edlpt=j(nt,1,1)*(dlpot);
			  ed1t=edb1t||edlpt; ed0t=edb0t||edlpt;

              edt=ewp1t#ed1t+ewp0t#ed0t;

              if tt=1 then do; 
				 dt=dtt;
				 ed=edt;
                 vd=ed1t`*(ewp1t#wes#ed1t)+ed0t`*(ewp0t#wes#ed0t);
			 end;
             else do;
                 dt=dt+dtt;
				 ed=ed+edt;
				 vd=vd+ed1t`*(ewp1t#wes#ed1t)+ed0t`*(ewp0t#wes#ed0t);
            end;
		end;

		vdd=vd-ed`*(wes#ed);

            
        esc=(dt-wes#ed);
        es=(esc[+,])`;

		end;
   

	 else es=j(dimt,1,1E10);
        
finish;



start estjacx;
     Ht=-vdd;
finish;









do i=1 to nt;

hsi=hs[i,];
obs=loc(hsi^=9);
hsi=(hsi[obs])`; 
hns=hn[,obs];
hcs=rowcat(char(hns));

sgi=j(1,k*k,0);


do j=0 to 2##nsnp-1;
  a=j(1,nsnp,0);
  cite=1;
  r=mod(j,2);
  a[cite]=r;
  m=(j-r)/2;
  do while (m>=2);
     cite=cite+1;
	 r=mod(m,2);
	 a[cite]=r;
	 m=(m-r)/2;
  end;
  if m>0 then a[cite+1]=m;

  a=(a[obs])`;
  ac=rowcat(char(a));
  if nrow(xsect(ac,hcs))^=0 then do;
	 bc=(hsi-a);
	 bc=rowcat(char(bc));
	 if nrow(xsect(bc,hcs))^=0 then do;
		nn1=(hcs=ac)[+];nn2=(hcs=bc)[+];
	    hh1=loc(hcs=ac);hh2=loc(hcs=bc);
	    do ii=1 to nn1;
		  do jj=1 to nn2;
			  h1i=hh1[ii];;h2i=hh2[jj];
			  hi=(h1i-1)*k+h2i;
			  sgi[hi]=1;
		  end;
		end;
	  end;
   end;
  
 end;
if i=1 then sg=sgi;
else sg=sg//sgi;

end;



   
   sg1=sg[1:n1,];
   sg0=sg[n1+1:nt,];

  
   


   
   beta=0//j(dh,1,0)//j(dhg*dimzg,1,0)//j(dimz,1,0);
   phi=j(k-1,1,0);
   fr=exp(phi);
   fr=fr/(1+fr[+]);
   fr=(1-fr[+])//fr;
   /*fr=hp0;*/

   
 
   run estfx; /*print it fr;*/
   fr=(fr<1E-5)*(1E-5)+(fr>=1E-5)#fr;
   phi=log(fr/fr[1]);
   phi=(phi<-10)*(-10)+(phi>=-10)#phi;
   phi=phi[2:k]; /*print phi;*/

   fre=exp(phi);
   fre=fre/(1+fre[+]);
   fre=(1-fre[+])//fre;
 
  
  

  dim=nrow(beta);
  dimp=k-1;
  /*
  phi=log(fr/fr[1]);
  phi=(phi<-20)*(-20)+(phi>=-20)#phi;
  phi=phi[2:k];
  */
  phi=j(dimp,1,0);

  dimpz=kz-1;
 
  b=beta//phi;
  dimt=dim+dimp;
  
 
  
  
  
  oldb=b+1;
  es=20;est=20;
  do ite=1 to 100 while  (max(abs(oldb-b))>0.001& max(abs(es))<1E10 & max(abs(est))<1E10 );
     oldb=b;

     run weightx;

    we1=sg1#pyp1;we1s=we1[,+];we1s=(we1s>0)#(we1s)+(we1s=0)*1E5;we1=we1#(1/we1s);
	we0=sg0#pyp0;we0s=we0[,+];we0s=(we0s>0)#(we0s)+(we0s=0)*1E5;we0=we0#(1/we0s);

	we=(we1//we0);
	wes=we[,+];

    
    run newtonx;diff=((oldb-b));/*print  b diff es ite;*/

   

  
end;


/*print de;*/


if ( max(abs(es[cc]))<=0.0001  & max(abs(oldb-b))<=0.001  &
max(abs(b))<150) then do;

  bm=b[cc];

  if nrow(bm)=dimt then do;

     bp=bm[dim+1:dim+dimp];
 

     fre=exp(bp);
     fre=fre/(fre[+]+1);
     fre=(1-fre[+])//fre;
  

     esc=esc[,cc];
     sc1=esc[1:n1,];sc1=sc1[:,];
     sc0=esc[n1+1:nt,];sc0=sc0[:,];

     omega=n1*sc1`*sc1+n0*sc0`*sc0;

     vsc=esc`*esc;
     ivsc=inv(vsc);

  /*var1=ih*(vsc-omega)*ih; vb1=vecdiag(var1);*/
     var2=ivsc-ivsc*omega*ivsc;
     vb2=vecdiag(var2);

     var=j(dimt,1,.);
     var[cc]=vb2;
     se=sqrt(var);


  
     f0=fre[1];
     f=fre[2:k];
     fv=diag(f)-f*f`;
     fc=-f0*f`;
     fc=fc//fv;

     varp=var2[dim+1:dim+dimp,dim+1:dim+dimp];
     varf=fc*varp*fc`;


     vf=vecdiag(varf);
     sef=sqrt(vf);

end;

  
 
  



    else do;
	    bm=j(dimt,1,.);
        var=j(dimt,1,.);
		vf=j(dimp+1,1,.);
		se=j(dimt,1,.);
		sef=j(dimp+1,1,.);
		fre=j(dimp+1,1,.);
    end;
       

end;
else do;
         bm=j(dimt,1,.);
        var=j(dimt,1,.);
		vf=j(dimp+1,1,.);
		se=j(dimt,1,.);
		sef=j(dimp+1,1,.);
		fre=j(dimp+1,1,.);

end;

end;


  para=bm//fre;
  se=/*var`||vf`||*/se//sef;
  z=para/se;
  p_val=2*(1-probnorm(abs(z)));
 


  print 'HapRegNew Macro';

  label=sym`;
  haplotype=hn;

  print label haplotype;

  /*
  print 'baseline haplotypes: haplotype 1',
  'rare haplotypes grouped into baseline: haplotype ' (rare)[l=' '],
  'risk haplotypes: haplotype ' (hsel`)[l=' '];
  */ 
  file print; 
  put;
  put @5 'baseline haplotypes: haplotype ' "1 ";
  put @5 'rare haplotypes grouped into baseline: haplotype ' "&rare";
  put @5 'risk haplotypes: haplotype ' "&hsel";
  if (mode="a" | mode="A") then put @5 'mode: additive';
  if (mode="d" | mode="D") then put @5 'mode: dominant';
  put;
   
  print name  para  se  z  p_val;
  


 
quit iml;

%mend;

/*Demo codes:;

*This hypoDat.txt is from the R package hapassoc, which is modified by adding the ID to its header;
proc import datafile="C:\Users\cheng\Downloads\hapassoc\data\hypoDat.txt"
dbms=dlm out=geno_pheno replace;
delimiter=' ';
getnames=yes;
guessingrows=max;
run;

%allele_columns2geno(
dsd=geno_pheno,
cols4alleles=4-9,
outdsd=out
);

*%debug_macro;

%HapRegNew(
data=out, 
hdata=, 
d=2, 
zsel=3, 
zgsel=3, 
zzsel=3, 
snp=4-6, 
rare=, 
hsel=2 3 4 5, 
hselg=3,
mode=a, 
pr1=0.2
); 


*/

