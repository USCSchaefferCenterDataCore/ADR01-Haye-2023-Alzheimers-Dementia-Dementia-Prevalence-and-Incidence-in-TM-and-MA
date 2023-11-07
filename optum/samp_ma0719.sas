/*********************************************************************************************/
TITLE1 'Optum MA Sample';

* AUTHOR: Patricia Ferido;

* INPUT: Optum DOD Files;

* PURPOSE: Create a sample selection file with annual flags for enrollment in Optum;

options compress=yes nocenter ls=150 ps=200 errors=5 errorabend errorcheck=strict mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

libname samp "../../data/sample_selection";
libname optum "/sch-data-library/dua-data/OPTUM-Full/Original_data/Data";
libname onepct "/sch-data-library/dua-data/OPTUM/Original_data/Data/1_Percent";

/*
Creating the following variables:
	- number of months in year enrolled
	- age at beginning of year
	- race
	- sex
	- date of birth (only year)
	- date of death (only day month)
	- enrolled all year
	- number of months dual in year
*/

options obs=max;

* Get unique records;
proc sql;
	create table patids as
		select distinct patid, eligeff, eligend, gdr_cd, lis_dual, yrdob, race
		from optum.dod_mbr_enroll_r
		where bus="MCR"
		order by patid, eligeff, eligend;
run;

* Checking for multiple records of gdr_cd, yrdob, and race;

*These don't happen;
proc sort data=patids out=patids_gdr_s nodupkey; by patid gdr_cd; run;

data patids_gdrck;
	set patids_gdr_s;
	by patid gdr_cd;
	if not(first.patid and last.patid);
run;

proc sort data=patids out=patids_race_s nodupkey; by patid race; run;
	
data patids_raceck;
	set patids_race_s;
	by patid race;
	if not(first.patid and last.patid);
run;

proc sort data=patids out=patids_yrdob_s nodupkey; by patid yrdob; run;
	
data patids_yrdobck;
	set patids_yrdob_s;
	by patid yrdob;
	if not(first.patid and last.patid);
run;

data patids_yrdobck1;
	set patids_yrdobck;
	by patid;
	if last.patid;
run;
*0.002% of patients have a year of DOB change;
*I will take a the most common year, if there are ties, then taking the first;

data patids_yrdobck2;
	set patids_yrdobck;
	by patid yrdob;
	if first.yrdob then count=0;
	count+1;
	if last.yrdob;
run;

proc sort data=patids_yrdobck2; by patid descending count yrdob; run;

data patids_yrdob_resolve;
	set patids_yrdobck;
	by patid;
	if first.patid;
	keep patid yrdob;
run;

proc print data=patids_yrdob_resolve (obs=100); run;
	
data checks;
	set patids;
	if eligeff>eligend;
run;

