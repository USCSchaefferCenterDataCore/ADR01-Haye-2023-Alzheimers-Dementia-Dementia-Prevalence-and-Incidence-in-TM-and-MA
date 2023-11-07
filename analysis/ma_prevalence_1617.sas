/*********************************************************************************************/
title1 'Exploring AD Incidence Definition';

* Author: PF;
* Purpose: Prevalence in 2016 and 2017
	- 1 year snapshot
	- enrolled in year t
	- sample characteristics for the 2016 and 2017, pooled and separate
	- linear predict prevalence for unique sex, age, race and average CCI for ma Part D sample
	- adjusted to ma and Part D characteristics - rates of sex, age, and race;

options compress=yes nocenter ls=150 ps=200 errors=5 mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

options obs=max;
data maptd_prev;
	merge base.samp_1yrmaptd_0620_66plus (in=a keep=bene_id age_beg2016 age_beg2017 age_groupa2016 age_groupa2017 sex race_bg birth_date death_date insamp2016 insamp2017 insamp2018
			where=(insamp2016 or insamp2017))
		  base.cci_ma_beneadj16 (keep=bene_id totalcc2016 wgtcc2016)
		  base.cci_ma_beneadj17 (keep=bene_id totalcc2017 wgtcc2017)
		  &outlib..adrdinc_dxrxsymp_yrly_1yrv2016ma (keep=bene_id scen_dxrxsymp_inc2016 dropdxrxsymp2016)
		  &outlib..adrdinc_dxrxsymp_yrly_1yrv2017ma (keep=bene_id scen_dxrxsymp_inc2017 dropdxrxsymp2017)
		  sh054066.bene_status_year2016 (keep=bene_id anydual anylis rename=(anydual=anydual16 anylis=anylis16))
		  sh054066.bene_status_year2017 (keep=bene_id anydual anylis rename=(anydual=anydual17 anylis=anylis17))
;
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

 /**Creating perm; 
data ad.maptd_prev1yrv1617;
	set maptd_prev;
run;
*/

%macro maprevexp(data,out);
proc export data=&data.
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_prev1617.xlsx"
	dbms=xlsx
	replace;
	sheet="&out.";
run;
%mend;

* Full sample;
proc means data=maptd_prev noprint;
	where prev2016 ne .;
	var female age_d2016: race_d: cci2016 prev2016 dual2016 lis2016;
	output out=maptd_samp2016 sum()= mean()= std(cci2016)= lclm(prev2016)= uclm(prev2016)= / autoname;
run;

proc means data=maptd_prev noprint;
	where prev2017 ne .;
	var female age_d2017: race_d: cci2017 prev2017 dual2017 lis2017;
	output out=maptd_samp2017 sum()= mean()= std(cci2017)= lclm(prev2017)= uclm(prev2017)= / autoname;
run;

%maprevexp(maptd_samp2016,maptd_samp2016);
%maprevexp(maptd_samp2017,maptd_samp2017);

* Prev sample;
proc means data=ad.maptd_prev1yrv1617 noprint;
	where prev2016;
	var female age_d2016: race_d: cci2016 prev2016 dual2016 lis2016 age_beg2016;
	output out=maptd_prevsamp2016 sum()= mean()= std(cci2016 age_beg2016)=/ autoname;
run;

proc means data=ad.maptd_prev1yrv1617 noprint;
	where prev2017;
	var female age_d2017: race_d: cci2017 dual2017 lis2017 age_beg2017;
	output out=maptd_prevsamp2017 sum()= mean()= std(cci2017 age_beg2017)=/ autoname;
run;

%maprevexp(maptd_prevsamp2016,maptd_prevsamp2016);
%maprevexp(maptd_prevsamp2017,maptd_prevsamp2017);

* CCI mean for pooled;
data maptd_samp_cci1617;
	set maptd_prev (where=(prev2016 ne . ) rename=(cci2016=cci) keep=cci2016 prev2016) maptd_prev (where=(prev2017 ne . ) rename=(cci2017=cci) keep=cci2017 prev2017);
run;

proc means data=maptd_samp_cci1617 noprint;
	var cci;
	output out=maptd_samp_cci1617 sum()= mean()= std(cci)=/ autoname;
run;

