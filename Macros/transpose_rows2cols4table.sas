%macro transpose_rows2cols4table(
/*
Transpose rows-to-columns for a table;
Creates a mapping dataset (mapout) that stores long original &by values for each short column id;
Note: long2wide4multigrpsSameTypeVars is better than this one for handling column names with length >32;
*/
data=, out=, by=rowlabels, var=_numeric_, mapout=longcoldsd
);
    %if %length(&data)=0 %then %do;
        %put ERROR: data= is required.;
        %return;
    %end;
    %if %length(&out)=0 %then %let out=&data._transposed;
    %if %length(&mapout)=0 %then %let mapout=&out._colnames;

    /* intermediate transpose to get one value per &by */
    proc sort data=&data; by &by; run;
    proc transpose data=&data out=_tmp_trans1(keep=&by col1 _name_);
        var &var;
        by &by;
    run;

    /* distinct &by values -> assign short unique ids (safe against SAS name truncation) */
    proc sort data=_tmp_trans1(keep=&by) nodupkey out=_tmp_idmap;
        by &by;
    run;

    data _tmp_idmap;
        set _tmp_idmap;
        retain _idnum 0;
        _idnum + 1;
        length _idname $32 _longby $32767;
        /* create short unique id that will be used as column names (fits 32-char limit) */
        _idname = cats('COL', put(_idnum, z7.)); /* e.g. COL0000001, unique and short */
        /* create a printable long label combining all by variables (if multiple) */
        _longby = catx(' | ', of &by);
        keep &by _idname _longby;
    run;

    /* save the mapping to a user-visible dataset */
    data &mapout;
        set _tmp_idmap;
    run;

    /* merge short ids back into the transposed rows */
    proc sort data=_tmp_trans1; by &by; run;
    proc sort data=_tmp_idmap; by &by; run;

    data _tmp_trans1b;
        merge _tmp_trans1(in=_a) _tmp_idmap(in=_b);
        by &by;
        if _a;
    run;

    /* final transposed dataset using short unique ids as column names */
    proc sort data=_tmp_trans1b; by _name_ _idname; run;
    proc transpose data=_tmp_trans1b out=&out;
        var col1;
        by _name_;
        id _idname;
    run;

    /* attach labels to transposed columns with the original &by values for clarity */
    proc sql noprint;
        select catx('=', _idname, quote(trim(_longby))) into :labstmt separated by ' '
        from _tmp_idmap;
    quit;

    %if %length(&labstmt) %then %do;
        proc datasets library=work nolist;
            modify &out;
            label &labstmt;
        quit;
    %end;

    /* rename _name_ to Rowlabels for readability */
    data &out;
        set &out;
        rename _name_=Rowlabels;
    run;

    /* optional: cleanup temporary datasets (uncomment if desired) */
    /*
    proc datasets library=work nolist;
        delete _tmp_trans1 _tmp_trans1b _tmp_idmap;
    quit;
    */
%mend transpose_rows2cols4table;


/* Demo codes:;
x cd "C:\Users\cheng\OneDrive\Desktop\AML_Vars_Package";
%let file=GSEA_NES_NTU_vs_NG.txt;
proc import datafile="&file" out=x replace dbms=tab;
getnames=yes;
guessingrows=max;
run;
*it will transpose all rows in a table into columns;
%transpose_rows2cols4table(data=x, out=x1, by=rowlabels, mapout=longcoldsd);

*/
