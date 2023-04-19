
%macro MutRegOverlappedBlock(block_dsdin
                            ,block_chr_var
                            ,block_st_var
							,block_end_var
							,chr
							,mindist
							,maxdist
							,Mut_dsdin
							,Mut_chr_var
							,Mut_st_var
							,mut_sample_var
							,Final_dsdout
							,block_filcolor
							,block_filaltcolor
							,dotsize
							,dotcolor
							,max_y
							,add_sample_ref_line=0
							,graph_designwidth=400
							,sample_refline_pattern=solid
							,ref_line_color=white
                            );
/*select color in sgdesigner and add initial 'CX'*/
%if &block_filcolor eq %then %let block_filcolor=CXC6C3C6; 
%if &block_filaltcolor eq %then %let block_filaltcolor=CX00CCCC;
%if &dotsize eq %then %let dotsize=5;
%if &dotcolor eq %then %let dotcolor=CX000000;

data block;
set &block_dsdin;
rename &block_chr_var=block_chr
       &block_st_var=block_x
	   &block_end_var=block_x1
;
run;

*Make base bed smaller;

%subset_bed(bed_dsd=block,
            bed_chr_var=block_chr,
            bed_st_var=block_x,
            bed_end_var=block_x1,
            query_chr=&chr,
            query_st=&mindist,
            query_end=&maxdist,
            subbed_out=sub_block,
            numeric_chr_in_bed_dsd=0
);


*Make sure to merge overlapped bed regions, otherwise, the Bed4BlockGraph will output wrong data for block graph;
%MergerOverlappedRegInBed(bedin=sub_block
                         ,chr_var=block_chr
                         ,st_var=block_x
                         ,end_var=block_x1
                         ,bedout=xyz);

%Bed4BlockGraph(dsdin=xyz
                ,mindist=&mindist
                ,maxdist=&maxdist
                ,chr=&chr
                ,chr_var=block_chr
                ,st_var=block_x
                ,end_var=block_x1
                ,dsdout=block1
				,graph_wd=&graph_designwidth
				,graph_ht=60
                ,show_block_values=0
);

data block1;
set block1(drop=block_x);
rename st=block_x d4bar=block_y;/*st and d4bar was created by macro Bed4BlockGraph*/

data Mut;
set &Mut_dsdin;
rename &mut_chr_var=mut_chr
       &mut_st_var=mut_x
;
where &mut_chr_var="&chr" and 
      &mut_st_var between &mindist and &maxdist;
run;


%AddRowNumber4Com_Vars(dsdin=Mut
                      ,Com_Vars=mut_chr &mut_sample_var
                      ,desending_or_not=1
                      ,dsdout=Mut1);

data &Final_dsdout;
set block1(keep=block_x block_y) Mut1(keep=Mut_x ord);/*ord is a group label created by macro AddRowNumber4Com_Vars*/
run;
data &Final_dsdout;
set &Final_dsdout;
rename ord=Mut_y;
run;

/*find mut in feature and group mut based on its overlap with feature*/
proc sql;
create table &Final_dsdout as
select a.*,b.block_x as st,b.block_x1 as end
from &Final_dsdout as a
left join
block as b
on a.mut_x between b.block_x and b.block_x1
   and b.block_chr="&chr";

data &Final_dsdout;
set &Final_dsdout;
scatter_grp=0;
if st>0 then scatter_grp=1;
if mut_x>&maxdist then delete;
run;

data &Final_dsdout;
set &Final_dsdout;
if scatter_grp=1 then do;
   mut_x1=mut_x;mut_y1=mut_y;
   mut_x=.;mut_y=.;
end;
else do;
   mut_x1=.;mut_y1=.;
end;
run;

/*Add a record of mut_x=&mindist-1 and mut_x=0 if there is no records of mut_x and mut_y*/
/*Which will enable the creation of y-aix and the height of the final graph as that of &max_y*/

data &Final_dsdout;
set &Final_dsdout;
if _n_=1 then do;
 mut_x2=&mindist-1;
 mut_y2=0;
end;
run;

