%macro range2consecutive_num(
arg,/*input nums separated by space and '-' or other customized linker using perl regular expression is applied to link consecutive numbers, 
such as 10-300 or 10..300; note: when using customized linker rather than "-", do not include "-" in the input arg!*/
step=1 1 1, /*single or multiple step(s) to be used to separate consecutive numbers;
the ordered steps will be matched with its corresponding consective numbers in the arg;
if the step is missing for the consecutive number, the last step will be used!*/
linker4consecutivenum=%nrstr(-) /*linker to be used to split consecutive numbers;
default is "-", otherwise, provide perl regular expression to match the strings for
separating these consecutive numbers, such as "\.\."; note that the rgx is exscaped!
*/
);
%local nlinkers nsteps _si_ last_step rstep n _sn_;
%let nsteps=%ntokens(&step);
%let last_step=%scan(&step,&nsteps);
/*To make the macro easier to run, replace customized linker with "-";*/
%if "&linker4consecutivenum"^="-" %then %do;
       %if %index(&arg,%str(-)) %then %do;
					%put Error: please use consistent linker for consectutive numbers and ensure no "-" included in the input number range: &arg!;
          %abort 255;
       %end;
			 %let arg=%sysfunc(prxchange(s/&linker4consecutivenum/-/,-1,&arg));
%end;

%let nlinkers=%sysfunc(countc(&arg,%str(-)));
        %if &nlinkers>&nsteps %then %do;
            %do _si_=%eval(&nsteps+1) %to &nlinkers;
               %let step=&step &last_step;
             %end;
%end;

%let consect_range=;
/*  make sure range in the format: 0-10 20-300;*/
%let n=1;
%let _sn_=1;
%do %until (%qscan(&arg,%eval(&n),%str( ))=%str()); 
   %let range=%qscan(&arg,%eval(&n),%str( ));

  %if %index(&range,%str(-)) %then %do;
   %let st=%qscan(&range,1,%str(-));
   %let end=%qscan(&range,2,%str(-));
   %do i=&st %to &end %by %scan(&step,&_sn_,%str( ));
         %let consect_range=&consect_range &i;
	 %end;
   %let _sn_=%eval(&_sn_+1); 
  %end;
  %else %do;
         %let consect_range=&consect_range &range;
   %end;
    %let n=%eval(&n+1);
%end;

&consect_range

%put &&consect_range;

%mend range2consecutive_num;

/*
options mprint mlogic symbolgen;

%macro xx;
%let x=%range2consecutive_num(arg=0-10 15 20-300,step=10);
%put &x;
%let x=%range2consecutive_num(arg=0-10 15 20-300,step=10 50);
%put &x;

*This will fail because "-" and other linker can not be used at the same time;
%let x=%range2consecutive_num(arg=0-10 15 20..300,step=10 50,linker4consecutivenum=%str(\.\.));
*This works;
%let x=%range2consecutive_num(arg=0..10 15 20..300,step=10 50,linker4consecutivenum=%str(\.\.));
 %put &x;

%mend;

%xx;

*/


