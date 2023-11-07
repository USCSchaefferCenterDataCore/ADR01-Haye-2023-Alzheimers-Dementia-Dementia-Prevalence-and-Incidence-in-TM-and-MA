/*********************************************************************************************/
title1 'Exploring AD Incidence Definition';

* Author: PF;
* Purpose: T-Tests between MA and FFS incidence subgroups;

options compress=yes nocenter ls=150 ps=200 errors=5 mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

data maffsinc16_ttestses;
	set &tempwork..inc16_ffs_wsubses (in=_ffs) &tempwork..inc16_ma_wsubses (in=_ma);
	ffs=_ffs;
run;

%macro maffsincttestses(var,val,p,out);
%do yr=16 %to 17;
ods output ConfLimits=maffsinc&yr._ttest_ci_&out.ses;
ods output ttests=maffsinc&yr._ttest_&out.ses;
proc ttest data=maffsinc16_ttestses;
	where &var.=&val.;
	class ffs;
	var p_&p.;
run;
%end;
%mend;

%maffsincttestses(race_dw,1,race,w);
%maffsincttestses(race_db,1,race,b);
%maffsincttestses(race_dh,1,race,h);
%maffsincttestses(race_da,1,race,a);
%maffsincttestses(race_dn,1,race,n);
%maffsincttestses(race_do,1,race,o);
%maffsincttestses(female,1,sex,f);
%maffsincttestses(female,0,sex,m);

* Stacking all together;
data maffsinc16_ttest_cises;
	set maffsinc16_ttest_ci_wses (in=w)
		maffsinc16_ttest_ci_bses (in=b)
		maffsinc16_ttest_ci_hses (in=h)
		maffsinc16_ttest_ci_nses (in=n)
		maffsinc16_ttest_ci_ases (in=a)
		maffsinc16_ttest_ci_oses (in=o)
		maffsinc16_ttest_ci_fses (in=f)
		maffsinc16_ttest_ci_mses (in=m)
		;
	if w then sub='w';
	if b then sub='b';
	if h then sub='h';
	if a then sub='a';
	if n then sub='n';
	if o then sub='o';
	if f then sub='f';
	if m then sub='m';
run;

data maffsinc17_ttest_cises;
	set maffsinc17_ttest_ci_wses (in=w)
		maffsinc17_ttest_ci_bses (in=b)
		maffsinc17_ttest_ci_hses (in=h)
		maffsinc17_ttest_ci_nses (in=n)
		maffsinc17_ttest_ci_ases (in=a)
		maffsinc17_ttest_ci_oses (in=o)
		maffsinc17_ttest_ci_fses (in=f)
		maffsinc17_ttest_ci_mses (in=m)
		;
	if w then sub='w';
	if b then sub='b';
	if h then sub='h';
	if a then sub='a';
	if n then sub='n';
	if o then sub='o';
	if f then sub='f';
	if m then sub='m';
run;

data maffsinc16_ttestses;
	set maffsinc16_ttest_wses (in=w)
		maffsinc16_ttest_bses (in=b)
		maffsinc16_ttest_hses (in=h)
		maffsinc16_ttest_nses (in=n)
		maffsinc16_ttest_ases (in=a)
		maffsinc16_ttest_oses (in=o)
		maffsinc16_ttest_fses (in=f)
		maffsinc16_ttest_mses (in=m)
		;
	if w then sub='w';
	if b then sub='b';
	if h then sub='h';
	if a then sub='a';
	if n then sub='n';
	if o then sub='o';
	if f then sub='f';
	if m then sub='m';
run;

data maffsinc17_ttestses;
	set maffsinc17_ttest_wses (in=w)
		maffsinc17_ttest_bses (in=b)
		maffsinc17_ttest_hses (in=h)
		maffsinc17_ttest_nses (in=n)
		maffsinc17_ttest_ases (in=a)
		maffsinc17_ttest_oses (in=o)
		maffsinc17_ttest_fses (in=f)
		maffsinc17_ttest_mses (in=m)
		;
	if w then sub='w';
	if b then sub='b';
	if h then sub='h';
	if a then sub='a';
	if n then sub='n';
	if o then sub='o';
	if f then sub='f';
	if m then sub='m';
run;

proc export data=maffsinc16_ttest_cises
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsinc_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsinc16_ttest_cises";
run;

proc export data=maffsinc16_ttestses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsinc_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsinc16_ttestses";
run;

proc export data=maffsinc17_ttest_cises
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsinc_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsinc17_ttest_cises";
run;

proc export data=maffsinc17_ttestses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsinc_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsinc17_ttestses";
run;

/**** T-tests on sample differences ****/
data maffs_incsamp;
	set ad.maptd_inc1yrv1617 (in=_ma) ad.ffsptd_inc1yrv1617 (in=_ffs);
	ffs=_ffs;
run;

ods output ConfLimits=maffsinc16_samp_ttest_ci;
ods output ttests=maffsinc16_samp_ttest;
proc ttest data=maffs_incsamp;
	where inc2016 ne .;
	class ffs;
	var female race_dw race_db race_dh race_da race_dn race_do age_d2016_lt70 age_d2016_7074 age_d2016_7579 age_d2016_ge80 cci2016 dual2016 lis2016; 
run;

ods output ConfLimits=maffsinc17_samp_ttest_ci;
ods output ttests=maffsinc17_samp_ttest;
proc ttest data=maffs_incsamp;
	where inc2017 ne .;
	class ffs;
	var female race_dw race_db race_dh race_da race_dn race_do age_d2017_lt70 age_d2017_7074 age_d2017_7579 age_d2017_ge80 cci2017 dual2017 lis2017; 
run;

proc export data=maffsinc16_samp_ttest_ci
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsinc_samp_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsinc16_samp_ttest_ci";
run;

proc export data=maffsinc16_samp_ttest
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsinc_samp_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsinc16_samp_ttest";
run;

proc export data=maffsinc17_samp_ttest_ci
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsinc_samp_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsinc17_samp_ttest_ci";
run;

proc export data=maffsinc17_samp_ttest
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsinc_samp_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsinc17_samp_ttest";
run;






