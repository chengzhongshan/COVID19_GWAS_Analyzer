
%macro bed_block_complement4blockplot(dsdin,chr_var,chr_value,st_var,end_var,dsdout,minst,maxend,generate_dsd_only);

*subset data by chr and make st and end into a single;
*column as pos;
data &dsdin.a;
set &dsdin;
where &chr_var="&chr_value" and (
      (&st_var>=&minst and &end_var<=&maxend and &end_var>=&minst) or 
	  (&st_var<&minst and &end_var>&minst) or 
	  (&st_var<&maxend and &end_var>&maxend) 
);
run;

/*Merged overlapped region in bed*/
/*Overlapped regions will affect the final block plot*/;
/*%MergerOverlappedRegInBed(bedin=&dsdin.a*/
/*                         ,chr_var=&chr_var*/
/*                         ,st_var=&st_var*/
/*                         ,end_var=&end_var*/
/*                         ,bedout=&dsdin.a);*/

data &dsdin.a;
set &dsdin.a;
array x{*} &st_var &end_var;
do i=1 to 2;
 pos=x{i};output;
end;
run;

data &dsdout;
set &dsdin.a;
run;

/*
*NO Need the following process to adjust the complement of each bed region!;
***********************************************************************;
*sort data by chr st end, as well as i;
proc sort data=&dsdin.a;
by &chr_var &st_var &end_var i;
run;
*get forward value of pos for updating the complement of each bed block;
data &dsdin.b;
set &dsdin.a end=eof;
keep pos;
if (eof) then do;
output;
pos=.;output;
end;
else if _n_>1 then do;
output;
end;
else do;
*no need to be output;
end;
run;

*update the new pos column into the dsd b;
data &dsdout;
merge &dsdin.a &dsdin.b;
run;

data &dsdout;
set &dsdout;
if i=2 then do;
st=end+1;
end=pos-1;
end;
run;
*Note: the last st pos needs to be kept!;
*********************************************************;
*/


%if &generate_dsd_only^=1 %then %do;

%local mindist maxdist;
%let mindist=&minst;
%let maxdist=&maxend;

proc template;
define statgraph Graph;
dynamic _POS2 _I;
begingraph / designwidth=1200 designheight=100;
   layout lattice / rowdatarange=data columndatarange=data rowgutter=10 columngutter=10;
/*Display block values and labels*/
/*      layout overlay/walldisplay=none xaxisopts=( display=(LINE TICKS TICKVALUES) linearopts=(viewmin=&mindist viewmax=&maxdist  tickvaluesequence=( start=%eval(&mindist-1) end=&maxdist increment=%eval((&maxdist-&mindist+1)/10) )));*/
/*         blockplot x=_POS2 block=_I / name='block' display=(FILL OUTLINE VALUES LABEL ) */
/*                   extendblockonmissing=true filltype=multicolor;*/

/*Not Display block values and labels*/
      layout overlay/walldisplay=none xaxisopts=( display=(LINE TICKS TICKVALUES) linearopts=(viewmin=&mindist viewmax=&maxdist  tickvaluesequence=( start=%eval(&mindist-1) end=&maxdist increment=%eval((&maxdist-&mindist+1)/10) )));
         blockplot x=_POS2 block=_I / name='block' display=(FILL) 
                   extendblockonmissing=true filltype=multicolor;
      endlayout;
   endlayout;
endgraph;
end;
run;

proc sgrender data=&dsdout template=Graph;
dynamic _POS2="POS" _I="I";
run;

%end;

%mend;

/*Demo:

data a;
input chr $ st end;
cards;
chr7 10 30
chr7 40 100
chr7 150 300
;
run;

%bed_block_complement4blockplot(dsdin=a,chr_var=chr,chr_value=chr7,st_var=st,end_var=end,dsdout=xxx,minst=15,maxend=250,generate_dsd_only=0);


data bed;
input chr $ st end;
cards;
chr7 100 200
chr7 400 800
;
run;
%bed_block_complement4blockplot(dsdin=bed,chr_var=chr,chr_value=chr7,st_var=st,end_var=end,dsdout=yyy,minst=1,maxend=1000,generate_dsd_only=1);

*/
