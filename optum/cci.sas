/*********************************************************************************************/
TITLE1 'Optum MA Sample';

* AUTHOR: Patricia Ferido;

* INPUT: Optum DOD Files;

* PURPOSE: Calculate CCI for Optum MA sample;

options compress=yes nocenter ls=150 ps=200 errors=5 errorabend errorcheck=strict mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

libname samp "../../data/sample_selection";
libname optum "/sch-data-library/dua-data/OPTUM-Full/Original_data/Data";
libname onepct "/sch-data-library/dua-data/OPTUM/Original_data/Data/1_Percent";

%let minyear=2007;
%let maxyear=2019;

%macro dxpull;
	
	data samp;
			merge samp.samp_1yrma20072019 (in=a keep=patid anysamp0719 rename=(anysamp0719=anysamp0719_1yr))
						samp.samp_3yrma20072019 (in=b keep=patid anysamp0719 rename=(anysamp0719=anysamp0719_3yr));
			by patid;
			if max(anysamp0719_1yr,anysamp0719_3yr)=1;
	run;
	
	%do year=&minyear %to &maxyear;
		
		%do q=1 %to 4;
			
			data dx&year.q&q.;
				merge optum.dod_diag&year.q&q. (in=a keep=patid fst_dt diag)
							samp (in=b);
				by patid;
				if a and b;
			run;
		
		%end;
		
		data dx&year.;
			set dx&year.q1-dx&year.q4;
			by patid;
		run;
	%end;
%mend;

%dxpull;

%include "cci_icd_macro.sas";

%macro cci_yr;
	%do year=&minyear. %to &maxyear.;
			
		%_charlsonicd (data=dx&year.,
									 out=cci_&year.,
									 dx=diag,
									 dxtype=,
									 type=off,
									 debug=on);
									 
		* Get weighted CCI for the year;
		data samp.cci_bene&year.;
			set cci_&year. (keep=patid cc_grp_1-cc_grp_17);
			by patid;
			
			retain ccgrp1 ccgrp2 ccgrp3 ccgrp4 ccgrp5 ccgrp6 ccgrp7 ccgrp8 ccgrp9 
          ccgrp10 ccgrp11 ccgrp12 ccgrp13 ccgrp14 ccgrp15 ccgrp16 ccgrp17;
  
			   if first.patid then do;
			      ccgrp1=0; ccgrp2=0; ccgrp3=0; ccgrp4=0; ccgrp5=0; ccgrp6=0; ccgrp7=0; ccgrp8=0; ccgrp9=0; 
			      ccgrp10=0; ccgrp11=0; ccgrp12=0; ccgrp13=0; ccgrp14=0; ccgrp15=0; ccgrp16=0; ccgrp17=0;
			   end;

			*** these are the original comorbidity variables generated from each hospital separation or physician claim;
			array hsp{17} cc_grp_1  cc_grp_2  cc_grp_3  cc_grp_4  cc_grp_5  cc_grp_6  cc_grp_7  cc_grp_8  cc_grp_9 
			                 cc_grp_10 cc_grp_11 cc_grp_12 cc_grp_13 cc_grp_14 cc_grp_15 cc_grp_16 cc_grp_17;
			                                                   
			*** these are the summary comorbidity values over all claims;   
			array tot{17} ccgrp1 ccgrp2 ccgrp3 ccgrp4 ccgrp5 ccgrp6 ccgrp7 ccgrp8 ccgrp9 
			                 ccgrp10 ccgrp11 ccgrp12 ccgrp13 ccgrp14 ccgrp15 ccgrp16 ccgrp17;
			   
			   do i = 1 to 17;
			      if hsp{i} = 1 then tot{i} = 1;
			   end;
			   
			   if last.patid then do;
			      totalcc = sum(of ccgrp1-ccgrp17);
			              
			              *** use Charlson weights to calculate a weighted score;
			              wgtcc = sum(of ccgrp1-ccgrp10) + ccgrp11*2 + ccgrp12*2 + ccgrp13*2 + ccgrp14*2 +
			                      ccgrp15*3 + ccgrp16*6 + ccgrp17*6;        

			              output;
			   end;
			   
			   label ccgrp1 = 'Charlson Comorbidity Group 1: Myocardial Infarction'
			         ccgrp2 = 'Charlson Comorbidity Group 2: Congestive Heart Failure'
			                        ccgrp3 = 'Charlson Comorbidity Group 3: Peripheral Vascular Disease'
			                        ccgrp4 = 'Charlson Comorbidity Group 4: Cerebrovascular Disease'
			                        ccgrp5 = 'Charlson Comorbidity Group 5: Dementia'
			                        ccgrp6 = 'Charlson Comorbidity Group 6: Chronic Pulmonary Disease'
			                        ccgrp7 = 'Charlson Comorbidity Group 7: Connective Tissue Disease-Rheumatic Disease'
			                        ccgrp8 = 'Charlson Comorbidity Group 8: Peptic Ulcer Disease'
			                        ccgrp9 = 'Charlson Comorbidity Group 9: Mild Liver Disease' 
			                        ccgrp10 = 'Charlson Comorbidity Group 10: Diabetes without complications' 
			                        ccgrp11 = 'Charlson Comorbidity Group 11: Diabetes with complications'
			                        ccgrp12 = 'Charlson Comorbidity Group 12: Paraplegia and Hemiplegia' 
			                        ccgrp13 = 'Charlson Comorbidity Group 13: Renal Disease' 
			                        ccgrp14 = 'Charlson Comorbidity Group 14: Cancer' 
			                        ccgrp15 = 'Charlson Comorbidity Group 15: Moderate or Severe Liver Disease' 
			                        ccgrp16 = 'Charlson Comorbidity Group 16: Metastatic Carcinoma' 
			                        ccgrp17 = 'Charlson Comorbidity Group 17: HIV/AIDS'
			                        totalcc = 'Sum of 17 Charlson Comorbidity Groups'
			                        wgtcc = 'Weighted Sum of 17 Charlson Comorbidity Groups';
			   
			   keep patid totalcc wgtcc ccgrp1 ccgrp2 ccgrp3 ccgrp4 ccgrp5 ccgrp6 ccgrp7 
			        ccgrp8 ccgrp9 ccgrp10 ccgrp11 ccgrp12 ccgrp13 ccgrp14 ccgrp15 ccgrp16 ccgrp17;        
			run;   
	%end;
	
	* make a long file;
	data samp.cci_bene0719;
		merge %do year=&minyear. %to &maxyear.;
			samp.cci_bene&year. (keep=patid totalcc wgtcc rename=(totalcc=totalcc&year. wgtcc=wgtcc&year.))
		%end;;
		by patid;
	run;
%mend;

%cci_yr;

proc print data=samp.cci_bene0719 (obs=100); run;

proc contents data=samp.cci_bene0719; run;

	
	
				
				
		