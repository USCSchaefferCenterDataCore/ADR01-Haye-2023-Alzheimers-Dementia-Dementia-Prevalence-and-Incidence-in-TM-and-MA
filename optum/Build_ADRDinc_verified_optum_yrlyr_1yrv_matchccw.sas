/*********************************************************************************************/
title1 'Exploring AD Incidence Definition';

* Author: PF;
* Purpose: 	Verified ADRD Valid Verified Scenarios - verified in 1 year using only information starting in year t on
		- 1) ADRD + RX drug
		- 2) ADRD + ADRD 
		- 3) ADRD + Dementia Symptoms
		- 4) ADRD + Death	
		Merging together AD drugs, Dementia claims, dementia symptoms, specialists,
		& relevant CPT codes to make final analytical file
		- Adding limits to the verifications:
			- Death needs to occur within a year for it to count as a verify condition;

* Input: dementia_dxdt20072019, dementia_rxdt20072019;
* Output: yearly verification by dx, rx, symp;

options compress=yes nocenter ls=150 ps=200 errors=5 mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

libname samp "../../data/sample_selection";
libname demdx "../../data/dementia";
libname optum "/sch-data-library/dua-data/OPTUM-Full/Original_data/Data";
libname onepct "/sch-data-library/dua-data/OPTUM/Original_data/Data/1_Percent";
libname inc "../../data/incidence_methods";
libname temp "../../data/temp";
%let tempwork=temp;
%let outlib=inc;

* only doing from these years to match MA;
%let minyear=2015;
%let mindatayear=2015;
%let maxyear=2018;

options obs=max;

***** Defining ICD-10 using new 2017 30 CCW definition;
%let icd10dx="F0150" "F0151" "F0280" "F0281" "F0390" "F0391" "F05" "G138" "G3101" "G3109" "G311" "G312" "G3183" "G94" "R4181" "G300" "G301" "G308" "G309";
***** Defining ICD-9 as old definition but adding in dementia with lewy-bodies;
%let icd9dx="3310"  "33111" "33119" "3312"  "3317"  "2900"  "29010"
            "29011" "29012" "29013" "29020" "29021" "2903"  "29040" 
            "29041" "29042" "29043" "29410" "29411" "29420" 
            "29421" "797" "33182" "2940" "2948";


***** Dem symptoms;
%let dem_symp9="78093", "7843", "78469";
%let dem_symp10="R412","R413","R4701","R481","R482","R488";
%let amnesia="R412","R413","78093";
%let aphasia="R4701","7843";
%let agn_apr="R481","R482","R488","78469";
%let mci="33183","G3184";

data _null_;
	time=mdy(12,31,&maxyear.)-mdy(1,1,&mindatayear.)+1;
	call symput('time',time);
run;
/*
***** Creating base file;
data &tempwork..analytical;
	format year best4.;
	merge demdx.dementia_dxdt2007_2019 (in=a rename=fst_dt=date keep=dxtypes patid fst_dt demdx1-demdx25) demdx.dementia_rxdt2007_2019 (in=b rename=fill_dt=date where=(&minyear.<=year(date)<=&maxyear.));
	by patid date;

	year=year(date);

	if patid ne "";
	
	* 2017 transition definition;
	array demdx [*] $ demdx1-demdx25;
	adrddx=0;
	do i=1 to dim(demdx);
		if demdx[i] in(&icd9dx,&icd10dx) then adrddx=1;
	end;

	if find(dxtypes,"p") or find(dxtypes,"m") then symptom=1;
	else symptom=0;
	
	* Identifying symptoms;
	do i=1 to dim(demdx);
			if demdx[i] in(&amnesia) then amnesia=1;
			if demdx[i] in(&aphasia) then aphasia=1;
			if demdx[i] in(&agn_apr) then agn_apr=1;
			if demdx[i] in(&mci) then mci=1;
	end;
	if aphasia=1 then demsymptom_quala="aph";
	if amnesia=1 then demsymptom_qualb="amn";
	if agn_apr=1 then demsymptom_qualc="agn";
	if mci=1 then demsymptom_quald="mci";
	length demsymptoms_desc $12.;
	demsymptoms_desc=demsymptom_quala||demsymptom_qualb||demsymptom_qualc||demsymptom_quald;
	drop demsymptom_qual:;
		
run;

proc sort data=&tempwork..analytical; by patid year date; run;
*/

