/*********************************************************************************************/
TITLE1 'Optum MA Sample';

* AUTHOR: Patricia Ferido;

* INPUT: samp_1yrma_2007_2019;

* PURPOSE: Get sample characteristics for the 2017 and 2017 sample enrolled from year t-1 to year t+1;

options compress=yes nocenter ls=150 ps=200 errors=5 errorabend errorcheck=strict mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

libname samp "../../data/sample_selection";
libname optum "/sch-data-library/dua-data/OPTUM-Full/Original_data/Data";
libname onepct "/sch-data-library/dua-data/OPTUM/Original_data/Data/1_Percent";
libname inc "../../data/incidence_methods";
libname ffs "../../data/mavffs";

proc contents data=optum.dod_mbrwdeath; run;
	
proc contents data=optum.dod_mbr_enroll_r; run;
	
proc print data=optum.dod_mbr_enroll_r (obs=100); var patid eligeff eligend lis_dual bus; where bus="MCR"; run;
proc freq data=optum.dod_mbr_enroll_r;
	table bus*lis_dual / out=check missing;
run;

proc print data=check; run;

* Calculate who has dual or lis in 2016 and 2017;
data duallis;
	set optum.dod_mbr_enroll_r (keep=patid eligeff eligend lis_dual bus where=(bus="MCR"));
	duallis2016=0;
	duallis2017=0;
	if lis_dual in('D','L') then do;
		if year(eligeff)<=2016<=year(eligend) then duallis2016=1;
		if year(eligeff)<=2017<=year(eligend) then duallis2017=1;
	end;
run;

proc means data=duallis noprint nway;
	class patid;
	var duallis:;
	output out=duallis_max (drop=_type_ _freq_) max()=;
run;

proc print data=duallis_max (obs=100); run;
	
data ffs.bene_duallis1617;
	set duallis_max;
run;



