/*********************************************************************************************/
title1 'Compare Incidence and incidence in MA v FFS v Optum';

* Author: PF;
* Purpose: Optum verified incidence in 2016 and 2017;

options compress=yes nocenter ls=150 ps=200 errors=5 errorcheck=strict mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

libname samp "../../data/sample_selection";
libname demdx "../../data/dementia";
libname optum "/sch-data-library/dua-data/OPTUM-Full/Original_data/Data";
libname onepct "/sch-data-library/dua-data/OPTUM/Original_data/Data/1_Percent";
libname inc "../../data/incidence_methods";
libname ffs "../../data/mavffs";

options obs=max;

data optum_inc;
	merge samp.samp_1yrma20072019_66plus (in=a keep=insamp2015-insamp2018 patid age_beg2016 age_beg2017 age_group2016 age_group2017 gdr_cd death_mo death_yr race
					where=(insamp2016 or insamp2017))
				samp.cci_bene0719 (in=b keep=patid totalcc2016 wgtcc2016 totalcc2017 wgtcc2017)
				inc.adrdinc_dxrxsymp_yrly_1yrv2015 (keep=patid scen_dxrxsymp_inc2015 dropdxrxsymp2015)
				inc.adrdinc_dxrxsymp_yrly_1yrv2016 (keep=patid scen_dxrxsymp_inc2016 dropdxrxsymp2016)
				inc.adrdinc_dxrxsymp_yrly_1yrv2017 (keep=patid scen_dxrxsymp_inc2017 dropdxrxsymp2017);
	by patid;
	if a;
	
	incci=b;
	
	* 2016 incidence;
	if sum(insamp2015,insamp2016,insamp2017)=3 and scen_dxrxsymp_inc2015=. then do;
		inc2016=0;
		if scen_dxrxsymp_inc2016 ne . and dropdxrxsymp2016 ne 1 then inc2016=1;
	end;
	
	cci2016=max(wgtcc2016,0);
	
	age_d2016_lt70=(find(age_group2016,"1.")>0);
	age_d2016_7074=(find(age_group2016,"2.")>0);
	age_d2016_7579=(find(age_group2016,"3.")>0);
	age_d2016_ge80=(find(age_group2016,"4.")>0);
	
		* 2017 incidence;
	if sum(insamp2015,insamp2016,insamp2017)=3 and scen_dxrxsymp_inc2016=. then do;
		inc2017=0;
		if scen_dxrxsymp_inc2017 ne . and dropdxrxsymp2017 ne 1 then inc2017=1;
	end;
	
	* quantifying how many 2017 incidence had an incidence in 2015;
	if inc2017 ne . then do;
		inc2017_but15=0;
		if scen_dxrxsymp_inc2015 ne . and dropdxrxsymp2015 ne 1 then inc2017_but15=1;
	end;
	
	cci2017=max(wgtcc2017,0);
	
	age_d2017_lt70=(find(age_group2017,"1.")>0);
	age_d2017_7074=(find(age_group2017,"2.")>0);
	age_d2017_7579=(find(age_group2017,"3.")>0);
	age_d2017_ge80=(find(age_group2017,"4.")>0);
	
	* female;
	female=(gdr_cd='F');
	
	* race;
	race_dw=(race="W");
	race_db=(race="B");
	race_dh=(race="H");
	race_da=(race="A");
	race_do=(race="" or race="U");
	
run;

* Checks;
proc freq data=optum_inc;
	table incci female*gdr_cd race*(race_d:) inc2017*inc2017_but15/ missing;
run;

%macro export(data,out);
proc export data=&data.
	outfile="./output/incidence1617.xlsx"
	dbms=xlsx
	replace;
	sheet="&out.";
run;
%mend;

* Full sample;
proc means data=optum_inc noprint;
	where inc2016 ne .;
	var female age_d2016: race_d: cci2016 inc2016;
	output out=optum_samp2016 sum()= mean()= std(cci2016)= lclm(inc2016)= uclm(inc2016)= / autoname;
run;

proc means data=optum_inc noprint;
	where inc2017 ne .;
	var female age_d2017: race_d: cci2017 inc2017;
	output out=optum_samp2017 sum()= mean()= std(cci2017)= lclm(inc2017)= uclm(inc2017)= / autoname;
run;
%export(optum_samp2016,optum_samp2016);
%export(optum_samp2017,optum_samp2017);

* inc sample;
proc means data=optum_inc noprint;
	where inc2016;
	var female age_d2016: race_d: cci2016 inc2016;
	output out=optum_incsamp2016 sum()= mean()= std(cci2016)= / autoname;
run;

proc means data=optum_inc noprint;
	where inc2017;
	var female age_d2017: race_d: cci2017 inc2017;
	output out=optum_incsamp2017 sum()= mean()= std(cci2017)=/ autoname;
run;

%export(optum_incsamp2016,optum_incsamp2016);
%export(optum_incsamp2017,optum_incsamp2017);

