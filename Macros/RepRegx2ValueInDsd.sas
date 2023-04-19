%macro RepRegx2ValueInDsd(dsdin,dsdout,RepRegx,Num_or_Char);

data &dsdout;
   set &dsdin;
   %if &Num_or_Char=1 %then %do;
   array change _numeric_;
   %end;
   %else %do;
   array change _character_;
   %end;
        do over change;
            change=prxchange("&RepRegx",-1,change);
        end;
 run ;

%mend;
/*
options mprint mlogic symbolgen;
*Change all specific characters into -9;
%RepRegx2ValueInDsd(mut3,mut3_,s/^\s*$/-9/,0);
*Change all specfic numeric into -9;
%RepRegx2ValueInDsd(mut3,mut3__,s/^\s*\.\s*$/-9/,1);
*/
