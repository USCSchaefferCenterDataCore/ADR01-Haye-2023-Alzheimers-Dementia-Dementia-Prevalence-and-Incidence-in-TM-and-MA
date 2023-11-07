/*********************************************************************************************/
title1 'Exploring AD Incidence Definition';

* Author: PF;
* Purpose: incidence in 2016 and 2017 for each subgroup
	- 1 year snapshot
	- enrolled in year t
	- sample characteristics for the 2016 and 2017, pooled and separate
	- linear predict incidence for unique sex, age, race and average CCI for ma Part D sample
	- adjusted to ma and Part D characteristics - rates of sex, age, and race;

options compress=yes nocenter ls=150 ps=200 errors=5 mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

options obs=max;

/**** By race ****/
%macro maincbyrace;
%do yr=16 %to 17;

* Explore average cci for each subgroup in MA;
proc means data=ad.maptd_inc1yrv1617 noprint nway;
	where inc20&yr. ne .;
	class race_bg;
	var cci20&yr.;
	output out=ma_ccibyrace_inc&yr. mean()=cci;
run;

* Getting average cci for each subgroup;
proc means data=ad.ffsptd_inc1yrv1617 noprint nway;
	where inc20&yr. ne .;
	class race_bg;
	var cci20&yr.;
	output out=ffs_ccibyrace_inc&yr. mean()=cci;
run;

data _null_;
	set ffs_ccibyrace_inc&yr.;
	if race_bg="1" then call symput("cciw&yr.",cci);
	if race_bg="2" then call symput("ccib&yr.",cci);
	if race_bg="3" then call symput("ccio&yr.",cci);
	if race_bg="4" then call symput("ccia&yr.",cci);
	if race_bg="5" then call symput("ccih&yr.",cci);
	if race_bg="6" then call symput("ccin&yr.",cci);
run;

* Updating the prediction dataset with the CCI for each subgroup;
data &tempwork..incpredict&yr._byrace;
	set &tempwork..incpredict&yr.;
	race_dw=0;
	if race_db=1 then wgtcc=&&ccib&yr..;
	else if race_dh=1 then wgtcc=&&ccih&yr..;
	else if race_da=1 then wgtcc=&&ccia&yr..;
	else if race_dn=1 then wgtcc=&&ccin&yr..;
	else if race_do=1 then wgtcc=&&ccio&yr..;
	else do;
		race_dw=1;
		wgtcc=&&cciw&yr..;
	end;
run;

* Running separate models for each subgroup;
data maptd_inc_pred&yr.byrace;
	set maptd_inc (in=a rename=(age_d20&yr._7074=age7074 age_d20&yr._7579=age7579 age_d20&yr._ge80=agege80 cci20&yr.=wgtcc)) &tempwork..incpredict&yr._byrace (in=b);
	predict=b;
run;