data &tempwork..analytical1;
	merge &tempwork..analytical (in=a) samp.samp_ma20072019 (in=b keep=patid yrdob death_yr death_mo);
	by patid;
	if a and b;
	samp=b;
	* assuming death date is end of month;
	if death_mo=12 then death_date=mdy(1,1,death_yr)-1;
	else death_date=mdy(death_mo+1,1,death_yr)-1; 
run;

proc freq data=&tempwork..analytical1;
	table samp;
run;


***** Analysis of AD Incidence;
%macro inc_1yrv;
/*
data &outlib..adrdincv1yrv_scen_firstma;
	set &tempwork..analyticalma1;
	by patid year date;
	
	* For everybody, getting date of first AD dx, dementia dx, dementia symptoms, or AD drug use
	- If any of the above dates come before the qualifications for AD outcome below, then that 
	person has no outcome;
	
	%do yr=&minyear. %to &maxyear.;
		length first_adrd_type&yr.  $9. first_symptoms_desc&yr. $12.;
		if (first.year and year=&yr.) or first.patid then do;
			first_dx&yr.=.;
			first_adrd_type&yr.="";
			first_adrx&yr.=.;
			first_symptoms&yr.=.;
			first_symptoms_desc&yr.="";
		end;
		retain first_dx&yr. first_adrx&yr. first_symptoms&yr. first_symptoms_desc&yr. first_adrd_type&yr.;

		* Setting first ADRX, dem symtpoms & ADRD date;
		if year=&yr. then do;
			if first_dx&yr.=. and adrddx=1 then do;
				first_dx&yr.=date;
				first_adrd_type&yr.=dxtypes;
			end;
			if first_adrx&yr.=. and ADdrug=1 then first_adrx&yr.=date;
			if first_symptoms&yr.=. and symptom=1 then do;
				first_symptoms&yr.=date;
				first_symptoms_desc&yr.=demsymptoms_desc;
			end;
		end;
		format first_dx&yr. first_adrx&yr. first_symptoms&yr. death_date mmddyy10.;
	%end;

	if last.patid;
run;

data &outlib..adrdincv1yrv_scendx_longma;
	set &tempwork..analyticalma1;
	by patid year date;

	* Scenario 1: Two records of AD Diagnosis;
	
	%do yr=&minyear. %to &maxyear;
		retain scen_dx_inc&yr. scen_dx_vtime&yr. scen_dx_dx2dt&yr. scen_dx_inctype&yr. scen_dx_vtype&yr. scen_dx_vdt&yr. ;
		format scen_dx_inc&yr. scen_dx_vdt&yr. scen_dx_dx2dt&yr. mmddyy10. scen_dx_inctype&yr. scen_dx_vtype&yr. $4.;
		if (first.year and year=&yr.) or first.patid then do;
			scen_dx_inc&yr.=.;
			scen_dx_inctype&yr.="";
			scen_dx_vtype&yr.="";
			scen_dx_vtime&yr.=.;
			scen_dx_dx2dt&yr.=.;
			scen_dx_vdt&yr.=.;
		end;
		if year>=&yr. then do;
			if adrddx=1 then do;
				if scen_dx_inc&yr.=. and .<date-scen_dx_dx2dt&yr.<=365 then do;
					scen_dx_inc&yr.=scen_dx_dx2dt&yr.;
					scen_dx_vdt&yr.=date;
					scen_dx_vtime&yr.=date-scen_dx_inc&yr.;
					scen_dx_inctype&yr.="1";
					scen_dx_vtype&yr.="1";
				end;
				else if scen_dx_inc&yr.=. and year(date)=&yr. then scen_dx_dx2dt&yr.=date;
			end;
		end;
	%end;

	* Death scenarios;
	%do yr=&minyear. %to &maxyear.;
	if (first.year and year=&yr.) or first.patid then do;
		death_dx&yr.=.;
		death_dx_type&yr.="    ";
		death_dx_vtime&yr.=.;
	end;
	retain death_dx:;
	format death_dx&yr. death_date mmddyy10.;
	if year=&yr. then do;
		if death_dx&yr.=. and adrddx and .<death_date-date<=365 then do;
			death_dx&yr.=date;
			death_dx_vtime&yr.=death_date-date;
			death_dx_type&yr.="1";
		end;
	end;
	%end;
	
	* Using death scenario as last resort if missing;
	if last.patid then do;
		%do yr=&minyear. %to &maxyear.;
		if scen_dx_inc&yr.=. and death_dx&yr. ne . then do;
			scen_dx_inc&yr.=death_dx&yr.;
			scen_dx_vdt&yr.=death_date;
			scen_dx_vtime&yr.=death_dx_vtime&yr.;
			scen_dx_inctype&yr.=death_dx_type&yr.;
			scen_dx_vtype&yr.="   4";
		end;
		%end;
	end;
	
	%do yr=&minyear. %to &maxyear.;
	if .<scen_dx_vtime&yr.<0 then dropdx&yr.=1;
	
	label 
	scen_dx_inc&yr.="ADRD incident date for scenario using only dx"
	scen_dx_vdt&yr.="Date of verification for scenario using only dx"
	scen_dx_vtime&yr.="Verification time for scenario using only dx"
	scen_dx_inctype&yr.="1-incident date is ADRD dx, 2-incident date is drug use, 3-incident date is dem symptom"
	scen_dx_vtype&yr.="1-verification date is ADRD dx, 2-verification date is drug use, 3-verification date is dem symptom, 4-verified by death"
	;
	%end;
run;

data &outlib..adrdincv1yrv_scendxrx_longma;
	set &tempwork..analyticalma1;
	by patid year date;

	* Scenario RX: dx +dx, dx + Rx;
	array scen_dxrx_dxdt_ [&time.] _temporary_;
	array scen_dxrx_type_ [&time.] $4. _temporary_;

	if first.patid then do;
		do i=1 to &time.;
			scen_dxrx_dxdt_[i]=.;
			scen_dxrx_type_[i]="";
		end;
	end;
	day=date-mdy(1,1,&minyear.)+1;
	start=max(1,date-mdy(1,1,&minyear.)-365+1);
	end=min(day,&time.);
	if (adrddx or ADdrug) and 1<=day<=&time. then do;
		scen_dxrx_dxdt_[day]=date;
		if adrddx then substr(scen_dxrx_type_[day],1,1)="1";
		if addrug then substr(scen_dxrx_type_[day],2,1)="2";
	end;

	%do yr=&minyear. %to &maxyear.;

	*start is capped at start of year;
	startyr_day=mdy(1,1,&yr.)-mdy(1,1,&minyear.)+1;
	start=max(start,startyr_day);

	retain scen_dxrx_inc&yr. scen_dxrx_dxdt&yr. scen_dxrx_dx2dt&yr. scen_dxrx_vdt&yr. scen_dxrx_vtime&yr. scen_dxrx_inctype&yr. scen_dxrx_vtype&yr. scen_dxrx_dx2type&yr.;
	format scen_dxrx_inc&yr. scen_dxrx_dxdt&yr. scen_dxrx_dx2dt&yr. scen_dxrx_vdt&yr. mmddyy10.
		   scen_dxrx_inctype&yr. scen_dxrx_vtype&yr. scen_dxrx_dx2type&yr. $4.;

	if (first.year and year=&yr.) or first.patid then do;
		scen_dxrx_inc&yr.=.;
		scen_dxrx_vtime&yr.=.;
		scen_dxrx_dxdt&yr.=.;
		scen_dxrx_dx2dt&yr.=.;
		scen_dxrx_dx2type&yr.="";
		scen_dxrx_vdt&yr.=.;
		scen_dxrx_inctype&yr.="";
		scen_dxrx_vtype&yr.="";
	end;

	if &yr.<=year<=%eval(&yr.+1) then do;
	if scen_dxrx_inc&yr.=. then do;
		do i=start to end;
			if (find(scen_dxrx_type_[i],"1")) and scen_dxrx_dxdt&yr.=. then scen_dxrx_dxdt&yr.=scen_dxrx_dxdt_[i];	
			* getting second qualifying;
			if scen_dxrx_dx2dt&yr.=. then do;
				if (scen_dxrx_type_[i]="1" and scen_dxrx_dxdt_[i]>scen_dxrx_dxdt&yr.)
				or (find(scen_dxrx_type_[i],"2")) then do;
					scen_dxrx_dx2dt&yr.=scen_dxrx_dxdt_[i];
					scen_dxrx_dx2type&yr.=scen_dxrx_type_[i];
				end;
			end;
		end;
		if scen_dxrx_dxdt&yr. ne . and scen_dxrx_dx2dt&yr. ne .
		and min(year(scen_dxrx_dxdt&yr.),year(scen_dxrx_dx2dt&yr.))=&yr. then do;
			if scen_dxrx_dxdt&yr.<=scen_dxrx_dx2dt&yr. then do;
				scen_dxrx_inc&yr.=scen_dxrx_dxdt&yr.;
				scen_dxrx_vdt&yr.=scen_dxrx_dx2dt&yr.;
				if scen_dxrx_dxdt&yr.<scen_dxrx_dx2dt&yr. then substr(scen_dxrx_inctype&yr.,1,1)="1";
				if scen_dxrx_dxdt&yr.=scen_dxrx_dx2dt&yr. then scen_dxrx_inctype&yr.="12";
				scen_dxrx_vtype&yr.=scen_dxrx_dx2type&yr.;
				scen_dxrx_vtime&yr.=scen_dxrx_dx2dt&yr.-scen_dxrx_dxdt&yr.;
			end;
			if scen_dxrx_dx2dt&yr.<scen_dxrx_dxdt&yr. then do;
				scen_dxrx_inc&yr.=scen_dxrx_dx2dt&yr.;
				scen_dxrx_vdt&yr.=scen_dxrx_dxdt&yr.;
				scen_dxrx_inctype&yr.=scen_dxrx_dx2type&yr.;
				scen_dxrx_vtype&yr.="1";
				scen_dxrx_vtime&yr.=scen_dxrx_dxdt&yr.-scen_dxrx_dx2dt&yr.;
			end;
		end;
		else do;
			scen_dxrx_dxdt&yr.=.;
			scen_dxrx_dx2dt&yr.=.;
			scen_dxrx_dx2type&yr.="";
		end;
	end;
	end;
	%end;

	* Death scenarios;
	%do yr=&minyear. %to &maxyear.;
	if (first.year and year=&yr.) or first.patid then do;
		death_dxrx&yr.=.;
		death_dxrx_type&yr.="    ";
		death_dxrx_vtime&yr.=.;
	end;
	retain death_dx:;
	format death_dxrx&yr. death_date mmddyy10.;
	if year=&yr. then do;
		if death_dxrx&yr.=. and (adrddx) and .<death_date-date<=365 then do;
			death_dxrx&yr.=date;
			death_dxrx_vtime&yr.=death_date-date;
			if adrddx then substr(death_dxrx_type&yr.,1,1)="1";
		end;
	end;

	%end;
	
	* Using death scenario as last resort if missing;
	if last.patid then do;
	%do yr=&minyear. %to &maxyear.;
		if scen_dxrx_inc&yr.=. and death_dxrx&yr. ne . then do;
			scen_dxrx_inc&yr.=death_dxrx&yr.;
			scen_dxrx_vdt&yr.=death_date;
			scen_dxrx_vtime&yr.=death_dxrx_vtime&yr.;
			scen_dxrx_inctype&yr.=death_dxrx_type&yr.;
			scen_dxrx_vtype&yr.="   4";
		end;
		%end;
	end;
	
	%do yr=&minyear. %to &maxyear.;
	if .<scen_dxrx_vtime&yr.<0 then dropdxrx&yr.=1;

	label 
	scen_dxrx_inc&yr.="ADRD incident date for scenario using dx and drugs"
	scen_dxrx_vdt&yr.="Date of verification for scenario using dx and drugs"
	scen_dxrx_vtime&yr.="Verification time for scenario using dx and drugs"
	scen_dxrx_inctype&yr.="1-incident date is ADRD dx, 2-incident date is drug use, 3-incident date is dem symptom"
	scen_dxrx_vtype&yr.="1-verification date is ADRD dx, 2-verification date is drug use, 3-verification date is dem symptom, 4-verified by death"
	;
	%end;

run;

data &outlib..adrdincv1yrv_scendxsymp_longma;
	set &tempwork..analyticalma1;
	by patid year date;

	* Scenario Symp: dx +dx, dx + symp;
	array scen_dxsymp_dxdt_ [&time.] _temporary_;
	array scen_dxsymp_type_ [&time.] $4. _temporary_;
	
	if first.patid then do;
		do i=1 to &time.;
			scen_dxsymp_dxdt_[i]=.;
			scen_dxsymp_type_[i]="";
		end;
	end;
	day=date-mdy(1,1,&minyear.)+1;
	start=max(1,date-mdy(1,1,&minyear.)-365+1);
	end=min(day,&time.);
	if (adrddx or symptom) and 1<=day<=&time. then do;
		scen_dxsymp_dxdt_[day]=date;
		if adrddx then substr(scen_dxsymp_type_[day],1,1)="1";
		if symptom then substr(scen_dxsymp_type_[day],3,1)="3";
	end;

	%do yr=&minyear. %to &maxyear.;

	*start is capped at start of year;
	startyr_day=mdy(1,1,&yr.)-mdy(1,1,&minyear.)+1;
	start=max(start,startyr_day);

	retain scen_dxsymp_inc&yr. scen_dxsymp_dxdt&yr. scen_dxsymp_dx2dt&yr. scen_dxsymp_vdt&yr. scen_dxsymp_vtime&yr. scen_dxsymp_inctype&yr. 
		   scen_dxsymp_vtype&yr. scen_dxsymp_dx2type&yr.;
	format scen_dxsymp_inc&yr. scen_dxsymp_dxdt&yr. scen_dxsymp_dx2dt&yr. scen_dxsymp_vdt&yr. mmddyy10.
				scen_dxsymp_inctype&yr. scen_dxsymp_vtype&yr. scen_dxsymp_dx2type&yr. $4.;
	if (first.year and year=&yr.) or first.patid then do;
		scen_dxsymp_inc&yr.=.;
		scen_dxsymp_vtime&yr.=.;
		scen_dxsymp_dxdt&yr.=.;
		scen_dxsymp_dx2dt&yr.=.;
		scen_dxsymp_dx2type&yr.="";
		scen_dxsymp_vdt&yr.=.;
		scen_dxsymp_inctype&yr.="";
		scen_dxsymp_vtype&yr.="";
	end;
	if &yr.<=year<=%eval(&yr.+1) then do;
		if scen_dxsymp_inc&yr.=. then do;
			do i=start to end;
				if (find(scen_dxsymp_type_[i],"1")) and scen_dxsymp_dxdt&yr.=. then scen_dxsymp_dxdt&yr.=scen_dxsymp_dxdt_[i];	
				* getting second qualifying;
				if scen_dxsymp_dx2dt&yr.=. then do;
					if (scen_dxsymp_type_[i]="1" and scen_dxsymp_dxdt_[i]>scen_dxsymp_dxdt&yr.)
					or (find(scen_dxsymp_type_[i],"3")) then do;
						scen_dxsymp_dx2dt&yr.=scen_dxsymp_dxdt_[i];
						scen_dxsymp_dx2type&yr.=scen_dxsymp_type_[i];
					end;
				end;
			end;
			if scen_dxsymp_dxdt&yr. ne . and scen_dxsymp_dx2dt&yr. ne . 
				and min(year(scen_dxsymp_dxdt&yr.),year(scen_dxsymp_dx2dt&yr.))=&yr. then do; * ensuring that minimum date is in year, otherwise, keep searching;
				if scen_dxsymp_dxdt&yr.<=scen_dxsymp_dx2dt&yr. then do;
					scen_dxsymp_inc&yr.=scen_dxsymp_dxdt&yr.;
					scen_dxsymp_vdt&yr.=scen_dxsymp_dx2dt&yr.;
					if scen_dxsymp_dxdt&yr.<scen_dxsymp_dx2dt&yr. then substr(scen_dxsymp_inctype&yr.,1,1)="1";
					if scen_dxsymp_dxdt&yr.=scen_dxsymp_dx2dt&yr. then scen_dxsymp_inctype&yr.="1 3";
					scen_dxsymp_vtype&yr.=scen_dxsymp_dx2type&yr.;
					scen_dxsymp_vtime&yr.=scen_dxsymp_dx2dt&yr.-scen_dxsymp_dxdt&yr.;
				end;
				if (scen_dxsymp_dx2dt&yr.<scen_dxsymp_dxdt&yr.) then do;
					scen_dxsymp_inc&yr.=scen_dxsymp_dx2dt&yr.;
					scen_dxsymp_vdt&yr.=scen_dxsymp_dxdt&yr.;
					scen_dxsymp_inctype&yr.=scen_dxsymp_dx2type&yr.;
					scen_dxsymp_vtype&yr.="1";
					scen_dxsymp_vtime&yr.=scen_dxsymp_dxdt&yr.-scen_dxsymp_dx2dt&yr.;
				end;
			end;
			else do;
				scen_dxsymp_dxdt&yr.=.;
				scen_dxsymp_dx2dt&yr.=.;
				scen_dxsymp_dx2type&yr.="";
			end;
		end;
	end;
	%end;

	* Death scenarios;
	%do yr=&minyear. %to &maxyear.;
	if (first.year and year=&yr.) or first.patid then do;
		death_dxsymp&yr.=.;
		death_dxsymp_type&yr.="    ";
		death_dxsymp_vtime&yr.=.;
	end;
	retain death_dx:;
	format death_dxsymp&yr. death_date mmddyy10.;
	if year=&yr. then do;
		if death_dxsymp&yr.=. and (adrddx) and .<death_date-date<=365 then do;
			death_dxsymp&yr.=date;
			death_dxsymp_vtime&yr.=death_date-date;
			if adrddx then substr(death_dxsymp_type&yr.,1,1)="1";
		end;
	end;
	%end;
	
	* Using death scenario as last resort if missing;
	if last.patid then do;
		%do yr=&minyear. %to &maxyear.;
		if scen_dxsymp_inc&yr.=. and death_dxsymp&yr. ne . then do;
			scen_dxsymp_inc&yr.=death_dxsymp&yr.;
			scen_dxsymp_vdt&yr.=death_date;
			scen_dxsymp_vtime&yr.=death_dxsymp_vtime&yr.;
			scen_dxsymp_inctype&yr.=death_dxsymp_type&yr.;
			scen_dxsymp_vtype&yr.="   4";
		end;
		%end;
	end;
	
	%do yr=&minyear. %to &maxyear.;
	if .<scen_dxsymp_vtime&yr.<0 then dropdxsymp&yr.=1;
	
	label 
	scen_dxsymp_inc&yr.="ADRD incident date for scenario using dx and symptoms"
	scen_dxsymp_vdt&yr.="Date of verification for scenario using dx and symptoms"
	scen_dxsymp_vtime&yr.="Verification time for scenario using dx and symptoms"
	scen_dxsymp_inctype&yr.="1-incident date is ADRD dx, 2-incident date is drug use, 3-incident date is dem symptom"
	scen_dxsymp_vtype&yr.="1-verification date is ADRD dx, 2-verification date is drug use, 3-verification date is dem symptom, 4-verified by death"
	;
	%end;
run;
*/

