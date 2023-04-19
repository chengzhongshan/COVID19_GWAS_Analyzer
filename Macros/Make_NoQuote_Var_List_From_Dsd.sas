%Macro Make_NoQuote_Var_List_From_Dsd(indsd,var,sep);
%global noquote_var_list;
%let noquote_var_list=;
proc sql noprint;
   select 
    unique(compress(&var))
    into: noquote_var_list
    separated by &sep
    from &indsd;
quit;
%Mend;

/*
options mprint mlogic symbolgen macrogen;
%Make_NoQuote_Var_List_From_Dsd(indsd=sashelp.cars,var=model,sep=",");
%put &noquote_var_list;

%Make_NoQuote_Var_List_From_Dsd(indsd=sashelp.cars,var=model,sep=" ");
*/

