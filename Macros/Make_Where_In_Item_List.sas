%macro Make_Where_In_Item_List(query_name,indsd,dsd_variable,out_item_list);
data _NULL_;
length item_list $50.;*Be caution about the length;
set &indsd end=eof;
retain ct 0;
file "&out_item_list..sas" noprint;
if _n_ eq 1 then
   put "where &query_name in (" @;
item_list=quote(trim(&dsd_variable));
put item_list @;
if eof then 
   put ");";
else
   put "," @;
run;
%mend;
