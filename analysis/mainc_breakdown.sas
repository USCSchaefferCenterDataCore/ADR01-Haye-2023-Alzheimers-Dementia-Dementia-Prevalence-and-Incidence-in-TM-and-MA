/*********************************************************************************************/
title1 'Exploring AD Incidence Definition';

* Author: PF;
* Purpose: ADRD inc verified breakdown by first dx;
* Input: incidence dataset, yearly flags;

options compress=yes nocenter ls=150 ps=200 errors=5 mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

options obs=max;
data maptdinc_breakdown;
	merge maptd_inc (in=a keep=bene_id inc2016 inc2017 female age_d2016: age_d2017: cci2016 cci2017 race_d: dual: lis: where=(inc2016 or inc2017))
	&outlib..adrdinc_dxrxsymp_yrly_1yrv2016ma
	&outlib..adrdinc_dxrxsymp_yrly_1yrv2017ma ;
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

proc sort data=maptdinc_breakdown; by bene_id firstdt; run;

data maptdinc_breakdown1;
	merge maptdinc_breakdown (in=a) demdx.dementia_dt_ma15_18 (in=b keep=bene_id clm_thru_dt dxtypes claim_types rename=(clm_thru_dt=firstdt));
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
	else if find(firstinctype,'2') then loc_rx=1;
	else check=1;

run;

proc freq data=maptdinc_breakdown1;
	table firstinctype*(firstdx firstmci firstsymp firstrx)/ missing;
run;

proc freq data=maptdinc_breakdown1;
	where firstsymp;
	table firstinctype*dxtypes / missing;
run;

proc freq data=maptdinc_breakdown1 noprint;
	where firstmult=1;
	table firstdx*firstrx*firstmci*firstsymp / out=maptd_mult_breakdown;
run;

proc freq data=maptdinc_breakdown1 noprint;
	where firstmult=1 and incyr=2016;
	table firstdx*firstrx*firstmci*firstsymp / out=maptd_mult_breakdown16;
run;

proc freq data=maptdinc_breakdown1 noprint;
	where firstmult=1 and incyr=2017;
	table firstdx*firstrx*firstmci*firstsymp / out=maptd_mult_breakdown17;
run;

data maptdinc_breakdown_;
	set maptdinc_breakdown1;
	if firstmult=1 then do;
				firstdx=0;
				firstrx=0;
				firstmci=0;
				firstsymp=0;
	end;

	* making one set of age variables for weighting ;
	if incyr=2016 then do;
		age_dlt70=age_d2016_lt70;
		age_d7074=age_d2016_7074;
		age_d7579=age_d2016_7579;
		age_dge80=age_d2016_ge80;
		dual=dual2016;
		lis=lis2016;
	end;

	if incyr=2017 then do;
		age_dlt70=age_d2017_lt70;
		age_d7074=age_d2017_7074;
		age_d7579=age_d2017_7579;
		age_dge80=age_d2017_ge80;
		dual=dual2017;
		lis=lis2017;
	end;

run;

proc means data=maptdinc_breakdown_ noprint;
	class incyr;
	var firstdx firstrx firstmci firstsymp firstmult loc_:;
	output out=maptdinc_breakdown_stats sum()= mean()= lclm()= uclm()= / autoname;
run;

proc export data=maptdinc_breakdown_stats
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptdinc_breakdown1617.xlsx"
	dbms=xlsx
	replace;
	sheet="ma";
run;

proc export data=maptd_mult_breakdown
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptdinc_breakdown1617.xlsx"
	dbms=xlsx
	replace;
	sheet="ma_mult";
run;

proc export data=maptd_mult_breakdown16
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptdinc_breakdown1617.xlsx"
	dbms=xlsx
	replace;
	sheet="ma_mult16";
run;

proc export data=maptd_mult_breakdown17
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptdinc_breakdown1617.xlsx"
	dbms=xlsx
	replace;
	sheet="ma_mult17";
run;

* Weighted breakdown;
proc freq data=maptdinc_breakdown_ noprint;
	where incyr=2016;
	table female*age_dge80*age_d7579*age_d7074*age_dlt70*race_do*race_dn*race_da*race_dh*race_db*race_dw / out=mainc_dist16  (rename=(count=countma percent=pctma));
run;

proc freq data=maptdinc_breakdown_ noprint;
	where incyr=2017;
	table female*age_dge80*age_d7579*age_d7074*age_dlt70*race_do*race_dn*race_da*race_dh*race_db*race_dw / out=mainc_dist17 (rename=(count=countma percent=pctma));
run;

data weight_breakdown16;
	merge &tempwork..ffsptd_incweights16 (in=a rename=(age_d2016_ge80=age_dge80 age_d2016_7579=age_d7579 age_d2016_7074=age_d7074 age_d2016_lt70=age_dlt70)) mainc_dist16 (in=b);
	by female age_dge80 age_d7579 age_d7074 age_dlt70 race_do race_dn race_da race_dh race_db race_dw;
	weight=(percent/100)/countma;
	incyr=2016;
