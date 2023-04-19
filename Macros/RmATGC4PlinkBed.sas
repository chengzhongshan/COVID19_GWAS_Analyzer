%macro RmATGC4PlinkBed(PlinkBed,NewPlinkBed,Plink_EXE=plink1.9.exe);
%Import_Space_Separated_File(abs_filename=&PlinkBed..bim,
                                firstobs=1,
								getnames=NO,
                                outdsd=PLINK);
data Plink;
set Plink;
if (compress(catx("",trim(var5),trim(var6)))
      in ("AT","TA",
	      "CG","GC")
    ) then do;
tag=-9;
end;
run;

data _null_;
set Plink(where=(tag=-9));
file "&&PlinkBed..rm";
put var2;
run;

/*Create MAP for rsID updating*/
X "&Plink_EXE --bfile &PlinkBed --make-bed
                --exclude &PlinkBed..rm --out &NewPlinkBed";

%mend;

