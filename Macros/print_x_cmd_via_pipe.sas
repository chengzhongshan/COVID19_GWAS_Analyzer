%macro print_x_cmd_via_pipe(xcmd=);
    /*Note: do not include double or single quotes in the xcmd argument*/
filename FX pipe "&xcmd";
data _null_;
  infile FX;
  input;
  put _infile_;
run;
%mend;

