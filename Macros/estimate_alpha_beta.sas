%macro estimate_alpha_beta(
/*Note: this macro will calcuate alpha and beta of beta distribution for data step;
It is important to know that mu=alpha/(alpha+beta) and var=alpha*beta/((alpha+beta)**2*(alpha+beta+1)),
as well as alpha=((1-mu)/var-1/mu)*mu**2 and beta=alpha*(1/mu-1);
*/
mu=, /*Mean of beta distribution*/
var= /*Variance of beta distribution*/
);
alpha=((1-&mu)/&var-1/&mu)*&mu**2;
beta=alpha*(1/&mu-1);
%mend;

/*Demo codes:;

data alphabeta;
	mu=0.15;
	var=0.2;
    %estimate_alpha_beta(mu=mu,var=var);
run;
proc print;run;

*/
