/*********************************************************************************************/
title1 'Exploring AD Incidence Definition';

* Author: PF;
* Purpose: ADRD prevalence verified breakdown by first dx;
* Input: incidence dataset, yearly flags;

options compress=yes nocenter ls=150 ps=200 errors=5 mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

options obs=max;
data prev_location16;
	merge ffsptd_prev (in=a keep=bene_id prev2016 where=(prev2016)) 
		&outlib..adrdinc_dxrxsymp_yrly_1yrv2016;
	by bene_id;
	if a;
	prevyr=2016;
	rename scen_dxrxsymp_inc2016=prevdt scen_dxrxsymp_inctype2016=inctype;
run;

data prev_location17;
	merge ffsptd_prev (in=a keep=bene_id prev2017 where=(prev2017)) 
		&outlib..adrdinc_dxrxsymp_yrly_1yrv2017;
	by bene_id;
	if a;
	prevyr=2017;
	rename scen_dxrxsymp_inc2017=prevdt scen_dxrxsymp_inctype2017=inctype;
run;

data prev_location;
	set prev_location16 prev_location17;
run;

proc sort data=prev_location; by bene_id prevdt; run;

data prev_location1;
	merge prev_location (in=a) demdx.dementia_dt_1999_2021 (in=b keep=bene_id demdx_dt dxtypes claim_types rename=(demdx_dt=prevdt));
	by bene_id prevdt;
	if a;
	
	* location;
	if find(claim_types,'5') then loc='car';
	else if find(claim_types,'3') then loc='op';
	else if find(claim_types,'1') then loc='ip';
	else if find(claim_types,'2') then loc='snf';
	else if find(claim_types,'4') then loc='hha';
	else if find(inctype,'2') then loc='rx';
	else check=1;

run;

proc freq data=prev_location1;
	table prevyr*loc / out=ffsptd_prevlocation outpct; 
run;

proc export data=ffsptd_prevlocation
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/ffsptdprev_breakdown1617.xlsx"
	dbms=xlsx
	replace;
	sheet="ffs_prevlocation";
run;
