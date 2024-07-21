%macro ranperm4enrichment_test(
perm_n=10,
n_gs=30,
n_random_cells=3,
dsdout=_perm_dsd_,
transpose_dsd=1
);

/*%let perm_n=10;*/
/*%let n_gs=30;*/
/*%let n_random_cells=3;*/

data &dsdout;

do i=1 to &perm_n;
array G{&n_gs} x1-x&n_gs.;
 do gi=1 to &n_random_cells;
     G{gi}=1;
 end;
 call streaminit(i);
 /*array G{&n_gs} _temporary_ (0*&n_gs);*/
 _iorc_=i*10000;
 call ranperm(_iorc_,of G{*}); 
 *Fill missing value as 0 but failed;
/* call stdize('mult=',2,'missing=',-1, 'range',of G{*});*/
/* call stdize('mult=',1,'missing=',-1, 'range',of G{*});*/
 output;
 call missing(of G{*});
end;

drop gi i;

run;

/*proc print;run;*/
proc transpose data=&dsdout out=&dsdout(drop=_name_) prefix=x;
var _numeric_;
run;

/*proc print;run;*/

%mend;

/*Demo codes:;

%ranperm4enrichment_test(
perm_n=10,
n_gs=30,
n_random_cells=3,
dsdout=_perm_dsd_,
transpose_dsd=1
);
proc print;run;


*/