* Collapsing overlapping time frames;
data samp;
	merge patids (in=a) patids_yrdob_resolve (in=b);
	by patid;
	
	* Count MA enrollment months;
	array mo [156] mo1-mo156;
	array dualmo [156] dualmo1-dualmo156;
	array lismo [156] lismo1-lismo156;
	
	*retaining and restarting at first patid;
	retain mo1-mo156 dualmo1-dualmo156 lismo1-lismo156;
	if first.patid then do i=1 to dim(mo);
		mo[i]=.;
		dualmo[i]=.;
		lismo[i]=.;
	end;
	
	*setting start and end;
	start=intck('month',mdy(1,1,2007),eligeff,'d')+1;
	end=intck('month',mdy(1,1,2007),eligend,'d')+1;
	if lis_dual='D' then do;
		dualstart=start;
		dualend=end;
	end;
	if lis_dual='L' then do;
		lisstart=start;
		lisend=end;
	end;
	
	*flagging months of enrollment: MA, dual & LIS;
	do i=start to end;
		mo[i]=1;
	end;
	if dualstart ne . then do i=dualstart to dualend;
		dualmo[i]=1;
	end;
	if lisstart ne . then do i=lisstart to lisend;
		lismo[i]=1;
	end;
	
	* summing up;
	ma_enrmo2007=sum(of mo1-mo12);
	ma_enrmo2008=sum(of mo13-mo24);
	ma_enrmo2009=sum(of mo25-mo36);
	ma_enrmo2010=sum(of mo37-mo48);
	ma_enrmo2011=sum(of mo49-mo60);
	ma_enrmo2012=sum(of mo61-mo72);
	ma_enrmo2013=sum(of mo73-mo84);
	ma_enrmo2014=sum(of mo85-mo96);
	ma_enrmo2015=sum(of mo97-mo108);
	ma_enrmo2016=sum(of mo109-mo120);
	ma_enrmo2017=sum(of mo121-mo132);
	ma_enrmo2018=sum(of mo133-mo144);
	ma_enrmo2019=sum(of mo145-mo156);
	dual_enrmo2007=sum(of dualmo1-dualmo12);
	dual_enrmo2008=sum(of dualmo13-dualmo24);
	dual_enrmo2009=sum(of dualmo25-dualmo36);
	dual_enrmo2010=sum(of dualmo37-dualmo48);
	dual_enrmo2011=sum(of dualmo49-dualmo60);
	dual_enrmo2012=sum(of dualmo61-dualmo72);
	dual_enrmo2013=sum(of dualmo73-dualmo84);
	dual_enrmo2014=sum(of dualmo85-dualmo96);
	dual_enrmo2015=sum(of dualmo97-dualmo108);
	dual_enrmo2016=sum(of dualmo109-dualmo120);
	dual_enrmo2017=sum(of dualmo121-dualmo132);
	dual_enrmo2018=sum(of dualmo133-dualmo144);
	dual_enrmo2019=sum(of dualmo145-dualmo156);
	lis_enrmo2007=sum(of lismo1-lismo12);
	lis_enrmo2008=sum(of lismo13-lismo24);
	lis_enrmo2009=sum(of lismo25-lismo36);
	lis_enrmo2010=sum(of lismo37-lismo48);
	lis_enrmo2011=sum(of lismo49-lismo60);
	lis_enrmo2012=sum(of lismo61-lismo72);
	lis_enrmo2013=sum(of lismo73-lismo84);
	lis_enrmo2014=sum(of lismo85-lismo96);
	lis_enrmo2015=sum(of lismo97-lismo108);
	lis_enrmo2016=sum(of lismo109-lismo120);
	lis_enrmo2017=sum(of lismo121-lismo132);
	lis_enrmo2018=sum(of lismo133-lismo144);
	lis_enrmo2019=sum(of lismo145-lismo156);
	
	if last.patid;
	
	drop mo: dualmo: lismo: start end dualstart dualend lisstart lisend;
	
run;

proc print data=samp (obs=100);
	var patid lis_dual eligeff eligend dual_enrmo: lis_enrmo:; 
run;

proc univariate data=samp noprint outtable=mo_ck;
	var ma_enrmo2007-ma_enrmo2019 dual_enrmo2007-dual_enrmo2019 lis_enrmo2007-lis_enrmo2019;
run;

proc print data=mo_ck; run;
	
* Create all year flags for continuous ma enrollment in that year;
data samp1;
	merge samp (in=a) optum.dod_mbrwdeath (in=b keep=patid ymdod);
	by patid;
	
	if a;
	
	samp=a;
	dod=b;
	
	death_yr=substr(ymdod,1,4)*1;
	death_mo=substr(ymdod,5)*1;
	
	* Creating a measure of the last day of the month by adding a month and subtracting one day;
	death_yr_add=death_yr;
	death_mo_add=death_mo+1;
	if death_mo_add>12 then do;
		death_mo_add=(death_mo_add-12);
		death_yr_add+1;
	end;
	death_endmo_date=mdy(death_mo_add,1,death_yr_add)-1;
	
	array ma_mo_enr [2007:2019] ma_enrmo2007-ma_enrmo2019;
	array ma_enrallyr [2007:2019] ma_enrallyr2007-ma_enrallyr2019;
	array moalive [2007:2019] moalive2007-moalive2019;
	
	* Enrolled all year if enrolled in MA all 12 months of the year or in all months until death;
	do yr=2007 to 2019;
		ma_enrallyr[yr]=0;
		if ma_mo_enr[yr] ne . then do;
			moalive[yr]=intck('month',mdy(1,1,yr),min(mdy(12,31,yr),death_endmo_date),'d')+1;
			if ma_mo_enr[yr]=moalive[yr] then ma_enrallyr[yr]=1;
			if ma_mo_enr[yr]>moalive[yr] then check_over=1;
			if ma_mo_enr[yr]<moalive[yr] then check_under=1;
		end;
	end;
	
run;

proc freq data=samp1;
	table samp*dod;
run;

* Quantify how many people are still enrolled even after their death date;
proc freq data=samp1;
	table check_over / missing;
run;

proc print data=samp1 (obs=100);
	var patid ymdod ma_enrmo2007-ma_enrmo2019 ma_enrallyr: check_over check_under;
run;

proc print data=samp1 (obs=100);
	where check_over=1 or check_under=1;
run;

proc contents data=samp1; run;
	
data samp.samp_ma20072019;
	set samp1;
	drop samp dod yr moalive: i death_yr_add death_mo_add check_over check_under ymdod death_endmo_date lis_dual;
run;


		
	