data &outlib..adrdincv1yrv_scendxrxsymp_long;
	set &tempwork..analytical1;
	by patid year date;

	* Scenario All: DX, RX, SYmp;
	array scen_dxrxsymp_dxdt_ [&time.] _temporary_;
	array scen_dxrxsymp_type_ [&time.] $4. _temporary_;
	
	if first.patid then do;
		do i=1 to &time.;
			scen_dxrxsymp_dxdt_[i]=.;
			scen_dxrxsymp_type_[i]="";
		end;
	end;

	day=date-mdy(1,1,&minyear.)+1;
	start=max(1,date-mdy(1,1,&minyear.)-365+1);
	end=min(day,&time.);
	if (adrddx or ADdrug or symptom) and 1<=day<=&time. then do;
		scen_dxrxsymp_dxdt_[day]=date;
		if adrddx then substr(scen_dxrxsymp_type_[day],1,1)="1";
		if addrug then substr(scen_dxrxsymp_type_[day],2,1)="2";
		if symptom then substr(scen_dxrxsymp_type_[day],3,1)="3";
	end;
	
	%do yr=&minyear. %to &maxyear.;

	*start is capped at start of year;
	startyr_day=mdy(1,1,&yr.)-mdy(1,1,&minyear.)+1;
	start=max(start,startyr_day);

	retain scen_dxrxsymp_inc&yr. scen_dxrxsymp_dxdt&yr. scen_dxrxsymp_dx2dt&yr. scen_dxrxsymp_vdt&yr. scen_dxrxsymp_vtime&yr. scen_dxrxsymp_inctype&yr. scen_dxrxsymp_vtype&yr. scen_dxrxsymp_dx2type&yr.;
	format scen_dxrxsymp_inc&yr. scen_dxrxsymp_dxdt&yr. scen_dxrxsymp_dx2dt&yr. scen_dxrxsymp_vdt&yr. mmddyy10.
				scen_dxrxsymp_inctype&yr. scen_dxrxsymp_vtype&yr. scen_dxrxsymp_dx2type&yr. $4.;

	if (first.year and year=&yr.) or first.patid then do;
		scen_dxrxsymp_inc&yr.=.;
		scen_dxrxsymp_vtime&yr.=.;
		scen_dxrxsymp_dxdt&yr.=.;
		scen_dxrxsymp_dx2dt&yr.=.;
		scen_dxrxsymp_dx2type&yr.="";
		scen_dxrxsymp_vdt&yr.=.;
		scen_dxrxsymp_inctype&yr.="";
		scen_dxrxsymp_vtype&yr.="";
	end;

	if &yr.<=year<=%eval(&yr.+1) then do;
		if scen_dxrxsymp_inc&yr.=. then do;
			do i=start to end;
				if (find(scen_dxrxsymp_type_[i],"1")) and scen_dxrxsymp_dxdt&yr.=. then scen_dxrxsymp_dxdt&yr.=scen_dxrxsymp_dxdt_[i];	
				* getting second qualifying;
				if scen_dxrxsymp_dx2dt&yr.=. then do;
					if (scen_dxrxsymp_type_[i]="1" and scen_dxrxsymp_dxdt_[i]>scen_dxrxsymp_dxdt&yr.)
					or (find(scen_dxrxsymp_type_[i],"2")) or (find(scen_dxrxsymp_type_[i],"3")) then do;
						scen_dxrxsymp_dx2dt&yr.=scen_dxrxsymp_dxdt_[i];
						scen_dxrxsymp_dx2type&yr.=scen_dxrxsymp_type_[i];
					end;
				end;
			end;
			if scen_dxrxsymp_dxdt&yr. ne . and scen_dxrxsymp_dx2dt&yr. ne .
			and min(year(scen_dxrxsymp_dxdt&yr.),year(scen_dxrxsymp_dx2dt&yr.))=&yr.then do;
				if scen_dxrxsymp_dxdt&yr.<=scen_dxrxsymp_dx2dt&yr. then do;
					scen_dxrxsymp_inc&yr.=scen_dxrxsymp_dxdt&yr.;
					scen_dxrxsymp_vdt&yr.=scen_dxrxsymp_dx2dt&yr.;
					if scen_dxrxsymp_dxdt&yr.<scen_dxrxsymp_dx2dt&yr. then substr(scen_dxrxsymp_inctype&yr.,1,1)="1";
					if scen_dxrxsymp_dxdt&yr.=scen_dxrxsymp_dx2dt&yr. then scen_dxrxsymp_inctype&yr.=scen_dxrxsymp_dx2type&yr.;
					scen_dxrxsymp_vtype&yr.=scen_dxrxsymp_dx2type&yr.;
					scen_dxrxsymp_vtime&yr.=scen_dxrxsymp_dx2dt&yr.-scen_dxrxsymp_dxdt&yr.;
				end;
				if scen_dxrxsymp_dx2dt&yr.<scen_dxrxsymp_dxdt&yr. then do;
					scen_dxrxsymp_inc&yr.=scen_dxrxsymp_dx2dt&yr.;
					scen_dxrxsymp_vdt&yr.=scen_dxrxsymp_dxdt&yr.;
					scen_dxrxsymp_inctype&yr.=scen_dxrxsymp_dx2type&yr.;
					scen_dxrxsymp_vtype&yr.="1";
					scen_dxrxsymp_vtime&yr.=scen_dxrxsymp_dxdt&yr.-scen_dxrxsymp_dx2dt&yr.;
				end;
			end;
			else do;
				scen_dxrxsymp_dxdt&yr.=.;
				scen_dxrxsymp_dx2dt&yr.=.;
				scen_dxrxsymp_dx2type&yr.="";
			end;
		end;
	end;

	%end;

	* Death scenarios;
	%do yr=&minyear. %to &maxyear.;
	if (first.year and year=&yr.) or first.patid then do;
		death_dxrxsymp&yr.=.;
		death_dxrxsymp_type&yr.="    ";
		death_dxrxsymp_vtime&yr.=.;
	end;
	retain death_dx:;
	format death_dxrxsymp&yr. death_date mmddyy10.;
	if year=&yr. then do;
		if death_dxrxsymp&yr.=. and (adrddx) and .<death_date-date<=365 then do;
			death_dxrxsymp&yr.=date;
			death_dxrxsymp_vtime&yr.=death_date-date;
			if adrddx then substr(death_dxrxsymp_type&yr.,1,1)="1";
		end;
	end;

	%end;
	
	* Using death scenario as last resort if missing;
	if last.patid then do;
		%do yr=&minyear. %to &maxyear.;
		if scen_dxrxsymp_inc&yr.=. and death_dxrxsymp&yr. ne . then do;
			scen_dxrxsymp_inc&yr.=death_dxrxsymp&yr.;
			scen_dxrxsymp_vdt&yr.=death_date;
			scen_dxrxsymp_vtime&yr.=death_dxrxsymp_vtime&yr.;
			scen_dxrxsymp_inctype&yr.=death_dxrxsymp_type&yr.;
			scen_dxrxsymp_vtype&yr.="   4";
		end;
		%end;
	end;
	
	%do yr=&minyear. %to &maxyear.;
	if .<scen_dxrxsymp_vtime&yr.<0 then dropdxrxsymp&yr.=1;
	
	label 
	scen_dxrxsymp_inc&yr.="ADRD incident date for scenario using dx, drugs and symptoms"
	scen_dxrxsymp_vdt&yr.="Date of verification for scenario using dx, drugs and symptoms"
	scen_dxrxsymp_vtime&yr.="Verification time for scenario using dx, drugs and symptoms"
	scen_dxrxsymp_inctype&yr.="1-incident date is ADRD dx, 2-incident date is drug use, 3-incident date is dem symptom"
	scen_dxrxsymp_vtype&yr.="1-verification date is ADRD dx, 2-verification date is drug use, 3-verification date is dem symptom, 4-verified by death";	
	;
	%end;
