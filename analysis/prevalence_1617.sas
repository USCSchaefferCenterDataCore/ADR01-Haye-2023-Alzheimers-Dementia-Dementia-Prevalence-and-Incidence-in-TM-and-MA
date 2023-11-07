/*********************************************************************************************/
title1 'Exploring AD Incidence Definition';

* Author: PF;
* Purpose: Prevalence in 2016 and 2017
	- 1 year snapshot
	- enrolled in year t
	- sample characteristics for the 2016 and 2017, pooled and separate
	- linear predict prevalence for unique sex, age, race and average CCI for FFS Part D sample
	- adjusted to FFS and Part D characteristics - rates of sex, age, and race;

options compress=yes nocenter ls=150 ps=200 errors=5 mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

options obs=max;
data ffsptd_prev;
	merge base.samp_1yrffsptd_0620_66plus (in=a keep=bene_id age_beg2016 age_beg2017 age_groupa2016 age_groupa2017 sex race_bg birth_date death_date insamp2016 insamp2017 insamp2018
			where=(insamp2016 or insamp2017))
		  base.cci_ffsptd_bene0619 (keep=bene_id totalcc2016 wgtcc2016 totalcc2017 wgtcc2017)
		  &outlib..adrdinc_dxrxsymp_yrly_1yrv2016 (keep=bene_id scen_dxrxsymp_inc2016 dropdxrxsymp2016)
		  &outlib..adrdinc_dxrxsymp_yrly_1yrv2017 (keep=bene_id scen_dxrxsymp_inc2017 dropdxrxsymp2017)
		  sh054066.bene_status_year2016 (keep=bene_id anydual anylis rename=(anydual=anydual16 anylis=anylis16))
		  sh054066.bene_status_year2017 (keep=bene_id anydual anylis rename=(anydual=anydual17 anylis=anylis17));
	by bene_id;
	if a;

	* 2016 prevalence;
	if insamp2016 and insamp2017 then do;
		prev2016=0;
		if scen_dxrxsymp_inc2016 ne . and dropdxrxsymp2016 ne 1 then prev2016=1;
	end;

	cci2016=max(wgtcc2016,0);

	age_d2016_lt70=(find(age_groupa2016,"1.")>0);
	age_d2016_7074=(find(age_groupa2016,"74")>0);
	age_d2016_7579=(find(age_groupa2016,"75")>0);
	age_d2016_ge80=(find(age_groupa2016,"3.")>0);

	dual2016=(anydual16="Y");
	lis2016=(anylis16="Y");

	* 2017 prevalence;
	if insamp2017 and insamp2018 then do;
		prev2017=0;
		if scen_dxrxsymp_inc2017 ne . and dropdxrxsymp2017 ne 1 then prev2017=1;
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

/* Create perm */
data ad.ffsptd_prev1yrv1617;
	set ffsptd_prev;
run;

%macro ffsprevexp(data,out);
proc export data=&data.
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_prev1617.xlsx"
	dbms=xlsx
	replace;
	sheet="&out.";
run;
%mend;

* Full sample;
proc means data=ad.ffsptd_prev1yrv1617 noprint;
	where prev2016 ne .;
	var female age_d2016: race_d: cci2016 prev2016 dual2016 lis2016 age_beg2016;
	output out=ffsptd_samp2016 sum()= mean()= std(cci2016 age_beg2016)= lclm(prev2016)= uclm(prev2016)= / autoname;
run;

proc means data=ad.ffsptd_prev1yrv1617 noprint;
	where prev2017 ne .;
	var female age_d2017: race_d: cci2017 prev2017 dual2017 lis2017 age_beg2017;
	output out=ffsptd_samp2017 sum()= mean()= std(cci2017 age_beg2017)= lclm(prev2017)= uclm(prev2017)= / autoname;
run;

%ffsprevexp(ffsptd_samp2016,ffsptd_samp2016);
%ffsprevexp(ffsptd_samp2017,ffsptd_samp2017);

* Prev sample;
proc means data=ad.ffsptd_prev1yrv1617 noprint;
	where prev2016;
	var female age_d2016: race_d: cci2016 prev2016 dual2016 lis2016 age_beg2016;
	output out=ffsptd_prevsamp2016 sum()= mean()= std(cci2016 age_beg2016)=/ autoname;
run;

