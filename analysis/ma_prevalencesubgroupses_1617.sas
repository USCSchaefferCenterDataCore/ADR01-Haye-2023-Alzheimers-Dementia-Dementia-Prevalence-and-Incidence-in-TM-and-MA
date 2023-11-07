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
/***** Add SES to subgroup analysis *****/
%macro mapredictses;
%do yr=16 %to 17;
data maptd_prev_pred&yr.byraceses;
	set maptd_prev (in=a rename=(age_d20&yr._7074=age7074 age_d20&yr._7579=age7579 age_d20&yr._ge80=agege80 cci20&yr.=wgtcc dual20&yr.=dual lis20&yr.=lis)) &tempwork..prevpredict&yr._byraceses (in=b);
	predict=b;
run;
%end;
%mend;

%mapredictses;

%macro maprevbyrace_modelses(racevar);
%do yr=16 %to 17;
ods output parameterestimates=prev&yr._maptd_linregses&racevar.;
proc reg data=maptd_prev_pred&yr.byraceses;
	where (prev20&yr. ne . or predict=1) and &racevar.=1;
	model prev20&yr.=female age7074 age7579 agege80 wgtcc dual lis;
	output out=prev&yr._malinpredses&racevar. (where=(predict=1 and &racevar.=1) keep=female &racevar. age7074 age7579 agege80 wgtcc dual lis p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;

proc export data=prev&yr._maptd_linregses&racevar.
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="prev&yr._maptd_linregses&racevar.";
run;
%end;
%mend;

%maprevbyrace_modelses(race_dw);
%maprevbyrace_modelses(race_db);
%maprevbyrace_modelses(race_dh);
%maprevbyrace_modelses(race_da);
%maprevbyrace_modelses(race_dn);
%maprevbyrace_modelses(race_do);

* Stack all the predictions together to weight by age and sex distribution in ma;
data prev16_maptd_linpredsubraceses;
	set prev16_malinpredses:;
	array race [*] race_d:;
	do i=1 to dim(race);
		if race[i]=. then race[i]=0;
	end;
run;

data prev17_maptd_linpredsubraceses;
	set prev17_malinpredses:;
	array race [*] race_d:;
	do i=1 to dim(race);
		if race[i]=. then race[i]=0;
	end;
run;

proc sort data=prev16_maptd_linpredsubraceses;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db dual lis;
run;

proc sort data=prev17_maptd_linpredsubraceses;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db dual lis;
run;


/***** By Sex *****/
%macro maprevbysexses;
%do yr=16 %to 17;
* Running separate models for each subgroup;
data maptd_prev_pred&yr.bysexses;
	set maptd_prev (in=a rename=(age_d20&yr._7074=age7074 age_d20&yr._7579=age7579 age_d20&yr._ge80=agege80 cci20&yr.=wgtcc dual20&yr.=dual lis20&yr.=lis)) &tempwork..prevpredict&yr._bysexses (in=b);
	predict=b;
run;

%macro maprevbysex_modelses(sexval,out);
ods output parameterestimates=prev&yr._maptd_linregses&out.;
proc reg data=maptd_prev_pred&yr.bysexses;
	where (prev20&yr. ne . or predict=1) and female=&sexval.;
	model prev20&yr.=race_db race_dh race_da race_dn race_do age7074 age7579 agege80 wgtcc dual lis;
	output out=prev&yr._malinpredses&out. (where=(predict=1 and female=&sexval.) keep=female race_db race_dh race_da race_dn race_do age7074 age7579 agege80 wgtcc dual lis p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;
proc export data=prev&yr._maptd_linregses&out.
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="prev&yr._maptd_linregses&out.";
run;
%mend;

%maprevbysex_modelses(0,sexm);
%maprevbysex_modelses(1,sexf);

%end;
%mend;

%maprevbysexses;

* Stack all the predictions together to weight by age and sex distribution in ma;
data prev16_maptd_linpredsubsexses;
	set prev16_malinpredsessex:;
run;

data prev17_maptd_linpredsubsexses;
	set prev17_malinpredsessex:;
run;

proc sort data=prev16_maptd_linpredsubsexses;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db dual lis;
run;

proc sort data=prev17_maptd_linpredsubsexses;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db dual lis;
run;

* Combine all the weights together;
data prev16_ma_wsubses;
	merge prev16_maptd_linpredsubraceses (in=a rename=(p=p_race wgtcc=wgtcc_race lclm=lcl_race uclm=ucl_race predict=predict_race))
		  prev16_maptd_linpredsubsexses (in=a rename=(p=p_sex wgtcc=wgtcc_sex lclm=lcl_sex uclm=ucl_sex predict=predict_sex))
		  &tempwork..ffsptd_weights16ses (in=b rename=(age_d2016_ge80=agege80 age_d2016_7579=age7579 age_d2016_7074=age7074 dual2016=dual lis2016=lis));
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db dual lis;
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

data prev17_ma_wsubses;
	merge prev17_maptd_linpredsubraceses (in=a rename=(p=p_race wgtcc=wgtcc_race lclm=lcl_race uclm=ucl_race predict=predict_race))
		  prev17_maptd_linpredsubsexses (in=a rename=(p=p_sex wgtcc=wgtcc_sex lclm=lcl_sex uclm=ucl_sex predict=predict_sex))
		  &tempwork..ffsptd_weights17ses (in=b rename=(age_d2017_ge80=agege80 age_d2017_7579=age7579 age_d2017_7074=age7074 dual2017=dual lis2017=lis));
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db dual lis;
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

 *Create perm; 
data &tempwork..prev16_ma_wsubses;
	set prev16_ma_wsubses;
run;

data &tempwork..prev17_ma_wsubses;
	set prev17_ma_wsubses;
run;

* Prevalence by race;
proc means data=prev16_ma_wsubses noprint nway;
	class race_bg;
	var p_race;
	output out=prev16_ma_weightedsubraceses sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=prev17_ma_wsubses noprint nway;
	class race_bg;
	var p_race;
	output out=prev17_ma_weightedsubraceses sum()= mean()= lclm()= uclm()= / autoname;
run;

proc export data=prev16_ma_weightedsubraceses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="maprev_subraceses16";
run;

proc export data=prev17_ma_weightedsubraceses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="maprev_subraceses17";
run;

* Prevalence by sex;
proc means data=prev16_ma_wsubses noprint nway;
	class female;
	var p_sex;
	output out=prev16_ma_weightedsubsexses sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=prev17_ma_wsubses noprint nway;
	class female;
	var p_sex;
	output out=prev17_ma_weightedsubsexses sum()= mean()= lclm()= uclm()= / autoname;
run;

proc export data=prev16_ma_weightedsubsexses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="maprev_subsexses16";
run;

proc export data=prev17_ma_weightedsubsexses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="maprev_subsexses17";
run;

/* T-test differences bewteen subgroups  - white reference */
%macro maprev_subracettest(raceval,out);
%do yr=16 %to 17;
ods output ConfLimits=maprev_subrace&yr._&out.ttest_cises;
ods output ttests=maprev_subrace&yr._&out.ttestses;
proc ttest data=prev&yr._ma_wsubses;
	where race_bg in('1',"&raceval.");
	class race_bg;
	var p_race;
run;
%end;
%mend;

%maprev_subracettest(2,b);
%maprev_subracettest(3,o);
%maprev_subracettest(4,a);
%maprev_subracettest(5,h);
%maprev_subracettest(6,n);

* Stack all t-test results;
*16;
data maprev_subrace16_ttest_cises;
	set maprev_subrace16_bttest_cises (in=b)
		maprev_subrace16_httest_cises (in=h)
		maprev_subrace16_attest_cises (in=a)
		maprev_subrace16_nttest_cises (in=n)
		maprev_subrace16_ottest_cises(in=o);
	if b then race_bg='b';
	if h then race_bg='h';
	if a then race_bg='a';
	if n then race_bg='n';
	if o then race_bg='o';
run;

data maprev_subrace16_ttestses;
	set maprev_subrace16_bttestses (in=b)
		maprev_subrace16_httestses (in=h)
		maprev_subrace16_attestses (in=a)
		maprev_subrace16_nttestses (in=n)
		maprev_subrace16_ottestses (in=o);
	if b then race_bg='b';
	if h then race_bg='h';
	if a then race_bg='a';
	if n then race_bg='n';
	if o then race_bg='o';
run;

proc export data=maprev_subrace16_ttest_cises
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="maprev_subrace16_ttest_cises";
run;

proc export data=maprev_subrace16_ttestses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="maprev_subrace16_ttestses";
run;

* 17;
data maprev_subrace17_ttest_cises;
	set maprev_subrace17_bttest_cises (in=b)
		maprev_subrace17_httest_cises (in=h)
		maprev_subrace17_attest_cises (in=a)
		maprev_subrace17_nttest_cises (in=n)
		maprev_subrace17_ottest_cises (in=o);
	if b then race_bg='b';
	if h then race_bg='h';
	if a then race_bg='a';
	if n then race_bg='n';
	if o then race_bg='o';
run;

data maprev_subrace17_ttestses;
	set maprev_subrace17_bttestses (in=b)
		maprev_subrace17_httestses (in=h)
		maprev_subrace17_attestses (in=a)
		maprev_subrace17_nttestses (in=n)
		maprev_subrace17_ottestses (in=o);
	if b then race_bg='b';
	if h then race_bg='h';
	if a then race_bg='a';
	if n then race_bg='n';
	if o then race_bg='o';
run;

proc export data=maprev_subrace17_ttest_cises
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="maprev_subrace17_ttest_cises";
run;

proc export data=maprev_subrace17_ttestses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="maprev_subrace17_ttestses";
run;

* T-test for sex;
ods output ConfLimits=maprev_subsex16_ttest_cises;
ods output ttests=maprev_subsex16_ttestses;
proc ttest data=prev16_ma_wsubses;
	class female;
	var p_sex;
run;
	
ods output ConfLimits=maprev_subsex17_ttest_cises;
ods output ttests=maprev_subsex17_ttestses;
proc ttest data=prev17_ma_wsubses;
	class female;
	var p_sex;
run;

proc export data=maprev_subsex16_ttest_cises
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="maprev_subsex16_ttest_cises";
run;

proc export data=maprev_subsex16_ttestses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="maprev_subsex16_ttestses";
run;

proc export data=maprev_subsex17_ttest_cises
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="maprev_subsex17_ttest_cises";
run;

proc export data=maprev_subsex17_ttestses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="maprev_subsex17_ttestses";
run;

