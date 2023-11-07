/*********************************************************************************************/
title1 'Exploring AD Incidence Definition';

* Author: PF;
* Purpose: T-Tests between MA and FFS prevalence subgroups;

options compress=yes nocenter ls=150 ps=200 errors=5 mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

data maffsprev16_ttestses;
	set &tempwork..prev16_ffs_wsubses (in=_ffs) &tempwork..prev16_ma_wsubses (in=_ma);
	ffs=_ffs;
run;

%macro maffsprevttestses(var,val,p,out);
%do yr=16 %to 17;
ods output ConfLimits=maffsprev&yr._ttest_ci_&out.ses;
ods output ttests=maffsprev&yr._ttest_&out.ses;
proc ttest data=maffsprev16_ttestses;
	where &var.=&val.;
	class ffs;
	var p_&p.;
run;
%end;
%mend;

%maffsprevttestses(race_dw,1,race,w);
%maffsprevttestses(race_db,1,race,b);
%maffsprevttestses(race_dh,1,race,h);
%maffsprevttestses(race_da,1,race,a);
%maffsprevttestses(race_dn,1,race,n);
%maffsprevttestses(race_do,1,race,o);
%maffsprevttestses(female,1,sex,f);
%maffsprevttestses(female,0,sex,m);

* Stacking all together;
data maffsprev16_ttest_cises;
	set maffsprev16_ttest_ci_wses (in=w)
		maffsprev16_ttest_ci_bses (in=b)
		maffsprev16_ttest_ci_hses (in=h)
		maffsprev16_ttest_ci_nses (in=n)
		maffsprev16_ttest_ci_ases (in=a)
		maffsprev16_ttest_ci_oses (in=o)
		maffsprev16_ttest_ci_fses (in=f)
		maffsprev16_ttest_ci_mses (in=m)
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

data maffsprev17_ttest_cises;
	set maffsprev17_ttest_ci_wses (in=w)
		maffsprev17_ttest_ci_bses (in=b)
		maffsprev17_ttest_ci_hses (in=h)
		maffsprev17_ttest_ci_nses (in=n)
		maffsprev17_ttest_ci_ases (in=a)
		maffsprev17_ttest_ci_oses (in=o)
		maffsprev17_ttest_ci_fses (in=f)
		maffsprev17_ttest_ci_mses (in=m)
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

data maffsprev16_ttestses;
	set maffsprev16_ttest_wses (in=w)
		maffsprev16_ttest_bses (in=b)
		maffsprev16_ttest_hses (in=h)
		maffsprev16_ttest_nses (in=n)
		maffsprev16_ttest_ases (in=a)
		maffsprev16_ttest_oses (in=o)
		maffsprev16_ttest_fses (in=f)
		maffsprev16_ttest_mses (in=m)
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

data maffsprev17_ttestses;
	set maffsprev17_ttest_wses (in=w)
		maffsprev17_ttest_bses (in=b)
		maffsprev17_ttest_hses (in=h)
		maffsprev17_ttest_nses (in=n)
		maffsprev17_ttest_ases (in=a)
		maffsprev17_ttest_oses (in=o)
		maffsprev17_ttest_fses (in=f)
		maffsprev17_ttest_mses (in=m)
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

proc export data=maffsprev16_ttest_cises
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsprev_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsprev16_ttest_cises";
run;

proc export data=maffsprev16_ttestses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsprev_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsprev16_ttestses";
run;

proc export data=maffsprev17_ttest_cises
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsprev_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsprev17_ttest_cises";
run;

proc export data=maffsprev17_ttestses
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsprev_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsprev17_ttestses";
run;

/**** T-tests on sample differences ****/
data maffs_prevsamp;
	set ad.maptd_prev1yrv1617 (in=_ma) ad.ffsptd_prev1yrv1617 (in=_ffs);
	ffs=_ffs;
run;

ods output ConfLimits=maffsprev16_samp_ttest_ci;
ods output ttests=maffsprev16_samp_ttest;
proc ttest data=maffs_prevsamp;
	where prev2016 ne .;
	class ffs;
	var female race_dw race_db race_dh race_da race_dn race_do age_d2016_lt70 age_d2016_7074 age_d2016_7579 age_d2016_ge80 cci2016 dual2016 lis2016; 
run;

ods output ConfLimits=maffsprev17_samp_ttest_ci;
ods output ttests=maffsprev17_samp_ttest;
proc ttest data=maffs_prevsamp;
	where prev2017 ne .;
	class ffs;
	var female race_dw race_db race_dh race_da race_dn race_do age_d2017_lt70 age_d2017_7074 age_d2017_7579 age_d2017_ge80 cci2017 dual2017 lis2017; 
run;

proc export data=maffsprev16_samp_ttest_ci
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsprev_samp_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsprev16_samp_ttest_ci";
run;

proc export data=maffsprev16_samp_ttest
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsprev_samp_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsprev16_samp_ttest";
run;

proc export data=maffsprev17_samp_ttest_ci
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsprev_samp_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsprev17_samp_ttest_ci";
run;

proc export data=maffsprev17_samp_ttest
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsprev_samp_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsprev17_samp_ttest";
run;






