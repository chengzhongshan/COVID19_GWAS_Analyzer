/*
  data spambase;
      %let url=//archive.ics.uci.edu/ml/machine-learning-databases;
      infile "http:&url/spambase/spambase.data"
            device=url delimiter=',';
      input wf_make wf_adress wf_all wf_3d wf_our
            wf_over wf_remove wf_internet wf_order wf_mail
            wf_receive wf_will wf_people wf_report wf_addresses
            wf_free wf_business wf_email wf_you wf_credit
            wf_your wf_font wf_000 wf_money wf_hp
            wf_hpl wf_george wf_650 wf_lab wf_labs
            wf_telnet wf_857 wf_data wf_415 wf_85
            wf_technology wf_1999 wf_parts wf_pm wf_direct
            wf_cs wf_meeting wf_original wf_project wf_re
            wf_edu wf_table wf_conference
            cf_semicolon cf_parenthese cf_bracket cf_exclamation
            cf_dollar cf_pound
            average longest total spam;
   run;
proc hpforest data=spambase maxtrees=200;
   input w: c: average longest total/level=interval;
   target spam/level=binary;
   ods output FitStatistics=fitstats(rename=(Ntrees=Trees));
run;

data fitstats;
   set fitstats;
   label Trees = 'Number of Trees';
   label MiscAll = 'Full Data';
   label Miscoob = 'OOB';
run;

proc sgplot data=fitstats;
   title "OOB vs Training";
   series x=Trees y=MiscAll;
   series x=Trees y=MiscOob/lineattrs=(pattern=shortdash thickness=2);
   yaxis label='Misclassification Rate';
run;
title;
*/

