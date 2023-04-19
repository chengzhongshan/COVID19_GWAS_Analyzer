%Macro Make_Quote_Var_List_From_Dsd(indsd,var,sep);
%global quoted_var_list;
%let quoted_var_list=;
proc sql noprint;
   select 
    unique(quote(compress(&var)))
    into: quoted_var_list
    separated by &sep
    from &indsd;
quit;
%Mend;

/*
*Default separator=' ';
%Make_Quote_Var_List_From_Dsd(indsd=sashelp.cars,var=model,sep=",");
%put &quoted_var_list;

%Make_Quote_Var_List_From_Dsd(indsd=sashelp.cars,var=model,sep=" ");
*/