/**** Creating a dataset for predictiosn - unique sex, race, age cat, and avg CCI for FFS part D ****/
data incpredict16;
	input female race_db race_dh race_da race_do age7074 age7579 agege80 wgtcc;
	datalines;
	0 0 0 0 0 0 0 0 2.15
	0 1 0 0 0 0 0 0 2.15
	0 0 1 0 0 0 0 0 2.15
	0 0 0 1 0 0 0 0 2.15
	0 0 0 0 1 0 0 0 2.15
	0 0 0 0 0 1 0 0 2.15
	0 1 0 0 0 1 0 0 2.15
	0 0 1 0 0 1 0 0 2.15
	0 0 0 1 0 1 0 0 2.15
	0 0 0 0 1 1 0 0 2.15
	0 0 0 0 0 0 1 0 2.15
	0 1 0 0 0 0 1 0 2.15
	0 0 1 0 0 0 1 0 2.15
	0 0 0 1 0 0 1 0 2.15
	0 0 0 0 1 0 1 0 2.15
	0 0 0 0 0 0 0 1 2.15
	0 1 0 0 0 0 0 1 2.15
	0 0 1 0 0 0 0 1 2.15
	0 0 0 1 0 0 0 1 2.15
	0 0 0 0 1 0 0 1 2.15
	1 0 0 0 0 0 0 0 2.15
	1 1 0 0 0 0 0 0 2.15
	1 0 1 0 0 0 0 0 2.15
	1 0 0 1 0 0 0 0 2.15
	1 0 0 0 1 0 0 0 2.15
	1 0 0 0 0 1 0 0 2.15
	1 1 0 0 0 1 0 0 2.15
	1 0 1 0 0 1 0 0 2.15
	1 0 0 1 0 1 0 0 2.15
	1 0 0 0 1 1 0 0 2.15
	1 0 0 0 0 0 1 0 2.15
	1 1 0 0 0 0 1 0 2.15
	1 0 1 0 0 0 1 0 2.15
	1 0 0 1 0 0 1 0 2.15
	1 0 0 0 1 0 1 0 2.15
	1 0 0 0 0 0 0 1 2.15
	1 1 0 0 0 0 0 1 2.15
	1 0 1 0 0 0 0 1 2.15
	1 0 0 1 0 0 0 1 2.15
	1 0 0 0 1 0 0 1 2.15
	;
run;

data incpredict17;
	input female race_db race_dh race_da race_do age7074 age7579 agege80 wgtcc;
	datalines;
	0 0 0 0 0 0 0 0 2.19
	0 1 0 0 0 0 0 0 2.19
	0 0 1 0 0 0 0 0 2.19
	0 0 0 1 0 0 0 0 2.19
	0 0 0 0 1 0 0 0 2.19
	0 0 0 0 0 1 0 0 2.19
	0 1 0 0 0 1 0 0 2.19
	0 0 1 0 0 1 0 0 2.19
	0 0 0 1 0 1 0 0 2.19
	0 0 0 0 1 1 0 0 2.19
	0 0 0 0 0 0 1 0 2.19
	0 1 0 0 0 0 1 0 2.19
	0 0 1 0 0 0 1 0 2.19
	0 0 0 1 0 0 1 0 2.19
	0 0 0 0 1 0 1 0 2.19
	0 0 0 0 0 0 0 1 2.19
	0 1 0 0 0 0 0 1 2.19
	0 0 1 0 0 0 0 1 2.19
	0 0 0 1 0 0 0 1 2.19
	0 0 0 0 1 0 0 1 2.19
	1 0 0 0 0 0 0 0 2.19
	1 1 0 0 0 0 0 0 2.19
	1 0 1 0 0 0 0 0 2.19
	1 0 0 1 0 0 0 0 2.19
	1 0 0 0 1 0 0 0 2.19
	1 0 0 0 0 1 0 0 2.19
	1 1 0 0 0 1 0 0 2.19
	1 0 1 0 0 1 0 0 2.19
	1 0 0 1 0 1 0 0 2.19
	1 0 0 0 1 1 0 0 2.19
	1 0 0 0 0 0 1 0 2.19
	1 1 0 0 0 0 1 0 2.19
	1 0 1 0 0 0 1 0 2.19
	1 0 0 1 0 0 1 0 2.19
	1 0 0 0 1 0 1 0 2.19
	1 0 0 0 0 0 0 1 2.19
	1 1 0 0 0 0 0 1 2.19
	1 0 1 0 0 0 0 1 2.19
	1 0 0 1 0 0 0 1 2.19
	1 0 0 0 1 0 0 1 2.19
	;
run;

/**** Linear Models ****/
data optum_inc_pred16;
	set optum_inc (rename=(age_d2016_7074=age7074 age_d2016_7579=age7579 age_d2016_ge80=agege80 cci2016=wgtcc)) incpredict16 (in=b);
	predict=b;
	if b then insamp2016=1;
