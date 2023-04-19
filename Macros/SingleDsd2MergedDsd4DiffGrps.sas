
%macro SingleDsd2MergedDsd4DiffGrps(singledsd,num_grp_var,mergeddsd);
  
  %SplitDsdIntoMultiDsdsByNumGrp(dsd=&singledsd,numgrpvar=&num_grp_var,newdsd_prefix=xxxxxx);

  *delete the final dsd if it is there;
  proc datasets lib=work nolist;
  delete &mergeddsd;
  run;
  
  *create the final dsd by mergering all subset dsd without any common vars!;
  data &mergeddsd;
  merge xxxxxx:;
  run;

  *delete other temporary dsd;
  proc datasets lib=work nolist;
  delete xxxxxx:;
  run;

%mend;

/*Demo:

data xyz;
input st d4bar grp;
cards;
10 1 1
11 2 1
30 3 1
40 4 2
70 5 1
80 6 1
400 7 2
410 8 1
1400 9 2
1401 10 2
;
run;

options mprint mlogic symbolgen;
%SingleDsd2MergedDsd4DiffGrps(singledsd=xyz,num_grp_var=grp,mergeddsd=final);

*/


