/*********************************************************************************************/
title1 'Exploring AD Incidence Definition';

* Author: PF;
* Purpose: ADRD prevalence verified breakdown by first dx;
* Input: incidence dataset, yearly flags;

options compress=yes nocenter ls=150 ps=200 errors=5 mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

options obs=max;
data prev_location16ma;
	merge maptd_prev (in=a keep=bene_id prev2016 age_d2016: female race_d: cci2016 dual: lis: where=(prev2016)) 
		&outlib..adrdinc_dxrxsymp_yrly_1yrv2016ma;
	by bene_id;
	if a;
	prevyr=2016;
	rename scen_dxrxsymp_inc2016=prevdt scen_dxrxsymp_inctype2016=inctype;
run;

data prev_location17ma;
	merge maptd_prev (in=a keep=bene_id prev2017 age_d2017: female race_d: cci2017 dual: lis: where=(prev2017)) 
		&outlib..adrdinc_dxrxsymp_yrly_1yrv2017ma;
	by bene_id;
	if a;
	prevyr=2017;
	rename scen_dxrxsymp_inc2017=prevdt scen_dxrxsymp_inctype2017=inctype;
run;

data prev_locationma;
	set prev_location16ma prev_location17ma;
run;

proc sort data=prev_locationma; by bene_id prevdt; run;

data prev_locationma1;
	merge prev_locationma (in=a) demdx.dementia_dt_ma15_18 (in=b keep=bene_id clm_thru_dt dxtypes claim_types rename=(clm_thru_dt=prevdt));
	by bene_id prevdt;
	if a;
	
	* location;
	loc_car=0;
	loc_op=0;
	loc_ip=0;
	loc_snf=0;
	loc_hha=0;
	loc_rx=0;
	if find(claim_types,'5') then loc_car=1;
	else if find(claim_types,'3') then loc_op=1;
	else if find(claim_types,'1') then loc_ip=1;
	else if find(claim_types,'2') then loc_snf=1;
	else if find(claim_types,'4') then loc_hha=1;
	else if find(inctype,'2') then loc_rx=1;
	else check=1;

	* making one set of age variables for weighting ;
	if prevyr=2016 then do;
		age_dlt70=age_d2016_lt70;
		age_d7074=age_d2016_7074;
		age_d7579=age_d2016_7579;
		age_dge80=age_d2016_ge80;
		dual=dual2016;
		lis=lis2016;
	end;

	if prevyr=2017 then do;
		age_dlt70=age_d2017_lt70;
		age_d7074=age_d2017_7074;
		age_d7579=age_d2017_7579;
		age_dge80=age_d2017_ge80;
		dual=dual2017;
		lis=lis2017;
	end;

run;

proc means data=prev_locationma1 noprint;
	class prevyr;
	var loc_:;
	output out=maptdprev_breakdown_stats sum()= mean()= lclm()= uclm()= / autoname;
run;

proc export data=maptdprev_breakdown_stats
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptdprev_breakdown1617.xlsx"
	dbms=xlsx
	replace;
	sheet="ma";
run;

* Weighted breakdown;
proc freq data=prev_locationma1 noprint;
	where prevyr=2016;
	table female*age_dge80*age_d7579*age_d7074*age_dlt70*race_do*race_dn*race_da*race_dh*race_db*race_dw / out=maprev_dist16  (rename=(count=countma percent=pctma));
run;

proc freq data=prev_locationma1 noprint;
	where prevyr=2017;
	table female*age_dge80*age_d7579*age_d7074*age_dlt70*race_do*race_dn*race_da*race_dh*race_db*race_dw / out=maprev_dist17 (rename=(count=countma percent=pctma));
run;

data prevweight_breakdown16;
	merge &tempwork..ffsptd_weights16 (in=a rename=(age_d2016_ge80=age_dge80 age_d2016_7579=age_d7579 age_d2016_7074=age_d7074 age_d2016_lt70=age_dlt70)) maprev_dist16 (in=b);
	by female age_dge80 age_d7579 age_d7074 age_dlt70 race_do race_dn race_da race_dh race_db race_dw;
	weight=(percent/100)/countma;
	prevyr=2016;
run;