data maptd_prev_cci1617;
	set maptd_prev (where=(prev2016) rename=(cci2016=cci) keep=cci2016 prev2016) maptd_prev (where=(prev2017) rename=(cci2017=cci) keep=cci2017 prev2017);
run;

proc means data=maptd_prev_cci1617 noprint;
	var cci;
	output out=maptd_prevsamp_cci1617 sum()= mean()= std(cci)=/ autoname;
run;

/**** Unadjusted prevalence rates ****/
* Prev; 
%macro unadjprev(out,subgroup=,class=);
%do yr=2016 %to 2017;
proc means data=maptd_prev noprint nway;
	where prev&yr. ne .;
	&subgroup. class &class.;
	var prev&yr.;
	output out=maptd_unadjprev&out.&yr. sum()= mean()= lclm()= uclm()= / autoname;
run;

proc export data=maptd_unadjprev&out.&yr.
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_unadjprev1617.xlsx"
	dbms=xlsx
	replace;
	sheet="unadjmaprev_&out.&yr.";
run;
%end;
%mend;

* dual;
%unadjprev(bydual,class=dual&yr.);

* lis;
%unadjprev(bylis,class=lis&yr.);

* overall;
%unadjprev(overall,subgroup=*);

* by sex;
%unadjprev(bysex,class=female);

* by age;
%unadjprev(byage,class=age_5y&yr.);

* by race;
%unadjprev(byrace,class=race_bg);

/* Age-Adjust sex (male reference) and race (white reference) */
%macro maageadj(refvalue,refvar,out);
%do yr=2016 %to 2017;
proc freq data=maptd_prev noprint;
	where prev&yr. ne . and &refvar.=&refvalue.;
	table age_5y&yr. / out=agedist_ref&out.&yr.(rename=(count=count_ref percent=pct_ref));
run;

proc freq data=maptd_prev noprint;
	where prev&yr. ne .;
	table age_5y&yr.*&refvar. / out=agedist_&out.&yr. (keep=count age_5y&yr. &refvar.) outpct;
run;

data age_weight&out.&yr.;
	merge agedist_ref&out.&yr. (in=a) agedist_&out.&yr. (in=b);
	by age_5y&yr.;
	weight=(pct_ref/100)/count;
run;

proc sort data=age_weight&out.&yr.; by &refvar. age_5y&yr.; run;
proc sort data=maptd_prev out=maptd_prev&yr.; where prev&yr. ne .; by &refvar. age_5y&yr.; run;

data demprev16maw_&out.&yr.;
	merge maptd_prev&yr. (in=a keep=bene_id &refvar. age_5y&yr. prev&yr.) age_weight&out.&yr. (in=b);
	by &refvar. age_5y&yr.;
run;

proc means data=demprev16maw_&out.&yr. noprint nway;
	class &refvar.;
	weight weight;
	var prev&yr.;
	output out=demprev16ma_by&out.&yr._adj sum()= mean()= lclm()= uclm()= / autoname;
run; 

proc export data=demprev16ma_by&out.&yr._adj
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptd_unadjprev1617.xlsx"
	dbms=xlsx
	replace;
	sheet="unadjprevma_by&out.&yr._adj";
run;
%end;
%mend;

* Dual;
%maageadj(0,dual&yr.,dual);

* LIS;
%maageadj(0,lis&yr.,lis);

* Sex;
%maageadj(0,female,sex);

* Race;
%maageadj("1",race_bg,race);

/**** Linear Models ****/
data maptd_prev_pred16;
	set maptd_prev (rename=(age_d2016_7074=age7074 age_d2016_7579=age7579 age_d2016_ge80=agege80 cci2016=wgtcc)) &tempwork..prevpredict16 (in=b);
	predict=b;
	if b then insamp2016=1;
run;

