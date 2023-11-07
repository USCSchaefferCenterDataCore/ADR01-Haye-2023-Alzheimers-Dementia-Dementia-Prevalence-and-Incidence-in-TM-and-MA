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
%macro predictses;
%do yr=16 %to 17;
* Getting average cci for each subgroup;
proc means data=ad.ffsptd_prev1yrv1617 noprint nway;
	where prev20&yr. ne .;
	class race_bg;
	var cci20&yr.;
	output out=ffs_ccibyrace_prev&yr. mean()=cci;
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

data &tempwork..prevpredict&yr._byraceses;
	set &tempwork..prevpredict&yr._byrace (in=dual1lis1)
		&tempwork..prevpredict&yr._byrace (in=dual0lis0)
		&tempwork..prevpredict&yr._byrace (in=dual1lis0)
		&tempwork..prevpredict&yr._byrace (in=dual0lis1);
	if dual1lis1 then do;
		dual=1;
		lis=1;
	end;
	if dual0lis0 then do;
		dual=0;
		lis=0;
	end;
	if dual1lis0 then do;
		dual=1;
		lis=0;
	end;
	if dual0lis1 then do;
		dual=0;
		lis=1;
	end;
run;

data ffsptd_prev_pred&yr.byraceses;
	set ad.ffsptd_prev1yrv1617 (in=a rename=(age_d20&yr._7074=age7074 age_d20&yr._7579=age7579 age_d20&yr._ge80=agege80 cci20&yr.=wgtcc dual20&yr.=dual lis20&yr.=lis)) &tempwork..prevpredict&yr._byraceses (in=b);
	predict=b;
run;
%end;
%mend;

%predictses;