proc means data=ad.ffsptd_prev1yrv1617 noprint;
	where prev2017;
	var female age_d2017: race_d: cci2017 dual2017 lis2017 age_beg2017;
	output out=ffsptd_prevsamp2017 sum()= mean()= std(cci2017 age_beg2017)=/ autoname;
run;

%ffsprevexp(ffsptd_prevsamp2016,ffsptd_prevsamp2016);
%ffsprevexp(ffsptd_prevsamp2017,ffsptd_prevsamp2017);

* CCI mean for pooled;
data ffsptd_samp_cci1617;
	set ffsptd_prev (where=(prev2016 ne . ) rename=(cci2016=cci) keep=cci2016 prev2016) ffsptd_prev (where=(prev2017 ne . ) rename=(cci2017=cci) keep=cci2017 prev2017);
run;

proc means data=ffsptd_samp_cci1617 noprint;
	var cci;
	output out=ffsptd_samp_cci1617 sum()= mean()= std(cci)=/ autoname;
run;

data ffsptd_prev_cci1617;
	set ffsptd_prev (where=(prev2016) rename=(cci2016=cci) keep=cci2016 prev2016) ffsptd_prev (where=(prev2017) rename=(cci2017=cci) keep=cci2017 prev2017);
run;

proc means data=ffsptd_prev_cci1617 noprint;
	var cci;
	output out=ffsptd_prevsamp_cci1617 sum()= mean()= std(cci)=/ autoname;
run;

/**** Unadjusted prevalence ****/
* Prev; 
%macro unadjprev(out,subgroup=,class=);
%do yr=2016 %to 2017;
proc means data=ffsptd_prev noprint nway;
	where prev&yr. ne .;
	&subgroup. class &class.;
	var prev&yr.;
	output out=ffsptd_unadjprev&out.&yr. sum()= mean()= lclm()= uclm()= / autoname;
run;

proc export data=ffsptd_unadjprev&out.&yr.
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_unadjprev1617.xlsx"
	dbms=xlsx
	replace;
	sheet="unadjffsprev_&out.&yr.";
run;
%end;
%mend;

* by dual;
%unadjprev(bydual,class=dual&yr.);

* by lis;
%unadjprev(bylis,class=lis&yr.);

* overall;
%unadjprev(overall,subgroup=*);

* by sex;
%unadjprev(bysex,class=female);

* by age;
%unadjprev(byage,class=age_5y&yr.);

* by race;
%unadjprev(byrace,class=race_bg);


/* Age-Adjust sex (ffsle reference) and race (white reference) */
%macro ffsageadj(refvalue,refvar,out);
%do yr=2016 %to 2017;
proc freq data=ffsptd_prev noprint;
	where prev&yr. ne . and &refvar.=&refvalue.;
	table age_5y&yr. / out=agedist_ref&out.&yr.(rename=(count=count_ref percent=pct_ref));
run;

proc freq data=ffsptd_prev noprint;
	where prev&yr. ne .;
	table age_5y&yr.*&refvar. / out=agedist_&out.&yr. (keep=count age_5y&yr. &refvar.) outpct;
run;

data age_weight&out.&yr.;
	merge agedist_ref&out.&yr. (in=a) agedist_&out.&yr. (in=b);
	by age_5y&yr.;
	weight=(pct_ref/100)/count;
run;

proc sort data=age_weight&out.&yr.; by &refvar. age_5y&yr.; run;
proc sort data=ffsptd_prev out=ffsptd_prev&yr.; where prev&yr. ne .; by &refvar. age_5y&yr.; run;

data demprev16ffsw_&out.&yr.;
	merge ffsptd_prev&yr. (in=a keep=bene_id &refvar. age_5y&yr. prev&yr.) age_weight&out.&yr. (in=b);
	by &refvar. age_5y&yr.;
run;

proc means data=demprev16ffsw_&out.&yr. noprint nway;
	class &refvar.;
	weight weight;
	var prev&yr.;
	output out=demprev16ffs_by&out.&yr._adj sum()= mean()= lclm()= uclm()= / autoname;
run; 

