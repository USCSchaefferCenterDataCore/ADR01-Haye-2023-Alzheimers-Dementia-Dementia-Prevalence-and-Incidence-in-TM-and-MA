/*********************************************************************************************/
title1 'Exploring AD Incidence Definition';

* Author: PF;
* Purpose: incidence in 2016 and 2017
	- 1 year washout period, clear of incidence in year t
	- enrolled in 3 years - year t-1, year t and year t+1
	- sample characteristics for the 2016 and 2017, pooled and separate
	- linear predict incidence for unique sex, age, race and average CCI for FFS Part D sample
	- adjusted to FFS and Part D characteristics - rates of sex, age, and race;

options compress=yes nocenter ls=150 ps=200 errors=5 mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

options obs=max;
data ffsptd_inc;
	merge base.samp_1yrffsptd_0620_66plus (in=a keep=bene_id age_beg2015-age_beg2018 age_groupa2015-age_groupa2018 sex race_bg birth_date death_date insamp2015-insamp2018
			where=(insamp2016 or insamp2017))
		  base.cci_ffsptd_bene0619 (in=b keep=bene_id totalcc2016 wgtcc2016 totalcc2017 wgtcc2017)
		  &outlib..adrdinc_dxrxsymp_yrly_1yrv2015 (keep=bene_id scen_dxrxsymp_inc2015 dropdxrxsymp2015)
		  &outlib..adrdinc_dxrxsymp_yrly_1yrv2016 (keep=bene_id scen_dxrxsymp_inc2016 dropdxrxsymp2016)
		  &outlib..adrdinc_dxrxsymp_yrly_1yrv2017 (keep=bene_id scen_dxrxsymp_inc2017 dropdxrxsymp2017)
		  sh054066.bene_status_year2016 (keep=bene_id anydual anylis rename=(anydual=anydual16 anylis=anylis16))
		  sh054066.bene_status_year2017 (keep=bene_id anydual anylis rename=(anydual=anydual17 anylis=anylis17));
	by bene_id;
	if a;

	incci=b;

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

	* quantifying how many 2017 incidence had an incidence in 2015;
	if inc2017 ne . then do;
		inc2017_but15=0;
		if scen_dxrxsymp_inc2015 ne . and dropdxrxsymp2015 ne 1 then inc2017_but15=1;
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
	if race_bg in("0","") then race_bg="3";
	race_dw=(race_bg="1");
	race_db=(race_bg="2");
	race_dh=(race_bg="5");
	race_da=(race_bg="4");
	race_dn=(race_bg="6");
	race_do=(race_bg="3");

	* age 5year bands;
	if 65<=age_beg2016<70 then age_5y2016=1;
	else if 70<=age_beg2016<75 then age_5y2016=2;
	else if 75<=age_beg2016<80 then age_5y2016=3;
	else if 80<=age_beg2016<85 then age_5y2016=4;
	else if 85<=age_beg2016<90 then age_5y2016=5;
	else if 90<=age_beg2016 then age_5y2016=6;

	* age 5year bands;
	if 65<=age_beg2017<70 then age_5y2017=1;
	else if 70<=age_beg2017<75 then age_5y2017=2;
	else if 75<=age_beg2017<80 then age_5y2017=3;
	else if 80<=age_beg2017<85 then age_5y2017=4;
	else if 85<=age_beg2017<90 then age_5y2017=5;
	else if 90<=age_beg2017 then age_5y2017=6;
run;

 *Create perm ;
data ad.ffsptd_inc1yrv1617;
	set ffsptd_inc;
run;


proc freq data=ffsptd_inc;
	table incci inc2017*inc2017_but15;
run;

%macro ffsincexp(data,out);
proc export data=&data.
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_inc1617.xlsx"
	dbms=xlsx
	replace;
	sheet="&out.";
run;
%mend;

* Full sample;
proc means data=ffsptd_inc noprint;
	where inc2016 ne .;
	var female age_d2016: race_d: cci2016 inc2016 dual2016 lis2016;
	output out=ffsptd_samp2016 sum()= mean()= std(cci2016)= lclm(inc2016)= uclm(inc2016)= / autoname;
run;

proc means data=ffsptd_inc noprint;
	where inc2017 ne .;
	var female age_d2017: race_d: cci2017 inc2017 dual2017 lis2017;
	output out=ffsptd_samp2017 sum()= mean()= std(cci2017)= lclm(inc2017)= uclm(inc2017)= / autoname;
run;

