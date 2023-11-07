/*********************************************************************************************/
TITLE1 'CCI';

* AUTHOR: Patricia Ferido;
* PURPOSE: Adjudicating MA 2017 claims to feed into CCI;

options compress=yes nocenter ls=160 ps=200 errors=5  errorcheck=strict mprint merror
	mergenoby=warn varlenchk=warn dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/
/***

The next steps will be:
- Find clm_orig_cntl_num that match in original
- Merge clm_orig_cntl_num and clean those claims
- Drop old claims
- Merge in new claims
- Get on date level by clm_thru_dt - removing duplicates
- Send through my dementia incidence methods programs 
    - adjust for short time frame

Run the CCW programs on the encounter data

***/

* Will use a multiple step process to figure out which claims need to be adjusted.;

* Keeping all claims with claim_orig_cntl_num in main files;
* Keeping only bene_id, clm_freq_cd, clm_mdcl_rec, icd_dgns_cd:;
* Renaming to compare;

options obs=max;
%let yr=17;
%let max_demdx=52;
* Pulling chart reviews - defined as claim with an clm_orig_cntl_num;
%macro pull_orig(ctyp,maxdgns);

data &tempwork..&ctyp._clm_cr;
	set enrfpl17.&ctyp._base_enc (where=(clm_orig_cntl_num ne "") keep=bene_id clm_orig_cntl_num clm_cntl_num clm_freq_cd clm_mdcl_rec icd_dgns_cd:);
	rename clm_cntl_num=crclm_cntl_num clm_orig_cntl_num=clm_cntl_num clm_freq_cd=crclm_freq_cd clm_mdcl_rec=crclm_mdcl_rec
		   %do i=1 %to &maxdgns.;
		   icd_dgns_cd&i.=cricd_dgns_cd&i.
		   %end;;
run;

* Sorting chart reviews;
%if "&ctyp."="carrier" %then %do;
proc sort data=&tempwork..&ctyp._clm_cr out=&tempwork..&ctyp._clm_cr_s; by bene_id clm_cntl_num crclm_cntl_num; run;
%end;
%else %if "&ctyp."="op" %then %do;
proc sort data=&tempwork..&ctyp._clm_cr out=&tempwork..&ctyp._clm_cr_s; by bene_id clm_cntl_num crclm_cntl_num; run;
%end;
%else %do;
data _null_;
	if _n_=0 then set &tempwork..&ctyp._clm_cr;
	if _n_=1 then do;
		declare hash sort(dataset: "&tempwork..&ctyp._clm_cr",
						  ordered: "A",
						  multidata: "Y");
		sort.defineKey("bene_id","clm_cntl_num","crclm_cntl_num");
		sort.defineData("bene_id","clm_cntl_num","crclm_cntl_num",%do i=1 %to &maxdgns; "cricd_dgns_cd&i.",%end;"crclm_freq_cd","crclm_mdcl_rec");
		sort.definedone();
	end;
	sort.output(dataset:"&tempwork..&ctyp._clm_cr_s");
run;
%end;
%mend;

%pull_orig(carrier,13);
%pull_orig(hha,25);
%pull_orig(snf,25);
%pull_orig(ip,25);
%pull_orig(op,25);

* Do adjudication;
%macro adj(ctyp,maxdgns,typmax=&max_demdx);
* Sorting original claims to edit;

%if "&ctyp."="carrier" %then %do;
proc sort data=enrfpl17.&ctyp._base_enc out=&tempwork..&ctyp._toedit; by bene_id clm_cntl_num; run;
%end;
%else %if "&ctyp."="op" %then %do;
proc sort data=enrfpl17.&ctyp._base_enc out=&tempwork..&ctyp._toedit; by bene_id clm_cntl_num; run;
%end;
%else %do;
data _null_;
	if _n_=0 then set enrfpl17.&ctyp._base_enc;
	if _n_=1 then do;
		declare hash sort(dataset: "enrfpl17.&ctyp._base_enc",
						  ordered: "A",
						  multidata: "Y");
		sort.defineKey("bene_id","clm_cntl_num");
		sort.defineData("bene_id","clm_cntl_num","clm_orig_cntl_num",%do i=1 %to &maxdgns; "icd_dgns_cd&i.",%end;"clm_freq_cd","clm_mdcl_rec");
		sort.definedone();
	end;
	sort.output(dataset:"&tempwork..&ctyp._toedit");
