   *               _\|/_
                   (o o)
    +----oOO-{_}-OOo----------------------------------------------------------------------------+
    :                                                                                                                       :
    :    MultiTranspose  (version 1.0.3, February 2011)                                            :
    :                                                                                                                      :
    :    Transposing multiple variables in a data set                                                :
    :                                                                                                                     :
    :     http://www.medicine.mcgill.ca/epidemiology/Joseph/PBelisle                  :
    +--------------------------------------------------------------------------------------------;
/*Demo:
http://www.medicine.mcgill.ca/epidemiology/joseph/pbelisle/MultiTranspose.html

%MultiTranspose(data=ex1, out=out1, vars=sbp wt, by=centre subjectno, pivot=visit, library=work);

%MultiTranspose(data=ex1, out=out1_1, vars=sbp wt, by=centre subjectno, pivot=visit, dropMissingPivot=0, library=work);

%MultiTranspose(data=ex1, out=out1_2, vars=sbp wt, by=centre subjectno, pivot=visit, copy=gender, library=work);

%MultiTranspose(data=ex2, out=out2, by=acct, pivot=OBS_DT, vars=HBAL_AMT MBAL_AMT, library=work);

%MultiTranspose(data=ex3, out=out3, by=item, vars=price qty, pivot=flavor, library=work);

%MultiTranspose(data=ex3, out=out3num, by=item, vars=price qty, pivot=flavor, UseNumericExt=1, library=work);


*My simple Demo;
data x;
input a b c;
cards;
1 3 4
2 2 3
1 1 1
;

*N.B.: pivot is the variable used to lable the newly generated wide-columns;

%MultiTranspose(data=x, out=tr_x, by=b, vars=c, pivot=a, UseNumericExt=1, library=work);

*/