run;

/* Split out each into year and keep last.patid */
/*
data %do yr=&minyear. %to &maxyear.;
	 &tempwork..scenfirst_&yr.ma (keep=patid first_dx&yr. first_adrx&yr. first_symptoms&yr. first_symptoms_desc&yr. first_adrd_type&yr.)
	 %end;;
	set &outlib..adrdincv1yrlb_scen_firstma;
	by patid;
run;

data %do yr=&minyear. %to &maxyear.;
	 &tempwork..scendx_&yr.ma (keep=patid scen_dx_inc&yr. scen_dx_vdt&yr. scen_dx_vtime&yr. scen_dx_inctype&yr. scen_dx_vtype&yr. dropdx&yr.)
	 %end;;
	set &outlib..adrdincv1yrv_scendx_longma;
	by patid;
	if last.patid;
run;

data %do yr=&minyear. %to &maxyear.;
	 &tempwork..scendxrx_&yr.ma (keep=patid scen_dxrx_inc&yr. scen_dxrx_vdt&yr. scen_dxrx_vtime&yr. scen_dxrx_inctype&yr. scen_dxrx_vtype&yr. dropdxrx&yr.)
	 %end;;
	set &outlib..adrdincv1yrv_scendxrx_longma;
	by patid;
	if last.patid;
run;

data %do yr=&minyear. %to &maxyear.;
	 &tempwork..scendxsymp_&yr.ma (keep=patid scen_dxsymp_inc&yr. scen_dxsymp_vdt&yr. scen_dxsymp_vtime&yr. scen_dxsymp_inctype&yr. scen_dxsymp_vtype&yr. dropdxsymp&yr.)
	 %end;;
	set &outlib..adrdincv1yrv_scendxsymp_longma;
	by patid;
	if last.patid;
run;
*/
data %do yr=&minyear. %to &maxyear.;
	 &outlib..adrdinc_dxrxsymp_yrly_1yrv&yr. (keep=patid scen_dxrxsymp_inc&yr. scen_dxrxsymp_vdt&yr. scen_dxrxsymp_vtime&yr. scen_dxrxsymp_inctype&yr. scen_dxrxsymp_vtype&yr. dropdxrxsymp&yr.)
	 %end;;
	set &outlib..adrdincv1yrv_scendxrxsymp_long;
	by patid; 
	if last.patid;
run;

/* Checks */
%do yr=&minyear. %to &maxyear.;
proc freq data=&outlib..adrdinc_dxrxsymp_yrly_1yrv&yr. noprint;
	table scen_dxrxsymp_inctype&yr.*scen_dxrxsymp_vtype&yr. / out=check_type&yr.;
run;

proc print data=check_type&yr.; run;

proc univariate data=&outlib..adrdinc_dxrxsymp_yrly_1yrv&yr. noprint outtable=check_vtime&yr.;
	var scen_dxrxsymp_vtime&yr.;
run;

proc print data=check_vtime&yr.; run;
%end;

/* Stack all together */
/*
%do yr=&minyear. %to &maxyear.;
data &outlib..adrdinc_verified_1yrv_&yr.ma;
	merge &tempwork..scenfirst_&yr.ma &tempwork..scendx_&yr.ma &tempwork..scendxrx_&yr.ma &tempwork..scendxsymp_&yr.ma  &tempwork..scendxrxsymp_&yr.ma;
	by patid;
run;

%end;
*/
%mend;

%inc_1yrv;

options obs=max;