run;
%end;

* Merge to the pulled dementia codes and edit;
data &tempwork..adj_&ctyp.;
	merge &tempwork..&ctyp._toedit (in=a) &tempwork..&ctyp._clm_cr_s (in=b);
	by bene_id clm_cntl_num;
	toedit=a;
	edits=b;

	array dx [*] icd_dgns_cd1-icd_dgns_cd&typmax.;
	array crdx [*] cricd_dgns_cd1-cricd_dgns_cd&typmax.;
	array ndx [*] $ ndx1-ndx&typmax.;

	* setting up new diagnoses;
	if first.clm_cntl_num then do;
		edit="   ";
		do i=1 to &typmax.;
			ndx[i]=dx[i];
			if dx[i] ne "" then dxcount=i;
		end;
	end;
	retain ndx: edit dxcount;
	
	if toedit=1 and edits=1 then do;

		* adding diagnoses - clm_mdcl_rec ne 8 and clm_freq_cd not in(7,8);
		if crclm_freq_cd ne "" and crclm_freq_cd not in("7","8") and crclm_mdcl_rec ne "8" then do i=1 to &typmax.;
			add_found=0;
			if crdx[i] ne "" then do;
				do j=1 to &typmax. while(add_found=0);
					if crdx[i]=ndx[j] then add_found=1;
				end;
				if add_found=0 then do;
					dxcount=dxcount+1;
					ndx[dxcount]=crdx[i];
					substr(edit,1,1)='1';
				end;
			end;
		end;

		* replacing codes - clm_freq_cd is 7 and clm_mdcl_rec ne 8;
		if crclm_freq_cd="7" and crclm_mdcl_rec ne "8" then do i=1 to &typmax.;
			ndx[i]=crdx[i];
			substr(edit,2,1)='7';
		end;

		* deleting diagnoses - clm_mdcl_rec="8";
		delete_found=0;
		if crclm_mdcl_rec='8' then do i=1 to &typmax.;
			do j=1 to &typmax.;
				if crdx[i] ne "" and crdx[i]=ndx[j] then do;
					delete_found=1;
					ndx[j]="";
					substr(edit,3,1)='8';
				end;
			end;
		end;

		* voiding all diagnoses - clm_freq_cd = '8' and clm_mdcl_rec ne 8;
		if crclm_freq_cd='8' and crclm_mdcl_rec ne '8' then delete;

	end;

run;

proc freq data=&tempwork..adj_&ctyp.;
	table edit;
	table toedit*crclm_freq_cd;
	table toedit*edits;
run;

data &tempwork..adj_&ctyp._ck;
	set &tempwork..adj_&ctyp.;
	by bene_id clm_cntl_num;
	if not(first.clm_cntl_num and last.clm_cntl_num);
run;
%mend;

%adj(hha,25);
%adj(snf,25);
%adj(op,25,typmax=100);
%adj(ip,25,typmax=125);

proc univariate data=&tempwork..adj_ip; var dxcount; run;
proc univariate data=&tempwork..adj_hha; var dxcount; run;
proc univariate data=&tempwork..adj_snf; var dxcount; run;
proc univariate data=&tempwork..adj_op; var dxcount; run;

* Limit to last claim;
* Drop the diagnoses that we don't need and rename;
%macro finalize_adj(ctyp,typmax);

