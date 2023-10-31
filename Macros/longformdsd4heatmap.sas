%macro longformdsd4heatmap(
/*Compared to the macro heatmap4longformatdsd, this macro may not be good enough!
whenever possible, please use the heatmap4longformatdsd! The macro is kept for 
code reusing purpose!*/
dsdin,
row_var,
col_var,
value_var,
value_upperthres,
Newvalue4upper,
value_lowerthres,
Newvalue4lower,
cluster,
srtbyrow,
srtbycol,
htmap_colwgt,
htmap_rowwgt,
dsdout
);

%Scaleup_nrow_ncol(dsdin=&dsdin,
                   row_var4row=&row_var,
                   row_var4col=&col_var,
                   value_var=&value_var,
                   dsdout=&dsdout);

data &dsdout;
set &dsdout;
if &value_var>&value_upperthres then &value_var=&Newvalue4upper;
if &value_var<&value_lowerthres then &value_var=&Newvalue4lower;
run;


proc sort data=&dsdout;by &row_var &col_var;run;

%if %eval(&cluster^=1) %then %do;

/* ods graphics on/height=20in width=16in; */
proc sgplot data=&dsdout;
title h=10pt "Heatmap for dataset: &dsdin";
heatmapparm y=&row_var x=&col_var colorresponse=&value_var/
            colormodel=(lightyellow lightred brown) outline;
/*cxFAFBFE cx667FA2 cxD05B5B cxFAFF00*/
/*heatmapparm y=Gene_Symbol x=Tissue colorresponse=logP;*/
/*text y=&col_var x=&row_var text=&value_var;*/
xaxis reverse;	
run;
%end;

%else %do;

/*make cluster for &row_var*/
%longdsd2matlabmatrix(dsd=&dsdout
                     ,var_row=&row_var
                     ,var_col=&col_var
                     ,data_var=&value_var
                     ,value2asign4missing=0
                     ,dsdout=row_var&dsdout
                     ,outdir4matrix=);
%matrix4cluster(dsdin=row_var&dsdout,
                distance_method=Euclid,
                dist_matrix_out=rowvar_dist,
				dendrogram_out=dendrogram_rowvar,
                cluster_method=average,
				id_var4cluster=&row_var,
				numeric_vars=
                      );


/*make cluster for &col_var*/
%longdsd2matlabmatrix(dsd=&dsdout
                     ,var_row=&col_var
                     ,var_col=&row_var
                     ,data_var=&value_var
                     ,value2asign4missing=0
                     ,dsdout=col_var&dsdout
                     ,outdir4matrix=);
%matrix4cluster(dsdin=col_var&dsdout,
                distance_method=Euclid,
                dist_matrix_out=colvar_dist,
				dendrogram_out=dendrogram_colvar,
                cluster_method=average,
				id_var4cluster=&col_var,
				numeric_vars=
                      );


/*merge heatmap and cluster datasets together*/
data &dsdout;
merge dendrogram_rowvar dendrogram_colvar &dsdout;
run;

%if %eval(&srtbyrow=1 and &srtbycol=0) %then %do;
/*Note: make sure to let rowdata and columndata with union range*/
 proc template;
   define statgraph HeatDendrogram;
      begingraph;
         layout lattice    / rowdatarange=union columndatarange=union
                             columns=2 
                             columnweights=(&htmap_colwgt);
            *entrytitle "Second Attempt: Display and Align the Three Components";      
            layout overlay;
               dendrogram nodeID=&row_var._name parentID=&row_var._parent clusterheight=&row_var._hgt / tip=none
                             orient=horizontal;
            endlayout;
            layout overlay;
               heatmapparm y=&row_var x=&col_var colorresponse=&value_var /
                             colormodel=(cxFAFBFE cx667FA2 cxD05B5B);
            endlayout;
         endlayout;
     endgraph;
   end;