%ffsincexp(ffsptd_samp2016,ffsptd_samp2016);
%ffsincexp(ffsptd_samp2017,ffsptd_samp2017);

* inc sample;
proc means data=ffsptd_inc noprint;
	where inc2016;
	var female age_d2016: race_d: cci2016 inc2016 dual2016 lis2016;
	output out=ffsptd_incsamp2016 sum()= mean()= std(cci2016)=/ autoname;
run;

proc means data=ffsptd_inc noprint;
	where inc2017;
	var female age_d2017: race_d: cci2017 dual2017 lis2017;
	output out=ffsptd_incsamp2017 sum()= mean()= std(cci2017)=/ autoname;
run;

%ffsincexp(ffsptd_incsamp2016,ffsptd_incsamp2016);
%ffsincexp(ffsptd_incsamp2017,ffsptd_incsamp2017);


/**** Unadjusted incidence ****/
* inc; 
%macro unadjinc(out,subgroup=,class=);
%do yr=2016 %to 2017;
proc means data=ffsptd_inc noprint nway;
	where inc&yr. ne .;
	&subgroup. class &class.;
	var inc&yr.;
	output out=ffsptd_unadjinc&out.&yr. sum()= mean()= lclm()= uclm()= / autoname;
run;

proc export data=ffsptd_unadjinc&out.&yr.
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_unadjinc1617.xlsx"
	dbms=xlsx
	replace;
	sheet="unadjffsinc_&out.&yr.";
run;
%end;
%mend;

* by dual;
%unadjinc(bydual,class=dual&yr.);

* by lis;
%unadjinc(bylis,class=lis&yr.);

* overall;
%unadjinc(overall,subgroup=*);

* by sex;
%unadjinc(bysex,class=female);

* by age;
%unadjinc(byage,class=age_5y&yr.);

* by race;
%unadjinc(byrace,class=race_bg);

/* Age-Adjust sex (ffsle reference) and race (white reference) */
%macro ffsageadj(refvalue,refvar,out);
%do yr=2016 %to 2017;
proc freq data=ffsptd_inc noprint;
	where inc&yr. ne . and &refvar.=&refvalue.;
	table age_5y&yr. / out=agedist_ref&out.&yr.(rename=(count=count_ref percent=pct_ref));
run;

proc freq data=ffsptd_inc noprint;
	where inc&yr. ne .;
	table age_5y&yr.*&refvar. / out=agedist_&out.&yr. (keep=count age_5y&yr. &refvar.) outpct;
run;

data age_weight&out.&yr.;
	merge agedist_ref&out.&yr. (in=a) agedist_&out.&yr. (in=b);
	by age_5y&yr.;
	weight=(pct_ref/100)/count;
run;

proc sort data=age_weight&out.&yr.; by &refvar. age_5y&yr.; run;
proc sort data=ffsptd_inc out=ffsptd_inc&yr.; where inc&yr. ne . ; by &refvar. age_5y&yr.; run;

data deminc16ffsw_&out.&yr.;
	merge ffsptd_inc&yr. (in=a keep=bene_id &refvar. age_5y&yr. inc&yr.) age_weight&out.&yr. (in=b);
	by &refvar. age_5y&yr.;
run;

proc means data=deminc16ffsw_&out.&yr. noprint nway;
	class &refvar.;
	weight weight;
	var inc&yr.;
	output out=deminc16ffs_by&out.&yr._adj sum()= mean()= lclm()= uclm()= / autoname;
run; 

proc export data=deminc16ffs_by&out.&yr._adj
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_unadjinc1617.xlsx"
	dbms=xlsx
	replace;
	sheet="unadjincffs_by&out.&yr._adj";
run;
%end;
%mend;

* Dual;
%ffsageadj(0,dual&yr.,dual);

* LIS;
%ffsageadj(0,lis&yr.,lis);

* Sex;
%ffsageadj(0,female,sex);

* Race;
%ffsageadj("1",race_bg,race);