data _null_;
	if _n_=0 then set &tempwork..adj_&ctyp.;
	if _n_=1 then do;
		declare hash sort(dataset: "&tempwork..adj_&ctyp.",
						  ordered: "A",
						  multidata: "Y");
		sort.defineKey("bene_id","clm_cntl_num");
		sort.defineData("bene_id","clm_cntl_num",%do i=1 %to &typmax; "ndx&i.",%end;"toedit","clm_freq_cd","clm_mdcl_rec");
		sort.definedone();
	end;
	sort.output(dataset:"&tempwork..adj_&ctyp._s");
run;

data &tempwork..adj_&ctyp.1;
	set &tempwork..adj_&ctyp._s;
	by bene_id clm_cntl_num;
	if toedit=1;
	if last.clm_cntl_num;
	drop toedit;
	rename %do i=1 %to &typmax; ndx&i.=dx&i. %end;;	
run;

* Merge to claims that were uesd to edit and drop;
data _null_;
	if _n_=0 then set &tempwork..adj_&ctyp.;
	if _n_=1 then do;
		declare hash sort(dataset: "&tempwork..adj_&ctyp.",
						  ordered: "A",
						  multidata: "Y");
		sort.defineKey("bene_id","crclm_cntl_num");
		sort.defineData("bene_id","crclm_cntl_num","toedit","edits","crclm_freq_cd","crclm_mdcl_rec");
		sort.definedone();
	end;
	sort.output(dataset:"&tempwork..adj_&ctyp._s");
run; 
	 
data &outlib..&ctyp._adj_ma&yr. (drop=drop crclm_freq_cd crclm_mdcl_rec toedit edits) &tempwork..&ctyp._drops;
	merge &tempwork..adj_&ctyp.1 (in=a) &tempwork..adj_&ctyp._s (in=b
	where=(edits=1) rename=(crclm_cntl_num=clm_cntl_num));
	by bene_id clm_cntl_num;
	if a;
	if b then do;
		* deleting the ones that match;
		if toedit=1 then drop=1;
		* deleting the ones that would void claims or delete diagnoses;
		if crclm_freq_cd='8' and crclm_mdcl_rec ne '8' then drop=1;
		if crclm_mdcl_rec='8' then drop=1;
	end;
	* dropping main records that have a clm_bill_freq_cd of 8 or clm_mdcl_rec of 8;
	if clm_freq_cd='8' or clm_mdcl_rec='8' then drop=1;
	if drop=1 then output &tempwork..&ctyp._drops;
	else output &outlib..&ctyp._adj_ma&yr.;
run;

%mend;

%finalize_adj(ip,80);
%finalize_adj(snf,40);
%finalize_adj(hha,52);

* OP have to do a normal sort;
%let ctyp=OP;
%let typmax=70;
%macro finalize_op;

proc sort data=&tempwork..adj_&ctyp. out=&tempwork..adj_&ctyp._s (keep=bene_id clm_cntl_num toedit ndx: clm_freq_cd clm_mdcl_rec); by bene_id clm_cntl_num; run;

data &tempwork..adj_&ctyp.1;
	set &tempwork..adj_&ctyp._s;
	by bene_id clm_cntl_num;
	if toedit=1;
	if last.clm_cntl_num;
	drop toedit;
	rename %do i=1 %to &typmax; ndx&i.=dx&i. %end;;	
run;


* Merge to claims that were uesd to edit and drop;
proc sort data=&tempwork..adj_&ctyp. out=&tempwork..adj_&ctyp._s (keep=bene_id crclm_cntl_num toedit edits crclm_freq_cd crclm_mdcl_rec); by bene_id crclm_cntl_num; run;
	
