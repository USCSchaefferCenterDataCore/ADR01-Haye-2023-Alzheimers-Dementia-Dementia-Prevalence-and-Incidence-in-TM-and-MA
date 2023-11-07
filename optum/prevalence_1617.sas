/*********************************************************************************************/
title1 'Compare Incidence and Prevalence in MA v FFS v Optum';

* Author: PF;
* Purpose: Optum verified prevalence in 2016 and 2017;

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

data optum_prev;
	merge samp.samp_1yrma20072019_66plus (in=a keep=insamp2016 insamp2017 patid age_beg2016 age_beg2017 age_group2016 age_group2017 gdr_cd death_mo death_yr race  where=(insamp2016 or insamp2017))
				samp.cci_bene0719 (in=b keep=patid totalcc2016 wgtcc2016 totalcc2017 wgtcc2017)
				inc.adrdinc_dxrxsymp_yrly_1yrv2016 (keep=patid scen_dxrxsymp_inc2016 dropdxrxsymp2016)
				inc.adrdinc_dxrxsymp_yrly_1yrv2017 (keep=patid scen_dxrxsymp_inc2017 dropdxrxsymp2017);
	by patid;
	if a;
	
	incci=b;
	
	* 2016 prevalence;
	if insamp2016 then do;
		prev2016=0;
		if scen_dxrxsymp_inc2016 ne . and dropdxrxsymp2016 ne 1 then prev2016=1;
	end;
	
	cci2016=max(wgtcc2016,0);
	
	age_d2016_lt70=(find(age_group2016,"1.")>0);
	age_d2016_7074=(find(age_group2016,"2.")>0);
	age_d2016_7579=(find(age_group2016,"3.")>0);
	age_d2016_ge80=(find(age_group2016,"4.")>0);
	
		* 2017 prevalence;
	if insamp2017 then do;
		prev2017=0;
		if scen_dxrxsymp_inc2017 ne . and dropdxrxsymp2017 ne 1 then prev2017=1;
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
proc freq data=optum_prev;
	table incci female*gdr_cd race*(race_d:) / missing;
run;

%macro export(data,out);
proc export data=&data.
	outfile="./output/prevalence1617.xlsx"
	dbms=xlsx
	replace;
	sheet="&out.";
run;
%mend;

* Full sample;
proc means data=optum_prev noprint;
	where insamp2016;
	var female age_d2016: race_d: cci2016 prev2016;
	output out=optum_samp2016 sum()= mean()= std(cci2016)= lclm(prev2016)= uclm(prev2016)= / autoname;
run;

proc means data=optum_prev noprint;
	where insamp2017;
	var female age_d2017: race_d: cci2017 prev2017;
	output out=optum_samp2017 sum()= mean()= std(cci2017)= lclm(prev2017)= uclm(prev2017)= / autoname;
run;

%export(optum_samp2016,optum_samp2016);
%export(optum_samp2017,optum_samp2017);

* Prev sample;
proc means data=optum_prev noprint;
	where prev2016;
	var female age_d2016: race_d: cci2016 prev2016;
	output out=optum_prevsamp2016 sum()= mean()= std(cci2016)= / autoname;
run;

proc means data=optum_prev noprint;
	where prev2017;
	var female age_d2017: race_d: cci2017 prev2017;
	output out=optum_prevsamp2017 sum()= mean()= std(cci2017)=/ autoname;
run;

%export(optum_prevsamp2016,optum_prevsamp2016);
%export(optum_prevsamp2017,optum_prevsamp2017);

* CCI for both;
data optum_prev_cci1617;
	set optum_prev (where=(prev2016) rename=(cci2016=cci) keep=cci2016 prev2016)
			optum_prev (where=(prev2017) rename=(cci2017=cci) keep=cci2017 prev2017);
run;

proc means data=optum_prev_cci1617 noprint;
	var cci;
	output out=optum_prevsamp_cci1617 sum()= mean()= std()= / autoname;
run;

proc print data=optum_prevsamp_cci1617; run;
	
endsas;


