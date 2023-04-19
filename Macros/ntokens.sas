
%macro ntokens(list);
    %eval(1 + %length(%sysfunc(compbl(&list))) - %length(%sysfunc(compress(&list))))
%mend ntokens;
