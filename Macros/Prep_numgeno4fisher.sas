%macro Prep_numgeno4fisher(
    dsin=,           /* Input dataset name (already imported) */
    snplist=,        /* Space-separated list of SNP variable names */
    outds=,          /* Output dataset for fisher4cntdsd */
    byvars=cancertype /* By variables, default as in your code */
);

    /* Filter out missing phenotype */
    data work.geno_tmp;
        set &dsin;
        where PHENOTYPE^=-9;
    run;

    /* Reshape to long format */
    data long_geno;
        set work.geno_tmp;
        array g{*} &snplist;
        do i=1 to dim(g);
            GT=g{i};
            Var=vname(g{i});
            output;
        end;
        drop i &snplist;
    run;
   %let byvars=&byvars Var;
    /* Sort */
    proc sort data=long_geno; by &byvars GT; run;

    /* Dominant model */
    data long_geno;
        set long_geno;
        if GT>=1 then GT=1;
        else if GT=0 then GT=0;
        else GT=.;
    run;

    /* Frequency table */
    proc freq data=long_geno noprint;
        table GT*Phenotype/list out=gt_frq;
        by &byvars;
    run;

    /* Group names */
    data gt_frq;
        set gt_frq;
        if GT=0 and Phenotype=1 then grpname="case0var";
        else if GT=1 and Phenotype=1 then grpname="case1var";
        else if GT=0 and Phenotype=2 then grpname="ctr0var";
        else if GT=1 and Phenotype=2 then grpname="ctr1var";
        keep &byvars grpname count;
    run;

    proc sort data=gt_frq; by &byvars grpname; run;

    /* Transpose for fisher4cntdsd */
    proc transpose data=gt_frq out=&outds(drop=_name_ _label_);
        by &byvars;
        id grpname;
        var count;
    run;

%mend Prep_numgeno4fisher;