/**** Creating a dataset for predictiosn - unique sex, race, age cat, and avg CCI for FFS part D ****/
data prevpredict16;
	input female race_db race_dh race_da race_do age7074 age7579 agege80 wgtcc;
	datalines;
	0 0 0 0 0 0 0 0 2.24
	0 1 0 0 0 0 0 0 2.24
	0 0 1 0 0 0 0 0 2.24
	0 0 0 1 0 0 0 0 2.24
	0 0 0 0 1 0 0 0 2.24
	0 0 0 0 0 1 0 0 2.24
	0 1 0 0 0 1 0 0 2.24
	0 0 1 0 0 1 0 0 2.24
	0 0 0 1 0 1 0 0 2.24
	0 0 0 0 1 1 0 0 2.24
	0 0 0 0 0 0 1 0 2.24
	0 1 0 0 0 0 1 0 2.24
	0 0 1 0 0 0 1 0 2.24
	0 0 0 1 0 0 1 0 2.24
	0 0 0 0 1 0 1 0 2.24
	0 0 0 0 0 0 0 1 2.24
	0 1 0 0 0 0 0 1 2.24
	0 0 1 0 0 0 0 1 2.24
	0 0 0 1 0 0 0 1 2.24
	0 0 0 0 1 0 0 1 2.24
	1 0 0 0 0 0 0 0 2.24
	1 1 0 0 0 0 0 0 2.24
	1 0 1 0 0 0 0 0 2.24
	1 0 0 1 0 0 0 0 2.24
	1 0 0 0 1 0 0 0 2.24
	1 0 0 0 0 1 0 0 2.24
	1 1 0 0 0 1 0 0 2.24
	1 0 1 0 0 1 0 0 2.24
	1 0 0 1 0 1 0 0 2.24
	1 0 0 0 1 1 0 0 2.24
	1 0 0 0 0 0 1 0 2.24
	1 1 0 0 0 0 1 0 2.24
	1 0 1 0 0 0 1 0 2.24
	1 0 0 1 0 0 1 0 2.24
	1 0 0 0 1 0 1 0 2.24
	1 0 0 0 0 0 0 1 2.24
	1 1 0 0 0 0 0 1 2.24
	1 0 1 0 0 0 0 1 2.24
	1 0 0 1 0 0 0 1 2.24
	1 0 0 0 1 0 0 1 2.24
	;
run;

data prevpredict17;
	input female race_db race_dh race_da race_do age7074 age7579 agege80 wgtcc;
	datalines;
	0 0 0 0 0 0 0 0 2.27
	0 1 0 0 0 0 0 0 2.27
	0 0 1 0 0 0 0 0 2.27
	0 0 0 1 0 0 0 0 2.27
	0 0 0 0 1 0 0 0 2.27
	0 0 0 0 0 1 0 0 2.27
	0 1 0 0 0 1 0 0 2.27
	0 0 1 0 0 1 0 0 2.27
	0 0 0 1 0 1 0 0 2.27
	0 0 0 0 1 1 0 0 2.27
	0 0 0 0 0 0 1 0 2.27
	0 1 0 0 0 0 1 0 2.27
	0 0 1 0 0 0 1 0 2.27
	0 0 0 1 0 0 1 0 2.27
	0 0 0 0 1 0 1 0 2.27
	0 0 0 0 0 0 0 1 2.27
	0 1 0 0 0 0 0 1 2.27
	0 0 1 0 0 0 0 1 2.27
	0 0 0 1 0 0 0 1 2.27
	0 0 0 0 1 0 0 1 2.27
	1 0 0 0 0 0 0 0 2.27
	1 1 0 0 0 0 0 0 2.27
	1 0 1 0 0 0 0 0 2.27
	1 0 0 1 0 0 0 0 2.27
	1 0 0 0 1 0 0 0 2.27
	1 0 0 0 0 1 0 0 2.27
	1 1 0 0 0 1 0 0 2.27
	1 0 1 0 0 1 0 0 2.27
	1 0 0 1 0 1 0 0 2.27
	1 0 0 0 1 1 0 0 2.27
	1 0 0 0 0 0 1 0 2.27
	1 1 0 0 0 0 1 0 2.27
	1 0 1 0 0 0 1 0 2.27
	1 0 0 1 0 0 1 0 2.27
	1 0 0 0 1 0 1 0 2.27
	1 0 0 0 0 0 0 1 2.27
	1 1 0 0 0 0 0 1 2.27
	1 0 1 0 0 0 0 1 2.27
	1 0 0 1 0 0 0 1 2.27
	1 0 0 0 1 0 0 1 2.27
	;
