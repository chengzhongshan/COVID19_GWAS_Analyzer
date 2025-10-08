%macro bed_regions_plot(indata=, yvar=, groupvar=name, startvar=start, endvar=end, linesize=10);
    data bed_regions;
        set &indata.;
        length pos 8;
        array p{*} &startvar. &endvar.;
        do i = 1 to 2;
            pos = p{i};
            output;
        end;
        drop i;
    run;

    proc print data=bed_regions; run;

    proc sgplot data=bed_regions;
        series x=pos y=&yvar / group=&groupvar. lineattrs=(thickness=&linesize) name="Regions";
        xaxis label="Genomic Position";
        yaxis label="&yvar";
        title "BED Regions Visualization";
        keylegend "Regions";
    run;
%mend bed_regions_plot;

/* Demo codes;
data bed_regions_raw;
    infile datalines dsd truncover;
    input chrom :$20. start end name :$50. score strand :$1.;
    datalines;
chr1,100,800,regionA,960,+
chr1,350,900,regionB,850,-
chr1,20,700,regionC,700,+
chr1,120,900,regionD,500,-
;
run;

%bed_regions_plot(
indata=bed_regions_raw, 
yvar=score,
groupvar=name, startvar=start, endvar=end,
linesize=20
);

*/
