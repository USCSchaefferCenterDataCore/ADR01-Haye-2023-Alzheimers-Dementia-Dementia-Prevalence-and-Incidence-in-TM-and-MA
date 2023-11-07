/*********************************************************************************************/
title1 'Exploring AD Incidence Definition';

* Author: PF;
* Purpose: Unadjusted Prevalence for overall population (TM and MA);

options compress=yes nocenter ls=150 ps=200 errors=5 mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

/* Combine all and MA prevalence */
data allptd_prev;
	set ffsptd_prev ad.maptd_prev1yrv1617;
run;

/**** Unadjusted Prevalence ****/
* Prev; 
%macro unadjprev(out,subgroup=,class=);
%do yr=2016 %to 2017;
proc means data=allptd_prev noprint nway;
	where prev&yr. ne .;
	&subgroup. class &class.;
	var prev&yr.;
	output out=allptd_unadjprev&out.&yr. sum()= mean()= lclm()= uclm()= / autoname;
run;

proc export data=allptd_unadjprev&out.&yr.
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/allptd_unadjprev1617.xlsx"
	dbms=xlsx
	replace;
	sheet="unadjallprev_&out.&yr.";
run;
%end;
%mend;

* overall;
%unadjprev(overall,subgroup=*);

* by sex;
%unadjprev(bysex,class=female);

* by age;
%unadjprev(byage,class=age_5y&yr.);

* by race;
%unadjprev(byrace,class=race_bg);

* by dual;
%unadjprev(bydual,class=dual&yr.);

* by lis;
%unadjprev(bylis,class=lis&yr.);

/* Age-Adjust sex (male reference) and race (white reference) */
%macro allageadj(refvalue,refvar,out);
%do yr=2016 %to 2017;
proc freq data=allptd_prev noprint;
	where prev&yr. ne . and &refvar.=&refvalue.;
	table age_5y&yr. / out=agedist_ref&out.&yr.(rename=(count=count_ref percent=pct_ref));
run;

proc freq data=allptd_prev noprint;
	where prev&yr. ne .;
	table age_5y&yr.*&refvar. / out=agedist_&out.&yr. (keep=count age_5y&yr. &refvar.) outpct;
run;

data age_weight&out.&yr.;
	merge agedist_ref&out.&yr. (in=a) agedist_&out.&yr. (in=b);
	by age_5y&yr.;
	weight=(pct_ref/100)/count;
run;

proc sort data=age_weight&out.&yr.; by &refvar. age_5y&yr.; run;
proc sort data=allptd_prev out=allptd_prev&yr.; where prev&yr. ne .; by &refvar. age_5y&yr.; run;

data demprev16allw_&out.&yr.;
	merge allptd_prev&yr. (in=a keep=bene_id &refvar. age_5y&yr. prev&yr.) age_weight&out.&yr. (in=b);
	by &refvar. age_5y&yr.;
run;

proc means data=demprev16allw_&out.&yr. noprint nway;
	class &refvar.;
	weight weight;
	var prev&yr.;
	output out=demprev16all_by&out.&yr._adj sum()= mean()= lclm()= uclm()= / autoname;
run; 

proc export data=demprev16all_by&out.&yr._adj
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/allptd_unadjprev1617.xlsx"
	dbms=xlsx
	replace;
	sheet="unadjprevall_by&out.&yr._adj";
run;
%end;
%mend;

* Sex;
%allageadj(0,female,sex);

* Race;
%allageadj("1",race_bg,race);

* dual;
%allageadj(0,dual&yr.,dual);

* lis;
%allageadj(0,lis&yr.,lis);