%macro maincbyrace_model(racevar);
ods output parameterestimates=inc&yr._maptd_linreg&racevar.;
proc reg data=maptd_inc_pred&yr.byrace;
	where (inc20&yr. ne . or predict=1) and &racevar.=1;
	model inc20&yr.=female age7074 age7579 agege80 wgtcc;
	output out=inc&yr._malinpredict&racevar. (where=(predict=1 and &racevar.=1) keep=female &racevar. age7074 age7579 agege80 wgtcc p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;

proc export data=inc&yr._maptd_linreg&racevar.
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="inc&yr._maptd_linreg&racevar.";
run;
%mend;

%maincbyrace_model(race_dw);
%maincbyrace_model(race_db);
%maincbyrace_model(race_dh);
%maincbyrace_model(race_da);
%maincbyrace_model(race_dn);
%maincbyrace_model(race_do);

%end;
%mend;

%maincbyrace;

* Stack all the predictions together to weight by age and sex distribution in FFS;
data inc16_maptd_linpredictsubrace;
	set inc16_malinpredictrace:;
	array race [*] race_d:;
	do i=1 to dim(race);
		if race[i]=. then race[i]=0;
	end;
run;

data inc17_maptd_linpredictsubrace;
	set inc17_malinpredictrace:;
	array race [*] race_d:;
	do i=1 to dim(race);
		if race[i]=. then race[i]=0;
	end;
run;

proc sort data=inc16_maptd_linpredictsubrace;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
run;

proc sort data=inc17_maptd_linpredictsubrace;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
run;

/***** By Sex *****/
%macro maincbysex;
%do yr=16 %to 17;

* Getting average cci for each subgroup;
proc means data=ad.ffsptd_inc1yrv1617 noprint nway;
	where inc20&yr. ne .;
	class female;
	var cci20&yr.;
	output out=ffs_ccibysex mean()=cci;
run;

data _null_;
	set ffs_ccibysex;
	if female=0 then call symput("ccim&yr.",cci);
	if female=1 then call symput("ccif&yr.",cci);
run;

* Updating the prediction dataset with the CCI for each subgroup;
data &tempwork..incpredict&yr._bysex;
	set &tempwork..incpredict&yr.;
	if female=1 then wgtcc=&&ccif&yr..;
	else if female=0 then wgtcc=&&ccim&yr..;
run;

* Running separate models for each subgroup;
data maptd_inc_pred&yr.bysex;
	set maptd_inc (in=a rename=(age_d20&yr._7074=age7074 age_d20&yr._7579=age7579 age_d20&yr._ge80=agege80 cci20&yr.=wgtcc)) &tempwork..incpredict&yr._bysex (in=b);
	predict=b;
run;

%macro maincbysex_model(sexval,out);
ods output parameterestimates=inc&yr._maptd_linreg&sexval.;
proc reg data=maptd_inc_pred&yr.bysex;
	where (inc20&yr. ne . or predict=1) and female=&sexval.;
	model inc20&yr.=race_db race_dh race_da race_dn race_do age7074 age7579 agege80 wgtcc;
	output out=inc&yr._malinpredict&out. (where=(predict=1 and female=&sexval.) keep=female race_db race_dh race_da race_dn race_do age7074 age7579 agege80 wgtcc p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;

proc export data=inc&yr._maptd_linreg&sexval.
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="inc&yr._maptd_linreg&sexval.";
run;
%mend;

%maincbysex_model(0,sexm);
%maincbysex_model(1,sexf);

%end;
%mend;

%maincbysex;

* Stack all the predictions together to weight by age and sex distribution in FFS;
data inc16_maptd_linpredictsubsex;
	set inc16_malinpredictsex:;
run;

data inc17_maptd_linpredictsubsex;
	set inc17_malinpredictsex:;
run;

proc sort data=inc16_maptd_linpredictsubsex;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
run;

proc sort data=inc17_maptd_linpredictsubsex;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
run;

* Combine all the weights together;
data inc16_ma_wsub;
	merge inc16_maptd_linpredictsubrace (in=a rename=(p=p_race wgtcc=wgtcc_race lclm=lcl_race uclm=ucl_race predict=predict_race))
		  inc16_maptd_linpredictsubsex (in=a rename=(p=p_sex wgtcc=wgtcc_sex lclm=lcl_sex uclm=ucl_sex predict=predict_sex))
		  &tempwork..ffsptd_incweights16 (in=b rename=(age_d2016_ge80=agege80 age_d2016_7579=age7579 age_d2016_7074=age7074));
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
	if age7074 then age_groupa="2. 70-74";
	else if age7579 then age_groupa="2. 75-89";
	else if agege80 then age_groupa="3. 80+";
	else age_groupa="1. <70";
	if race_db=1 then race_bg='2';
	else if race_dh=1 then race_bg='5';
	else if race_da=1 then race_bg='4';
	else if race_dn=1 then race_bg='6';
	else if race_do=1 then race_bg='3';
	else race_bg='1';
	if count ne . then do i=1 to count;
		output;
	end;
run;

data inc17_ma_wsub;
	merge inc17_maptd_linpredictsubrace (in=a rename=(p=p_race wgtcc=wgtcc_race lclm=lcl_race uclm=ucl_race predict=predict_race))
		  inc17_maptd_linpredictsubsex (in=a rename=(p=p_sex wgtcc=wgtcc_sex lclm=lcl_sex uclm=ucl_sex predict=predict_sex))
		  &tempwork..ffsptd_incweights17 (in=b rename=(age_d2017_ge80=agege80 age_d2017_7579=age7579 age_d2017_7074=age7074));
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
	if age7074 then age_groupa="2. 70-74";
	else if age7579 then age_groupa="2. 75-89";
	else if agege80 then age_groupa="3. 80+";
	else age_groupa="1. <70";
	if race_db=1 then race_bg='2';
	else if race_dh=1 then race_bg='5';
	else if race_da=1 then race_bg='4';
	else if race_dn=1 then race_bg='6';
	else if race_do=1 then race_bg='3';
	else race_bg='1';
	if count ne . then do i=1 to count;
		output;
	end;
run;

/* Create perm 
data &tempwork..inc16_ma_wsub;
	set inc16_ma_wsub;
run;

data &tempwork..inc17_ma_wsub;
	set inc17_ma_wsub;
run;
*/

* incidence by race;
proc means data=inc16_ma_wsub noprint nway;
	class race_bg;
	var p_race;
	output out=inc16_ma_weightedsubrace sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=inc17_ma_wsub noprint nway;
	class race_bg;
	var p_race;
	output out=inc17_ma_weightedsubrace sum()= mean()= lclm()= uclm()= / autoname;
run;

proc export data=inc16_ma_weightedsubrace
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="mainc_subrace16";
run;

proc export data=inc17_ma_weightedsubrace
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="mainc_subrace17";
run;

* incidence by sex;
proc means data=inc16_ma_wsub noprint nway;
	class female;
	var p_sex;
	output out=inc16_ma_weightedsubsex sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=inc17_ma_wsub noprint nway;
	class female;
	var p_sex;
	output out=inc17_ma_weightedsubsex sum()= mean()= lclm()= uclm()= / autoname;
run;

proc export data=inc16_ma_weightedsubsex
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="mainc_subsex16";
run;

proc export data=inc17_ma_weightedsubsex
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="mainc_subsex17";
run;

/* T-test within group differences */
%macro mainc_subracettest(raceval,out);
%do yr=16 %to 17;
ods output ConfLimits=mainc_subrace&yr._&out.ttest_ci;
ods output ttests=mainc_subrace&yr._&out.ttest;
proc ttest data=inc&yr._ma_wsub;
	where race_bg in('1',"&raceval.");
	class race_bg;
	var p_race;
run;
%end;
%mend;

%mainc_subracettest(2,b);
%mainc_subracettest(3,o);
%mainc_subracettest(4,a);
%mainc_subracettest(5,h);
%mainc_subracettest(6,n);

* Stack all t-test results;
*16;
data mainc_subrace16_ttest_ci;
	set mainc_subrace16_bttest_ci (in=b)
		mainc_subrace16_httest_ci (in=h)
		mainc_subrace16_attest_ci (in=a)
		mainc_subrace16_nttest_ci (in=n)
		mainc_subrace16_ottest_ci (in=o);
	if b then race_bg='b';
	if h then race_bg='h';
	if a then race_bg='a';
	if n then race_bg='n';
	if o then race_bg='o';
run;

data mainc_subrace16_ttest;
	set mainc_subrace16_bttest (in=b)
		mainc_subrace16_httest (in=h)
		mainc_subrace16_attest (in=a)
		mainc_subrace16_nttest (in=n)
		mainc_subrace16_ottest (in=o);
	if b then race_bg='b';
	if h then race_bg='h';
	if a then race_bg='a';
	if n then race_bg='n';
	if o then race_bg='o';
run;

proc export data=mainc_subrace16_ttest_ci
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="mainc_subrace16_ttest_ci";
run;

proc export data=mainc_subrace16_ttest
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="mainc_subrace16_ttest";
run;

* 17;
data mainc_subrace17_ttest_ci;
	set mainc_subrace17_bttest_ci (in=b)
		mainc_subrace17_httest_ci (in=h)
		mainc_subrace17_attest_ci (in=a)
		mainc_subrace17_nttest_ci (in=n)
		mainc_subrace17_ottest_ci (in=o);
	if b then race_bg='b';
	if h then race_bg='h';
	if a then race_bg='a';
	if n then race_bg='n';
	if o then race_bg='o';
run;

data mainc_subrace17_ttest;
	set mainc_subrace17_bttest (in=b)
		mainc_subrace17_httest (in=h)
		mainc_subrace17_attest (in=a)
		mainc_subrace17_nttest (in=n)
		mainc_subrace17_ottest (in=o);
	if b then race_bg='b';
	if h then race_bg='h';
	if a then race_bg='a';
	if n then race_bg='n';
	if o then race_bg='o';
run;

proc export data=mainc_subrace17_ttest_ci
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="mainc_subrace17_ttest_ci";
run;

proc export data=mainc_subrace17_ttest
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="mainc_subrace17_ttest";
run;

* T-test for sex;
ods output ConfLimits=mainc_subsex16_ttest_ci;
ods output ttests=mainc_subsex16_ttest;
proc ttest data=inc16_ma_wsub;
	class female;
	var p_sex;
run;
	
ods output ConfLimits=mainc_subsex17_ttest_ci;
ods output ttests=mainc_subsex17_ttest;
proc ttest data=inc17_ma_wsub;
	class female;
	var p_sex;
run;

proc export data=mainc_subsex16_ttest_ci
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="mainc_subsex16_ttest_ci";
run;

proc export data=mainc_subsex16_ttest
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="mainc_subsex16_ttest";
run;

proc export data=mainc_subsex17_ttest_ci
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="mainc_subsex17_ttest_ci";
run;

proc export data=mainc_subsex17_ttest
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="mainc_subsex17_ttest";
run;











