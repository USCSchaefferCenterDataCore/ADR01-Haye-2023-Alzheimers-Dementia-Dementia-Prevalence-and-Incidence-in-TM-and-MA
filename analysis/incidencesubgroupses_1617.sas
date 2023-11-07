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
/***** Add SES to subgroup analysis *****/
%macro predictses;
%do yr=16 %to 17;
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

data &tempwork..incpredict&yr._byraceses;
	set &tempwork..incpredict&yr._byrace (in=dual1lis1)
		&tempwork..incpredict&yr._byrace (in=dual0lis0)
		&tempwork..incpredict&yr._byrace (in=dual1lis0)
		&tempwork..incpredict&yr._byrace (in=dual0lis1);
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

data ffsptd_inc_pred&yr.byraceses;
	set ffsptd_inc (in=a rename=(age_d20&yr._7074=age7074 age_d20&yr._7579=age7579 age_d20&yr._ge80=agege80 cci20&yr.=wgtcc dual20&yr.=dual lis20&yr.=lis)) &tempwork..incpredict&yr._byraceses (in=b);
	predict=b;
run;
%end;
%mend;

%predictses;

%macro ffsincbyrace_modelses(racevar);
%do yr=16 %to 17;
ods output parameterestimates=inc&yr._ffsptd_linregses&racevar.;
proc reg data=ffsptd_inc_pred&yr.byraceses;
	where (inc20&yr. ne . or predict=1) and &racevar.=1;
	model inc20&yr.=female age7074 age7579 agege80 wgtcc dual lis;
	output out=inc&yr._ffslinpredses&racevar. (where=(predict=1 and &racevar.=1) keep=female &racevar. age7074 age7579 agege80 wgtcc dual lis p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;

proc export data=inc&yr._ffsptd_linregses&racevar.
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="inc&yr._ffsptd_linregses&racevar.";
run;
%end;
%mend;

%ffsincbyrace_modelses(race_dw);
%ffsincbyrace_modelses(race_db);
%ffsincbyrace_modelses(race_dh);
%ffsincbyrace_modelses(race_da);
%ffsincbyrace_modelses(race_dn);
%ffsincbyrace_modelses(race_do);

* Stack all the predictions together to weight by age and sex distribution in FFS;
data inc16_ffsptd_linpredsubraceses;
	set inc16_ffslinpredses:;
	array race [*] race_d:;
	do i=1 to dim(race);
		if race[i]=. then race[i]=0;
	end;
run;

data inc17_ffsptd_linpredsubraceses;
	set inc17_ffslinpredses:;
	array race [*] race_d:;
	do i=1 to dim(race);
		if race[i]=. then race[i]=0;
	end;
run;

proc sort data=inc16_ffsptd_linpredsubraceses;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db dual lis;
run;

proc sort data=inc17_ffsptd_linpredsubraceses;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db dual lis;
run;


/***** By Sex *****/
%macro ffsincbysexses;
%do yr=16 %to 17;
* Getting average cci for each subgroup;
proc means data=ad.ffsptd_inc1yrv1617 noprint nway;
	where inc20&yr. ne .;
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
data &tempwork..incpredict&yr._bysex;
	set &tempwork..incpredict&yr.;
	if female=1 then wgtcc=&&ccif&yr..;
	else if female=0 then wgtcc=&&ccim&yr..;
run;

data &tempwork..incpredict&yr._bysexses;
	set &tempwork..incpredict&yr._bysex (in=dual1lis1)
		&tempwork..incpredict&yr._bysex (in=dual0lis0)
		&tempwork..incpredict&yr._bysex (in=dual1lis0)
		&tempwork..incpredict&yr._bysex (in=dual0lis1);
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

data ffsptd_inc_pred&yr.bysexses;
	set ffsptd_inc (in=a rename=(age_d20&yr._7074=age7074 age_d20&yr._7579=age7579 age_d20&yr._ge80=agege80 cci20&yr.=wgtcc dual20&yr.=dual lis20&yr.=lis)) &tempwork..incpredict&yr._bysexses (in=b);
	predict=b;
run;

%macro ffsincbysex_modelses(sexval,out);
ods output parameterestimates=inc&yr._ffsptd_linregses&out.;
proc reg data=ffsptd_inc_pred&yr.bysexses;
	where (inc20&yr. ne . or predict=1) and female=&sexval.;
	model inc20&yr.=race_db race_dh race_da race_dn race_do age7074 age7579 agege80 wgtcc dual lis;
	output out=inc&yr._ffslinpredses&out. (where=(predict=1 and female=&sexval.) keep=female race_db race_dh race_da race_dn race_do age7074 age7579 agege80 wgtcc dual lis p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;
proc export data=inc&yr._ffsptd_linregses&out.
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="inc&yr._ffsptd_linregses&out.";
run;
%mend;

%ffsincbysex_modelses(0,sexm);
%ffsincbysex_modelses(1,sexf);

%end;
%mend;

%ffsincbysexses;

* Stack all the predictions together to weight by age and sex distribution in FFS;
data inc16_ffsptd_linpredsubsexses;
	set inc16_ffslinpredsessex:;
run;

data inc17_ffsptd_linpredsubsexses;
	set inc17_ffslinpredsessex:;
run;

proc sort data=inc16_ffsptd_linpredsubsexses;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db dual lis;
run;

proc sort data=inc17_ffsptd_linpredsubsexses;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db dual lis;
run;

* Combine all the weights together;
data inc16_ffs_wsubses;
	merge inc16_ffsptd_linpredsubraceses (in=a rename=(p=p_race wgtcc=wgtcc_race lclm=lcl_race uclm=ucl_race predict=predict_race))
		  inc16_ffsptd_linpredsubsexses (in=a rename=(p=p_sex wgtcc=wgtcc_sex lclm=lcl_sex uclm=ucl_sex predict=predict_sex))
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

data inc17_ffs_wsubses;
	merge inc17_ffsptd_linpredsubraceses (in=a rename=(p=p_race wgtcc=wgtcc_race lclm=lcl_race uclm=ucl_race predict=predict_race))
		  inc17_ffsptd_linpredsubsexses (in=a rename=(p=p_sex wgtcc=wgtcc_sex lclm=lcl_sex uclm=ucl_sex predict=predict_sex))
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
data &tempwork..inc16_ffs_wsubses;
	set inc16_ffs_wsubses;
run;

data &tempwork..inc17_ffs_wsubses;
	set inc17_ffs_wsubses;
run;

* incidence by race;
proc means data=inc16_ffs_wsubses noprint nway;
	class race_bg;
	var p_race;
	output out=inc16_ffs_weightedsubraceses sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=inc17_ffs_wsubses noprint nway;
	class race_bg;
	var p_race;
	output out=inc17_ffs_weightedsubraceses sum()= mean()= lclm()= uclm()= / autoname;
run;

proc export data=inc16_ffs_weightedsubraceses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsinc_subraceses16";
run;

proc export data=inc17_ffs_weightedsubraceses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsinc_subraceses17";
run;

* incidence by sex;
proc means data=inc16_ffs_wsubses noprint nway;
	class female;
	var p_sex;
	output out=inc16_ffs_weightedsubsexses sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=inc17_ffs_wsubses noprint nway;
	class female;
	var p_sex;
	output out=inc17_ffs_weightedsubsexses sum()= mean()= lclm()= uclm()= / autoname;
run;

proc export data=inc16_ffs_weightedsubsexses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsinc_subsexses16";
run;

proc export data=inc17_ffs_weightedsubsexses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsinc_subsexses17";
run;

/* T-test differences bewteen subgroups  - white reference */
%macro ffsinc_subracettest(raceval,out);
%do yr=16 %to 17;
ods output ConfLimits=ffsinc_subrace&yr._&out.ttest_cises;
ods output ttests=ffsinc_subrace&yr._&out.ttestses;
proc ttest data=inc&yr._ffs_wsubses;
	where race_bg in('1',"&raceval.");
	class race_bg;
	var p_race;
run;
%end;
%mend;

%ffsinc_subracettest(2,b);
%ffsinc_subracettest(3,o);
%ffsinc_subracettest(4,a);
%ffsinc_subracettest(5,h);
%ffsinc_subracettest(6,n);

* Stack all t-test results;
*16;
data ffsinc_subrace16_ttest_cises;
	set ffsinc_subrace16_bttest_cises (in=b)
		ffsinc_subrace16_httest_cises (in=h)
		ffsinc_subrace16_attest_cises (in=a)
		ffsinc_subrace16_nttest_cises (in=n)
		ffsinc_subrace16_ottest_cises(in=o);
	if b then race_bg='b';
	if h then race_bg='h';
	if a then race_bg='a';
	if n then race_bg='n';
	if o then race_bg='o';
run;

data ffsinc_subrace16_ttestses;
	set ffsinc_subrace16_bttestses (in=b)
		ffsinc_subrace16_httestses (in=h)
		ffsinc_subrace16_attestses (in=a)
		ffsinc_subrace16_nttestses (in=n)
		ffsinc_subrace16_ottestses (in=o);
	if b then race_bg='b';
	if h then race_bg='h';
	if a then race_bg='a';
	if n then race_bg='n';
	if o then race_bg='o';
run;

proc export data=ffsinc_subrace16_ttest_cises
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsinc_subrace16_ttest_cises";
run;

proc export data=ffsinc_subrace16_ttestses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsinc_subrace16_ttestses";
run;

* 17;
data ffsinc_subrace17_ttest_cises;
	set ffsinc_subrace17_bttest_cises (in=b)
		ffsinc_subrace17_httest_cises (in=h)
		ffsinc_subrace17_attest_cises (in=a)
		ffsinc_subrace17_nttest_cises (in=n)
		ffsinc_subrace17_ottest_cises (in=o);
	if b then race_bg='b';
	if h then race_bg='h';
	if a then race_bg='a';
	if n then race_bg='n';
	if o then race_bg='o';
run;

data ffsinc_subrace17_ttestses;
	set ffsinc_subrace17_bttestses (in=b)
		ffsinc_subrace17_httestses (in=h)
		ffsinc_subrace17_attestses (in=a)
		ffsinc_subrace17_nttestses (in=n)
		ffsinc_subrace17_ottestses (in=o);
	if b then race_bg='b';
	if h then race_bg='h';
	if a then race_bg='a';
	if n then race_bg='n';
	if o then race_bg='o';
run;

proc export data=ffsinc_subrace17_ttest_cises
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsinc_subrace17_ttest_cises";
run;

proc export data=ffsinc_subrace17_ttestses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsinc_subrace17_ttestses";
run;

* T-test for sex;
ods output ConfLimits=ffsinc_subsex16_ttest_cises;
ods output ttests=ffsinc_subsex16_ttestses;
proc ttest data=inc16_ffs_wsubses;
	class female;
	var p_sex;
run;
	
ods output ConfLimits=ffsinc_subsex17_ttest_cises;
ods output ttests=ffsinc_subsex17_ttestses;
proc ttest data=inc17_ffs_wsubses;
	class female;
	var p_sex;
run;

proc export data=ffsinc_subsex16_ttest_cises
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsinc_subsex16_ttest_cises";
run;

proc export data=ffsinc_subsex16_ttestses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsinc_subsex16_ttestses";
run;

proc export data=ffsinc_subsex17_ttest_cises
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsinc_subsex17_ttest_cises";
run;

proc export data=ffsinc_subsex17_ttestses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_inc1617_subgroup.xlsx"
	dbms=xlsx
	replace;
	sheet="ffsinc_subsex17_ttestses";
run;

