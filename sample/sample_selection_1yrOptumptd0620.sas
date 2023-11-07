/*********************************************************************************************/
TITLE1 'Base';

* AUTHOR: Patricia Ferido;

* DATE: 8/20/2020;

* PURPOSE: Selecting Sample
					- Require over 65+ in year
					- Require ma, Part D all year until death;

* INPUT: bene_status_yearYYYY, bene_demog2018;
* OUTPUT: samp_1yroptumptd_0620;;

options compress=yes nocenter ls=160 ps=200 errors=5  errorcheck=strict mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

***** Running header;
***%include "header.sas";

***** Formats;
proc format;
	value $raceft
		"0"="Unknown"
		"1"="Non-Hispanic White"
		"2"="Black"
		"3"="Other"
		"4"="Asian/Pacific Islander"
		"5"="Hispanic"
		"6"="American Indian/Alaska Native"
		"7"="All Races";
	value $sexft
		"1"="Male"
		"2"="Female";
	value agegroup
		low-<75 = "1. <75"
		75-84  = "2. 75-84"
		85 - high = "3. 85+";
	value agegroupa
		low-<70 = "1. <70  "
		70-74 = "2. 70-74"
		75-79  = "2. 75-89"
		80 - high = "3. 80+";
run;

%let minyear=2006;
%let maxyear=2020;
%let demogyr=2020;

options obs=max;
*Proc transpose the MBSF to get Part C Plan ID;
%macro ptc_pull;
%do year=&minyear. %to &maxyear.;
data &tempwork..partc&year.;
	set mbsf.mbsf_abcd_&year.;
	array ptc [*] ptc_cntrct_id_01-ptc_cntrct_id_12;
	do i=1 to 12;
		if ptc[i] not in("0","N","O") then keep=1;
	end;
	if keep;
run;

proc transpose data=&tempwork..partc&year.
	out=&tempwork..ptc_cntrct_id&year. (rename=(contract_id1=contract_id))
	prefix=contract_id;
	var ptc_cntrct_id_01-ptc_cntrct_id_12;
	by bene_id;
run;

proc transpose data=&tempwork..partc&year.
	out=&tempwork..ptc_pbp_id&year. (rename=(plan_id1=plan_id))
	prefix=plan_id;
    var ptc_pbp_id_01-ptc_pbp_id_12;
	by bene_id;
run;

data &tempwork..ptc_cntrct_id&year.;
	set &tempwork..ptc_cntrct_id&year.;
	month=compress(_name_,,'ap')*1;
run;

data &tempwork..ptc_pbp_id&year.;
	set &tempwork..ptc_pbp_id&year.;
	month=compress(_name_,,'ap')*1;
run;

proc sort data=&tempwork..ptc_cntrct_id&year.; by bene_id month; run;
proc sort data=&tempwork..ptc_pbp_id&year.; by bene_id month; run;

data &tempwork..ptc_id&year.;
	merge &tempwork..ptc_cntrct_id&year. (in=a) &tempwork..ptc_pbp_id&year. (in=b);
	by bene_id month;
run;

proc sort data=&tempwork..ptc_id&year.; by contract_id plan_id; run;

data &tempwork..ptc_plan&year.;
	merge &tempwork..ptc_id&year. (in=a) pdch&year..plan_char_&year._extract (in=b keep=contract_id plan_id plan_name organization_marketing_name %if &year>2011 %then parent_organization;);
	by contract_id plan_id;
	if a;
	optum=0;
	%if &year<=2011 %then if find(upcase(plan_name),'UNITEDHEALTH') or find(upcase(organization_marketing_name),'UNITEDHEALTH') then optum=1;
	%if &year>2011 %then if find(parent_organization,'UnitedHealth') then optum=1;;
run;

proc sort data=&tempwork..ptc_plan&year.; by bene_id; run;

proc transpose data=&tempwork..ptc_plan&year. out=&tempwork..ptc_plan&year._t (drop=_name_)
	prefix=optum;
    id=month;
	var optum;
	by bene_id;
run;

*Merge to bene_demog and mbsf;
data base.optum&year.;
	merge &tempwork..ptc_plan&year._t (in=a)
	sh054066.bene_demog&demogyr. (in=c)
	mbsf.mbsf_abcd_&year. (in=b keep=bene_id MDCR_ENTLMT_BUYIN_IND_01-mdcr_entlmt_buyin_ind_12);
	by bene_id;

	array enr [*] mdcr_entlmt_buyin_ind_01-mdcr_entlmt_buyin_ind_12;
	array optum [*] optum1-optum12;

	optum_notallyr&year.=0;
	optum_allyr&year.=0;
	optum_mo&year.=0;
	do mo=1 to 12;
		if optum[mo]=1 then optum_mo&year.=optum_mo&year.+1;
		if enr[mo] ne "0" and optum[mo] ne 1 then optum_notallyr&year.=1;
	end;
	if optum_mo&year.>=1 and optum_notallyr&year.=0 then optum_allyr&year.=1;
	* Age;
	year=&year.;
	age_beg&year.=year-year(birth_date)-1;
