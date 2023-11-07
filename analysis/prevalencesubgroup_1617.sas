/*********************************************************************************************/
title1 'Exploring AD Incidence Definition';

* Author: PF;
* Purpose: Prevalence in 2016 and 2017 for each subgroup
	- 1 year snapshot
	- enrolled in year t
	- sample characteristics for the 2016 and 2017, pooled and separate
	- linear predict prevalence for unique sex, age, race and average CCI for ma Part D sample
	- adjusted to ma and Part D characteristics - rates of sex, age, and race;

options compress=yes nocenter ls=150 ps=200 errors=5 mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

options obs=max;

/**** By race ****/
%macro ffsprevbyrace;
%do yr=16 %to 17;
* Explore average cci for each subgroup in MA;

proc means data=ad.maptd_prev1yrv1617 noprint nway;
	where prev20&yr. ne .;
	class race_bg;
	var cci20&yr.;
	output out=ma_ccibyrace_prev&yr. mean()=cci;
run;

proc export data=ma_ccibyrace_prev&yr.
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ma_ccibyrace_prev&yr.";
run;

* Getting average cci for each subgroup;
proc means data=ad.ffsptd_prev1yrv1617 noprint nway;
	where prev20&yr. ne .;
	class race_bg;
	var cci20&yr.;
	output out=ffs_ccibyrace_prev&yr. mean()=cci;
run;

proc export data=ffs_ccibyrace_prev&yr.
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffs_ccibyrace_prev&yr.";
run;


data _null_;
	set ffs_ccibyrace_prev&yr.;
	if race_bg="1" then call symput("cciw&yr.",cci);
	if race_bg="2" then call symput("ccib&yr.",cci);
	if race_bg="3" then call symput("ccio&yr.",cci);
	if race_bg="4" then call symput("ccia&yr.",cci);
	if race_bg="5" then call symput("ccih&yr.",cci);
	if race_bg="6" then call symput("ccin&yr.",cci);
run;

* Updating the prediction dataset with the CCI for each subgroup;
data &tempwork..prevpredict&yr._byrace;
	set &tempwork..prevpredict&yr.;
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
data ffsptd_prev_pred&yr.byrace;
	set ffsptd_prev (in=a rename=(age_d20&yr._7074=age7074 age_d20&yr._7579=age7579 age_d20&yr._ge80=agege80 cci20&yr.=wgtcc)) &tempwork..prevpredict&yr._byrace (in=b);
	predict=b;
run;