run;

/**** Linear Models ****/
data optum_prev_pred16;
	set optum_prev (rename=(age_d2016_7074=age7074 age_d2016_7579=age7579 age_d2016_ge80=agege80 cci2016=wgtcc)) prevpredict16 (in=b);
	predict=b;
	if b then insamp2016=1;
run;

proc reg data=optum_prev_pred16 outest=prev16_optum_linreg;
	where insamp2016;
	model prev2016=female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_do;
	output out=prev16_optum_linpredict (where=(predict=1) keep=female age7074 age7579 agege80 wgtcc race_d: p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;
%export(prev16_optum_linreg,prev16_optum_linreg);
%export(prev16_optum_linpredict,prev16_optum_linpredict);

data optum_prev_pred17;
	set optum_prev (rename=(age_d2017_7074=age7074 age_d2017_7579=age7579 age_d2017_ge80=agege80 cci2017=wgtcc)) prevpredict17 (in=b);
	predict=b;
	if b then insamp2017=1;
run;

proc reg data=optum_prev_pred17 outest=prev17_optum_linreg;
	where insamp2017;
	model prev2017=female age7074 age7579 agege80 wgtcc race_db race_dh race_da race_do;
	output out=prev17_optum_linpredict (where=(predict=1) keep=female age7074 age7579 agege80 wgtcc race_d: p lclm uclm predict) predicted=p lclm=lclm uclm=uclm lcl=lcl ucl=ucl;
run;
%export(prev17_optum_linreg,prev17_optum_linreg);
%export(prev17_optum_linpredict,prev17_optum_linpredict);

/**** Weight - use distributions from the FFS Part D ****/
proc sort data=prev16_optum_linpredict;
	by female agege80 age7579 age7074 race_do race_da race_dh race_db;
run;

proc sort data=prev17_optum_linpredict;
	by female agege80 age7579 age7074 race_do race_da race_dh race_db;
run;

proc sort data=ffs.ffsptd_prevweights16;
	by female agege80 age7579 age7074 race_do race_da race_dh race_db;
run;

proc sort data=ffs.ffsptd_prevweights17;
	by female agege80 age7579 age7074 race_do race_da race_dh race_db;
run;

data prev16_weighted;
	merge prev16_optum_linpredict (in=a) ffs.ffsptd_prevweights16 (in=b);
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

data prev17_weighted;
	merge prev17_optum_linpredict (in=a) ffs.ffsptd_prevweights17 (in=b);
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

* Overall prevalence;
proc means data=prev16_weighted noprint;
	var p;
	output out=prev16_weightedall sum()= mean()= lclm()= uclm()= / autoname;
run;

proc means data=prev17_weighted noprint;
	var p;
	output out=prev17_weightedall sum()= mean()= lclm()= uclm()= / autoname;
run;
%export(prev16_weightedall,prev16_weightedall);
%export(prev17_weightedall,prev17_weightedall);

%macro prevageadj(data,refvalue,refvar,out);
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
	
data demprevw_&out.;
	merge &data (in=a keep=&refvar. age_group p) age_weight&out. (in=b);
	by &refvar. age_group;
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
%prevageadj(prev16_weighted,'W',race,race16);
%prevageadj(prev17_weighted,0,female,female17);
%prevageadj(prev17_weighted,'W',race,race17);

%export(demprev_byfemale16_adj,prev16_weightedbysex);
%export(demprev_byfemale17_adj,prev17_weightedbysex);
%export(demprev_byrace16_adj,prev16_weightedbyrace);
%export(demprev_byrace17_adj,prev17_weightedbyrace);

%export(demprev_byfemale16_unadj,prev16_weightedbysex_unadj);
%export(demprev_byfemale17_unadj,prev17_weightedbysex_unadj);
%export(demprev_byrace16_unadj,prev16_weightedbyrace_unadj);
%export(demprev_byrace17_unadj,prev17_weightedbyrace_unadj);