run;
%end;

data base.samp_1yroptum_0620;
	merge
	%do year=&minyear. %to &maxyear.;
		&tempwork..optum&year. (keep=bene_id birth_date death_date sex race_bg dropflag age_beg&year. optum_mo&year. optum_allyr&year.)
	%end;;
	by bene_id;

	%do year=&minyear. %to &maxyear.;
		age_group&year.=put(age_beg&year.,agegroup.)
		age_groupa&year.=put(age_beg&year.,agegroupa.);

		if age_beg&year>=65
		and dropflag="N"
		and (optum_allyr&year.=1)
		then insamp&year.=1;
		else insamp&year.=0;
	%end;

	anysamp=max(of insamp&minyear.-insamp&maxyear.);
run;
%mend;

%ptc_pull;

***** Step 3: Sample Statistics;
%macro stats;

* By year;
%do year=&minsampyear %to &maxsampyear;
proc freq data=&outlib..samp_1yroptumptd_0620 noprint;
	where insamp&year=1;
	format race_bg $raceft. sex $sexft.;
	table race_bg / out=&tempwork..byrace_&year;
	table age_group&year / out=&tempwork..byage_&year;
	table age_groupa&year / out=&tempwork..byagea_&year;
	table sex / out=&tempwork..bysex_&year;
run;

proc transpose data=&tempwork..byrace_&year out=&tempwork..byrace_&year._t (drop=_name_ _label_); var count; id race_bg; run;
proc transpose data=&tempwork..byage_&year out=&tempwork..byage_&year._t (drop=_name_ _label_); var count; id age_group&year; run;
proc transpose data=&tempwork..byagea_&year out=&tempwork..byagea_&year._t (drop=_name_ _label_); var count; id age_groupa&year; run;
proc transpose data=&tempwork..bysex_&year out=&tempwork..bysex_&year._t (drop=_name_ _label_); var count; id sex; run;

proc contents data=&tempwork..byrace_&year._t; run;
proc contents data=&tempwork..byage_&year._t; run;
proc contents data=&tempwork..bysex_&year._t; run;

proc means data=&outlib..samp_1yroptumptd_0620 noprint;
	where insamp&year=1;
	output out=&tempwork..avgage_&year (drop=_type_ rename=_freq_=total_bene) mean(age_beg&year)=avgage;
run;

data &tempwork..stats&year;
	length year $7.;
	merge &tempwork..byrace_&year._t &tempwork..byage_&year._t &tempwork..byagea_&year._t &tempwork..bysex_&year._t &tempwork..avgage_&year;
	year="&year";
run;
%end;

* Overall - only from 2007 to 2013;
proc freq data=&outlib..samp_1yroptumptd_0620 noprint;
	where anysamp=1;
	format race_bg $raceft. sex $sexft.;
	table race_bg / out=&tempwork..byrace_all;
	table sex / out=&tempwork..bysex_all;
run;

proc transpose data=&tempwork..byrace_all out=&tempwork..byrace_all_t (drop=_name_ _label_); var count; id race_bg; run;
proc transpose data=&tempwork..bysex_all out=&tempwork..bysex_all_t (drop=_name_ _label_); var count; id sex; run;

data &tempwork..allages;
	set
	%do year=&minsampyear %to &maxsampyear;
		&outlib..samp_1yroptumptd_0620 (where=(insamp&year=1) keep=insamp&year bene_id age_beg&year rename=(age_beg&year=age_beg))
	%end;;
run;

proc means data=&tempwork..allages;
	var age_beg;
	output out=&tempwork..avgage_all (drop=_type_ _freq_) mean=avgage;
run;

data &tempwork..statsoverall;
	merge &tempwork..byrace_all_t &tempwork..bysex_all_t &tempwork..avgage_all;
	year="all";
run;

data samp_stats_optumptd;
	set &tempwork..stats&minsampyear-&tempwork..stats&maxsampyear &tempwork..statsoverall;
run;

proc export data=samp_stats_optumptd
	outfile="&rootpath./Projects/Programs/base/exports/samp_stats_1yroptumptd_0620.xlsx"
	dbms=xlsx
	replace;
	sheet="stats";
run;

proc contents data=&outlib..samp_1yroptumptd_0620; run;

%do year=&minsampyear. %to &maxsampyear.;
proc freq data=&outlib..samp_1yroptumptd_0620;
	where insamp&year.=1;
	table age_beg&year. / out=&tempwork..freq_1yragedist&year.;
run;

proc export data=&tempwork..freq_1yragedist&year.
	outfile="&rootpath./Projects/Programs/base/exports/samp_stats_1yroptumptd_0620.xlsx"
	dbms=xlsx
	replace;
	sheet="detail_age_dist&year.";
run;	
%end;

%mend;

%stats;


options obs=max;
