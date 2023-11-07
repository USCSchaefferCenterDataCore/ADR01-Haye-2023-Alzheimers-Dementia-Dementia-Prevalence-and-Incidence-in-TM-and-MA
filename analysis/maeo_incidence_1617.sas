/*********************************************************************************************/
title1 'Exploring AD Incidence Definition';

* Author: PF;
* Purpose: incidence in 2016 and 2017
	- 1 year washout period, clear of incidence in year t
	- enrolled in 3 years - year t-1, year t and year t+1
	- sample characteristics for the 2016 and 2017, pooled and separate
	- linear predict incidence for unique sex, age, race and average CCI for maeo Part D sample
	- adjusted to maeo and Part D characteristics - rates of sex, age, and race;

options compress=yes nocenter ls=150 ps=200 errors=5 mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

options obs=max;
data maeoptd_inc;
	merge base.samp_1yroptumptd_0619_66plus(in=a keep=bene_id age_beg2015-age_beg2018 age_groupa2015-age_groupa2018 sex race_bg birth_date death_date insamp2015-insamp2018
			where=(insamp2016 or insamp2017))
		  base.cci_ma_beneadj16 (keep=bene_id totalcc2016 wgtcc2016)
		  base.cci_ma_beneadj17 (keep=bene_id totalcc2017 wgtcc2017)
		  &outlib..adrdinc_dxrxsymp_yrly_1yrv2015ma (keep=bene_id scen_dxrxsymp_inc2015 dropdxrxsymp2015)
		  &outlib..adrdinc_dxrxsymp_yrly_1yrv2016ma (keep=bene_id scen_dxrxsymp_inc2016 dropdxrxsymp2016)
		  &outlib..adrdinc_dxrxsymp_yrly_1yrv2017ma (keep=bene_id scen_dxrxsymp_inc2017 dropdxrxsymp2017)
		  sh054066.bene_status_year2016 (keep=bene_id anydual anylis rename=(anydual=anydual16 anylis=anylis16))
		  sh054066.bene_status_year2017 (keep=bene_id anydual anylis rename=(anydual=anydual17 anylis=anylis17));
	by bene_id;
	if a;

	* 2016 incidence;
	if sum(insamp2015,insamp2016,insamp2017)=3 and scen_dxrxsymp_inc2015=. then do;
		inc2016=0;
		if scen_dxrxsymp_inc2016 ne . and dropdxrxsymp2016 ne 1 then inc2016=1;
	end;

	cci2016=max(wgtcc2016,0);

	age_d2016_lt70=(find(age_groupa2016,"1.")>0);
	age_d2016_7074=(find(age_groupa2016,"74")>0);
	age_d2016_7579=(find(age_groupa2016,"75")>0);
	age_d2016_ge80=(find(age_groupa2016,"3.")>0);

	dual2016=(anydual16="Y");
	lis2016=(anylis16="Y");

	* 2017 incidence;
	if sum(insamp2016,insamp2017,insamp2018)=3 and scen_dxrxsymp_inc2016=. then do;
		inc2017=0;
		if scen_dxrxsymp_inc2017 ne . and dropdxrxsymp2017 ne 1 then inc2017=1;
	end;

	cci2017=max(wgtcc2017,0);

	age_d2017_lt70=(find(age_groupa2017,"1.")>0);
	age_d2017_7074=(find(age_groupa2017,"74")>0);
	age_d2017_7579=(find(age_groupa2017,"75")>0);
	age_d2017_ge80=(find(age_groupa2017,"3.")>0);

	dual2017=(anydual17="Y");
	lis2017=(anylis17="Y");

	* female;
	female=(sex="2");

	* race;
	race_dw=(race_bg="1");
	race_db=(race_bg="2");
	race_dh=(race_bg="5");
	race_da=(race_bg="4");
	race_dn=(race_bg="6");
	race_do=(race_bg in("0","3",""));
run;

%macro maeoincexp(data,out);
proc export data=&data.
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maeoptd_inc1617.xlsx"
	dbms=xlsx
	replace;
	sheet="&out.";
run;
%mend;

* Full sample;
proc means data=maeoptd_inc noprint;
	where inc2016 ne .;
	var female age_d2016: race_d: cci2016 inc2016 dual2016 lis2016;
	output out=maeoptd_samp2016 sum()= mean()= std(cci2016)= lclm(inc2016)= uclm(inc2016)= / autoname;
run;

proc means data=maeoptd_inc noprint;
	where inc2017 ne .;
	var female age_d2017: race_d: cci2017 inc2017 dual2017 lis2017;
	output out=maeoptd_samp2017 sum()= mean()= std(cci2017)= lclm(inc2017)= uclm(inc2017)= / autoname;
run;

