%macro iml_PrintDescStats(table);
%local lib dsd;
%if %index(&table,.) %then %do;
 %let lib=%scan(&table,1,.);
 %let dsd=%scan(&table,2.);
%end;
%else %do;
 %let lib=work;
 %let dsd=&table;
%end;

proc iml;
start PrintDescStats( tbl );
cols = loc( TableIsVarNumeric(tbl) ); /* get column numbers */
if ncol(cols)=0 then do;
print "The table does not contain any numeric columns.";
return;
end;
stats = j(5, ncol(cols)); /* allocate matrix for results */
m = TableGetVarData(tbl, cols); /* extract data into matrix */
stats[1,] = countn(m); /* N for each column */
stats[2,] = mean(m); /* Mean for each column */
stats[3,] = std(m); /* Std Dev for each column */
stats[4,] = m[><, ]; /* Minimum for each column */
stats[5,] = m[<>, ]; /* Maximum for each column */
varNames = TableGetVarName(tbl, cols);
rowNames = {"N", "Mean", "Std Dev", "Minimum", "Maximum"};
print stats[L="Descriptive Statistics" r=rowNames c=varNames];
finish;
table = TableCreateFromDataSet("&lib", "&dsd");
run PrintDescStats(table);
%mend;
/*Demo codes:;

%debug_macro;
%iml_PrintDescStats(sashelp.cars);


*/

