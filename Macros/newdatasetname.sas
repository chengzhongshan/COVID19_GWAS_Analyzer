%macro newdatasetname(proposalname);
    %*Finds the first unused dataset named *datasetname*, adding a leading underscore and a numeric suffix as large as necessary to make it unique!;
    %local i newdatasetname;
    %let proposalname=%sysfunc(compress(&proposalname));
    %let newdatasetname=_&proposalname;

    %do %while(%sysfunc(exist(&newdatasetname)));
        %let i = %eval(&i+1);
        %let newdatasetname=_&proposalname&i;
    %end;
    &newdatasetname
%mend;