%macro MultiTranspose(out=, data=, vars=, by=, pivot=, copy=, dropMissingPivot=1, UseNumericExt=0, library=library);
	%local dsCandidateVarnames dsContents dsCopiedVars dsLocalOut dsNewVars dsNewVarsFreq dsPivotLabels dsPivotLabelsHigh dsPivotLabelsLow dsPivotLabelsOther dsPivotObsValues dsRowvarsFreq dsTmp dsTmpOut dsTransposedVars dsXtraVars;

	%local anyfmtHigh anyfmtLow anyfmtOther anymissinglabel anymissingPivotlabel anyrepeatedvarname byfmt bylbl byvar datefmt;
	%local formatl formattedPivot i llabel lmax lPivotlabel lPivotmylabel;
	%local nbyvars ncandidatevars ncopy newlbl newvar newvars nNewvars npivot npivotvalues nvars;
	%local pivotfmt pivotIsDate pivotIsNumeric pivotvalue s tmp tmpvar;
	%local v var vars xnewvars xtravar ynewvars;

	/*
		PIVOT names the column in the input file whose row values provide the column names in the output file.
		There should only be one variable in the PIVOT statement. Also, the column used for the PIVOT statement cannot have
		any duplicate values (for a given set of values taken by variables listed in BY)
	*/;

	* Check that mandatory arguments were filled;

	%if %length(%superq(out)) eq 0 %then %do;
		%put ERROR: [MultiTranspose] output file must be specified (through out= argument);
		%goto Farewell;
	%end;

	%if %length(%superq(data)) eq 0 %then %do;
		%put ERROR: [MultiTranspose] input data set must be specified (through data= argument);
		%goto Farewell;
	%end;

	%if %length(%superq(vars)) eq 0 %then %do;
		%put ERROR: [MultiTranspose] list of variables to be transposed must be specified (through vars= argument);
		%goto Farewell;
	%end;

	%if %length(%superq(by)) eq 0 %then %do;
		%put ERROR: [MultiTranspose] *by* variables must be specified (through by= argument);
		%goto Farewell;
	%end;

	%if %length(%superq(pivot)) eq 0 %then %do;
		%put ERROR: [MultiTranspose] pivot variable must be specified (through pivot= argument);
		%goto Farewell;
	%end;


	%let nbyvars	= %MultiTransposeNTokens(&by);
	%let npivot	= %MultiTransposeNTokens(&pivot);

	* ~~~ First make sure that no duplicate (in variables by * pivot) is found in source data set ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;

	%if &npivot ne 1 %then %do;
		%put ERROR: [MultiTranspose] one and only one variable name must be given in *pivot* argument;
		%goto Farewell;
	%end;

	%let dsCandidateVarnames = %MultiTransposeNewDatasetName(candidatevarnames);
	%let ncandidatevars = %sysevalf(&nbyvars+2);

	data &dsCandidateVarnames;
		retain found 0;
		length vname $ 32;
		do i = 1 to &ncandidatevars;
			vname = cats("_", i);
			if vname not in (%MultiTransposeDQList(&by &pivot)) then do;
				if not found then output;
				found = 1;
			end;
		end;
	run;

	proc sql noprint;
		select strip(vname) into :tmpvar
		from &dsCandidateVarnames;
	quit;

	%let dsRowvarsFreq = %MultiTransposeNewDatasetName(rowvarsfreq);

	proc sql;
		create table &dsRowvarsFreq as
		select %MultiTransposeCommasep(&by &pivot), sum(1) as &tmpvar
		from &data
		%if &dropMissingPivot eq 1 %then %do;
			where not missing(&pivot)
		%end;
		group %MultiTransposeCommasep(&by &pivot)
		;
	quit;

	proc sql noprint;
		select max(&tmpvar) into :tmp
		from &dsRowvarsFreq;
	quit;
	proc datasets nolist; delete &dsCandidateVarnames &dsRowvarsFreq; quit;

	%if &tmp gt 1 %then %do;
		%put ERROR: [MultiTranspose] duplicates were found in data &data in variables (&by) * &pivot;
		%goto Farewell;
	%end;

	* ~~~ Now make sure that no duplicate (in by * copy) is found in source data set ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;

	%let ncopy = %MultiTransposeNTokens(&copy);

	%if &ncopy %then %do;
		%let dsCopiedVars = %MultiTransposeNewDatasetName(copiedvars);

		proc sql;
			create table &dsCopiedVars as
			select distinct %MultiTransposeCommasep(&by &copy)
			from &data;
		quit;

		proc sql;
			create table &dsRowvarsFreq as
			select %MultiTransposeCommasep(&by), sum(1) as &tmpvar
			from &dsCopiedVars
			group %MultiTransposeCommasep(&by);
		quit;

		proc sql noprint;
			select max(&tmpvar) into :tmp
			from &dsRowvarsFreq;
		quit;
		proc datasets nolist; delete &dsRowvarsFreq; quit;

		%if &tmp gt 1 %then %do;
			proc datasets nolist; delete &dsCopiedVars; quit;
			%put ERROR: [MultiTranspose] some copy variables (&copy) are not uniquely defined for some output data rows (defined by &by);
			%goto Farewell;
		%end;
	%end;

	* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;

	* Create &out, just to make sure it exists and its name is not recycled;
	data &out; stop; run;

	%let dsContents = %MultiTransposeNewDatasetName(contents);
	proc contents data=&data noprint out=&dsContents (keep=name label type format formatl); run;

	%let dsTmp = %MultiTransposeNewDatasetName(tmp);

	proc sql noprint;
		select compress(ifc(substr(format,1,1) eq "$", substr(format,2), format)), type eq 1, formatl, 
			format in ("DATE", "DDMMYY", "DDMMYYB", "DDMMYYC", "DDMMYYD", "DDMMYYN", "DDMMYYP", "DDMMYYS", "EURDFDE", "EURDFMY", "EURDFDMY", "EURDFWKX", 
							"JULIAN", "MINGUO", "MMDDYY", "MMDDYYB", "MMDDYYC", "MMDDYYD", "MMDDYYN", "MMDDYYP", "MMDDYYS", "MMYY", "MMYYC", "MMYYD", "MMYYN", "MMYYP", "MMYYS", 
							"MONYY", "NENGO", "PDJULG", "PDJULI", "WEEKDATE", "WORDDATE", "WORDDATX", 
							"YYMM", "YYMMC", "YYMMDD", "YYMMP", "YYMMS", "YYMMN", "YYMMDD", "YYMON", "YYQ", "YYQC", "YYQD", "YYQP", "YYQSYYQN", "YYQR", "YYQRC", "YYQRD", "YYQRP", "YYQRS")
			into :pivotfmt, :pivotIsNumeric, :formatl, :pivotIsDate
		from &dsContents
		where upcase(name) eq upcase("&pivot");
	quit;

	%if &pivotIsDate %then %do;
		%if &formatl eq 0 %then %let datefmt=&pivotfmt;
		%else %let datefmt=%sysfunc(compress(&pivotfmt.&formatl));
	%end;

	/* Pivot values */;

	%let dsPivotObsValues = %MultiTransposeNewDatasetName(obspivots);
	proc sql;
		create table &dsPivotObsValues as
		select distinct(&pivot) as PivotValue
		from &data
		%if &dropMissingPivot %then %do;
			where not missing(&pivot)
		%end;
		order &pivot;
	quit;

	data &dsPivotObsValues;
		set &dsPivotObsValues;
		PivotIndex = _N_;
	run;

	proc sql noprint;
		select N(PivotIndex) into :npivotvalues
		from &dsPivotObsValues;
	quit;

	/* Vars to transpose */;

	%let nvars = %MultiTransposeNTokens(&vars);

	%let dsTransposedVars = %MultiTransposeNewDatasetName(transposedvars);
	data &dsTransposedVars;
		length name $32;
		%do v = 1 %to &nvars;
			%let var = %scan(&vars, &v);
			name = "&var";
			output;
		%end;
	run;

	%let dsNewVars = %MultiTransposeNewDatasetName(newvars);

	%if &pivotIsNumeric %then %do;
		proc sql;
			create table &dsNewVars as
			select v.name, upcase(v.name) as ucname, s.PivotValue, s.PivotIndex,
				case
					when s.PivotValue eq . then	cats(v.name, "00")
					%if &pivotIsDate %then %do;
						else cats(v.name, compress(put(s.PivotValue, &datefmt..)))              
					%end;
					%else %do;
						else cats(v.name, s.PivotValue)
					%end;
				end as NewVar length=200
			from &dsTransposedVars as v, &dsPivotObsValues as s;
		quit;
	%end;
	%else %do;
		%if &UseNumericExt %then %do;
			proc sql;
				create table &dsNewVars as
				select v.name, upcase(v.name) as ucname, s.PivotValue, s.PivotIndex, cats(v.name, s.PivotIndex) as NewVar length=200
				from &dsTransposedVars as v, &dsPivotObsValues as s;
			quit;
		%end;
		%else %do;
			proc sql;
				create table &dsNewVars as
				select v.name, upcase(v.name) as ucname, s.PivotValue, s.PivotIndex, tranwrd(compbl(cats(v.name, s.PivotValue)), " ", "_") as NewVar length=200
				from &dsTransposedVars as v, &dsPivotObsValues as s;
			quit;
		%end;
	%end;	

	data &dsNewVars (drop=j);
		set &dsNewVars;

		j = notalnum(NewVar);
		do while(j gt 0 and j le length(NewVar));
			if		j gt 1		then NewVar = substr(NewVar, 1, j-1) || "_" || substr(NewVar, j+1);
			else	if j eq 1	then NewVar = "_" || substr(NewVar, 2);
			j = notalnum(NewVar, j+1);
		end;

		ucnewvar = upcase(NewVar);
	run;


	%let dsXtraVars = %MultiTransposeNewDatasetName(xtravars);
	data &dsXtraVars;
		length ucnewvar $ 200;
		%do i = 1 %to &nbyvars;
			%let xtravar = %scan(&by, &i);
			ucnewvar = strip(upcase("&xtravar"));
			output;
		%end;
		%do i = 1 %to &ncopy;
			%let xtravar = %scan(&copy, &i);
			ucnewvar = strip(upcase("&xtravar"));
			output;
		%end;
	run;

	%let dsNewVarsFreq = %MultiTransposeNewDatasetName(newvarsfreq);
	proc sql;
		create table &dsNewVarsFreq as
		select a.ucnewvar, N(a.ucnewvar) as f
		from
			(
				select ucnewvar from &dsNewVars
				outer union corresponding
				select ucnewvar from &dsXtraVars
			) as a
		group a.ucnewvar;
	quit;
	proc datasets nolist; delete &dsXtraVars; quit;

	proc sql noprint;
		select ucnewvar, N(ucnewvar) gt 0 into :multipdefnvars separated by ", ", :anyrepeatedvarname
		from &dsNewVarsFreq
		where f gt 1;
	quit;

	%if &anyrepeatedvarname %then %do;
		%put ERROR: [MultiTranspose] given the variables to transpose and the values taken by variable &pivot, 
			some variables created in transposed output data set (&multipdefnvars) would have ambiguous meanings: 
			please rename some of the variables to transpose prior to calling MultiTranspose again in order to avoid these ambiguities.; 
		proc datasets nolist; delete &out; quit;
		%goto ByeBye;
	%end;

	/* Pivot fmt values */;

	%let dsPivotLabels = %MultiTransposeNewDatasetName(pivotlabels);
	%let formattedPivot = 0;

	%if %length(&pivotfmt) %then %do;
		%if &pivotIsDate %then %do;
			%let formattedPivot = 1;
			%let anyfmtHigh = 0;
			%let anyfmtLow = 0;
			%let anyfmtOther = 0;

			proc sql;
				create table &dsPivotLabels as
				select PivotValue as start, PivotValue as end, compress(put(PivotValue, &datefmt..)) as Label
				from &dsPivotObsValues;
			quit;
		%end;
		%else %if %upcase("&library") eq "WORK" or %sysfunc(exist(&library..formats)) %then %do;
			%let formattedPivot = 1;
			proc format library=&library cntlout=&dsTmp; run;

			data &dsTmp;
				set &dsTmp;

				if upcase(fmtname) ne upcase("&pivotfmt") then delete;

				High = 0;
				Low = 0;
				Other = 0;

				if			upcase(HLO) eq "L"	then do;
					start	= "";
					Low = 1;
				end;
				else if	upcase(HLO) eq "H"	then do;
					end	= "";
					High = 1;
				end;
				else if	upcase(HLO) eq "O"	then do;
					start = "";
					end	= "";
					Other = 1;
				end;
			run; 

			%if &pivotIsNumeric %then %do;
				proc sql;
					create table &dsPivotLabels as
					select input(start, best32.) as start, input(end, best32.) as end, Label, High, Low, Other
					from &dsTmp;
				quit;
			%end;
			%else %do;
				proc sql;
					create table &dsPivotLabels as
					select start, end, Label, High, Low, Other
					from &dsTmp;
				quit;
			%end;

			proc sql noprint;
				select max(High), max(Low), max(Other) into :anyfmtHigh, :anyfmtLow, :anyfmtOther
				from &dsPivotLabels;
			quit;

			%if &anyfmtHigh %then %do;
				%let dsPivotLabelsHigh = %MultiTransposeNewDatasetName(pivotlabelshigh);
				proc sql;
					create table &dsPivotLabelsHigh as
					select start, Label
					from &dsPivotLabels
					where High eq 1;
					delete from &dsPivotLabels where High eq 1;
				quit;
			%end;

			%if &anyfmtLow %then %do;
				%let dsPivotLabelsLow = %MultiTransposeNewDatasetName(pivotlabelslow);
				proc sql;
					create table &dsPivotLabelsLow as
					select end, Label
					from &dsPivotLabels
					where Low eq 1;
					delete from &dsPivotLabels where Low eq 1;
				quit;
			%end;

			%if &anyfmtOther %then %do;
				%let dsPivotLabelsOther = %MultiTransposeNewDatasetName(pivotlabelsother);
				proc sql;
					create table &dsPivotLabelsOther as
					select Label
					from &dsPivotLabels
					where Other eq 1;
					delete from &dsPivotLabels where Other eq 1;
				quit;
			%end;

			proc datasets nolist; delete &dsTmp; quit;
		%end;
	%end;
	%else %do;
		proc sql;
			create table &dsPivotLabels as
			select PivotValue as start, PivotValue as end, "" as Label
			from &dsPivotObsValues;
		quit;
	%end;

	/* Transpose data, one pivot-value at a time */;

	%let dsLocalOut	= %MultiTransposeNewDatasetName(localout);
	%let dsTmpOut	= %MultiTransposeNewDatasetName(tmpout);

	%do s = 1 %to &npivotvalues;
		proc sql noprint;
			select name, NewVar, NewVar into :vars separated by ' ', :newvars separated by ' ', :ynewvars separated by ", y."
			from &dsNewVars
			where PivotIndex eq &s;
		quit;
		
		proc sql;
			create table &dsTmp as
			select %MultiTransposeCommasep4sql(d, &by)
			%do v = 1 %to &nvars;
				%let var = %scan(&vars, &v);
				%let newvar = %scan(&newvars, &v);
				, d.&var as &newvar
			%end;
			from &data as d, &dsPivotObsValues as s
			where d.&pivot eq s.PivotValue and s.PivotIndex eq &s;
		quit;

		%if &s eq 1 %then %do;
			proc datasets nolist; change &dsTmp=&dsLocalOut; quit;
			%let xnewvars=&newvars;
		%end;
		%else %do;
			proc sql;
				create table &dsTmpOut as
				select
					%do i = 1 %to &nbyvars;
						%let byvar = %scan(&by, &i);
						coalesce(x.&byvar, y.&byvar) as &byvar,
					%end;
					%MultiTransposeCommasep4sql(x, &xnewvars), y.&ynewvars
				from &dsLocalOut as x
				full join &dsTmp as y
				on
					%do i = 1 %to &nbyvars;
						%let byvar = %scan(&by, &i);
						%if &i gt 1 %then %do;
							and
						%end;
						x.&byvar eq y.&byvar
					%end;
					;
			quit;
			proc datasets nolist; delete &dsLocalOut; change &dsTmpOut=&dsLocalOut; quit;
			%let xnewvars=&xnewvars &newvars;
		%end;
	%end;


	%if &ncopy eq 0 %then %do;
		proc datasets nolist; delete &out; change &dsLocalOut=&out; quit;
	%end;
	%else %do;
		proc sql;
			create table &out as
			select t.*, %MultiTransposeCommasep4sql(c, &copy)
			from &dsLocalOut as t, &dsCopiedVars as c
			where
			%do i = 1 %to &nbyvars;
				%let byvar = %scan(&by, &i);
				%if &i gt 1 %then %do;
					and
				%end;
				t.&byvar eq c.&byvar
			%end;
			;
		quit;
		proc datasets nolist; delete &dsCopiedVars &dsLocalOut; quit;
	%end;
	

	/* Get variable labels */;

	proc sql;
		create table &dsTmp as
		select t.*, c.label
		from &dsTransposedVars as t, &dsContents as c
		where upcase(t.name) eq upcase(c.name);
	quit;

	proc sql noprint;
		select max(length(strip(label))), max(length(strip(name))), max(missing(label)) into :llabel, :lmax, :anymissinglabel
		from &dsTmp;
	quit;

	%if &anymissinglabel and &lmax gt &llabel %then %let llabel = &lmax;

	proc sql;
		create table &dsTransposedVars as
		select *, coalesce(strip(label), strip(name)) as newvarLabel
		from &dsTmp;
	quit;
	proc datasets nolist; delete &dsTmp; quit;


	* If  pivot is a formatted variable, get the formats for each of its values, else define a label as "pivot = Value";

	%if &formattedPivot %then %do;
		proc sql;
			create table &dsTmp as
			select s.PivotValue, s.PivotIndex, l.Label as PivotLabel
			from &dsPivotObsValues as s
			left join &dsPivotLabels as l
			on (missing(s.PivotValue) and s.PivotValue eq l.start) 
				or (not missing(s.PivotValue) and s.PivotValue ge l.start and s.PivotValue le l.end);
		quit;

		%if &anyfmtHigh %then %do;
			proc datasets nolist; delete &dsPivotObsValues; change &dsTmp=&dsPivotObsValues; quit;
			proc sql;
				create table &dsTmp as
				select s.PivotValue, s.PivotIndex, coalesce(s.Label, x.Label) as PivotLabel
				from &dsPivotObsValues as s
				left join &dsPivotLabelsHigh as x
				on s.PivotValue ge x.start;
			quit;
			proc datasets nolist; delete &dsPivotLabelsHigh; quit;
		%end;

		%if &anyfmtLow %then %do;
			proc datasets nolist; delete &dsPivotObsValues; change &dsTmp=&dsPivotObsValues; quit;
			proc sql;
				create table &dsTmp as
				select s.PivotValue, s.PivotIndex, coalesce(s.Label, x.Label) as PivotLabel
				from &dsPivotObsValues as s
				left join &dsPivotLabelsLow as x
				on s.PivotValue le x.end;
			quit;
			proc datasets nolist; delete &dsPivotLabelsLow; quit;
		%end;

		%if &anyfmtOther %then %do;
			proc datasets nolist; delete &dsPivotObsValues; change &dsTmp=&dsPivotObsValues; quit;
			proc sql;
				create table &dsTmp as
				select s.PivotValue, s.PivotIndex, coalesce(s.Label, x.Label) as PivotLabel
				from &dsPivotObsValues as s, &dsPivotLabelsOther as x;
			quit;
			proc datasets nolist; delete &dsPivotLabelsOther; quit;
		%end;
	%end;
	%else %do;
		proc sql;
			create table &dsTmp as
			select PivotValue, PivotIndex, "" as PivotLabel
			from &dsPivotObsValues;
		quit;
	%end;
	proc datasets nolist; delete &dsPivotObsValues; change &dsTmp=&dsPivotObsValues; quit;

	proc sql noprint;
		select N(PivotIndex) gt 0 into :anymissingpivotlabel
		from &dsPivotObsValues
		where missing(PivotLabel);
	quit;

	%if &anymissingpivotlabel %then %do;
		proc sql noprint;
			select max(length(PivotLabel)) into :lpivotlabel
			from &dsPivotObsValues;
		quit;

		%if &pivotIsNumeric %then %do;
			proc sql noprint;
				select max(length(strip(put(PivotValue, best32.)))) into :lpivotmylabel
				from &dsPivotObsValues;
			quit;
		%end;
		%else %do;
			proc sql noprint;
				select max(length(PivotValue)) into :lpivotmylabel
				from &dsPivotObsValues;
			quit;
		%end;

		%let lpivotmylabel = %sysevalf(3+&lpivotmylabel+%length(&pivot));
		%if &lpivotmylabel gt &lpivotlabel %then %let lpivotlabel = &lpivotmylabel;

		%if &pivotIsNumeric %then %do;
			proc sql;
				create table &dsTmp as
				select PivotValue, PivotIndex, coalesce(PivotLabel, catx(" = ", strip("&pivot"), strip(put(PivotValue, best32.)))) as PivotLabel length=&lpivotlabel
				from &dsPivotObsValues;
			quit;
		%end;
		%else %do;
			proc sql;
				create table &dsTmp as
				select PivotValue, PivotIndex, coalesce(PivotLabel, catx(" = ", strip("&pivot"), strip(PivotValue))) as PivotLabel length=&lpivotlabel
				from &dsPivotObsValues;
			quit;
		%end;
		proc datasets nolist; delete &dsPivotObsValues; change &dsTmp=&dsPivotObsValues; quit;
	%end;

	* Give new labels to new (transposed) variables;

	proc sql;
		create table &dsTmp as
		select n.newvar, t.newvarlabel, s.PivotLabel
		from &dsNewVars as n, &dsTransposedVars as t, &dsPivotObsValues as s
		where n.name eq t.name and n.PivotIndex eq s.PivotIndex;
	quit;
	proc datasets nolist; delete &dsNewVars; change &dsTmp=&dsNewVars; quit;

	proc sql noprint;
		select NewVar, N(NewVar) into :newvars separated by ' ', :nNewvars
		from &dsNewVars;
	quit;

	%do i = 1 %to &nNewvars;
		%let newvar = %scan(&newvars, &i);

		proc sql noprint;
			select catx(":: ", tranwrd(newvarLabel, '"', '""'), tranwrd(PivotLabel, '"', '""')) into :newlbl
			from &dsNewVars
			where NewVar eq "&newvar";
		quit;

		proc datasets nolist; 
			modify &out;
			label &newvar = "&newlbl";
		quit; 
	%end;

	* Put back format on by variables;

	%do i = 1 %to &nbyvars;
		%let byvar = %scan(&by, &i);
		%let byfmt=;
		%let bylbl=;
		proc sql noprint;
			select
				ifc(anyalnum(format) or formatl gt 0, cats(format, ifc(formatl gt 0, strip(put(formatl, 4.)), ""), "."), ""), 
				tranwrd(label, '"', '""')
				into :byfmt, :bylbl
			from &dsContents 
			where lowcase(name) eq lowcase("&byvar");
		quit;

		%if %length(&byfmt) or %length(&bylbl) %then %do;
			proc datasets nolist;
				modify &out;
				%if %length(&bylbl) %then %do;
					label &byvar = "&bylbl";
				%end;
				%if %length(&byfmt) %then %do;
					format &byvar &byfmt;
				%end;
			quit;
		%end;
	%end;

	proc datasets nolist; delete &dsPivotLabels; quit;

	%ByeBye:
	proc datasets nolist; delete &dsContents &dsNewVars &dsNewVarsFreq &dsPivotObsValues &dsTransposedVars; quit;
	%Farewell:
