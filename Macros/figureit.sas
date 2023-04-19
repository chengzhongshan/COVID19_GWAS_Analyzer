%macro figureit(a,b);
   %let y=%sysevalf(&a+&b);
   %put The result with SYSEVALF is: &y;
   %put  The BOOLEAN value is: %sysevalf(&a +&b, boolean);
   %put  The CEIL value is: %sysevalf(&a +&b, ceil);
   %put  The FLOOR value is: %sysevalf(&a +&b, floor);
   %put  The INTEGER value is: %sysevalf(&a +&b, int);
%mend figureit;

/*Demo:

%figureit(100,1.597);

*/
