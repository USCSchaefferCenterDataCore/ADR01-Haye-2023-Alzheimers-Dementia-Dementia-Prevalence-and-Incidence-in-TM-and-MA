/*********************************************************************************************/
TITLE1 'Dementia Dx';

* AUTHOR: Patricia Ferido;

* INPUT: Optum DOD Files;

* PURPOSE: Turn dementia diagnoses date level
					 9/24/2020 - removing DME claims;

options compress=yes nocenter ls=150 ps=200 errors=5 errorabend errorcheck=strict mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

libname samp "../../data/sample_selection";
libname demdx "../../data/dementia";
libname optum "/sch-data-library/dua-data/OPTUM-Full/Original_data/Data";
libname onepct "/sch-data-library/dua-data/OPTUM/Original_data/Data/1_Percent";

/**** NOT DROPPING ANY CLAIM TYPES BUT MAY WANT TO ****/

%let minyear=2007;
%let maxyear=2019;
%let max_demdx=25;

***** Dementia Codes;
%let ccw_dx9="3310"  "33111" "33119" "3312"  "3317"  "2900"  "29010"
            "29011" "29012" "29013" "29020" "29021" "2903"  "29040" 
            "29041" "29042" "29043" "2940"  "29410" "29411" "29420" 
            "29421" "2948"  "797";
%let oth_dx9="33182" "33183" "33189" "3319" "2908" "2909" "2949" "78093" "7843" "78469";

%let ccw_dx10="F0150" "F0151" "F0280" "F0281" "F0390" "F0391" "F04" "G132" "G138" "F05"
							"F061" "F068" "G300" "G301" "G308" "G309" "G311" "G312" "G3101" "G3109"
							"G914" "G94" "R4181" "R54";

%let oth_dx10="G3183" "G3184" "G3189" "G319" "R411" "R412" "R413" "R4701" "R481" "R482" "R488" "F07" "F0789" "F079" "F09";
							
***** ICD9;
	***** Dementia Codes by type;
	%let AD_dx9="3310";
	%let ftd_dx9="33111", "33119";
	%let vasc_dx9="29040", "29041", "29042", "29043";
	%let senile_dx9="29010", "29011", "29012", "29013", "3312", "2900",  "29020", "29021", "2903", "797";
	%let unspec_dx9="29420", "29421";
	%let class_else9="3317", "2940", "29410", "29411", "2948" ;

	***** Other dementia dx codes not on the ccw list;
	%let lewy_dx9="33182";
	%let mci_dx9="33183";
	%let degen9="33189", "3319";
	%let oth_sen9="2908", "2909";
	%let oth_clelse9="2949";
	%let dem_symp9="78093", "7843", "78469","33183"; * includes MCI;

***** ICD10;
	***** Dementia Codes by type;
	%let AD_dx10="G300", "G301", "G308", "G309";
	%let ftd_dx10="G3101", "G3109";
	%let vasc_dx10="F0150", "F0151";
	%let senile_dx10="G311", "R4181", "R54";
	%let unspec_dx10="F0390", "F0391";
	%let class_else10="F0280", "F0281", "F04","F068","G138", "G94";
	* Excluded because no ICD-9 equivalent
					  G31.2 - Degeneration of nervous system due to alochol
						G91.4 - Hydrocephalus in diseases classified elsew
						F05 - Delirium due to known physiological cond
						F06.1 - Catatonic disorder due to known physiological cond
						G13.2 - Systemic atrophy aff cnsl in myxedema;
						
	***** Other dementia dx codes not on the ccw list or removed from the CCW list;
	%let lewy_dx10="G3183";
	%let mci_dx10="G3184";
	%let degen10="G3189","G319";
	%let oth_clelse10="F07","F0789","F079","F09";
	%let dem_symp10="R411","R412","R413","R4701","R481","R482","R488","G3184"; * includes MCI;
	%let ccw_excl_dx10="G312","G914","F05", "F061","G132";
	
* Merging to tos cd ;
proc sort data=demdx.dementia_dx&minyear._&maxyear. out=demdx_s; by patid clmid fst_dt; run;

* check for duplicate clmid;
proc sort data=optum.dod_m2016q1 nodupkey out=dod_m2016q1 (keep=patid clmid fst_dt loc_cd tos_cd); by patid clmid fst_dt loc_cd tos_cd; run;
proc sort data=optum.dod_m2016q2 nodupkey out=dod_m2016q2 (keep=patid clmid fst_dt loc_cd tos_cd); by patid clmid fst_dt loc_cd tos_cd; run;
proc sort data=optum.dod_m2016q3 nodupkey out=dod_m2016q3 (keep=patid clmid fst_dt loc_cd tos_cd); by patid clmid fst_dt loc_cd tos_cd; run;
proc sort data=optum.dod_m2016q4 nodupkey out=dod_m2016q4 (keep=patid clmid fst_dt loc_cd tos_cd); by patid clmid fst_dt loc_cd tos_cd; run;

