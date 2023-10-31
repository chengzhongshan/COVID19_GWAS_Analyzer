%macro rank4grps(grps,dsdout);
%let i=1;
data &dsdout;
length grps $300.;
%do %while (%scan(&grps,&i,%str( )) ne);
  %let gval=%scan(&grps,&i,%str( ));
  grps="&gval";num_grps=&i;
  output;
 %let i=%eval(&i+1);
%end;
run;

%mend;

/*Demo:

%rank4grps(
grps=rs8116534 rs472481 rs555336963 rs148143613 rs2924725 rs5927942,
dsdout=z
);
proc print;run;

*/