/**** Creating a dataset for predictions - unique sex, race, age cat, and ave CCI for FFS Part D ****/
data &tempwork..incpredict16;
	input female race_db race_dh race_da race_dn race_do age7074 age7579 agege80 wgtcc;
	datalines;
	0 0 0 0 0 0 0 0 0 2.15
	0 1 0 0 0 0 0 0 0 2.15
	0 0 1 0 0 0 0 0 0 2.15
	0 0 0 1 0 0 0 0 0 2.15
	0 0 0 0 1 0 0 0 0 2.15
	0 0 0 0 0 1 0 0 0 2.15
	0 0 0 0 0 0 1 0 0 2.15
	0 1 0 0 0 0 1 0 0 2.15
	0 0 1 0 0 0 1 0 0 2.15
	0 0 0 1 0 0 1 0 0 2.15
	0 0 0 0 1 0 1 0 0 2.15
	0 0 0 0 0 1 1 0 0 2.15
	0 0 0 0 0 0 0 1 0 2.15
	0 1 0 0 0 0 0 1 0 2.15
	0 0 1 0 0 0 0 1 0 2.15
	0 0 0 1 0 0 0 1 0 2.15
	0 0 0 0 1 0 0 1 0 2.15
	0 0 0 0 0 1 0 1 0 2.15
	0 0 0 0 0 0 0 0 1 2.15
	0 1 0 0 0 0 0 0 1 2.15
	0 0 1 0 0 0 0 0 1 2.15
	0 0 0 1 0 0 0 0 1 2.15
	0 0 0 0 1 0 0 0 1 2.15
	0 0 0 0 0 1 0 0 1 2.15
	1 0 0 0 0 0 0 0 0 2.15
	1 1 0 0 0 0 0 0 0 2.15
	1 0 1 0 0 0 0 0 0 2.15
	1 0 0 1 0 0 0 0 0 2.15
	1 0 0 0 1 0 0 0 0 2.15
	1 0 0 0 0 1 0 0 0 2.15
	1 0 0 0 0 0 1 0 0 2.15
	1 1 0 0 0 0 1 0 0 2.15
	1 0 1 0 0 0 1 0 0 2.15
	1 0 0 1 0 0 1 0 0 2.15
	1 0 0 0 1 0 1 0 0 2.15
	1 0 0 0 0 1 1 0 0 2.15
	1 0 0 0 0 0 0 1 0 2.15
	1 1 0 0 0 0 0 1 0 2.15
	1 0 1 0 0 0 0 1 0 2.15
	1 0 0 1 0 0 0 1 0 2.15
	1 0 0 0 1 0 0 1 0 2.15
	1 0 0 0 0 1 0 1 0 2.15
	1 0 0 0 0 0 0 0 1 2.15
	1 1 0 0 0 0 0 0 1 2.15
	1 0 1 0 0 0 0 0 1 2.15
	1 0 0 1 0 0 0 0 1 2.15
	1 0 0 0 1 0 0 0 1 2.15
	1 0 0 0 0 1 0 0 1 2.15
	;
run;

data &tempwork..incpredict17;
	input female race_db race_dh race_da race_dn race_do age7074 age7579 agege80 wgtcc;
	datalines;
	0 0 0 0 0 0 0 0 0 2.19
	0 1 0 0 0 0 0 0 0 2.19
	0 0 1 0 0 0 0 0 0 2.19
	0 0 0 1 0 0 0 0 0 2.19
	0 0 0 0 1 0 0 0 0 2.19
	0 0 0 0 0 1 0 0 0 2.19
	0 0 0 0 0 0 1 0 0 2.19
	0 1 0 0 0 0 1 0 0 2.19
	0 0 1 0 0 0 1 0 0 2.19
	0 0 0 1 0 0 1 0 0 2.19
	0 0 0 0 1 0 1 0 0 2.19
	0 0 0 0 0 1 1 0 0 2.19
	0 0 0 0 0 0 0 1 0 2.19
	0 1 0 0 0 0 0 1 0 2.19
	0 0 1 0 0 0 0 1 0 2.19
	0 0 0 1 0 0 0 1 0 2.19
	0 0 0 0 1 0 0 1 0 2.19
	0 0 0 0 0 1 0 1 0 2.19
	0 0 0 0 0 0 0 0 1 2.19
	0 1 0 0 0 0 0 0 1 2.19
	0 0 1 0 0 0 0 0 1 2.19
	0 0 0 1 0 0 0 0 1 2.19
	0 0 0 0 1 0 0 0 1 2.19
	0 0 0 0 0 1 0 0 1 2.19
	1 0 0 0 0 0 0 0 0 2.19
	1 1 0 0 0 0 0 0 0 2.19
	1 0 1 0 0 0 0 0 0 2.19
	1 0 0 1 0 0 0 0 0 2.19
	1 0 0 0 1 0 0 0 0 2.19
	1 0 0 0 0 1 0 0 0 2.19
	1 0 0 0 0 0 1 0 0 2.19
	1 1 0 0 0 0 1 0 0 2.19
	1 0 1 0 0 0 1 0 0 2.19
	1 0 0 1 0 0 1 0 0 2.19
	1 0 0 0 1 0 1 0 0 2.19
	1 0 0 0 0 1 1 0 0 2.19
	1 0 0 0 0 0 0 1 0 2.19
	1 1 0 0 0 0 0 1 0 2.19
	1 0 1 0 0 0 0 1 0 2.19
	1 0 0 1 0 0 0 1 0 2.19
	1 0 0 0 1 0 0 1 0 2.19
	1 0 0 0 0 1 0 1 0 2.19
	1 0 0 0 0 0 0 0 1 2.19
	1 1 0 0 0 0 0 0 1 2.19
	1 0 1 0 0 0 0 0 1 2.19
	1 0 0 1 0 0 0 0 1 2.19
	1 0 0 0 1 0 0 0 1 2.19
	1 0 0 0 0 1 0 0 1 2.19
	;