data dod_m2016;
	set dod_m2016q1-dod_m2016q4;
	by patid clmid fst_dt;
	if last.fst_dt;
run;

data demdx_nodme;
	merge demdx_s (in=a) dod_m2016;
	by patid clmid fst_dt;
	if a;
	claim_type="     ";
	if (tos_cd="FAC_IP.ACUTE") then claim_type="IP";
	if (tos_cd in("FAC_IP.REHSNF","FAC_IP.SNF")) then claim_type="SNF";
	if (substr(tos_cd,1,6)="FAC_OP") then claim_type="OP";
	if (substr(tos_cd,1,7)="ANC.DME") then claim_type="DME";
	if (tos_cd="ANC.HH/HPC") then claim_type="HHA";
	if (tos_cd="ANC.TRANSP") then claim_type="AMB";
	if (tos_cd in("ANC.DRUGAD","ANC.SRVSUP")) then claim_type="ANC";
	if (substr(tos_cd,1,4)="PROF" & loc_cd="1") then claim_type="OP";
	if claim_type="" then do;
		if (loc_cd="1") then claim_type="OP";
		if (loc_cd="2") then claim_type="CAR";
	end;
	if claim_type ne "DME";
run;

proc sort data=demdx_nodme; by patid fst_dt; run;
	
data demdx.dementia_dxdt&minyear._&maxyear.;
	set demdx_nodme;
	by patid fst_dt;
	
	length _dxtypes $ 13 _demdx1-_demdx&max_demdx $ 5;
	length  _dxmax 3;
	retain  _dxmax _dxtypes _demdx1-_demdx&max_demdx;
	
	array demdx_ [*] $ demdx1-demdx&max_demdx;
	array _demdx [*] $ _demdx1-_demdx&max_demdx;
	
	year=year(fst_dt);
	    
	* First claim on this data;
	if first.fst_dt=1 then do;
		do i=1 to dim(demdx_);
			_demdx[i]=demdx_[i];
		end;
		_demdx1=demdx;
		_dxtypes=dxtypes;
		_dxmax=1;
	end;
	
	* subsequent claims on the same date. Add any dementia dx not found in first date;
	else do;
			dxfound=0;
			do j=1 to _dxmax;
				if demdx=_demdx[j] then dxfound=1;
			end;
			if dxfound=0 then do;
				_dxmax=_dxmax+1;
				if _dxmax<&max_demdx then _demdx[_dxmax]=demdx;
				
				select (demdx); * update dxtypes string;
					when (&AD_dx9,&AD_dx10)  substr(_dxtypes,1,1)="A";
					when (&ftd_dx9,&ftd_dx10) substr(_dxtypes,2,1)="F";
					when (&vasc_dx9,&vasc_dx10) substr(_dxtypes,3,1)="V";
					when (&senile_dx9,&senile_dx10) substr(_dxtypes,4,1)="S";
					when (&unspec_dx9,&unspec_dx10) substr(_dxtypes,5,1)="U";
					when (&class_else9,&class_else10) substr(_dxtypes,6,1)="E";
					when (&lewy_dx9,&lewy_dx10) substr(_dxtypes,7,1)="l";
					when (&mci_dx9,&mci_dx10) substr(_dxtypes,8,1)="m";
					when (&degen9,&degen10) substr(_dxtypes,9,1)="d";
					when (&oth_sen9) substr(_dxtypes,10,1)="s";
					when (&oth_clelse9,&oth_clelse10) substr(_dxtypes,11,1)="e";
					when (&dem_symp9,&dem_symp10) substr(_dxtypes,12,1)="p";
					otherwise substr(_dxtypes,13,1)="X";
         end; /* select */
      end;  /* dxfound = 0 */
    end; /* do i=1 to _dxmax */
      	
    * output one obs per date;
    if last.fst_dt then do;
    	dxtypes=_dxtypes;
    	do i=1 to dim(demdx_);
    		demdx_[i]=_demdx[i];
    	end;
    	dx_max=_dxmax;
    	output;
    end;
    
    keep patid year fst_dt demdx1-demdx&max_demdx dx_max dxtypes claim_type;
run;

proc sort data=demdx.dementia_dxdt&minyear._&maxyear.;
	by patid year fst_dt;
run;
 
proc print data=demdx.dementia_dxdt&minyear._&maxyear. (obs=100); run;

proc contents data=demdx.dementia_dxdt&minyear._&maxyear.; run;
	