proc export data=demprev16ffs_by&out.&yr._adj
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptd_unadjprev1617.xlsx"
	dbms=xlsx
	replace;
	sheet="unadjprevffs_by&out.&yr._adj";
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
data &tempwork..prevpredict16;
	input female race_db race_dh race_da race_dn race_do age7074 age7579 agege80 wgtcc;
	datalines;
	0 0 0 0 0 0 0 0 0 2.24
	0 1 0 0 0 0 0 0 0 2.24
	0 0 1 0 0 0 0 0 0 2.24
	0 0 0 1 0 0 0 0 0 2.24
	0 0 0 0 1 0 0 0 0 2.24
	0 0 0 0 0 1 0 0 0 2.24
	0 0 0 0 0 0 1 0 0 2.24
	0 1 0 0 0 0 1 0 0 2.24
	0 0 1 0 0 0 1 0 0 2.24
	0 0 0 1 0 0 1 0 0 2.24
	0 0 0 0 1 0 1 0 0 2.24
	0 0 0 0 0 1 1 0 0 2.24
	0 0 0 0 0 0 0 1 0 2.24
	0 1 0 0 0 0 0 1 0 2.24
	0 0 1 0 0 0 0 1 0 2.24
	0 0 0 1 0 0 0 1 0 2.24
	0 0 0 0 1 0 0 1 0 2.24
	0 0 0 0 0 1 0 1 0 2.24
	0 0 0 0 0 0 0 0 1 2.24
	0 1 0 0 0 0 0 0 1 2.24
	0 0 1 0 0 0 0 0 1 2.24
	0 0 0 1 0 0 0 0 1 2.24
	0 0 0 0 1 0 0 0 1 2.24
	0 0 0 0 0 1 0 0 1 2.24
	1 0 0 0 0 0 0 0 0 2.24
	1 1 0 0 0 0 0 0 0 2.24
	1 0 1 0 0 0 0 0 0 2.24
	1 0 0 1 0 0 0 0 0 2.24
	1 0 0 0 1 0 0 0 0 2.24
	1 0 0 0 0 1 0 0 0 2.24
	1 0 0 0 0 0 1 0 0 2.24
	1 1 0 0 0 0 1 0 0 2.24
	1 0 1 0 0 0 1 0 0 2.24
	1 0 0 1 0 0 1 0 0 2.24
	1 0 0 0 1 0 1 0 0 2.24
	1 0 0 0 0 1 1 0 0 2.24
	1 0 0 0 0 0 0 1 0 2.24
	1 1 0 0 0 0 0 1 0 2.24
	1 0 1 0 0 0 0 1 0 2.24
	1 0 0 1 0 0 0 1 0 2.24
	1 0 0 0 1 0 0 1 0 2.24
	1 0 0 0 0 1 0 1 0 2.24
	1 0 0 0 0 0 0 0 1 2.24
	1 1 0 0 0 0 0 0 1 2.24
	1 0 1 0 0 0 0 0 1 2.24
	1 0 0 1 0 0 0 0 1 2.24
	1 0 0 0 1 0 0 0 1 2.24
	1 0 0 0 0 1 0 0 1 2.24
	;
run;

data &tempwork..prevpredict17;
	input female race_db race_dh race_da race_dn race_do age7074 age7579 agege80 wgtcc;
	datalines;
	0 0 0 0 0 0 0 0 0 2.27
	0 1 0 0 0 0 0 0 0 2.27
	0 0 1 0 0 0 0 0 0 2.27
	0 0 0 1 0 0 0 0 0 2.27
	0 0 0 0 1 0 0 0 0 2.27
	0 0 0 0 0 1 0 0 0 2.27
	0 0 0 0 0 0 1 0 0 2.27
	0 1 0 0 0 0 1 0 0 2.27
	0 0 1 0 0 0 1 0 0 2.27
	0 0 0 1 0 0 1 0 0 2.27
	0 0 0 0 1 0 1 0 0 2.27
	0 0 0 0 0 1 1 0 0 2.27
	0 0 0 0 0 0 0 1 0 2.27
	0 1 0 0 0 0 0 1 0 2.27
	0 0 1 0 0 0 0 1 0 2.27
	0 0 0 1 0 0 0 1 0 2.27
	0 0 0 0 1 0 0 1 0 2.27
	0 0 0 0 0 1 0 1 0 2.27
	0 0 0 0 0 0 0 0 1 2.27
	0 1 0 0 0 0 0 0 1 2.27
	0 0 1 0 0 0 0 0 1 2.27
	0 0 0 1 0 0 0 0 1 2.27
	0 0 0 0 1 0 0 0 1 2.27
	0 0 0 0 0 1 0 0 1 2.27
	1 0 0 0 0 0 0 0 0 2.27
	1 1 0 0 0 0 0 0 0 2.27
	1 0 1 0 0 0 0 0 0 2.27
	1 0 0 1 0 0 0 0 0 2.27
	1 0 0 0 1 0 0 0 0 2.27
	1 0 0 0 0 1 0 0 0 2.27
	1 0 0 0 0 0 1 0 0 2.27
	1 1 0 0 0 0 1 0 0 2.27
	1 0 1 0 0 0 1 0 0 2.27
	1 0 0 1 0 0 1 0 0 2.27
	1 0 0 0 1 0 1 0 0 2.27
	1 0 0 0 0 1 1 0 0 2.27
	1 0 0 0 0 0 0 1 0 2.27
	1 1 0 0 0 0 0 1 0 2.27
	1 0 1 0 0 0 0 1 0 2.27
	1 0 0 1 0 0 0 1 0 2.27
	1 0 0 0 1 0 0 1 0 2.27
	1 0 0 0 0 1 0 1 0 2.27
	1 0 0 0 0 0 0 0 1 2.27
	1 1 0 0 0 0 0 0 1 2.27
	1 0 1 0 0 0 0 0 1 2.27
	1 0 0 1 0 0 0 0 1 2.27
	1 0 0 0 1 0 0 0 1 2.27
	1 0 0 0 0 1 0 0 1 2.27
	;
