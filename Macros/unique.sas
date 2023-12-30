
%macro unique/parmbuff;                               
   %let i = 1;                                 
   %let w1 = %scan(&syspbuff,1);                      
   %do %while (&&w&i ne );                     
       %let i = %eval(&i + 1);                 
       %let w&i = %scan(&syspbuff,&i);                
   %end;      

   %do j=1 %to %eval(&i-1);                    
      %do k=%eval(&j+1) %to %eval(&i);       
          %if &&w&j = &&w&k %then %let w&k = ; 
      %end;                                    
   %end;                                       
   %let z =;       

   %do j=1 %to %eval(&i);         
      %let z = &z &&w&j;                       
   %end;                                       
   &z                                          
%mend unique;           
/*Demo code:;

*Note: the macro is updated by zhongshan cheng to accept comma separated list as input using parmbuff;

From: "Paul M. Dorfman" <pdorfma@ucs.att.com>
Newsgroups: comp.soft-sys.sas
Subject: Re: Removing duplicate strings in a macro variable?
Date: Sun, 18 Oct 1998 17:08:33 -0400

Now we can simply use this macro as a macro function, for instance:

%LET DDSTR = %unique (AAA BBB CCC AAA BBB 111);    

Of course, the argument of %unique can also be a macro reference, and the
result can be assigned either to the macrovariable being deduped or
something else. For example:

%LET &VAR1 = %unique (&VAR1);    

%LET &VAR2 = %unique (&VAR1);    

%LET DDSTR = %unique (AAA BBB CCC AAA BBB);  
  
%LET DDSTR = %unique (AAA, BBB, CCC, AAA, BBB);    

*The macro can be used with dosubl in the data step with data step variable as input;
option mprint mlogic symbolgen;
data a;
input X1 $ X2 $ X3 $;
comb=catx(" ",of X1-X3);
rc=dosubl('%let C'||left(put(_n_,3.))||'=%unique('||comb||')');
cards;
a b a
c d e
a d d
;
data a;
set a;
uniq_comb=symget('C'||left(put(_n_,3.)));
run;
proc print;run;

*Note for the following correction in the original macro;
*Correct the original macro;
*The original macro here are wrong, which will not remove duplicates if the input is like this: A D D;                                 
   %do j=1 %to %eval(&i-1);                    
      %do k=%eval(&j+1) %to %eval(&i-2);       

*Update the original macro to correctly remove duplicates;                            
   %do j=1 %to %eval(&i-1);                    

*/



