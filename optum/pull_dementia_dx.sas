/*********************************************************************************************/
TITLE1 'Dementia Dx';

* AUTHOR: Patricia Ferido;

* INPUT: Optum DOD Files;

* PURPOSE: Pull dementia diagnoses from files;

options compress=yes nocenter ls=150 ps=200 errors=5 errorabend errorcheck=strict mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

libname samp "../../data/sample_selection";
libname demdx "../../data/dementia";
libname optum "/sch-data-library/dua-data/OPTUM-Full/Original_data/Data";
libname onepct "/sch-data-library/dua-data/OPTUM/Original_data/Data/1_Percent";

/* Steps:
- Merge position code from medical claims
- Limit to dementia diagnosis claims */	

 
***** Years/Macro Variables;
%let minyear=2007;
%let maxyear=2019;

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

%macro dementiadx;
	
	%do year=&minyear %to &maxyear;
		
		%do q=1 %to 4;
			
			proc sort data=optum.dod_diag&year.q&q. out=diag_&year.q&q.s; by patid fst_dt; run;

			data demdx&year.q&q._1;
				set diag_&year.q&q.s;
				by patid fst_dt;
				
				length demdx $ 5 dxtypes $ 13;
				
				if diag in(&ccw_dx9,&ccw_dx10) then ccwdem=1;
				if diag in(&oth_dx9,&oth_dx10) then othdem=1;
				if max(ccwdem,othdem)=1 then demdx=diag;
				
				* keep dementia claims;
				if demdx ne "";
				
				select (diag);
				 when (&AD_dx9,&AD_dx10)  substr(dxtypes,1,1)="A";
			   when (&ftd_dx9,&ftd_dx10) substr(dxtypes,2,1)="F";
			   when (&vasc_dx9,&vasc_dx10) substr(dxtypes,3,1)="V";
			   when (&senile_dx9,&senile_dx10) substr(dxtypes,4,1)="S";
				 when (&unspec_dx9,&unspec_dx10) substr(dxtypes,5,1)="U";
				 when (&class_else9,&class_else10) substr(dxtypes,6,1)="E";
				 when (&lewy_dx9,&lewy_dx10) substr(dxtypes,7,1)="l";
				 when (&mci_dx9,&mci_dx10) substr(dxtypes,8,1)="m";
				 when (&degen9,&degen10) substr(dxtypes,9,1)="d";
				 when (&oth_sen9) substr(dxtypes,10,1)="s";
				 when (&oth_clelse9,&oth_clelse10) substr(dxtypes,11,1)="e";
				 when (&dem_symp9,&dem_symp10) substr(dxtypes,12,1)="p";
			   otherwise substr(dxtypes,13,1)="X";
			  end;
				
				drop diag extract_ym icd_flag version;
			run;

		%end;
	
	%end;
	
	* Setting all together;
	
	data demdx.dementia_dx2007_2019;
		set
			%do year=&minyear. %to &maxyear.;
				%do q=1 %to 4; 
					demdx&year.q&q._1
				%end;
			%end;;
		by patid fst_dt;
	run;

%mend;

%dementiadx;

proc print data=demdx.dementia_dx2007_2019 (obs=100); run;

* Explore;
proc freq data=demdx.dementia_dx2007_2019; 
	table dxtypes;
run;
