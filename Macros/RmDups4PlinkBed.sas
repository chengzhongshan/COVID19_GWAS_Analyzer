%macro RmDups4PlinkBed(Plink_EXE,PlinkBed,OutBed);
*If there are dup SNPs with the same name, we can not use the command ids-only with suppress-first;
%let Exclude_dups=%str(&PLINK_EXE --allow-no-sex --list-duplicate-vars suppress-first  --bfile &PlinkBed --out &OutBed);
%put &Exclude_dups;
X &Exclude_dups;

%let Exclude_dups=%str(&PLINK_EXE --allow-no-sex --bfile &PlinkBed --exclude &OutBed..dupvar --make-bed --out &OutBed);
%put &Exclude_dups;
X &Exclude_dups;
%mend;
