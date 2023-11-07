/*********************************************************************************************/
title1 'Exploring AD Incidence Definition';

* Author: PF;
* Purpose: T-Tests between MA and FFS prevalence subgroups;

options compress=yes nocenter ls=150 ps=200 errors=5 mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

data maffsprev16_ttest;
	set &tempwork..prev16_ffs_wsub (in=_ffs) &tempwork..prev16_ma_wsub (in=_ma);
	ffs=_ffs;
run;

%macro maffsprevttest(var,val,p,out);
%do yr=16 %to 17;
ods output ConfLimits=maffsprev&yr._ttest_ci_&out.;
ods output ttests=maffsprev&yr._ttest_&out.;
proc ttest data=maffsprev16_ttest;
	where &var.=&val.;
	class ffs;
	var p_&p.;
run;
%end;
%mend;

%maffsprevttest(race_dw,1,race,w);
%maffsprevttest(race_db,1,race,b);
%maffsprevttest(race_dh,1,race,h);
%maffsprevttest(race_da,1,race,a);
%maffsprevttest(race_dn,1,race,n);
%maffsprevttest(race_do,1,race,o);
%maffsprevttest(female,1,sex,f);
%maffsprevttest(female,0,sex,m);

* Stacking all together;
data maffsprev16_ttest_ci;
	set maffsprev16_ttest_ci_w (in=w)
		maffsprev16_ttest_ci_b (in=b)
		maffsprev16_ttest_ci_h (in=h)
		maffsprev16_ttest_ci_n (in=n)
		maffsprev16_ttest_ci_a (in=a)
		maffsprev16_ttest_ci_o (in=o)
		maffsprev16_ttest_ci_f (in=f)
		maffsprev16_ttest_ci_m (in=m)
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

data maffsprev17_ttest_ci;
	set maffsprev17_ttest_ci_w (in=w)
		maffsprev17_ttest_ci_b (in=b)
		maffsprev17_ttest_ci_h (in=h)
		maffsprev17_ttest_ci_n (in=n)
		maffsprev17_ttest_ci_a (in=a)
		maffsprev17_ttest_ci_o (in=o)
		maffsprev17_ttest_ci_f (in=f)
		maffsprev17_ttest_ci_m (in=m)
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

data maffsprev16_ttest;
	set maffsprev16_ttest_w (in=w)
		maffsprev16_ttest_b (in=b)
		maffsprev16_ttest_h (in=h)
		maffsprev16_ttest_n (in=n)
		maffsprev16_ttest_a (in=a)
		maffsprev16_ttest_o (in=o)
		maffsprev16_ttest_f (in=f)
		maffsprev16_ttest_m (in=m)
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

data maffsprev17_ttest;
	set maffsprev17_ttest_w (in=w)
		maffsprev17_ttest_b (in=b)
		maffsprev17_ttest_h (in=h)
		maffsprev17_ttest_n (in=n)
		maffsprev17_ttest_a (in=a)
		maffsprev17_ttest_o (in=o)
		maffsprev17_ttest_f (in=f)
		maffsprev17_ttest_m (in=m)
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

proc export data=maffsprev16_ttest_ci
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsprev_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsprev16_ttest_ci";
run;

proc export data=maffsprev16_ttest
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsprev_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsprev16_ttest";
run;

proc export data=maffsprev17_ttest_ci
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsprev_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsprev17_ttest_ci";
run;

proc export data=maffsprev17_ttest
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsprev_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsprev17_ttest";
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
	var female race_dw race_db race_dh race_da race_dn race_do age_d2016_lt70 age_d2016_7074 age_d2016_7579 age_d2016_ge80 cci2016; 
run;

ods output ConfLimits=maffsprev17_samp_ttest_ci;
ods output ttests=maffsprev17_samp_ttest;
proc ttest data=maffs_prevsamp;
	where prev2017 ne .;
	class ffs;
	var female race_dw race_db race_dh race_da race_dn race_do age_d2017_lt70 age_d2017_7074 age_d2017_7579 age_d2017_ge80 cci2017; 
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