data prevweight_breakdown17;
	merge &tempwork..ffsptd_weights17 (in=a rename=(age_d2017_ge80=age_dge80 age_d2017_7579=age_d7579 age_d2017_7074=age_d7074 age_d2017_lt70=age_dlt70)) maprev_dist17 (in=b);
	by female age_dge80 age_d7579 age_d7074 age_dlt70 race_do race_dn race_da race_dh race_db race_dw;
	weight=(percent/100)/countma;
	prevyr=2017;
run;

data prevweight_breakdown;
	set prevweight_breakdown16 prevweight_breakdown17;
run;

proc sort data=prevweight_breakdown; by prevyr female age_dge80 age_d7579 age_d7074 age_dlt70 race_do race_dn race_da race_dh race_db race_dw; run;
proc sort data=prev_locationma1; by prevyr female age_dge80 age_d7579 age_d7074 age_dlt70 race_do race_dn race_da race_dh race_db race_dw; run;

data prevweight_breakdown_w;
	merge prev_locationma1 (in=a) prevweight_breakdown (in=b);
	by prevyr female age_dge80 age_d7579 age_d7074 age_dlt70 race_do race_dn race_da race_dh race_db race_dw;
run; 

proc means data=prevweight_breakdown_w noprint;
	weight weight;
	class prevyr;
	var loc:;
	output out=maptdprev_breakdown_stats_w sum()= mean()= lclm()= uclm()= / autoname;
run;

proc export data=maptdprev_breakdown_stats_w
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptdprev_breakdown1617.xlsx"
	dbms=xlsx
	replace;
	sheet="ma_w";
run;


* Weighted breakdown;
proc freq data=prev_locationma1 noprint;
	where prevyr=2016;
	table female*age_dge80*age_d7579*age_d7074*age_dlt70*race_do*race_dn*race_da*race_dh*race_db*race_dw*dual*lis / out=maprev_dist16ses  (rename=(count=countma percent=pctma));
run;

proc freq data=prev_locationma1 noprint;
	where prevyr=2017;
	table female*age_dge80*age_d7579*age_d7074*age_dlt70*race_do*race_dn*race_da*race_dh*race_db*race_dw*dual*lis / out=maprev_dist17ses (rename=(count=countma percent=pctma));
run;

data prevweight_breakdown16ses;
	merge &tempwork..ffsptd_weights16ses (in=a rename=(age_d2016_ge80=age_dge80 age_d2016_7579=age_d7579 age_d2016_7074=age_d7074 age_d2016_lt70=age_dlt70 dual2016=dual lis2016=lis)) maprev_dist16ses (in=b);
	by female age_dge80 age_d7579 age_d7074 age_dlt70 race_do race_dn race_da race_dh race_db race_dw dual lis ;
	weight=(percent/100)/countma;
	prevyr=2016;
run;

data prevweight_breakdown17ses;
	merge &tempwork..ffsptd_weights17ses (in=a rename=(age_d2017_ge80=age_dge80 age_d2017_7579=age_d7579 age_d2017_7074=age_d7074 age_d2017_lt70=age_dlt70 dual2017=dual lis2017=lis)) maprev_dist17ses (in=b);
	by female age_dge80 age_d7579 age_d7074 age_dlt70 race_do race_dn race_da race_dh race_db race_dw dual lis ;
	weight=(percent/100)/countma;
	prevyr=2017;
run;

data prevweight_breakdownses;
	set prevweight_breakdown16ses prevweight_breakdown17ses;
run;

proc sort data=prevweight_breakdownses; by prevyr female age_dge80 age_d7579 age_d7074 age_dlt70 race_do race_dn race_da race_dh race_db race_dw dual lis; run;
proc sort data=prev_locationma1; by prevyr female age_dge80 age_d7579 age_d7074 age_dlt70 race_do race_dn race_da race_dh race_db race_dw dual lis; run;

data prevweight_breakdown_wses;
	merge prev_locationma1 (in=a) prevweight_breakdownses (in=b);
	by prevyr female age_dge80 age_d7579 age_d7074 age_dlt70 race_do race_dn race_da race_dh race_db race_dw;
run; 

proc means data=prevweight_breakdown_wses noprint;
	weight weight;
	class prevyr;
	var loc:;
	output out=maptdprev_breakdown_stats_wses sum()= mean()= lclm()= uclm()= / autoname;
run;

proc export data=maptdprev_breakdown_stats_wses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptdprev_breakdown1617.xlsx"
	dbms=xlsx
	replace;
	sheet="ma_wses";
run;
