%macro mkdir(dir);
%let count=0;
%let dlm=/;
%let dir=%sysfunc(prxchange(s/\\/\//,-1,&dir));

%if %quote(%substr(&dir,%length(&dir),1)) ^= "&dlm" %then %do;
%let dir=&dir&dlm;
%end;

%do j=1 %to %length(&dir);
%let subdir=%substr(&dir,&j,1);
%if "&subdir"="&dlm" %then %do;
%let count=%eval(&count+1);
%end; 
%end;

%put There are &count '/' in your dir &dir;


%let xdir=%substr(&dir,1,1);
%let ydir=%substr(&dir,2,1);

/*For windows: provived fullpath*/
%if ("&xdir"^="&dlm" and "&ydir"=':') %then %do;
%let drive=%substr(&dir,1,3);
%let level=&drive;
%do i=2 %to &count;
%let word=%scan(&dir,&i,&dlm);
%let lnew=&level&word&dlm;
data _null_;
rc=filename('newdir',"&lnew");
c=dopen('newdir');
if c=0 then new=dcreate("&word","&level");
run;
%let level=&lnew;
%end;
%end;

/*For Linux: provived fullpath*/
%else %if ("&xdir"="&dlm" and "&ydir"^=':') %then %do;
*For linux path like /home/user, it is necessary to asign the level as /;
%if %sysfunc(prxmatch(/^\//,&dir)) %then %let level=/;
%else %let level=;
%do i=1 %to &count;
%let word=%scan(&dir,&i,&dlm);
%let lnew=&level&word&dlm;
data _null_;
rc=filename('newdir',"&lnew");
c=dopen('newdir');
if c=0 then new=dcreate("&word","&level");
run;
%let level=&lnew;
%end;

%end;

/*For windows and Linux: provived relative path*/
%else %do;
%put your &dir is in relative path;
%put we will remove leading './' for your relative path;
%let curdir=%curdir;

%let dir=%sysfunc(prxchange(s/^\.\///,-1,&dir));
%let level=;
%do i=1 %to &count;
%let word=%scan(&dir,&i,&dlm);
%if &i=1 %then %do;
%let level=&word&dlm;
data y;
c=dopen("&level");
if c=0 then new=dcreate("&level","./");
run;
%end;
%else %do;
%let lnew=&level&word&dlm;
data _null_;
rc=filename('newdir',"&lnew");
c=dopen('newdir');
if c=0 then new=dcreate("&word","&level");
run;
%let level=&lnew;
%end;
%end;
%end;




%mend;

/*Demo: make sure the delimiter of the dirpath is '/';
 *The macro will create dir like the linux funciton 'mkdir -p' recursively;

options mprint mlogic symbolgen;

%let curdir=%curdir;
%put current path is &curdir;
%put your newly created dirs will be located under the dir: &curdir;

%mkdir(dir=xxx/yyy);

%getcwd;

*/