run;

/**** Linear Models ****/
data ffsptd_inc_pred16;
	set ffsptd_inc (rename=(age_d2016_7074=age7074 age_d2016_7579=age7579 age_d2016_ge80=agege80 cci2016=wgtcc)) &tempwork..incpredict16 (in=b);
	predict=b;
	if b then insamp2016=1;
run;

* base;
proc reg data=ffsptd_inc_pred16 outest=inc16_ffsptd_linregbase;
	where inc2016 ne . or predict;
	model inc2016=female age7074 age7579 agege80 race_db race_dh race_da race_dn race_do;
	output out=inc16_ffsptd_linpredictbase (where=(predict=1) keep=female age7074 age7579 agege80 race_d: p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;
%ffsincexp(inc16_ffsptd_linregbase,inc16_ffsptd_linregbase);
%ffsincexp(inc16_ffsptd_linpredictbase,inc16_ffsptd_linpredictbase);

* add cci;
proc reg data=ffsptd_inc_pred16 outest=inc16_ffsptd_linreg;
	where inc2016 ne . or predict;
	model inc2016=female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do;
	output out=inc16_ffsptd_linpredict (where=(predict=1) keep=female age7074 age7579 agege80 wgtcc race_d: p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;
%ffsincexp(inc16_ffsptd_linreg,inc16_ffsptd_linreg);
%ffsincexp(inc16_ffsptd_linpredict,inc16_ffsptd_linpredict);

data ffsptd_inc_pred17;
	set ffsptd_inc (rename=(age_d2017_7074=age7074 age_d2017_7579=age7579 age_d2017_ge80=agege80 cci2017=wgtcc)) &tempwork..incpredict17 (in=b);
	predict=b;
	if b then insamp2017=1;
run;

* base;
ods output parameterestimates=inc17_ffsptd_linregbase;
proc reg data=ffsptd_inc_pred17;
	where inc2017 ne . or predict;
	model inc2017=female age7074 age7579 agege80 race_db race_dh race_da race_dn race_do;
	output out=inc17_ffsptd_linpredictbase (where=(predict=1) keep=female age7074 age7579 agege80 wgtcc race_d: p lclm uclm predict) predicted=p lclm=lclm uclm=uclm;
run;
%ffsincexp(inc17_ffsptd_linregbase,inc17_ffsptd_linregbase);
%ffsincexp(inc17_ffsptd_linpredictbase,inc17_ffsptd_linpredictbase);

* add cci;
ods output parameterestimates=inc17_ffsptd_linreg;
proc reg data=ffsptd_inc_pred17;
	where inc2017 ne . or predict;
	model inc2017=female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do;
	output out=inc17_ffsptd_linpredict (where=(predict=1) keep=female age7074 age7579 agege80 wgtcc race_d: p lclm uclm predict) predicted=p lclm=lclm uclm=uclm;
run;
%ffsincexp(inc17_ffsptd_linreg,inc17_ffsptd_linreg);
%ffsincexp(inc17_ffsptd_linpredict,inc17_ffsptd_linpredict);

/**** Weight - use distributions from the FFS Part D ****/
proc freq data=ffsptd_inc noprint;
	where inc2016 ne .;
	table female*age_d2016_ge80*age_d2016_7579*age_d2016_7074*age_d2016_lt70*race_do*race_dn*race_da*race_dh*race_db*race_dw / out=&tempwork..ffsptd_incweights16;
run;

proc freq data=ad.ffsptd_inc1yrv1617 noprint;
	where inc2017 ne .;
	table female*age_d2017_ge80*age_d2017_7579*age_d2017_7074*age_d2017_lt70*race_do*race_dn*race_da*race_dh*race_db*race_dw / out=&tempwork..ffsptd_incweights17;
run;

* base;
proc sort data=inc16_ffsptd_linpredictbase;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
run;

proc sort data=inc17_ffsptd_linpredictbase;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
run;

data inc16_weightedbase;
	merge inc16_ffsptd_linpredictbase (in=a) &tempwork..ffsptd_weights16 (in=b rename=(age_d2016_ge80=agege80 age_d2016_7579=age7579 age_d2016_7074=age7074));
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
	do i=1 to count;
		output;
	end;
run;

data inc17_weightedbase;
	merge inc17_ffsptd_linpredictbase (in=a) &tempwork..ffsptd_weights17 (in=b rename=(age_d2017_ge80=agege80 age_d2017_7579=age7579 age_d2017_7074=age7074));
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
	do i=1 to count;
		output;
	end;
run;

/* Overall incidence */
proc means data=inc16_weightedbase noprint;
	var p;
	output out=inc16_weightedallbase sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=inc17_weightedbase noprint;
	var p;
	output out=inc17_weightedallbase sum()= mean()= lclm()= uclm()= / autoname;
run;

%ffsincexp(inc16_weightedallbase,inc16_weightedallbase);
%ffsincexp(inc17_weightedallbase,inc17_weightedallbase);

* With CCI;
proc sort data=inc16_ffsptd_linpredict;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
run;

proc sort data=inc17_ffsptd_linpredict;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
run;

data inc16_weighted;
	merge inc16_ffsptd_linpredict (in=a) &tempwork..ffsptd_weights16 (in=b rename=(age_d2016_ge80=agege80 age_d2016_7579=age7579 age_d2016_7074=age7074));
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
	do i=1 to count;
		output;
	end;
run;

data inc17_weighted;
	merge inc17_ffsptd_linpredict (in=a) &tempwork..ffsptd_weights17 (in=b rename=(age_d2017_ge80=agege80 age_d2017_7579=age7579 age_d2017_7074=age7074));
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
	do i=1 to count;
		output;
	end;
run;

/* Overall incidence */
proc means data=inc16_weighted noprint;
	var p;
	output out=inc16_weightedall sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=inc17_weighted noprint;
	var p;
	output out=inc17_weightedall sum()= mean()= lclm()= uclm()= / autoname;
run;

%ffsincexp(inc16_weightedall,inc16_weightedall);
%ffsincexp(inc17_weightedall,inc17_weightedall);

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

%incageadj(inc16_weighted,0,female,female16);
%incageadj(inc16_weighted,"1",race_bg,race16);
%incageadj(inc17_weighted,0,female,female17);
%incageadj(inc17_weighted,"1",race_bg,race17);

%ffsincexp(deminc_byfemale16_adj,inc16_weightedbysex);
%ffsincexp(deminc_byfemale17_adj,inc17_weightedbysex);
%ffsincexp(deminc_byrace16_adj,inc16_weightedbyrace);
%ffsincexp(deminc_byrace17_adj,inc17_weightedbyrace);

%ffsincexp(deminc_byfemale16_unadj,inc16_weightedbysex_unadj);
%ffsincexp(deminc_byfemale17_unadj,inc17_weightedbysex_unadj);
%ffsincexp(deminc_byrace16_unadj,inc16_weightedbyrace_unadj);
%ffsincexp(deminc_byrace17_unadj,inc17_weightedbyrace_unadj);

/**** Models with Dual/LIS ****/

/**** Creating a dataset for predictions - unique sex, race, age cat, and ave CCI for FFS Part D ****/
data &tempwork..incpredict16_ses;
	set &tempwork..incpredict16 (in=dual0lis0)
		&tempwork..incpredict16 (in=dual1lis1)
		&tempwork..incpredict16 (in=dual0lis1)
		&tempwork..incpredict16 (in=dual1lis0);
	if dual0lis0=1 then do;
		dual=0;
		lis=0;
	end;
	if dual1lis1=1 then do;
		dual=1;
		lis=1;
	end;
	if dual0lis1 then do;
		dual=0;
		lis=1;
	end;
	if dual1lis0 then do;
		dual=1;
		lis=0;
	end;
run;

data &tempwork..incpredict17_ses;
	set &tempwork..incpredict17 (in=dual0lis0)
		&tempwork..incpredict17 (in=dual1lis1)
		&tempwork..incpredict17 (in=dual0lis1)
		&tempwork..incpredict17 (in=dual1lis0);
	if dual0lis0=1 then do;
		dual=0;
		lis=0;
	end;
	if dual1lis1=1 then do;
		dual=1;
		lis=1;
	end;
	if dual0lis1 then do;
		dual=0;
		lis=1;
	end;
	if dual1lis0 then do;
		dual=1;
		lis=0;
	end;
run;

/**** Linear Models ****/
data ffsptd_inc_pred16ses;
	set ffsptd_inc (rename=(age_d2016_7074=age7074 age_d2016_7579=age7579 age_d2016_ge80=agege80 cci2016=wgtcc dual2016=dual lis2016=lis)) &tempwork..incpredict16_ses (in=b);
	predict=b;
	if b then insamp2016=1;
	keep predict inc2016 female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do dual lis;
run;

ods output parameterestimates=inc16_ffsptd_linregses;
proc reg data=ffsptd_inc_pred16ses;
	where inc2016 ne . or predict;
	model inc2016=female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do dual lis;
	output out=inc16_ffsptd_linpredictses (where=(predict=1) keep=female age7074 age7579 agege80 wgtcc race_d: p lclm uclm dual lis predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;
%ffsincexp(inc16_ffsptd_linregses,inc16_ffsptd_linregses);
%ffsincexp(inc16_ffsptd_linpredictses,inc16_ffsptd_linpredictses);

data ffsptd_inc_pred17ses;
	set ffsptd_inc (rename=(age_d2017_7074=age7074 age_d2017_7579=age7579 age_d2017_ge80=agege80 cci2017=wgtcc dual2017=dual lis2017=lis)) &tempwork..incpredict17_ses (in=b);
	predict=b;
	if b then insamp2017=1;
	keep predict inc2017 female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do dual lis;
run;

ods output parameterestimates=inc17_ffsptd_linregses;
proc reg data=ffsptd_inc_pred17ses;
	where inc2017 ne . or predict;
	model inc2017=female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do dual lis;
	output out=inc17_ffsptd_linpredictses (where=(predict=1) keep=female age7074 age7579 agege80 wgtcc race_d: dual lis p lclm uclm predict) predicted=p lclm=lclm uclm=uclm;
run;
%ffsincexp(inc17_ffsptd_linregses,inc17_ffsptd_linregses);
%ffsincexp(inc17_ffsptd_linpredictses,inc17_ffsptd_linpredictses);

/**** Weight - use distributions from the FFS Part D ****/
proc freq data=ffsptd_inc noprint;
	where inc2016 ne .;
	table female*age_d2016_ge80*age_d2016_7579*age_d2016_7074*age_d2016_lt70*race_do*race_dn*race_da*race_dh*race_db*race_dw*dual2016*lis2016 / out=&tempwork..ffsptd_incweights16ses;
run;

proc freq data=ad.ffsptd_inc1yrv1617 noprint;
	where inc2017 ne .;
	table female*age_d2017_ge80*age_d2017_7579*age_d2017_7074*age_d2017_lt70*race_do*race_dn*race_da*race_dh*race_db*race_dw*dual2017*lis2017 / out=&tempwork..ffsptd_incweights17ses;
run;

proc sort data=inc16_ffsptd_linpredictses;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db dual lis;
run;

proc sort data=inc17_ffsptd_linpredictses;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db dual lis;
run;

data inc16_weightedses;
	merge inc16_ffsptd_linpredictses (in=a) &tempwork..ffsptd_weights16ses (in=b rename=(age_d2016_ge80=agege80 age_d2016_7579=age7579 age_d2016_7074=age7074 dual2016=dual lis2016=lis));
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

data inc17_weightedses;
	merge inc17_ffsptd_linpredictses (in=a) &tempwork..ffsptd_incweights17ses (in=b rename=(age_d2017_ge80=agege80 age_d2017_7579=age7579 age_d2017_7074=age7074 dual2017=dual lis2017=lis));
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
proc means data=inc16_weightedses noprint;
	var p;
	output out=inc16_weightedallses sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=inc17_weightedses noprint;
	var p;
	output out=inc17_weightedallses sum()= mean()= lclm()= uclm()= / autoname;
run;

%ffsincexp(inc16_weightedallses,inc16_weightedallses);
%ffsincexp(inc17_weightedallses,inc17_weightedallses);



