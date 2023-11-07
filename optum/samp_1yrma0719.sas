/*********************************************************************************************/
TITLE1 'Optum MA Sample';

* AUTHOR: Patricia Ferido;
* PURPOSE: Create a sample selection file with annual flags for enrollment in Optum;
* INPUT: samp_ma0719;

options compress=yes nocenter ls=150 ps=200 errors=5 errorabend errorcheck=strict mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

libname samp "../../data/sample_selection";
libname optum "/sch-data-library/dua-data/OPTUM-Full/Original_data/Data";
libname onepct "/sch-data-library/dua-data/OPTUM/Original_data/Data/1_Percent";

%let minyear=2007;
%let maxyear=2019;

***** Formats;
proc format;
	value $raceft
		""="Unknown"
		"W"="Non-Hispanic White"
		"B"="Black"
		"U"="Unknown"
		"A"="Asian/Pacific Islander"
		"H"="Hispanic";
	value $sexft
		"M"="Male"
		"F"="Female"
		"U"="Unknown";
	value agegroup
		low-<70 = "1. <70"
		70-<75  = "2. 70-74"
		75-<80  = "3. 75-79"
		80 - high = "4. 80+";
run;

proc contents data=samp.samp_ma&minyear.&maxyear.; run;

%macro samp;
data samp.samp_1yrma&minyear.&maxyear.;
	set samp.samp_ma&minyear.&maxyear.;
	
	array insamp [&minyear.:&maxyear.] insamp&minyear.-insamp&maxyear.;
	array age_beg [&minyear.:&maxyear.] age_beg&minyear.-age_beg&maxyear.;
	array age_group [&minyear.:&maxyear.] $ age_group&minyear.-age_group&maxyear.;
	
	* assuming born at the beginning of the year;
	do year=&minyear. to min(death_yr,&maxyear.);
		age_beg[year]=year-yrdob;
		age_group[year]=put(age_beg[year],agegroup.);
	end;
	
	* sample - at least 67 years old, and enrolled in MA all year for three years;
	
	%do year=&minyear %to &maxyear;
		
			if age_beg&year>=65
			and ma_enrallyr&year=1
			then insamp&year=1;
			else insamp&year=0;
		
	%end;
	
	anysamp0719=max(of insamp2007-insamp2019);
	
	drop year;
	
run;

proc print data=samp.samp_1yrma&minyear.&maxyear. (obs=100); 
	var patid race gdr_cd yrdob death_yr age_beg: age_group: insamp: MA_enrallyr:;
run;
%mend;

%samp;

	***** Step 3: Sample Statistics;
%macro stats;

* By year;
%do year=&minyear %to &maxyear;
proc freq data=samp.samp_1yrma&minyear.&maxyear. noprint;
	where insamp&year=1;
	format race $raceft. gdr_cd $sexft.;
	table race / out=byrace_&year;
	table age_group&year / out=byage_&year;
	table gdr_cd / out=bygdr_cd_&year;
run;

proc transpose data=byrace_&year out=byrace_&year._t (drop=_name_ _label_); var count; id race; run;
proc transpose data=byage_&year out=byage_&year._t (drop=_name_ _label_); var count; id age_group&year; run;
proc transpose data=bygdr_cd_&year out=bygdr_cd_&year._t (drop=_name_ _label_); var count; id gdr_cd; run;

proc contents data=byrace_&year._t; run;
proc contents data=byage_&year._t; run;
proc contents data=bygdr_cd_&year._t; run;

proc means data=samp.samp_1yrma&minyear.&maxyear. noprint;
	where insamp&year=1;
	output out=avgage_&year (drop=_type_ rename=_freq_=total_bene) mean(age_beg&year)=avgage;
run;

data stats&year;
	length year $7.;
	merge byrace_&year._t byage_&year._t bygdr_cd_&year._t avgage_&year;
	year="&year";
run;
%end;

* Overall - only from 2007 to 2013;
proc means data=samp.samp_1yrma&minyear.&maxyear. noprint;
	where anysamp0719;
	output out=totalsamp_all (drop=_type_ rename=_freq_=total_bene);
run;

proc freq data=samp.samp_1yrma&minyear.&maxyear. noprint;
	where anysamp0719=1;
	format race $raceft. gdr_cd $sexft.;
	table race / out=byrace_all;
	table gdr_cd / out=bygdr_cd_all;
run;

proc transpose data=byrace_all out=byrace_all_t (drop=_name_ _label_); var count; id race; run;
proc transpose data=bygdr_cd_all out=bygdr_cd_all_t (drop=_name_ _label_); var count; id gdr_cd; run;

data allages;
	set
	%do year=&minyear %to &maxyear;
		samp.samp_1yrma&minyear.&maxyear. (where=(insamp&year=1) keep=insamp&year patid age_beg&year rename=(age_beg&year=age_beg))
	%end;;
run;

proc means data=allages;
	var age_beg;
	output out=avgage_all (drop=_type_ _freq_) mean=avgage;
run;

data statsoverall;
	merge byrace_all_t bygdr_cd_all_t avgage_all totalsamp_all;
	year="all";
run;

data stats_output;
	set stats&minyear-stats&maxyear statsoverall;
run;

%mend;

%stats;

ods excel file="./output/sample_1yrma_stats.xlsx";
proc print data=stats_output; run;
ods excel close;

