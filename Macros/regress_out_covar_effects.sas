%macro regress_out_covar_effects(
dsdin=,/*Input dsd*/
dsdout=,/*output dsd*/
varadjlist=,/*char covars used to adjust effects; these char covars are required to be put into the class statment*/
modeladjlist=,/*all covars, including char and numeric covars in a format for the model statment of proc glm; ensure the above varadjlist contain all required covars*/
signal_var=,/*The y variable subject to regress out covar effects*/
adjsignal_var= /*Final y variable name containing adjsted value of signal_var*/
);
/*ods trace on;*/
proc glm data=&dsdin noprint;
class &varadjlist;
model &signal_var = &modeladjlist;
output out=&dsdout  r=&adjsignal_var;
run;
/*ods trace off;*/
/*proc print data=&dsdout(obs=10);*/
/*run;*/

%mend;

/*Demo codes:;

proc print data=sashelp.cars(obs=10);
run;
%debug_macro;

%regress_out_covar_effects(
dsdin=sashelp.cars,
dsdout=adjcars,
varadjlist= DriveTrain Type,
modeladjlist=EngineSize Cylinders Horsepower Type DriveTrain,
signal_var=MPG_Highway,
adjsignal_var=adj_MPG_Highway 
);
proc print data=adjcars;
run;


*/