%maeoincexp(maeoptd_samp2016,maeoptd_samp2016);
%maeoincexp(maeoptd_samp2017,maeoptd_samp2017);

* inc sample;
proc means data=maeoptd_inc noprint;
	where inc2016;
	var female age_d2016: race_d: cci2016 inc2016 dual2016 lis2016;
	output out=maeoptd_incsamp2016 sum()= mean()= std(cci2016)=/ autoname;
run;

proc means data=maeoptd_inc noprint;
	where inc2017;
	var female age_d2017: race_d: cci2017 inc2017 dual2017 lis2017;
	output out=maeoptd_incsamp2017 sum()= mean()= std(cci2017)=/ autoname;
run;

%maeoincexp(maeoptd_incsamp2016,maeoptd_incsamp2016);
%maeoincexp(maeoptd_incsamp2017,maeoptd_incsamp2017);

/**** Linear Models ****/
data maeoptd_inc_pred16;
	set maeoptd_inc (rename=(age_d2016_7074=age7074 age_d2016_7579=age7579 age_d2016_ge80=agege80 cci2016=wgtcc)) &tempwork..incpredict16 (in=b);
	predict=b;
run;

proc reg data=maeoptd_inc_pred16 outest=inc16_maeoptd_linreg;
	where inc2016 ne . or predict;
	model inc2016=female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do;
	output out=inc16_maeoptd_linpredict (where=(predict=1) keep=female age7074 age7579 agege80 wgtcc race_d: p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;
%maeoincexp(inc16_maeoptd_linreg,inc16_maeoptd_linreg);
%maeoincexp(inc16_maeoptd_linpredict,inc16_maeoptd_linpredict);

data maeoptd_inc_pred17;
	set maeoptd_inc (rename=(age_d2017_7074=age7074 age_d2017_7579=age7579 age_d2017_ge80=agege80 cci2017=wgtcc)) &tempwork..incpredict17 (in=b);
	predict=b;
run;

proc reg data=maeoptd_inc_pred17 outest=inc17_maeoptd_linreg;
	where inc2017 ne . or predict;
	model inc2017=female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do;
	output out=inc17_maeoptd_linpredict (where=(predict=1) keep=female age7074 age7579 agege80 wgtcc race_d: p lclm uclm predict) predicted=p lclm=lclm uclm=uclm;
run;
%maeoincexp(inc17_maeoptd_linreg,inc17_maeoptd_linreg);
%maeoincexp(inc17_maeoptd_linpredict,inc17_maeoptd_linpredict);

/**** Weight - use distributions from the maeo Part D ****/
proc sort data=inc16_maeoptd_linpredict;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
run;

proc sort data=inc17_maeoptd_linpredict;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
run;

data inc16_maeo_weighted;
	merge inc16_maeoptd_linpredict (in=a) &tempwork..ffsptd_incweights16 (in=b rename=(age_d2016_ge80=agege80 age_d2016_7579=age7579 age_d2016_7074=age7074));
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

data inc17_maeo_weighted;
	merge inc17_maeoptd_linpredict (in=a) &tempwork..ffsptd_incweights17 (in=b rename=(age_d2017_ge80=agege80 age_d2017_7579=age7579 age_d2017_7074=age7074));
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

* Overall incidence;
proc means data=inc16_maeo_weighted noprint;
	var p;
	output out=inc16_maeo_weightedall sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=inc17_maeo_weighted noprint;
	var p;
	output out=inc17_maeo_weightedall sum()= mean()= lclm()= uclm()= / autoname;
run;

%maeoincexp(inc16_maeo_weightedall,inc16_maeo_weightedall);
%maeoincexp(inc17_maeo_weightedall,inc17_maeo_weightedall);

%macro incageadj(data,refvalue,refvar,out);
proc freq data=&data. noprint;
	where &refvar.=&refvalue.;
	table age_groupa / out=agedist_ref&out.(rename=(count=count_ref percent=pct_ref));
run;

proc freq data=&data noprint;
	table age_groupa*&refvar. / out=agedist_&out. (keep=count pct_col age_groupa &refvar.) outpct;
run;

data age_weight&out.;
	merge agedist_ref&out. (in=a) agedist_&out. (in=b);
	by age_groupa;
	weight=(pct_ref/100)/count;
run;

proc sort data=age_weight&out.; by &refvar. age_groupa; run;
proc sort data=&data.; by &refvar. age_groupa; run;

data demincw_&out.;
	merge &data (in=a keep=&refvar. age_groupa p) age_weight&out. (in=b);
	by &refvar. age_groupa;
run; 

proc means data=demincw_&out. noprint nway;
	class &refvar.;
	var p;
	output out=deminc_by&out._unadj mean()= lclm()= uclm()= / autoname;
run;

proc means data=demincw_&out. noprint nway;
	class &refvar.;
	weight weight;
	var p;
	output out=deminc_by&out._adj mean()= lclm()= uclm()= / autoname;
run;
%mend;

%incageadj(inc16_maeo_weighted,0,female,female16maeo);
%incageadj(inc16_maeo_weighted,"1",race_bg,race16maeo);
%incageadj(inc17_maeo_weighted,0,female,female17maeo);
%incageadj(inc17_maeo_weighted,"1",race_bg,race17maeo);

%maeoincexp(deminc_byfemale16maeo_adj,inc16maeo_weightedbysex);
%maeoincexp(deminc_byfemale17maeo_adj,inc17maeo_weightedbysex);
%maeoincexp(deminc_byrace16maeo_adj,inc16maeo_weightedbyrace);
%maeoincexp(deminc_byrace17maeo_adj,inc17maeo_weightedbyrace);

%maeoincexp(deminc_byfemale16maeo_unadj,inc16maeo_weightedbysex_unadj);
%maeoincexp(deminc_byfemale17maeo_unadj,inc17maeo_weightedbysex_unadj);
%maeoincexp(deminc_byrace16maeo_unadj,inc16maeo_weightedbyrace_unadj);
%maeoincexp(deminc_byrace17maeo_unadj,inc17maeo_weightedbyrace_unadj);


/**** Models with Dual/LIS ****/

/**** Linear Models ****/
data maeoptd_inc_pred16ses;
	set maeoptd_inc (rename=(age_d2016_7074=age7074 age_d2016_7579=age7579 age_d2016_ge80=agege80 cci2016=wgtcc dual2016=dual lis2016=lis)) &tempwork..incpredict16_ses (in=b);
	predict=b;
	if b then insamp2016=1;
	keep predict inc2016 female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do dual lis;
run;

ods output parameterestimates=inc16_maeoptd_linregses;
proc reg data=maeoptd_inc_pred16ses;
	where inc2016 ne . or predict;
	model inc2016=female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do dual lis;
	output out=inc16_maeoptd_linpredictses (where=(predict=1) keep=female age7074 age7579 agege80 wgtcc race_d: p lclm uclm dual lis predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;
%maeoincexp(inc16_maeoptd_linregses,inc16_maeoptd_linregses);
%maeoincexp(inc16_maeoptd_linpredictses,inc16_maeoptd_linpredictses);

data maeoptd_inc_pred17ses;
	set maeoptd_inc (rename=(age_d2017_7074=age7074 age_d2017_7579=age7579 age_d2017_ge80=agege80 cci2017=wgtcc dual2017=dual lis2017=lis)) &tempwork..incpredict17_ses (in=b);
	predict=b;
	if b then insamp2017=1;
	keep predict inc2017 female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do dual lis;
run;

ods output parameterestimates=inc17_maeoptd_linregses;
proc reg data=maeoptd_inc_pred17ses;
	where inc2017 ne . or predict;
	model inc2017=female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do dual lis;
	output out=inc17_maeoptd_linpredictses (where=(predict=1) keep=female age7074 age7579 agege80 wgtcc race_d: dual lis p lclm uclm predict) predicted=p lclm=lclm uclm=uclm;
run;
%maeoincexp(inc17_maeoptd_linregses,inc17_maeoptd_linregses);
%maeoincexp(inc17_maeoptd_linpredictses,inc17_maeoptd_linpredictses);

/**** Weight - use distributions from the ma Part D ****/
proc sort data=inc16_maeoptd_linpredictses;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db dual lis;
run;

proc sort data=inc17_maeoptd_linpredictses;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db dual lis;
run;

data inc16_maeo_weightedses;
	merge inc16_maeoptd_linpredictses (in=a) &tempwork..ffsptd_incweights16ses (in=b rename=(age_d2016_ge80=agege80 age_d2016_7579=age7579 age_d2016_7074=age7074 dual2016=dual lis2016=lis));
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
	do i=1 to count;
		output;
	end;
run;

data inc17_maeo_weightedses;
	merge inc17_maeoptd_linpredictses (in=a) &tempwork..ffsptd_incweights17ses (in=b rename=(age_d2017_ge80=agege80 age_d2017_7579=age7579 age_d2017_7074=age7074 dual2017=dual lis2017=lis));
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
	do i=1 to count;
		output;
	end;
run;

* Overall incidence;
proc means data=inc16_maeo_weightedses noprint;
	var p;
	output out=inc16_maeo_weightedallses sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=inc17_maeo_weightedses noprint;
	var p;
	output out=inc17_maeo_weightedallses sum()= mean()= lclm()= uclm()= / autoname;
run;

%maeoincexp(inc16_maeo_weightedallses,inc16_maeo_weightedallses);
%maeoincexp(inc17_maeo_weightedallses,inc17_maeo_weightedallses);
