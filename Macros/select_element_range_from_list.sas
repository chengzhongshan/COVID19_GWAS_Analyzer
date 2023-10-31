%macro select_element_range_from_list(list,st,end,sublist);
%global &sublist;
%let slcted_elems=%sysfunc(prxchange(s/^(\S+\s?){%sysevalf(&st-1)}((\S+\s?){%sysevalf(&end-&st+1)}).*/\2/,-1,&list)); 
%put &slcted_elems;
%let &sublist=&slcted_elems;
%mend;

/*Demo codes:;
%let Snps=xx yyy zzz xxx x y w f;
%select_element_range_from_list(
list=&Snps,
st=3,
end=5,
sublist=newlist
);
%put &newlist;

*/