%macro ffsprevbyrace_modelses(racevar);
%do yr=16 %to 17;
ods output parameterestimates=prev&yr._ffsptd_linregses&racevar.;
proc reg data=ffsptd_prev_pred&yr.byraceses;
	where (prev20&yr. ne . or predict=1) and &racevar.=1;
	model prev20&yr.=female age7074 age7579 agege80 wgtcc dual lis;
	output out=prev&yr._ffslinpredses&racevar. (where=(predict=1 and &racevar.=1) keep=female &racevar. age7074 age7579 agege80 wgtcc dual lis p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;

proc export data=prev&yr._ffsptd_linregses&racevar.
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="prev&yr._ffsptd_linregses&racevar.";
run;
%end;
%mend;

%ffsprevbyrace_modelses(race_dw);
%ffsprevbyrace_modelses(race_db);
%ffsprevbyrace_modelses(race_dh);
%ffsprevbyrace_modelses(race_da);
%ffsprevbyrace_modelses(race_dn);
%ffsprevbyrace_modelses(race_do);

* Stack all the predictions together to weight by age and sex distribution in FFS;
data prev16_ffsptd_linpredsubraceses;
	set prev16_ffslinpredses:;
	array race [*] race_d:;
	do i=1 to dim(race);
		if race[i]=. then race[i]=0;
	end;
run;

data prev17_ffsptd_linpredsubraceses;
	set prev17_ffslinpredses:;
	array race [*] race_d:;
	do i=1 to dim(race);
		if race[i]=. then race[i]=0;
	end;
run;

proc sort data=prev16_ffsptd_linpredsubraceses;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db dual lis;
run;

proc sort data=prev17_ffsptd_linpredsubraceses;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db dual lis;
run;


/***** By Sex *****/
%macro ffsprevbysexses;
%do yr=16 %to 17;
* Getting average cci for each subgroup;
proc means data=ad.ffsptd_prev1yrv1617 noprint nway;
	where prev20&yr. ne .;
	class female;
	var cci20&yr.;
	output out=ffs_ccibysex&yr. mean()=cci;
run;

data _null_;
	set ffs_ccibysex&yr.;
	if female=0 then call symput("ccim&yr.",cci);
	if female=1 then call symput("ccif&yr.",cci);
run;

* Updating the prediction dataset with the CCI for each subgroup;
data &tempwork..prevpredict&yr._bysex;
	set &tempwork..prevpredict&yr.;
	if female=1 then wgtcc=&&ccif&yr..;
	else if female=0 then wgtcc=&&ccim&yr..;
run;

data &tempwork..prevpredict&yr._bysexses;
	set &tempwork..prevpredict&yr._bysex (in=dual1lis1)
		&tempwork..prevpredict&yr._bysex (in=dual0lis0)
		&tempwork..prevpredict&yr._bysex (in=dual1lis0)
		&tempwork..prevpredict&yr._bysex (in=dual0lis1);
	if dual1lis1 then do;
		dual=1;
		lis=1;
	end;
	if dual0lis0 then do;
		dual=0;
		lis=0;
	end;
	if dual1lis0 then do;
		dual=1;
		lis=0;
	end;
	if dual0lis1 then do;
		dual=0;
		lis=1;
	end;
run;

* Running separate models for each subgroup;
data ffsptd_prev_pred&yr.bysexses;
	set ffsptd_prev (in=a rename=(age_d20&yr._7074=age7074 age_d20&yr._7579=age7579 age_d20&yr._ge80=agege80 cci20&yr.=wgtcc dual20&yr.=dual lis20&yr.=lis)) &tempwork..prevpredict&yr._bysexses (in=b);
	predict=b;
run;

%macro ffsprevbysex_modelses(sexval,out);
ods output parameterestimates=prev&yr._ffsptd_linregses&out.;
proc reg data=ffsptd_prev_pred&yr.bysexses;
	where (prev20&yr. ne . or predict=1) and female=&sexval.;
	model prev20&yr.=race_db race_dh race_da race_dn race_do age7074 age7579 agege80 wgtcc dual lis;
	output out=prev&yr._ffslinpredses&out. (where=(predict=1 and female=&sexval.) keep=female race_db race_dh race_da race_dn race_do age7074 age7579 agege80 wgtcc dual lis p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;
proc export data=prev&yr._ffsptd_linregses&out.
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="prev&yr._ffsptd_linregses&out.";
run;
%mend;

%ffsprevbysex_modelses(0,sexm);
%ffsprevbysex_modelses(1,sexf);

%end;
%mend;

%ffsprevbysexses;

* Stack all the predictions together to weight by age and sex distribution in FFS;
data prev16_ffsptd_linpredsubsexses;
	set prev16_ffslinpredsessex:;
run;

data prev17_ffsptd_linpredsubsexses;
	set prev17_ffslinpredsessex:;
run;

proc sort data=prev16_ffsptd_linpredsubsexses;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db dual lis;
run;

proc sort data=prev17_ffsptd_linpredsubsexses;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db dual lis;
run;

* Combine all the weights together;
data prev16_ffs_wsubses;
	merge prev16_ffsptd_linpredsubraceses (in=a rename=(p=p_race wgtcc=wgtcc_race lclm=lcl_race uclm=ucl_race predict=predict_race))
		  prev16_ffsptd_linpredsubsexses (in=a rename=(p=p_sex wgtcc=wgtcc_sex lclm=lcl_sex uclm=ucl_sex predict=predict_sex))
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

data prev17_ffs_wsubses;
	merge prev17_ffsptd_linpredsubraceses (in=a rename=(p=p_race wgtcc=wgtcc_race lclm=lcl_race uclm=ucl_race predict=predict_race))
		  prev17_ffsptd_linpredsubsexses (in=a rename=(p=p_sex wgtcc=wgtcc_sex lclm=lcl_sex uclm=ucl_sex predict=predict_sex))
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
data &tempwork..prev16_ffs_wsubses;
	set prev16_ffs_wsubses;
run;

data &tempwork..prev17_ffs_wsubses;
	set prev17_ffs_wsubses;
run;

* Prevalence by race;
proc means data=prev16_ffs_wsubses noprint nway;
	class race_bg;
	var p_race;
	output out=prev16_ffs_weightedsubraceses sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=prev17_ffs_wsubses noprint nway;
	class race_bg;
	var p_race;
	output out=prev17_ffs_weightedsubraceses sum()= mean()= lclm()= uclm()= / autoname;
run;

proc export data=prev16_ffs_weightedsubraceses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subraceses16";
run;

proc export data=prev17_ffs_weightedsubraceses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subraceses17";
run;

* Prevalence by sex;
proc means data=prev16_ffs_wsubses noprint nway;
	class female;
	var p_sex;
	output out=prev16_ffs_weightedsubsexses sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=prev17_ffs_wsubses noprint nway;
	class female;
	var p_sex;
	output out=prev17_ffs_weightedsubsexses sum()= mean()= lclm()= uclm()= / autoname;
run;

proc export data=prev16_ffs_weightedsubsexses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subsexses16";
run;

proc export data=prev17_ffs_weightedsubsexses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subsexses17";
run;

/* T-test differences bewteen subgroups  - white reference */
%macro ffsprev_subracettest(raceval,out);
%do yr=16 %to 17;
ods output ConfLimits=ffsprev_subrace&yr._&out.ttest_cises;
ods output ttests=ffsprev_subrace&yr._&out.ttestses;
proc ttest data=prev&yr._ffs_wsubses;
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
data ffsprev_subrace16_ttest_cises;
	set ffsprev_subrace16_bttest_cises (in=b)
		ffsprev_subrace16_httest_cises (in=h)
		ffsprev_subrace16_attest_cises (in=a)
		ffsprev_subrace16_nttest_cises (in=n)
		ffsprev_subrace16_ottest_cises(in=o);
	if b then race_bg='b';
	if h then race_bg='h';
	if a then race_bg='a';
	if n then race_bg='n';
	if o then race_bg='o';
run;

data ffsprev_subrace16_ttestses;
	set ffsprev_subrace16_bttestses (in=b)
		ffsprev_subrace16_httestses (in=h)
		ffsprev_subrace16_attestses (in=a)
		ffsprev_subrace16_nttestses (in=n)
		ffsprev_subrace16_ottestses (in=o);
	if b then race_bg='b';
	if h then race_bg='h';
	if a then race_bg='a';
	if n then race_bg='n';
	if o then race_bg='o';
run;

proc export data=ffsprev_subrace16_ttest_cises
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subrace16_ttest_cises";
run;

proc export data=ffsprev_subrace16_ttestses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subrace16_ttestses";
run;

* 17;
data ffsprev_subrace17_ttest_cises;
	set ffsprev_subrace17_bttest_cises (in=b)
		ffsprev_subrace17_httest_cises (in=h)
		ffsprev_subrace17_attest_cises (in=a)
		ffsprev_subrace17_nttest_cises (in=n)
		ffsprev_subrace17_ottest_cises (in=o);
	if b then race_bg='b';
	if h then race_bg='h';
	if a then race_bg='a';
	if n then race_bg='n';
	if o then race_bg='o';
run;

data ffsprev_subrace17_ttestses;
	set ffsprev_subrace17_bttestses (in=b)
		ffsprev_subrace17_httestses (in=h)
		ffsprev_subrace17_attestses (in=a)
		ffsprev_subrace17_nttestses (in=n)
		ffsprev_subrace17_ottestses (in=o);
	if b then race_bg='b';
	if h then race_bg='h';
	if a then race_bg='a';
	if n then race_bg='n';
	if o then race_bg='o';
run;

proc export data=ffsprev_subrace17_ttest_cises
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subrace17_ttest_cises";
run;

proc export data=ffsprev_subrace17_ttestses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subrace17_ttestses";
run;

* T-test for sex;
ods output ConfLimits=ffsprev_subsex16_ttest_cises;
ods output ttests=ffsprev_subsex16_ttestses;
proc ttest data=prev16_ffs_wsubses;
	class female;
	var p_sex;
run;
	
ods output ConfLimits=ffsprev_subsex17_ttest_cises;
ods output ttests=ffsprev_subsex17_ttestses;
proc ttest data=prev17_ffs_wsubses;
	class female;
	var p_sex;
run;

proc export data=ffsprev_subsex16_ttest_cises
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subsex16_ttest_cises";
run;

proc export data=ffsprev_subsex16_ttestses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subsex16_ttestses";
run;

proc export data=ffsprev_subsex17_ttest_cises
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subsex17_ttest_cises";
run;

proc export data=ffsprev_subsex17_ttestses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsprev_subsex17_ttestses";
run;

