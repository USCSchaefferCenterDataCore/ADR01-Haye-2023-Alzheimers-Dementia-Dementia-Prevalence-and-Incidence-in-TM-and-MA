/*********************************************************************************************/
title1 'Exploring AD Incidence Definition';

* Author: PF;
* Purpose: ADRD inc verified breakdown by first dx;
* Input: incidence dataset, yearly flags;

options compress=yes nocenter ls=150 ps=200 errors=5 mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

options obs=max;
data ffsptdinc_breakdown;
	merge ffsptd_inc (in=a keep=bene_id inc2016 inc2017 female age_d2016: age_d2017: cci2016 cci2017 race_d: where=(inc2016 or inc2017))
	&outlib..adrdinc_dxrxsymp_yrly_1yrv2016
	&outlib..adrdinc_dxrxsymp_yrly_1yrv2017 ;
	by bene_id;

	if a;

	format firstdt mmddyy10.;
	if inc2016=1 then do;
		firstdt=scen_dxrxsymp_inc2016;
		firstinctype=scen_dxrxsymp_inctype2016;
		incyr=2016;
	end;
	if inc2017=1 then do;
		firstdt=scen_dxrxsymp_inc2017;
		firstinctype=scen_dxrxsymp_inctype2017;
		incyr=2017;
	end;
run;

proc sort data=ffsptdinc_breakdown; by bene_id firstdt; run;

data ffsptdinc_breakdown1;
	merge ffsptdinc_breakdown (in=a) demdx.dementia_dt_1999_2021 (in=b keep=bene_id demdx_dt dxtypes claim_types rename=(demdx_dt=firstdt));
	by bene_id firstdt;
	if a;

	firstdx=0;
	firstrx=0;
	firstmci=0;
	firstsymp=0;
	firstmult=0;


	if find(firstinctype,'1')>0 then firstdx=1;
	if find(firstinctype,'2')>0 then firstrx=1;
	if find(firstinctype,'3')>0 then do;
		if find(dxtypes,'m')>0  then firstmci=1;
		if find(dxtypes,'p')>0 or find(dxtypes,'X') then firstsymp=1;
	end;
	if sum(firstdx,firstrx,firstmci,firstsymp)>1 then do;
		firstmult=1;
	end;
	if sum(firstdx,firstrx,firstmci,firstsymp)=0 then check=1;
	
	* location;
	if find(claim_types,'5') then loc='car';
	else if find(claim_types,'3') then loc='op';
	else if find(claim_types,'1') then loc='ip';
	else if find(claim_types,'2') then loc='snf';
	else if find(claim_types,'4') then loc='hha';
	else if find(firstinctype,'2') then loc='rx';
	else check=1;

run;

proc freq data=ffsptdinc_breakdown1;
	table firstinctype*dxtypes*(firstdx firstmci firstsymp firstrx) / missing;
run;

proc freq data=ffsptdinc_breakdown1 noprint;
	where firstmult=1;
	table firstdx*firstrx*firstmci*firstsymp / out=ffsptd_mult_breakdown;
run;

proc freq data=ffsptdinc_breakdown1 noprint;
	where firstmult=1 and incyr=2016;
	table firstdx*firstrx*firstmci*firstsymp / out=ffsptd_mult_breakdown16;
run;

proc freq data=ffsptdinc_breakdown1 noprint;
	where firstmult=1 and incyr=2017;
	table firstdx*firstrx*firstmci*firstsymp / out=ffsptd_mult_breakdown17;
run;

data ffsptdinc_breakdown_;
	set ffsptdinc_breakdown1;
	if firstmult=1 then do;
				firstdx=0;
				firstrx=0;
				firstmci=0;
				firstsymp=0;
	end;
run;

proc means data=ffsptdinc_breakdown_ noprint;
	class incyr;
	var firstdx firstrx firstmci firstsymp firstmult;
	output out=ffsptdinc_breakdown_stats sum()= mean()= lclm()= uclm()= / autoname;
run;

proc export data=ffsptdinc_breakdown_stats
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptdinc_breakdown1617.xlsx"
	dbms=xlsx
	replace;
	sheet="ffs";
run;

proc export data=ffsptd_mult_breakdown
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptdinc_breakdown1617.xlsx"
	dbms=xlsx
	replace;
	sheet="ffs_mult";
run;

proc export data=ffsptd_mult_breakdown16
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptdinc_breakdown1617.xlsx"
	dbms=xlsx
	replace;
	sheet="ffs_mult16";
run;

proc export data=ffsptd_mult_breakdown17
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptdinc_breakdown1617.xlsx"
	dbms=xlsx
	replace;
	sheet="ffs_mult17";
run;

* Location of incidence;
proc freq data=ffsptdinc_breakdown1;
	table incyr*loc / out=ffsptd_location outpct; 
run;

proc export data=ffsptd_location
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptdinc_breakdown1617.xlsx"
	dbms=xlsx
	replace;
	sheet="ffs_location";
run;

