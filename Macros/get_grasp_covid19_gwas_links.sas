%macro get_grasp_covid19_gwas_links(dsdout=grasp_covid_gwas_info);

filename graspout temp;
proc http url="https://grasp.nhlbi.nih.gov/covid19GWASResults.aspx"
method="get" out=graspout;
run;
data grasp_info;
infile graspout lrecl=32767 truncover;
input;
info=_infile_;
run;
filename graspout clear;

data grasp_info;
set grasp_info;
if prxmatch('/<td.*Summary Stats.*gz/i',info);
run;
data _null_;
set grasp_info(obs=10);
n=1;
info=tranwrd(info,'</td>','~');
do while (scan(Info,n,'~') ne "");
	 n=n+1;
end;
call symputx('num_items',n);
run;
/*%put &num_items;*/

data _x_(drop=info);
set grasp_info;
info=tranwrd(info,'</td>','~');
gwas=prxchange('s/.*\<a href=.([^><]+).\>Summary Stats.*/$1/',-1,info);
gwas=prxchange('s/.*\/([^\/]+).txt.gz/$1/',-1,gwas);
n=1;
do while (n<=&num_items);
	 item=scan(info,n,'~');
	 output;
	 n=n+1;
end;
run;

data _x_;
set _x_;
if prxmatch('/\>[\w\/,\.]+/',item) then do;
	item=prxchange('s/^[^>]+\>(.*)/$1/',-1,item);
end;
else do;
  delete;
end;
item=prxchange('s/.*href=.([^><]+)..*/$1/',-1,item);
item=prxchange('s/.*>([^>]+)/$1/',-1,item);
if prxmatch('/txt.gz/',item) then item=prxchange('s/(.*txt.gz).*/https:\/\/grasp.nhlbi.nih.gov\/$1/',-1,item);
run;

data _x_(drop=i header);
retain name item gwas;
set _x_(rename=(n=i));
length header $500.;
header=catx('|','DataSource', 'ReleaseDate', 'Description', 'CasesControlsNum', 
'Ancestry',	'Sex',  'Variants_in_Million', 'Tophits',	'SummaryStatsFull',
'TopAnnotated',	'Top_in_Grasp',	'Top_in_EBI',	'Top_in_GTeX',	
'Top_in_eQTLdb'	);
name=scan(header,i,'|');
if name^="";
run;

proc sort data=_x_;by gwas name item;

proc transpose data=_x_ out=&dsdout(drop=_name_);
var item;
id name;
by gwas;
run;

/*proc print;run;*/

%mend;

/*Demo codes:;

%get_grasp_covid19_gwas_links(dsdout=grasp_covid_gwas_info);

%ds2csv(data=grasp_covid_gwas_info,csvfile='E:/LongCOVID_HGI_GWAS/grasp_covid_gwas_info.csv',runmode=b);

*/