run;
%end;
%else %if (&srtbyrow=0 and &srtbycol=1) %then %do;
/*Note: make sure to let rowdata and columndata with union range*/
 proc template;
   define statgraph HeatDendrogram;
      begingraph;
         layout lattice    / rowdatarange=union columndatarange=union
                             rows=2 
                             rowweights=(&htmap_rowwgt);
            *entrytitle "Second Attempt: Display and Align the Three Components";      
            layout overlay;
               dendrogram nodeID=&col_var._name parentID=&col_var._parent clusterheight=&col_var._hgt / tip=none;
            endlayout;
            layout overlay;
               heatmapparm y=&row_var x=&col_var colorresponse=&value_var /
                             colormodel=(cxFAFBFE cx667FA2 cxD05B5B);
            endlayout;
         endlayout;
     endgraph;
   end;
run;
%end;
%else %do;
/*Note: make sure to let rowdata and columndata with union range*/
 proc template;
   define statgraph HeatDendrogram;
      begingraph;
         layout lattice    / rowdatarange=union columndatarange=union
                             rows=2 columns=2 
                             columnweights=(&htmap_colwgt) rowweights=(&htmap_rowwgt);
            *entrytitle "Second Attempt: Display and Align the Three Components";      
            layout overlay; entry ' '; endlayout;
            layout overlay;
               dendrogram nodeID=&col_var._name parentID=&col_var._parent clusterheight=&col_var._hgt / tip=none;
            endlayout;
            layout overlay;
               dendrogram nodeID=&row_var._name parentID=&row_var._parent clusterheight=&row_var._hgt / tip=none
                             orient=horizontal;
            endlayout;
            layout overlay;
               heatmapparm y=&row_var x=&col_var colorresponse=&value_var /
                             colormodel=(cxFAFBFE cx667FA2 cxD05B5B);
            endlayout;
         endlayout;
     endgraph;
   end;
run;
%end;
/* ods graphics on/height=20in width=15in;  */
proc sgrender data=&dsdout template=HeatDendrogram;
run;

/*Make heatmap with cluster output dsd*/
/*Need to update*/

%end;

%mend;
/*Demo: perform cluster analysis by row and col;
ods graphics on/height=20in width=15in;
%longformdsd4heatmap(dsdin=forheatmap,
                           row_var=gwas,
                           col_var=gene_name,
                           value_var=logP,
                           value_upperthres=10,
                           Newvalue4upper=10,
                           value_lowerthres=1.3,
                           Newvalue4lower=0,
						   cluster=0,
                           srtbyrow=1,
                           srtbycol=0,
						   htmap_colwgt=0.2 0.8,
						   htmap_rowwgt=0.2 0.8,
                           dsdout=x);

*Not perform cluster analysis;
*make cluster for rowvar;
%longformdsd4heatmap(dsdin=forheatmap,
                           row_var=gwas,
                           col_var=gene_name,
                           value_var=logP,
                           value_upperthres=8,
                           Newvalue4upper=8,
                           value_lowerthres=1.3,
                           Newvalue4lower=0,
						   cluster=1,
                           srtbyrow=1,
                           srtbycol=0,
						   htmap_colwgt=0.2 0.8,
						   htmap_rowwgt=0.2 0.8,
                           dsdout=x);

*make cluster for colvar;
%longformdsd4heatmap(dsdin=forheatmap,
                           row_var=gwas,
                           col_var=gene_name,
                           value_var=logP,
                           value_upperthres=8,
                           Newvalue4upper=8,
                           value_lowerthres=1.3,
                           Newvalue4lower=0,
						   cluster=1,
                           srtbyrow=0,
                           srtbycol=1,
						   htmap_colwgt=0.2 0.8,
						   htmap_rowwgt=0.2 0.8,
                           dsdout=x);

*make cluster for both row and col vars;
%longformdsd4heatmap(dsdin=forheatmap,
                           row_var=gwas,
                           col_var=gene_name,
                           value_var=logP,
                           value_upperthres=8,
                           Newvalue4upper=8,
                           value_lowerthres=1.3,
                           Newvalue4lower=0,
						   cluster=1,
                           srtbyrow=1,
                           srtbycol=1,
						   htmap_colwgt=0.2 0.8,
						   htmap_rowwgt=0.2 0.8,
                           dsdout=x);
*/




