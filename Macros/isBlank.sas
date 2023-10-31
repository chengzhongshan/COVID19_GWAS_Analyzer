%macro isBlank(param) ;
  %sysevalf(%superq(param)=,boolean)
%mend isBlank ;
/*Demo:;
*check whether the macro var is blank;
%isBlank(&xxx);
*/