* without CCI;
proc reg data=maptd_prev_pred16 outest=prev16_maptd_linregbase;
	where prev2016 ne . or predict=1;
	model prev2016=female age7074 age7579 agege80 race_db race_dh race_da race_dn race_do;
	output out=prev16_maptd_linpredictbase (where=(predict=1) keep=female age7074 age7579 agege80 race_d: p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;
%maprevexp(prev16_maptd_linregbase,prev16_maptd_linregbase);
%maprevexp(prev16_maptd_linpredictbase,prev16_maptd_linpredictbase);

* with CCI;
proc reg data=maptd_prev_pred16 outest=prev16_maptd_linreg;
	where prev2016 ne . or predict=1;
	model prev2016=female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do;
	output out=prev16_maptd_linpredict (where=(predict=1) keep=female age7074 age7579 agege80 wgtcc race_d: p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;
%maprevexp(prev16_maptd_linreg,prev16_maptd_linreg);
%maprevexp(prev16_maptd_linpredict,prev16_maptd_linpredict);

data maptd_prev_pred17;
	set maptd_prev (rename=(age_d2017_7074=age7074 age_d2017_7579=age7579 age_d2017_ge80=agege80 cci2017=wgtcc)) &tempwork..prevpredict17 (in=b);
	predict=b;
	if b then insamp2017=1;
run;

* without CCI;
ods output parameterestimates=prev17_maptd_linregbase;
proc reg data=maptd_prev_pred17;
	where prev2017 ne . or predict=1;
	model prev2017=female age7074 age7579 agege80 race_db race_dh race_da race_dn race_do;
	output out=prev17_maptd_linpredictbase (where=(predict=1) keep=female age7074 age7579 agege80 race_d: p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;
%maprevexp(prev17_maptd_linregbase,prev17_maptd_linregbase);
%maprevexp(prev17_maptd_linpredictbase,prev17_maptd_linpredictbase);

* with CCI;
ods output parameterestimates=prev17_maptd_linreg;
proc reg data=maptd_prev_pred17;
	where prev2017 ne . or predict=1;
	model prev2017=female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do;
	output out=prev17_maptd_linpredict (where=(predict=1) keep=female age7074 age7579 agege80 wgtcc race_d: p lclm uclm predict) predicted=p lclm=lclm uclm=uclm;
run;
%maprevexp(prev17_maptd_linreg,prev17_maptd_linreg);
%maprevexp(prev17_maptd_linpredict,prev17_maptd_linpredict);

/**** Weight - use distributions from the ma Part D ****/
* without CCI;
proc sort data=prev16_maptd_linpredictbase;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
run;

proc sort data=prev17_maptd_linpredictbase;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
run;

data prev16_ma_weightedbase;
	merge prev16_maptd_linpredictbase (in=a) &tempwork..ffsptd_weights16 (in=b rename=(age_d2016_ge80=agege80 age_d2016_7579=age7579 age_d2016_7074=age7074));
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

data prev17_ma_weightedbase;
	merge prev17_maptd_linpredictbase (in=a) &tempwork..ffsptd_weights17 (in=b rename=(age_d2017_ge80=agege80 age_d2017_7579=age7579 age_d2017_7074=age7074));
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

* Overall prevalence;
proc means data=prev16_ma_weightedbase noprint;
	var p;
	output out=prev16_ma_weightedallbase sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=prev17_ma_weightedbase noprint;
	var p;
	output out=prev17_ma_weightedallbase sum()= mean()= lclm()= uclm()= / autoname;
run;

%maprevexp(prev16_ma_weightedallbase,prev16_ma_weightedallbase);
%maprevexp(prev17_ma_weightedallbase,prev17_ma_weightedallbase);

* With CCI;
proc sort data=prev16_maptd_linpredict;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
run;

proc sort data=prev17_maptd_linpredict;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db;
run;

data prev16_ma_weighted;
	merge prev16_maptd_linpredict (in=a) &tempwork..ffsptd_weights16 (in=b rename=(age_d2016_ge80=agege80 age_d2016_7579=age7579 age_d2016_7074=age7074));
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

data prev17_ma_weighted;
	merge prev17_maptd_linpredict (in=a) &tempwork..ffsptd_weights17 (in=b rename=(age_d2017_ge80=agege80 age_d2017_7579=age7579 age_d2017_7074=age7074));
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

* Overall prevalence;
proc means data=prev16_ma_weighted noprint;
	var p;
	output out=prev16_ma_weightedall sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=prev17_ma_weighted noprint;
	var p;
	output out=prev17_ma_weightedall sum()= mean()= lclm()= uclm()= / autoname;
run;

%maprevexp(prev16_ma_weightedall,prev16_ma_weightedall);
%maprevexp(prev17_ma_weightedall,prev17_ma_weightedall);

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

%prevageadj(prev16_ma_weighted,0,female,female16ma);
%prevageadj(prev16_ma_weighted,"1",race_bg,race16ma);
%prevageadj(prev17_ma_weighted,0,female,female17ma);
%prevageadj(prev17_ma_weighted,"1",race_bg,race17ma);

%maprevexp(demprev_byfemale16ma_adj,prev16ma_weightedbysex);
%maprevexp(demprev_byfemale17ma_adj,prev17ma_weightedbysex);
%maprevexp(demprev_byrace16ma_adj,prev16ma_weightedbyrace);
%maprevexp(demprev_byrace17ma_adj,prev17ma_weightedbyrace);

%maprevexp(demprev_byfemale16ma_unadj,prev16ma_weightedbysex_unadj);
%maprevexp(demprev_byfemale17ma_unadj,prev17ma_weightedbysex_unadj);
%maprevexp(demprev_byrace16ma_unadj,prev16ma_weightedbyrace_unadj);
%maprevexp(demprev_byrace17ma_unadj,prev17ma_weightedbyrace_unadj);


/**** Models with Dual/LIS ****/

/**** Linear Models ****/
data maptd_prev_pred16ses;
	set maptd_prev (rename=(age_d2016_7074=age7074 age_d2016_7579=age7579 age_d2016_ge80=agege80 cci2016=wgtcc dual2016=dual lis2016=lis)) &tempwork..prevpredict16_ses (in=b);
	predict=b;
	if b then insamp2016=1;
	keep predict prev2016 female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do dual lis;
run;

ods output parameterestimates=prev16_maptd_linregses;
proc reg data=maptd_prev_pred16ses;
	where prev2016 ne . or predict;
	model prev2016=female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do dual lis;
	output out=prev16_maptd_linpredictses (where=(predict=1) keep=female age7074 age7579 agege80 wgtcc race_d: p lclm uclm dual lis predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;
%maprevexp(prev16_maptd_linregses,prev16_maptd_linregses);
%maprevexp(prev16_maptd_linpredictses,prev16_maptd_linpredictses);

data maptd_prev_pred17ses;
	set maptd_prev (rename=(age_d2017_7074=age7074 age_d2017_7579=age7579 age_d2017_ge80=agege80 cci2017=wgtcc dual2017=dual lis2017=lis)) &tempwork..prevpredict17_ses (in=b);
	predict=b;
	if b then insamp2017=1;
	keep predict prev2017 female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do dual lis;
run;

ods output parameterestimates=prev17_maptd_linregses;
proc reg data=maptd_prev_pred17ses;
	where prev2017 ne . or predict;
	model prev2017=female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_dn race_do dual lis;
	output out=prev17_maptd_linpredictses (where=(predict=1) keep=female age7074 age7579 agege80 wgtcc race_d: dual lis p lclm uclm predict) predicted=p lclm=lclm uclm=uclm;
run;
%maprevexp(prev17_maptd_linregses,prev17_maptd_linregses);
%maprevexp(prev17_maptd_linpredictses,prev17_maptd_linpredictses);

/**** Weight - use distributions from the FFS Part D ****/
proc sort data=prev16_maptd_linpredictses;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db dual lis;
run;

proc sort data=prev17_maptd_linpredictses;
	by female agege80 age7579 age7074 race_do race_dn race_da race_dh race_db dual lis;
run;

data prev16_ma_weightedses;
	merge prev16_maptd_linpredictses (in=a) &tempwork..ffsptd_weights16ses (in=b rename=(age_d2016_ge80=agege80 age_d2016_7579=age7579 age_d2016_7074=age7074 dual2016=dual lis2016=lis));
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

data prev17_ma_weightedses;
	merge prev17_maptd_linpredictses (in=a) &tempwork..ffsptd_weights17ses (in=b rename=(age_d2017_ge80=agege80 age_d2017_7579=age7579 age_d2017_7074=age7074 dual2017=dual lis2017=lis));
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
proc means data=prev16_ma_weightedses noprint;
	var p;
	output out=prev16_ma_weightedallses sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=prev17_ma_weightedses noprint;
	var p;
	output out=prev17_ma_weightedallses sum()= mean()= lclm()= uclm()= / autoname;
run;

%maprevexp(prev16_ma_weightedallses,prev16_ma_weightedallses);
%maprevexp(prev17_ma_weightedallses,prev17_ma_weightedallses);