run;

data weight_breakdown17;
	merge &tempwork..ffsptd_incweights17 (in=a rename=(age_d2017_ge80=age_dge80 age_d2017_7579=age_d7579 age_d2017_7074=age_d7074 age_d2017_lt70=age_dlt70)) mainc_dist17 (in=b);
	by female age_dge80 age_d7579 age_d7074 age_dlt70 race_do race_dn race_da race_dh race_db race_dw;
	weight=(percent/100)/countma;
	incyr=2017;
run;

data weight_breakdown;
	set weight_breakdown16 weight_breakdown17;
run;

proc sort data=weight_breakdown; by incyr female age_dge80 age_d7579 age_d7074 age_dlt70 race_do race_dn race_da race_dh race_db race_dw; run;
proc sort data=maptdinc_breakdown_; by incyr female age_dge80 age_d7579 age_d7074 age_dlt70 race_do race_dn race_da race_dh race_db race_dw; run;

data maptdinc_breakdown_w;
	merge maptdinc_breakdown_(in=a) weight_breakdown (in=b);
	by incyr female age_dge80 age_d7579 age_d7074 age_dlt70 race_do race_dn race_da race_dh race_db race_dw;
run; 

proc means data=maptdinc_breakdown_w noprint;
	weight weight;
	class incyr;
	var firstdx firstrx firstmci firstsymp firstmult loc:;
	output out=maptdinc_breakdown_stats_w sum()= mean()= lclm()= uclm()= / autoname;
run;

proc export data=maptdinc_breakdown_stats_w
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptdinc_breakdown1617.xlsx"
	dbms=xlsx
	replace;
	sheet="ma_w";
run;

proc export data=maptdinc_breakdown_stats
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptdinc_breakdown1617.xlsx"
	dbms=xlsx
	replace;
	sheet="ma";
run;

* Weighted breakdown with SES;
proc freq data=maptdinc_breakdown_ noprint;
	where incyr=2016;
	table female*age_dge80*age_d7579*age_d7074*age_dlt70*race_do*race_dn*race_da*race_dh*race_db*race_dw*dual*lis / out=mainc_dist16ses  (rename=(count=countma percent=pctma));
run;

proc freq data=maptdinc_breakdown_ noprint;
	where incyr=2017;
	table female*age_dge80*age_d7579*age_d7074*age_dlt70*race_do*race_dn*race_da*race_dh*race_db*race_dw*dual*lis / out=mainc_dist17ses (rename=(count=countma percent=pctma));
run;

data weight_breakdown16ses;
	merge &tempwork..ffsptd_incweights16ses (in=a rename=(age_d2016_ge80=age_dge80 age_d2016_7579=age_d7579 age_d2016_7074=age_d7074 age_d2016_lt70=age_dlt70 dual2016=dual lis2016=lis)) mainc_dist16ses (in=b);
	by female age_dge80 age_d7579 age_d7074 age_dlt70 race_do race_dn race_da race_dh race_db race_dw dual lis;
	weight=(percent/100)/countma;
	incyr=2016;
	if a and b;
run;

data weight_breakdown17ses;
	merge &tempwork..ffsptd_incweights17ses (in=a rename=(age_d2017_ge80=age_dge80 age_d2017_7579=age_d7579 age_d2017_7074=age_d7074 age_d2017_lt70=age_dlt70 dual2017=dual lis2017=lis)) mainc_dist17ses (in=b);
	by female age_dge80 age_d7579 age_d7074 age_dlt70 race_do race_dn race_da race_dh race_db race_dw dual lis;
	weight=(percent/100)/countma;
	incyr=2017;
	if a and b;
run;

data weight_breakdownses;
	set weight_breakdown16ses weight_breakdown17ses;
run;

proc sort data=weight_breakdownses; by incyr female age_dge80 age_d7579 age_d7074 age_dlt70 race_do race_dn race_da race_dh race_db race_dw dual lis; run;
proc sort data=maptdinc_breakdown_; by incyr female age_dge80 age_d7579 age_d7074 age_dlt70 race_do race_dn race_da race_dh race_db race_dw dual lis; run;

data maptdinc_breakdown_wses;
	merge maptdinc_breakdown_(in=a) weight_breakdownses (in=b);
	by incyr female age_dge80 age_d7579 age_d7074 age_dlt70 race_do race_dn race_da race_dh race_db race_dw dual lis;
run; 

proc means data=maptdinc_breakdown_wses noprint;
	weight weight;
	class incyr;
	var firstdx firstrx firstmci firstsymp firstmult loc:;
	output out=maptdinc_breakdown_stats_wses sum()= mean()= lclm()= uclm()= / autoname;
run;

proc export data=maptdinc_breakdown_stats_wses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maptdinc_breakdown1617.xlsx"
	dbms=xlsx
	replace;
	sheet="ma_wses";
run;


