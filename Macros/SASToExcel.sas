%macro SASToExcel(ImportLibrary=, ExportLocation=);

    ods output members = _Members;
    proc datasets lib = &ImportLibrary; run; quit;

    proc sql;
        select count(Name) into :NumOfDatasets from _Members;
        select Name into :Dataset1-:Dataset%trim(%left(&NumOfDatasets)) from _Members;
    quit;

    %do index = 1 %to &NumOfDatasets;
        proc export data=&ImportLibrary..&&Dataset&index.
        outfile="&ExportLocation"
        dbms=excel replace;
        sheet="&&Dataset&index";
        run;
    %end;

    proc datasets;
        delete _Memebers;
    quit;

%mend;

/*
%SASToExcel(ImportLibrary=raw, ExportLocation = c:\test.xlsx);
*/
