/*********************************************************************************************/
title1 'Exploring AD Incidence Definition';

* Author: PF;
* Purpose: T-Tests between MA and FFS incalence subgroups;

options compress=yes nocenter ls=150 ps=200 errors=5 mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

data maffsinc16_ttest;
	set &tempwork..inc16_ffs_wsub (in=_ffs) &tempwork..inc16_ma_wsub (in=_ma);
	ffs=_ffs;
run;

%macro maffsincttest(var,val,p,out);
%do yr=16 %to 17;
ods output ConfLimits=maffsinc&yr._ttest_ci_&out.;
ods output ttests=maffsinc&yr._ttest_&out.;
proc ttest data=maffsinc16_ttest;
	where &var.=&val.;
	class ffs;
	var p_&p.;
run;
%end;
%mend;

%maffsincttest(race_dw,1,race,w);
%maffsincttest(race_db,1,race,b);
%maffsincttest(race_dh,1,race,h);
%maffsincttest(race_da,1,race,a);
%maffsincttest(race_dn,1,race,n);
%maffsincttest(race_do,1,race,o);
%maffsincttest(female,1,sex,f);
%maffsincttest(female,0,sex,m);

* Stacking all together;
data maffsinc16_ttest_ci;
	set maffsinc16_ttest_ci_w (in=w)
		maffsinc16_ttest_ci_b (in=b)
		maffsinc16_ttest_ci_h (in=h)
		maffsinc16_ttest_ci_n (in=n)
		maffsinc16_ttest_ci_a (in=a)
		maffsinc16_ttest_ci_o (in=o)
		maffsinc16_ttest_ci_f (in=f)
		maffsinc16_ttest_ci_m (in=m)
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

data maffsinc17_ttest_ci;
	set maffsinc17_ttest_ci_w (in=w)
		maffsinc17_ttest_ci_b (in=b)
		maffsinc17_ttest_ci_h (in=h)
		maffsinc17_ttest_ci_n (in=n)
		maffsinc17_ttest_ci_a (in=a)
		maffsinc17_ttest_ci_o (in=o)
		maffsinc17_ttest_ci_f (in=f)
		maffsinc17_ttest_ci_m (in=m)
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

data maffsinc16_ttest;
	set maffsinc16_ttest_w (in=w)
		maffsinc16_ttest_b (in=b)
		maffsinc16_ttest_h (in=h)
		maffsinc16_ttest_n (in=n)
		maffsinc16_ttest_a (in=a)
		maffsinc16_ttest_o (in=o)
		maffsinc16_ttest_f (in=f)
		maffsinc16_ttest_m (in=m)
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

data maffsinc17_ttest;
	set maffsinc17_ttest_w (in=w)
		maffsinc17_ttest_b (in=b)
		maffsinc17_ttest_h (in=h)
		maffsinc17_ttest_n (in=n)
		maffsinc17_ttest_a (in=a)
		maffsinc17_ttest_o (in=o)
		maffsinc17_ttest_f (in=f)
		maffsinc17_ttest_m (in=m)
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

proc export data=maffsinc16_ttest_ci
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsinc_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsinc16_ttest_ci";
run;

proc export data=maffsinc16_ttest
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsinc_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsinc16_ttest";
run;

proc export data=maffsinc17_ttest_ci
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsinc_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsinc17_ttest_ci";
run;

proc export data=maffsinc17_ttest
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/maffsinc_ttest.xlsx"
	dbms=xlsx
	replace;
	sheet="maffsinc17_ttest";
run;