data &outlib..&ctyp._adj_ma&yr. (drop=drop crclm_freq_cd crclm_mdcl_rec toedit edits) &tempwork..&ctyp._drops;
	merge &tempwork..adj_&ctyp.1 (in=a) &tempwork..adj_&ctyp._s (in=b
	where=(edits=1) rename=(crclm_cntl_num=clm_cntl_num));
	by bene_id clm_cntl_num;
	if a;
	if b then do;
		* deleting the ones that match;
		if toedit=1 then drop=1;
		* deleting the ones that would void claims or delete diagnoses;
		if crclm_freq_cd='8' and crclm_mdcl_rec ne '8' then drop=1;
		if crclm_mdcl_rec='8' then drop=1;
	end;
	* dropping main records that have a clm_bill_freq_cd of 8 or clm_mdcl_rec of 8;
	if clm_freq_cd='8' or clm_mdcl_rec='8' then drop=1;
	if drop=1 then output &tempwork..&ctyp._drops;
	else output &outlib..&ctyp._adj_ma&yr.;
run;
%mend;

%finalize_op;

/* Doing a different thing for carrier - far too large to loop through
For carrier, taking out the chart reviews meant to add. Only merging on the chart reviews meant to replace and to delete.
*/
%let max_demdx=13;
proc sort data=enrfpl17.carrier_base_enc out=&tempwork..carrier_toedit (keep=bene_id clm_cntl_num clm_orig_cntl_num icd_dgns_cd1-icd_dgns_cd13 clm_freq_cd clm_mdcl_rec);
	by bene_id clm_cntl_num;
run;

data &tempwork..carrier_replace &tempwork..carrier_delete &tempwork..carrier_void;
	set &tempwork..carrier_clm_cr_s;
	if crclm_freq_cd="7" and crclm_mdcl_rec ne "8" then output &tempwork..carrier_replace;
	if crclm_mdcl_rec='8' then output &tempwork..carrier_delete;
run;

data &tempwork..adj_carrier_;
	merge &tempwork..carrier_toedit (in=a) &tempwork..carrier_replace (in=b) &tempwork..carrier_delete (in=c);
	by bene_id clm_cntl_num;
	toedit=a;
	edit_replace=b;
	edit_delete=c;

	array dx [*] icd_dgns_cd1-icd_dgns_cd&max_demdx.;
	array crdx [*] cricd_dgns_cd1-cricd_dgns_cd&max_demdx.;
	array ndx [*] $ ndx1-ndx&max_demdx.;

	* setting up new diagnoses;
	if first.clm_cntl_num then do;
		edit="   ";
		do i=1 to &max_demdx.;
			ndx[i]=dx[i];
			if dx[i] ne "" then dxcount=i;
		end;
	end;
	retain ndx: edit dxcount;
	
	if toedit=1 and (edit_replace=1 or edit_delete=1) then do;

		* replacing codes - clm_freq_cd is 7 and clm_mdcl_rec ne 8;
		if crclm_freq_cd="7" and crclm_mdcl_rec ne "8" then do i=1 to &max_demdx.;
			ndx[i]=crdx[i];
			substr(edit,2,1)='7';
		end;

		* deleting diagnoses - clm_mdcl_rec="8";
		delete_found=0;
		if crclm_mdcl_rec='8' then do i=1 to &max_demdx.;
			do j=1 to &max_demdx.;
				if crdx[i]=ndx[j] then do;
					delete_found=1;
					ndx[j]="";
					substr(edit,3,1)='8';
				end;
			end;
		end;

		* voiding all diagnoses - clm_freq_cd = '8' and clm_mdcl_rec ne 8;
		if crclm_freq_cd='8' and crclm_mdcl_rec ne '8' then delete;

	end;

run;

%macro carrier_adj(ctyp);

proc sort data=&tempwork..adj_&ctyp._; by bene_id clm_cntl_num; run;

data &tempwork..adj_&ctyp._1;
	set &tempwork..adj_&ctyp._ (drop=dx:);
	by bene_id clm_cntl_num;
	if toedit=1;
	if last.clm_cntl_num;
	drop crclm_cntl_num crclm_freq_cd crclm_mdcl_rec icd_dgns_cd: cricd_dgns_cd: toedit edit_replace edit_delete i j delete_found;
	rename %do i=1 %to 13; ndx&i.=dx&i. %end;;	