%macro ffsprevbyrace_model(racevar);
ods output parameterestimates=prev&yr._ffsptd_linreg&racevar.;
proc reg data=ffsptd_prev_pred&yr.byrace;
	where (prev20&yr. ne . or predict=1) and &racevar.=1;
	model prev20&yr.=female age7074 age7579 agege80 wgtcc;
	output out=prev&yr._ffslinpredict&racevar. (where=(predict=1 and &racevar.=1) keep=female &racevar. age7074 age7579 agege80 wgtcc p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;

proc export data=prev&yr._ffsptd_linreg&racevar.
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="prev&yr._ffsptd_linreg&racevar.";
run;
%mend;

%ffsprevbyrace_model(race_dw);
%ffsprevbyrace_model(race_db);
%ffsprevbyrace_model(race_dh);
%ffsprevbyrace_model(race_da);
%ffsprevbyrace_model(race_dn);
%ffsprevbyrace_model(race_do);

%end;
%mend;

%ffsprevbyrace;

* Stack all the predictions together to weight by age and sex distribution in FFS;
data prev16_ffsptd_linpredictsubrace;
	set prev16_ffslinpredictrace:;
	array race [*] race_d:;
	do i=1 to dim(race);
		if race[i]=. then race[i]=0;
	end;
run;

data prev17_ffsptd_linpredictsubrace;
	set prev17_ffslinpredictrace:;
	array race [*] race_d:;
	do i=1 to dim(race);
		if race[i]=. then race[i]=0;
	end;
run;

proc sort data=prev16_ffsptd_linpredictsubrace;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
run;

proc sort data=prev17_ffsptd_linpredictsubrace;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
run;

/***** By Sex *****/
%macro ffsprevbysex;
%do yr=16 %to 17;
* Getting average cci for each subgroup;

proc means data=ad.ffsptd_prev1yrv1617 noprint nway;
	where prev20&yr. ne .;
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
data &tempwork..prevpredict&yr._bysex;
	set &tempwork..prevpredict&yr.;
	if female=1 then wgtcc=&&ccif&yr..;
	else if female=0 then wgtcc=&&ccim&yr..;
run;

* Running separate models for each subgroup;
data ffsptd_prev_pred&yr.bysex;
	set ffsptd_prev (in=a rename=(age_d20&yr._7074=age7074 age_d20&yr._7579=age7579 age_d20&yr._ge80=agege80 cci20&yr.=wgtcc)) &tempwork..prevpredict&yr._bysex (in=b);
	predict=b;
run;

%macro ffsprevbysex_model(sexval,out);
ods output parameterestimates=prev&yr._ffsptd_linreg&out.;
proc reg data=ffsptd_prev_pred&yr.bysex;
	where (prev20&yr. ne . or predict=1) and female=&sexval.;
	model prev20&yr.=race_db race_dh race_da race_dn race_do age7074 age7579 agege80 wgtcc;
	output out=prev&yr._ffslinpredict&out. (where=(predict=1 and female=&sexval.) keep=female race_db race_dh race_da race_dn race_do age7074 age7579 agege80 wgtcc p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;
proc export data=prev&yr._ffsptd_linreg&out.
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="prev&yr._ffsptd_linreg&out.";
run;
%mend;

%ffsprevbysex_model(0,sexm);
%ffsprevbysex_model(1,sexf);

%end;
%mend;

%ffsprevbysex;

* Stack all the predictions together to weight by age and sex distribution in FFS;
data prev16_ffsptd_linpredictsubsex;
	set prev16_ffslinpredictsex:;
run;

data prev17_ffsptd_linpredictsubsex;
	set prev17_ffslinpredictsex:;
run;

proc sort data=prev16_ffsptd_linpredictsubsex;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
run;

proc sort data=prev17_ffsptd_linpredictsubsex;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
run;

* Combine all the weights together;
data prev16_ffs_wsub;
	merge prev16_ffsptd_linpredictsubrace (in=a rename=(p=p_race wgtcc=wgtcc_race lclm=lcl_race uclm=ucl_race predict=predict_race))
		  prev16_ffsptd_linpredictsubsex (in=a rename=(p=p_sex wgtcc=wgtcc_sex lclm=lcl_sex uclm=ucl_sex predict=predict_sex))
		  &tempwork..ffsptd_weights16 (in=b rename=(age_d2016_ge80=agege80 age_d2016_7579=age7579 age_d2016_7074=age7074));
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

data prev17_ffs_wsub;
	merge prev17_ffsptd_linpredictsubrace (in=a rename=(p=p_race wgtcc=wgtcc_race lclm=lcl_race uclm=ucl_race predict=predict_race))
		  prev17_ffsptd_linpredictsubsex (in=a rename=(p=p_sex wgtcc=wgtcc_sex lclm=lcl_sex uclm=ucl_sex predict=predict_sex))
		  &tempwork..ffsptd_weights17 (in=b rename=(age_d2017_ge80=agege80 age_d2017_7579=age7579 age_d2017_7074=age7074));
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
data &tempwork..prev16_ffs_wsub;
	set prev16_ffs_wsub;
run;

data &tempwork..prev17_ffs_wsub;
	set prev17_ffs_wsub;
run;
*/

* Prevalence by race;
proc means data=prev16_ffs_wsub noprint nway;
	class race_bg;
	var p_race;
	output out=prev16_ffs_weightedsubrace sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=prev17_ffs_wsub noprint nway;
	class race_bg;
	var p_race;
	output out=prev17_ffs_weightedsubrace sum()= mean()= lclm()= uclm()= / autoname;
run;

proc export data=prev16_ffs_weightedsubrace
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subrace16";
run;

proc export data=prev17_ffs_weightedsubrace
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subrace17";
run;

* Prevalence by sex;
proc means data=prev16_ffs_wsub noprint nway;
	class female;
	var p_sex;
	output out=prev16_ffs_weightedsubsex sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=prev17_ffs_wsub noprint nway;
	class female;
	var p_sex;
	output out=prev17_ffs_weightedsubsex sum()= mean()= lclm()= uclm()= / autoname;
run;

proc export data=prev16_ffs_weightedsubsex
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subsex16";
run;

proc export data=prev17_ffs_weightedsubsex
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subsex17";
run;

/* T-test differences bewteen subgroups  - white reference */
%macro ffsprev_subracettest(raceval,out);
%do yr=16 %to 17;
ods output ConfLimits=ffsprev_subrace&yr._&out.ttest_ci;
ods output ttests=ffsprev_subrace&yr._&out.ttest;
proc ttest data=prev&yr._ffs_wsub;
	where race_bg in('1',"&raceval.");
	class race_bg;
	var p_race;
run;
%end;
%mend;

%ffsprev_subracettest(2,b);
%ffsprev_subracettest(3,o);
%ffsprev_subracettest(4,a);
%ffsprev_subracettest(5,h);
%ffsprev_subracettest(6,n);

* Stack all t-test results;
*16;
data ffsprev_subrace16_ttest_ci;
	set ffsprev_subrace16_bttest_ci (in=b)
		ffsprev_subrace16_httest_ci (in=h)
		ffsprev_subrace16_attest_ci (in=a)
		ffsprev_subrace16_nttest_ci (in=n)
		ffsprev_subrace16_ottest_ci (in=o);
	if b then race_bg='b';
	if h then race_bg='h';
	if a then race_bg='a';
	if n then race_bg='n';
	if o then race_bg='o';
run;

data ffsprev_subrace16_ttest;
	set ffsprev_subrace16_bttest (in=b)
		ffsprev_subrace16_httest (in=h)
		ffsprev_subrace16_attest (in=a)
		ffsprev_subrace16_nttest (in=n)
		ffsprev_subrace16_ottest (in=o);
	if b then race_bg='b';
	if h then race_bg='h';
	if a then race_bg='a';
	if n then race_bg='n';
	if o then race_bg='o';
run;

proc export data=ffsprev_subrace16_ttest_ci
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subrace16_ttest_ci";
run;

proc export data=ffsprev_subrace16_ttest
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subrace16_ttest";
run;

* 17;
data ffsprev_subrace17_ttest_ci;
	set ffsprev_subrace17_bttest_ci (in=b)
		ffsprev_subrace17_httest_ci (in=h)
		ffsprev_subrace17_attest_ci (in=a)
		ffsprev_subrace17_nttest_ci (in=n)
		ffsprev_subrace17_ottest_ci (in=o);
	if b then race_bg='b';
	if h then race_bg='h';
	if a then race_bg='a';
	if n then race_bg='n';
	if o then race_bg='o';
run;

data ffsprev_subrace17_ttest;
	set ffsprev_subrace17_bttest (in=b)
		ffsprev_subrace17_httest (in=h)
		ffsprev_subrace17_attest (in=a)
		ffsprev_subrace17_nttest (in=n)
		ffsprev_subrace17_ottest (in=o);
	if b then race_bg='b';
	if h then race_bg='h';
	if a then race_bg='a';
	if n then race_bg='n';
	if o then race_bg='o';
run;

proc export data=ffsprev_subrace17_ttest_ci
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subrace17_ttest_ci";
run;

proc export data=ffsprev_subrace17_ttest
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subrace17_ttest";
run;

* T-test for sex;
ods output ConfLimits=ffsprev_subsex16_ttest_ci;
ods output ttests=ffsprev_subsex16_ttest;
proc ttest data=prev16_ffs_wsub;
	class female;
	var p_sex;
run;
	
ods output ConfLimits=ffsprev_subsex17_ttest_ci;
ods output ttests=ffsprev_subsex17_ttest;
proc ttest data=prev17_ffs_wsub;
	class female;
	var p_sex;
run;

proc export data=ffsprev_subsex16_ttest_ci
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subsex16_ttest_ci";
run;

proc export data=ffsprev_subsex16_ttest
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subsex16_ttest";
run;

proc export data=ffsprev_subsex17_ttest_ci
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subsex17_ttest_ci";
run;

proc export data=ffsprev_subsex17_ttest
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subsex17_ttest";
run;