run;

/**** Linear Models ****/
data ffsptd_prev_pred16;
	set ffsptd_prev (rename=(age_d2016_7074=age7074 age_d2016_7579=age7579 age_d2016_ge80=agege80 cci2016=wgtcc)) &tempwork..prevpredict16 (in=b);
	predict=b;
	if b then insamp2016=1;
run;

* base;
proc reg data=ffsptd_prev_pred16 outest=prev16_ffsptd_linregbase;
	where prev2016 ne . or predict;
	model prev2016=female age7074 age7579 agege80 race_db race_dh race_da race_dn race_do;
	output out=prev16_ffsptd_linpredictbase (where=(predict=1) keep=female age7074 age7579 agege80 race_d: p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;
%ffsprevexp(prev16_ffsptd_linregbase,prev16_ffsptd_linregbase);
%ffsprevexp(prev16_ffsptd_linpredictbase,prev16_ffsptd_linpredictbase);

* add cci;
proc reg data=ffsptd_prev_pred16 outest=prev16_ffsptd_linreg;
	where prev2016 ne . or predict;
	model prev2016=female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do;
	output out=prev16_ffsptd_linpredict (where=(predict=1) keep=female age7074 age7579 agege80 wgtcc race_d: p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;
%ffsprevexp(prev16_ffsptd_linreg,prev16_ffsptd_linreg);
%ffsprevexp(prev16_ffsptd_linpredict,prev16_ffsptd_linpredict);

data ffsptd_prev_pred17;
	set ffsptd_prev (rename=(age_d2017_7074=age7074 age_d2017_7579=age7579 age_d2017_ge80=agege80 cci2017=wgtcc)) &tempwork..prevpredict17 (in=b);
	predict=b;
	if b then insamp2017=1;
run;

* base;
ods output parameterestimates=prev17_ffsptd_linregbase;
proc reg data=ffsptd_prev_pred17;
	where prev2017 ne . or predict;
	model prev2017=female age7074 age7579 agege80 race_db race_dh race_da race_dn race_do;
	output out=prev17_ffsptd_linpredictbase (where=(predict=1) keep=female age7074 age7579 agege80 race_d: p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;
%ffsprevexp(prev17_ffsptd_linregbase,prev17_ffsptd_linregbase);
%ffsprevexp(prev17_ffsptd_linpredictbase,prev17_ffsptd_linpredictbase);

* add cci;
ods output parameterestimates=prev17_ffsptd_linreg;
proc reg data=ffsptd_prev_pred17;
	where prev2017 ne . or predict;
	model prev2017=female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do;
	output out=prev17_ffsptd_linpredict (where=(predict=1) keep=female age7074 age7579 agege80 wgtcc race_d: p lclm uclm predict) predicted=p lclm=lclm uclm=uclm;
run;
%ffsprevexp(prev17_ffsptd_linreg,prev17_ffsptd_linreg);
%ffsprevexp(prev17_ffsptd_linpredict,prev17_ffsptd_linpredict);

/**** Weight - use distributions from the FFS Part D ****/
proc freq data=ffsptd_prev noprint;
	where prev2016 ne .;
	table female*age_d2016_ge80*age_d2016_7579*age_d2016_7074*age_d2016_lt70*race_do*race_dn*race_da*race_dh*race_db*race_dw / out=&tempwork..ffsptd_weights16;
run;

proc freq data=ffsptd_prev noprint;
	where prev2017 ne .;
	table female*age_d2017_ge80*age_d2017_7579*age_d2017_7074*age_d2017_lt70*race_do*race_dn*race_da*race_dh*race_db*race_dw / out=&tempwork..ffsptd_weights17;
run;

* base;
proc sort data=prev16_ffsptd_linpredictbase;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
run;

proc sort data=prev17_ffsptd_linpredictbase;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
run;

data prev16_weightedbase;
	merge prev16_ffsptd_linpredictbase (in=a) &tempwork..ffsptd_weights16 (in=b rename=(age_d2016_ge80=agege80 age_d2016_7579=age7579 age_d2016_7074=age7074));
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

data prev17_weightedbase;
	merge prev17_ffsptd_linpredictbase (in=a) &tempwork..ffsptd_weights17 (in=b rename=(age_d2017_ge80=agege80 age_d2017_7579=age7579 age_d2017_7074=age7074));
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

* Overall prevalence;
proc means data=prev16_weightedbase noprint;
	var p;
	output out=prev16_weightedallbase sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=prev17_weightedbase noprint;
	var p;
	output out=prev17_weightedallbase sum()= mean()= lclm()= uclm()= / autoname;
run;

%ffsprevexp(prev16_weightedallbase,prev16_weightedallbase);
%ffsprevexp(prev17_weightedallbase,prev17_weightedallbase);

* add CCI;
proc sort data=prev16_ffsptd_linpredict;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
run;

proc sort data=prev17_ffsptd_linpredict;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
run;

data prev16_weighted;
	merge prev16_ffsptd_linpredict (in=a) &tempwork..ffsptd_weights16 (in=b rename=(age_d2016_ge80=agege80 age_d2016_7579=age7579 age_d2016_7074=age7074));
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

data prev17_weighted;
	merge prev17_ffsptd_linpredict (in=a) &tempwork..ffsptd_weights17 (in=b rename=(age_d2017_ge80=agege80 age_d2017_7579=age7579 age_d2017_7074=age7074));
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

* Overall prevalence;
proc means data=prev16_weighted noprint;
	var p;
	output out=prev16_weightedall sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=prev17_weighted noprint;
	var p;
	output out=prev17_weightedall sum()= mean()= lclm()= uclm()= / autoname;
run;

%ffsprevexp(prev16_weightedall,prev16_weightedall);
%ffsprevexp(prev17_weightedall,prev17_weightedall);

%macro prevageadj(data,refvalue,refvar,out);
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

data demprevw_&out.;
	merge &data (in=a keep=&refvar. age_groupa p) age_weight&out. (in=b);
	by &refvar. age_groupa;
run; 

proc means data=demprevw_&out. noprint nway;
	class &refvar.;
	var p;
	output out=demprev_by&out._unadj mean()= lclm()= uclm()= / autoname;
run;

proc means data=demprevw_&out. noprint nway;
	class &refvar.;
	weight weight;
	var p;
	output out=demprev_by&out._adj mean()= lclm()= uclm()= / autoname;
run;
%mend;

%prevageadj(prev16_weighted,0,female,female16);
%prevageadj(prev16_weighted,"1",race_bg,race16);
%prevageadj(prev17_weighted,0,female,female17);
%prevageadj(prev17_weighted,"1",race_bg,race17);

%ffsprevexp(demprev_byfemale16_adj,prev16_weightedbysex);
%ffsprevexp(demprev_byfemale17_adj,prev17_weightedbysex);
%ffsprevexp(demprev_byrace16_adj,prev16_weightedbyrace);
%ffsprevexp(demprev_byrace17_adj,prev17_weightedbyrace);

%ffsprevexp(demprev_byfemale16_unadj,prev16_weightedbysex_unadj);
%ffsprevexp(demprev_byfemale17_unadj,prev17_weightedbysex_unadj);
%ffsprevexp(demprev_byrace16_unadj,prev16_weightedbyrace_unadj);
%ffsprevexp(demprev_byrace17_unadj,prev17_weightedbyrace_unadj);


/**** Models with Dual/LIS ****/

/**** Creating a dataset for predictions - unique sex, race, age cat, and ave CCI for FFS Part D ****/
data &tempwork..prevpredict16_ses;
	set &tempwork..prevpredict16 (in=dual0lis0)
		&tempwork..prevpredict16 (in=dual1lis1)
		&tempwork..prevpredict16 (in=dual0lis1)
		&tempwork..prevpredict16 (in=dual1lis0);
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

data &tempwork..prevpredict17_ses;
	set &tempwork..prevpredict17 (in=dual0lis0)
		&tempwork..prevpredict17 (in=dual1lis1)
		&tempwork..prevpredict17 (in=dual0lis1)
		&tempwork..prevpredict17 (in=dual1lis0);
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
data ffsptd_prev_pred16ses;
	set ffsptd_prev (rename=(age_d2016_7074=age7074 age_d2016_7579=age7579 age_d2016_ge80=agege80 cci2016=wgtcc dual2016=dual lis2016=lis)) &tempwork..prevpredict16_ses (in=b);
	predict=b;
	if b then insamp2016=1;
	keep predict prev2016 female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do dual lis;
run;

ods output parameterestimates=prev16_ffsptd_linregses;
proc reg data=ffsptd_prev_pred16ses;
	where prev2016 ne . or predict;
	model prev2016=female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do dual lis;
	output out=prev16_ffsptd_linpredictses (where=(predict=1) keep=female age7074 age7579 agege80 wgtcc race_d: p lclm uclm dual lis predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;
%ffsprevexp(prev16_ffsptd_linregses,prev16_ffsptd_linregses);
%ffsprevexp(prev16_ffsptd_linpredictses,prev16_ffsptd_linpredictses);

data ffsptd_prev_pred17ses;
	set ffsptd_prev (rename=(age_d2017_7074=age7074 age_d2017_7579=age7579 age_d2017_ge80=agege80 cci2017=wgtcc dual2017=dual lis2017=lis)) &tempwork..prevpredict17_ses (in=b);
	predict=b;
	if b then insamp2017=1;
	keep predict prev2017 female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do dual lis;
run;

ods output parameterestimates=prev17_ffsptd_linregses;
proc reg data=ffsptd_prev_pred17ses;
	where prev2017 ne . or predict;
	model prev2017=female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do dual lis;
	output out=prev17_ffsptd_linpredictses (where=(predict=1) keep=female age7074 age7579 agege80 wgtcc race_d: dual lis p lclm uclm predict) predicted=p lclm=lclm uclm=uclm;
run;
%ffsprevexp(prev17_ffsptd_linregses,prev17_ffsptd_linregses);
%ffsprevexp(prev17_ffsptd_linpredictses,prev17_ffsptd_linpredictses);

/**** Weight - use distributions from the FFS Part D ****/
proc freq data=ffsptd_prev noprint;
	where prev2016 ne .;
	table female*age_d2016_ge80*age_d2016_7579*age_d2016_7074*age_d2016_lt70*race_do*race_dn*race_da*race_dh*race_db*race_dw*dual2016*lis2016 / out=&tempwork..ffsptd_weights16ses;
run;

proc freq data=ad.ffsptd_prev1yrv1617 noprint;
	where prev2017 ne .;
	table female*age_d2017_ge80*age_d2017_7579*age_d2017_7074*age_d2017_lt70*race_do*race_dn*race_da*race_dh*race_db*race_dw*dual2017*lis2017 / out=&tempwork..ffsptd_weights17ses;
run;

proc sort data=prev16_ffsptd_linpredictses;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db dual lis;
run;

proc sort data=prev17_ffsptd_linpredictses;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db dual lis;
run;

data prev16_weightedses;
	merge prev16_ffsptd_linpredictses (in=a) &tempwork..ffsptd_weights16ses (in=b rename=(age_d2016_ge80=agege80 age_d2016_7579=age7579 age_d2016_7074=age7074 dual2016=dual lis2016=lis));
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

data prev17_weightedses;
	merge prev17_ffsptd_linpredictses (in=a) &tempwork..ffsptd_weights17ses (in=b rename=(age_d2017_ge80=agege80 age_d2017_7579=age7579 age_d2017_7074=age7074 dual2017=dual lis2017=lis));
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

* Overall prevalence;
proc means data=prev16_weightedses noprint;
	var p;
	output out=prev16_weightedallses sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=prev17_weightedses noprint;
	var p;
	output out=prev17_weightedallses sum()= mean()= lclm()= uclm()= / autoname;
run;

%ffsprevexp(prev16_weightedallses,prev16_weightedallses);
%ffsprevexp(prev17_weightedallses,prev17_weightedallses);