run;

proc sort data=&tempwork..adj_&ctyp._; by bene_id crclm_cntl_num; run;
	
data &outlib..&ctyp._adj_ma&yr. (drop=drop crclm_freq_cd crclm_mdcl_rec toedit edit_delete) &tempwork..&ctyp._drops;
	merge &tempwork..adj_&ctyp._1 (in=a) &tempwork..adj_&ctyp._ (in=b keep=bene_id crclm_cntl_num toedit edit_delete crclm_freq_cd crclm_mdcl_rec
	where=(edit_delete=1) rename=(crclm_cntl_num=clm_cntl_num));
	by bene_id clm_cntl_num;
	if a;
	if b then do;
		* deleting the ones that match;
		if toedit=1 then drop=1;
		* deleting the ones that would void claims or delete diagnoses;
		if crclm_freq_cd='8' and crclm_mdcl_rec ne '8' then drop=1;
		if crclm_mdcl_rec='8' then drop=1;
	end;
	* dropping main records that have a clm_bill_freq_cd of 8 or clm_mdcl_rec of 8;
	if clm_freq_cd='8' or clm_mdcl_rec='8' then drop=1;
	if drop=1 then output &tempwork..&ctyp._drops;
	else output &outlib..&ctyp._adj_ma&yr.;
run;
%mend;

%carrier_adj(carrier);

/* CCI */
%include "&rootpath./Projects/Programs/base/cci_icd9_10_macro.sas";

%let minyear=17;
%let maxyear=17;
%macro cci_yr;
%do year=&minyear. %to &maxyear.;
data &tempwork..cci_clms_ma&year.;
	set &outlib..ip_adj_ma&year.
		&outlib..hha_adj_ma&year.
		&outlib..snf_adj_ma&year.
		&outlib..carrier_adj_ma&year.
		&outlib..op_adj_ma&year.;
	by bene_id;
run;

%_CharlsonICD (DATA    = &tempwork..cci_clms_ma&year.,     /* input data set */
               OUT     = &tempwork..cci_ma&year.,     /* output data set */
               dx      =dx1-dx26,     /* range of diagnosis variables (diag01-diag25) */
               dxtype  =,    /* range of diagnosis type variables 
                                       (diagtype01-diagtype25) */
               type    =off, /** on/off  turn on use of dxtype ***/
               debug   =on ) ;

* Get weighted CCI for the year;
data &tempwork..cci_ma_bene&year.;
   set &tempwork..cci_ma&year. (keep=bene_id cc_grp_1-cc_grp_17);
   by bene_id;
   
   retain ccgrp1 ccgrp2 ccgrp3 ccgrp4 ccgrp5 ccgrp6 ccgrp7 ccgrp8 ccgrp9 
          ccgrp10 ccgrp11 ccgrp12 ccgrp13 ccgrp14 ccgrp15 ccgrp16 ccgrp17;
   
   if first.bene_id then do;
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
   
   if last.bene_id then do;
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
                        wgtcc = 'Weighted Sum of 17 Charlson Comorbidity Groups'
                        ccwgtgrp = 'Category of Weighted Sum of 17 Charlson Comorbidity Groups';
   
   keep bene_id totalcc wgtcc ccgrp1 ccgrp2 ccgrp3 ccgrp4 ccgrp5 ccgrp6 ccgrp7 
        ccgrp8 ccgrp9 ccgrp10 ccgrp11 ccgrp12 ccgrp13 ccgrp14 ccgrp15 ccgrp16 ccgrp17;        
run;   
%end;

* Create a wide file of cci with cci for each year;
data base.cci_ma_beneadj&yr.;
	merge %do year=&minyear %to &maxyear;
	&tempwork..cci_ma_bene&year. (keep=bene_id totalcc wgtcc rename=(totalcc=totalcc20&year. wgtcc=wgtcc20&year.))
	%end;;
	by bene_id;
run;

%mend;

%cci_yr;