run;

proc reg data=optum_inc_pred16 outest=inc16_optum_linreg;
	where inc2016 ne . or predict;
	model inc2016=female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_do;
	output out=inc16_optum_linpredict (where=(predict=1) keep=female age7074 age7579 agege80 wgtcc race_d: p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;
%export(inc16_optum_linreg,inc16_optum_linreg);
%export(inc16_optum_linpredict,inc16_optum_linpredict);

data optum_inc_pred17;
	set optum_inc (rename=(age_d2017_7074=age7074 age_d2017_7579=age7579 age_d2017_ge80=agege80 cci2017=wgtcc)) incpredict17 (in=b);
	predict=b;
	if b then insamp2017=1;
run;

proc reg data=optum_inc_pred17 outest=inc17_optum_linreg;
	where inc2017 ne . or predict;
	model inc2017=female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_do;
	output out=inc17_optum_linpredict (where=(predict=1) keep=female age7074 age7579 agege80 wgtcc race_d: p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;
%export(inc17_optum_linreg,inc17_optum_linreg);
%export(inc17_optum_linpredict,inc17_optum_linpredict);

/**** Weight - use distributions from the FFS Part D ****/
proc sort data=inc16_optum_linpredict;
	by female agege80 age7579 age7074 race_do race_da race_dh race_db;
run;

proc sort data=inc17_optum_linpredict;
	by female agege80 age7579 age7074 race_do race_da race_dh race_db;
run;

proc sort data=ffs.ffsptd_incweights16;
	by female agege80 age7579 age7074 race_do race_da race_dh race_db;
run;

proc sort data=ffs.ffsptd_incweights17;
	by female agege80 age7579 age7074 race_do race_da race_dh race_db;
run;

data inc16_weighted;
	merge inc16_optum_linpredict (in=a) ffs.ffsptd_incweights16 (in=b);
	by female agege80 age7579 age7074 race_do race_da race_dh race_db;
	if age7074 then age_group='2. 70-74';
	else if age7579 then age_group='3. 75-79';
	else if agege80 then age_group='4. 80+';
	else age_group='1. <70';
	if race_db=1 then race='B';
	else if race_dh=1 then race='H';
	else if race_da=1 then race='A';
	else if race_do=1 then race='U';
	else race='W';
	do i=1 to count;
		output;
	end;
run;

data inc17_weighted;
	merge inc17_optum_linpredict (in=a) ffs.ffsptd_incweights17 (in=b);
	by female agege80 age7579 age7074 race_do race_da race_dh race_db;
	if age7074 then age_group='2. 70-74';
	else if age7579 then age_group='3. 75-79';
	else if agege80 then age_group='4. 80+';
	else age_group='1. <70';
	if race_db=1 then race='B';
	else if race_dh=1 then race='H';
	else if race_da=1 then race='A';
	else if race_do=1 then race='U';
	else race='W';
	do i=1 to count;
		output;
	end;
run;

* Overall incidence;
proc means data=inc16_weighted noprint;
	var p;
	output out=inc16_weightedall sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=inc17_weighted noprint;
	var p;
	output out=inc17_weightedall sum()= mean()= lclm()= uclm()= / autoname;
run;
%export(inc16_weightedall,inc16_weightedall);
%export(inc17_weightedall,inc17_weightedall);

%macro incageadj(data,refvalue,refvar,out);
proc freq data=&data. noprint;
	where &refvar.=&refvalue.;
	table age_group / out=agedist_ref&out. (rename=(count=count_ref percent=pct_ref));
run;

proc freq data=&data. noprint;
	table age_group*&refvar. / out=agedist_&out. (keep=count pct_col age_group &refvar.) outpct;
run;

data age_weight&out.;
	merge agedist_ref&out. (in=a) agedist_&out. (in=b);
	by age_group;
	weight=(pct_ref/100)/count;
run;

proc sort data=age_weight&out.; by &refvar. age_group; run;
proc sort data=&data.; by &refvar. age_group; run;
	
data demincw_&out.;
	merge &data (in=a keep=&refvar. age_group p) age_weight&out. (in=b);
	by &refvar. age_group;
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
%incageadj(inc16_weighted,'W',race,race16);
%incageadj(inc17_weighted,0,female,female17);
%incageadj(inc17_weighted,'W',race,race17);

%export(deminc_byfemale16_adj,inc16_weightedbysex);
%export(deminc_byfemale17_adj,inc17_weightedbysex);
%export(deminc_byrace16_adj,inc16_weightedbyrace);
%export(deminc_byrace17_adj,inc17_weightedbyrace);

%export(deminc_byfemale16_unadj,inc16_weightedbysex_unadj);
%export(deminc_byfemale17_unadj,inc17_weightedbysex_unadj);
%export(deminc_byrace16_unadj,inc16_weightedbyrace_unadj);
%export(deminc_byrace17_unadj,inc17_weightedbyrace_unadj);