proc template;
define statgraph Graph;
dynamic _BLOCK_X _BLOCK_Y _MUT_X _MUT_Y _MUT_X1 _MUT_Y1 _MUT_X2 _MUT_Y2;
/*pad=5 will add the extra 5px spaces to the left, right, top and bottom of the figure*/
/*Change designwidth and designheight to revise the figure*/
begingraph / pad=5 border=false designwidth=&graph_designwidth designheight=%eval(&max_y+10*&max_y); /*Make the graph's height as that of sample, plus 22 of margin*/
   layout lattice / rowdatarange=data columndatarange=data rowgutter=10 columngutter=10;
      layout overlay / walldisplay=none 
                       /*xaxisopts=( display=(LINE TICKVALUES TICKS ) griddisplay=off linearopts=( viewmin=%eval(&mindist-1) viewmax=&maxdist minorticks=OFF tickvaluesequence=( start=%eval(&mindist-1) end=&maxdist increment=%eval((&maxdist-&mindist+1)/10)))) 
                       yaxisopts=(display=(LINE)*/
	                   xaxisopts=( display=none griddisplay=off linearopts=( viewmin=%eval(&mindist-1) viewmax=&maxdist minorticks=OFF tickvaluesequence=( start=%eval(&mindist-1) end=&maxdist increment=%eval((&maxdist-&mindist+1)/10)))) 
                       yaxisopts=(display=none
                       %if &max_y ne %then %do; 
                         linearopts=(viewmin=1.0 viewmax=&max_y minorticks=OFF tickvaluesequence=(start=1.0 end=&max_y increment=1)) 
                       %end;
                       );

         /*					   Block plot*/
         blockplot x=_BLOCK_X block=_BLOCK_Y / name='block' display=(FILL) filltype=alternate fillattrs=(color=&block_filcolor) altfillattrs=(color=&block_filaltcolor);
											 /*		 Add &max_y reflines*/
		       %if &add_sample_ref_line=1 %then %do;
		       %do r=1 %to &max_y %by 1;
         referenceline y=&r / name="href&r" yaxis=Y curvelabelposition=max datatransparency=0 lineattrs=(pattern=&sample_refline_pattern thickness=0.1 color=&ref_line_color);
		       %end;
		       %end;
		       /*         scatterplot x=_MUT_X y=_MUT_Y/group=_MUT_GRP name='scatter' markerattrs=(color=&dotcolor symbol=CIRCLEFILLED size=&dotsize);*/
		       scatterplot x=_MUT_X y=_MUT_Y/name='scatter1' datatransparency=0 markerattrs=(symbol=circlefilled color=&dotcolor size=&dotsize);
		       scatterplot x=_MUT_X1 y=_MUT_Y1/name='scatter2' markerattrs=(symbol=circlefilled color=CXb2182b size=&dotsize);
		       scatterplot x=_MUT_X2 y=_MUT_Y2/name='scatter3' markerattrs=(symbol=square color=&block_filcolor size=&dotsize); 
		       /*Make marker color as block_filcolor and dotsize, just for making the height of scatterplot as designed*/
		       /*Can not make dotsize as 0 or other smallest values, which will make block shape strange*/
      endlayout;
   endlayout;
endgraph;
end;
run;

options printerpath=svg;
ods listing close;
ods printer file="&Final_dsdout..svg";

proc sgrender data=&Final_dsdout template=Graph;
dynamic _BLOCK_X="'BLOCK_X'n" _BLOCK_Y="'BLOCK_Y'n" _MUT_X="'MUT_X'n" _MUT_Y="'MUT_Y'n" _MUT_X1="'MUT_X1'n" _MUT_Y1="'MUT_Y1'n" _MUT_X2="'MUT_X2'n" _MUT_Y2="'MUT_Y2'n";
run;

ods printer close;
ods listing;

%mend;


/*Demo*/

/*
data bed;
input var1 $ var2 var3;
cards;
chr7 10 30
chr7 40 70
chr7 80 400
chr7  410 1500
;
data Mut;
input chr $ _st_ sample $;
cards;
chr7 11 a
chr7 20 a
chr7 30 b
chr7 40 a
chr7 14 a
chr7 400 c
chr7 100 d
chr7 1000 e
chr7 500 a
chr7 800 f
chr7 900 a
;

%MutRegOverlappedBlock(block_dsdin=bed
                      ,block_chr_var=var1
                      ,block_st_var=var2
				      ,block_end_var=var3
					  ,chr=chr7
					  ,mindist=10
					  ,maxdist=1500
					  ,Mut_dsdin=Mut
					  ,Mut_chr_var=chr
					  ,Mut_st_var=_st_
					  ,mut_sample_var=sample
					  ,Final_dsdout=AAA
					  ,block_filcolor=CXC6C3C6
					  ,block_filaltcolor=CX00CCCC
					  ,dotsize=10
					  ,dotcolor=CX000000
                      ,max_y=20 
                      ,add_sample_ref_line=1
                      ,graph_designwidth=800
					  ,sample_refline_pattern=3
					  ,ref_line_color=blue
);
*Select different refline pattern here:
*https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/grstatgraph/n13pm0ndse66l2n1u309543mx2yt.htm;

*Use SAS sgd template for making graph: E:\E_Queens\Temp\TCGA_Paper_Scripts\To-do-list\Paper_Realted_Scripts_Oct_16_2018\Mutation Mapped 2 Feature blocks.sgd;
*Need to set x-axis with mindist and maxdist, otherwise, the graph would be wrong;

*/


/*
 class GRAPHDATA1 /      
 color=CX445694; 
 class GRAPHDATA2 /      
 color=CXa23a2e; 
 class GRAPHDATA3 /      
 color=CX01665e; 
 class GRAPHDATA4 /      
 color=CX543005; 
                         
 class GRAPHDATA5 /      
 color=CX9d3cdb; 
 class GRAPHDATA6 /      
 color=CX7f8e1f; 
 class GRAPHDATA7 /      
 color=CX2597fa; 
 class GRAPHDATA8 /      
 color=CXb26084; 
                         
 class GRAPHDATA9 /      
 color=CXd17800;
 class GRAPHDATA10 /     
 color=CX47a82a; 
 class GRAPHDATA11 /     
 color=CXb38ef3; 
 class GRAPHDATA12 /     
 color=CXf9da04; 



*/