%mend;


%macro MultiTransposeCommasep(lov);
   %sysfunc(tranwrd(%Qsysfunc(compbl(%sysfunc(strip(&lov)))), %str( ), %str(, )))
%mend;


%macro MultiTransposeCommasep4sql(datasetindex, lov);
	&datasetindex..%sysfunc(tranwrd(%Qsysfunc(compbl(%sysfunc(strip(&lov)))), %str( ), %str(, &datasetindex..)))
%mend;


%macro MultiTransposeDQList(list);
	"%sysfunc(tranwrd(%sysfunc(compbl(&list)),%quote( ),%quote(", ")))"
%mend;


%macro MultiTransposeNewDatasetName(proposalname);
	%*Finds the first unused dataset named *datasetname*, adding a leading underscore and a numeric suffix as large as necessary to make it unique!;
	%local i newdatasetname;
	%let proposalname=%sysfunc(compress(&proposalname));
	%let newdatasetname=_&proposalname;

	%do %while(%sysfunc(exist(&newdatasetname)));
		%let i = %eval(&i+1);
		%let newdatasetname=_&proposalname&i;
	%end;

	&newdatasetname
%mend;


%macro MultiTransposeNTokens(list);
	%if %length(&list) %then %do;
		%eval(1 + %length(%sysfunc(compbl(&list))) - %length(%sysfunc(compress(&list))))
	%end;
	%else %do;
		0
	%end;
%mend;
