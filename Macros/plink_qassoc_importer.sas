%macro plink_qassoc_importer(
zipfile= ,/*file with appendix or .txt, .tgz, .gz, or .zip can be read by the macro*/
outdsd=assoc
);

%ImportFileHeadersFromZIP(
zip=&zipfile,
filename_rgx=.,
obs=max,
sasdsdout=&outdsd,
deleteZIP=0,
infile_command=%str(
firstobs=2 obs=max dsd truncover;
length snpid $20. ref $1. alt $3.;
input;
_infile_=prxchange('s/\s+/,/',-1,_infile_);
chr=scan(_infile_,1,',')+0;
snpid=scan(_infile_,2,',');
pos=scan(_infile_,3,',')+0;
alt=scan(_infile_,4,',');
frq_case=scan(_infile_,5,',') + 0;
frq_ctr=scan(_infile_,6,',') + 0;
ref=scan(_infile_,7,',');
P=scan(_infile_,9,',') + 0;
OR=scan(_infile_,10,',') + 0;
beta=log(OR);
logP=-log10(P);
if P^=.;
)
);
%mend;

