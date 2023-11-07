/*********************************************************************************************/
title1 'Exploring AD Incidence Definition';

* Author: PF;
* Purpose: Unadjusted Incidence for overall population (TM and MA);

options compress=yes nocenter ls=150 ps=200 errors=5 mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

/* Combine all and MA incidence */
data allptd_inc;
	set ffsptd_inc ad.maptd_inc1yrv1617;
run;

/**** Unadjusted Incidence  ****/
* inc; 
%macro unadjinc(out,subgroup=,class=);
%do yr=2016 %to 2017;
proc means data=allptd_inc noprint nway;
	where inc&yr. ne .;
	&subgroup. class &class.;
	var inc&yr.;
	output out=allptd_unadjinc&out.&yr. sum()= mean()= lclm()= uclm()= / autoname;
run;

proc export data=allptd_unadjinc&out.&yr.
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/allptd_unadjinc1617.xlsx"
	dbms=xlsx
	replace;
	sheet="unadjallinc_&out.&yr.";
run;
%end;
%mend;

* overall;
%unadjinc(overall,subgroup=*);

* by sex;
%unadjinc(bysex,class=female);

* by age;
%unadjinc(byage,class=age_5y&yr.);

* by race;
%unadjinc(byrace,class=race_bg);

* by dual;
%unadjinc(bydual,class=dual&yr.);

* by lis;
%unadjinc(bylis,class=lis&yr.);

/* Age-Adjust sex (male reference) and race (white reference) */
%macro allageadj(refvalue,refvar,out);
%do yr=2016 %to 2017;
proc freq data=allptd_inc noprint;
	where inc&yr. ne . and &refvar.=&refvalue.;
	table age_5y&yr. / out=agedist_ref&out.&yr.(rename=(count=count_ref percent=pct_ref));
run;

proc freq data=allptd_inc noprint;
	where inc&yr. ne .;
	table age_5y&yr.*&refvar. / out=agedist_&out.&yr. (keep=count age_5y&yr. &refvar.) outpct;
run;

data age_weight&out.&yr.;
	merge agedist_ref&out.&yr. (in=a) agedist_&out.&yr. (in=b);
	by age_5y&yr.;
	weight=(pct_ref/100)/count;
run;

proc sort data=age_weight&out.&yr.; by &refvar. age_5y&yr.; run;
proc sort data=allptd_inc out=allptd_inc&yr.; where inc&yr. ne .; by &refvar. age_5y&yr.; run;

data deminc16allw_&out.&yr.;
	merge allptd_inc&yr. (in=a keep=bene_id &refvar. age_5y&yr. inc&yr.) age_weight&out.&yr. (in=b);
	by &refvar. age_5y&yr.;
run;

proc means data=deminc16allw_&out.&yr. noprint nway;
	class &refvar.;
	weight weight;
	var inc&yr.;
	output out=deminc16all_by&out.&yr._adj sum()= mean()= lclm()= uclm()= / autoname;
run; 

proc export data=deminc16all_by&out.&yr._adj
	outfile="&rootpath./Projects/Programs/ad_incidence_methods/exports/allptd_unadjinc1617.xlsx"
	dbms=xlsx
	replace;
	sheet="unadjincall_by&out.&yr._adj";
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
