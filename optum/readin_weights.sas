/*********************************************************************************************/
title1 'Exploring AD incidence Definition';

* Author: PF;
* Purpose: 	Bring in incidence weights from FFS Part D population;

options compress=yes nocenter ls=150 ps=200 errors=5 mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

libname samp "../../data/sample_selection";
libname demdx "../../data/dementia";
libname optum "/sch-data-library/dua-data/OPTUM-Full/Original_data/Data";
libname onepct "/sch-data-library/dua-data/OPTUM/Original_data/Data/1_Percent";
libname inc "../../data/incidence_methods";
libname cc "/schaeffer-a/sch-projects/dua-data-projects/OPTUM/pferido/programs/CCW_package/data";
libname ffs "../../data/mavffs";

%let minyear=2007;
%let maxyear=2019;

options obs=max;

* with SES;
data ffs.ffsptd_incweights16ses;
	infile "./ffsptd_incweights16ses.csv" dsd dlm="2c"x lrecl=32767 firstobs=2 missover;
	informat 
		female  best12.
		agege80 best12.
		age7579 best12.
		age7074 best12.
		agelt70 best12.
		race_do best12.
		race_dn best12.
		race_da best12.
		race_dh best12.
		race_db best12.
		race_dw best12.
		duallis best12.
		count   best12.;
	informat 
		female  best12.
		agege80 best12.
		age7579 best12.
		age7074 best12.
		agelt70 best12.
		race_do best12.
		race_dn best12.
		race_da best12.
		race_dh best12.
		race_db best12.
		race_dw best12.
		duallis best12.
		count   best12.;
	input
		female  
		agege80
		age7579
		age7074 
		agelt70 
		race_do 
		race_dn 
		race_da 
		race_dh 
		race_db 
		race_dw 
		duallis
		count  ;
	if race_dn=1 then delete;
	drop race_dn;
run;

data ffs.ffsptd_incweights17ses;
	infile "./ffsptd_incweights17ses.csv" dsd dlm="2c"x lrecl=32767 firstobs=2 missover;
	informat 
		female  best12.
		agege80 best12.
		age7579 best12.
		age7074 best12.
		agelt70 best12.
		race_do best12.
		race_dn best12.
		race_da best12.
		race_dh best12.
		race_db best12.
		race_dw best12.
		duallis best12.
		count   best12.;
	informat 
		female  best12.
		agege80 best12.
		age7579 best12.
		age7074 best12.
		agelt70 best12.
		race_do best12.
		race_dn best12.
		race_da best12.
		race_dh best12.
		race_db best12.
		race_dw best12.
		duallis best12.
		count   best12.;
	input
		female  
		agege80
		age7579
		age7074 
		agelt70 
		race_do 
		race_dn 
		race_da 
		race_dh 
		race_db 
		race_dw 
		duallis
		count  ;
	if race_dn=1 then delete;
	drop race_dn;
run;


data ffs.ffsptd_prevweights17ses;
	infile "./ffsptd_prevweights17ses.csv" dsd dlm="2c"x lrecl=32767 firstobs=2 missover;
	informat 
		female  best12.
		agege80 best12.
		age7579 best12.
		age7074 best12.
		agelt70 best12.
		race_do best12.
		race_dn best12.
		race_da best12.
		race_dh best12.
		race_db best12.
		race_dw best12.
		duallis best12.
		count   best12.;
	informat 
		female  best12.
		agege80 best12.
		age7579 best12.
		age7074 best12.
		agelt70 best12.
		race_do best12.
		race_dn best12.
		race_da best12.
		race_dh best12.
		race_db best12.
		race_dw best12.
		duallis best12.
		count   best12.;
	input
		female  
		agege80
		age7579
		age7074 
		agelt70 
		race_do 
		race_dn 
		race_da 
		race_dh 
		race_db 
		race_dw 
		duallis
		count  ;
	if race_dn=1 then delete;
	drop race_dn;
run;


data ffs.ffsptd_prevweights16ses;
	infile "./ffsptd_prevweights16ses.csv" dsd dlm="2c"x lrecl=32767 firstobs=2 missover;
	informat 
		female  best12.
		agege80 best12.
		age7579 best12.
		age7074 best12.
		agelt70 best12.
		race_do best12.
		race_dn best12.
		race_da best12.
		race_dh best12.
		race_db best12.
		race_dw best12.
		duallis best12.
		count   best12.;
	informat 
		female  best12.
		agege80 best12.
		age7579 best12.
		age7074 best12.
		agelt70 best12.
		race_do best12.
		race_dn best12.
		race_da best12.
		race_dh best12.
		race_db best12.
		race_dw best12.
		duallis best12.
		count   best12.;
	input
		female  
		agege80
		age7579
		age7074 
		agelt70 
		race_do 
		race_dn 
		race_da 
		race_dh 
		race_db 
		race_dw 
		duallis
		count  ;
	if race_dn=1 then delete;
	drop race_dn;
run;

proc print data=ffs.ffsptd_prevweights16ses; run;
proc print data=ffs.ffsptd_prevweights17ses; run;
proc print data=ffs.ffsptd_incweights16ses; run;
proc print data=ffs.ffsptd_incweights17ses; run;
	
	
* Without ;
data ffs.ffsptd_incweights16;
	infile "./ffsptd_incweights16.csv" dsd dlm="2c"x lrecl=32767 firstobs=2 missover;
	informat 
		female  best12.
		agege80 best12.
		age7579 best12.
		age7074 best12.
		agelt70 best12.
		race_do best12.
		race_dn best12.
		race_da best12.
		race_dh best12.
		race_db best12.
		race_dw best12.
		count   best12.;
	informat 
		female  best12.
		agege80 best12.
		age7579 best12.
		age7074 best12.
		agelt70 best12.
		race_do best12.
		race_dn best12.
		race_da best12.
		race_dh best12.
		race_db best12.
		race_dw best12.
		count   best12.;
	input
		female  
		agege80
		age7579
		age7074 
		agelt70 
		race_do 
		race_dn 
		race_da 
		race_dh 
		race_db 
		race_dw 
		count  ;
	if race_dn=1 then delete;
	drop race_dn;
run;

data ffs.ffsptd_incweights17;
	infile "./ffsptd_incweights17.csv" dsd dlm="2c"x lrecl=32767 firstobs=2 missover;
	informat 
		female  best12.
		agege80 best12.
		age7579 best12.
		age7074 best12.
		agelt70 best12.
		race_do best12.
		race_dn best12.
		race_da best12.
		race_dh best12.
		race_db best12.
		race_dw best12.
		count   best12.;
	informat 
		female  best12.
		agege80 best12.
		age7579 best12.
		age7074 best12.
		agelt70 best12.
		race_do best12.
		race_dn best12.
		race_da best12.
		race_dh best12.
		race_db best12.
		race_dw best12.
		count   best12.;
	input
		female  
		agege80
		age7579
		age7074 
		agelt70 
		race_do 
		race_dn 
		race_da 
		race_dh 
		race_db 
		race_dw 
		count  ;
	if race_dn=1 then delete;
	drop race_dn;
run;


data ffs.ffsptd_prevweights17;
	infile "./ffsptd_prevweights17.csv" dsd dlm="2c"x lrecl=32767 firstobs=2 missover;
	informat 
		female  best12.
		agege80 best12.
		age7579 best12.
		age7074 best12.
		agelt70 best12.
		race_do best12.
		race_dn best12.
		race_da best12.
		race_dh best12.
		race_db best12.
		race_dw best12.
		count   best12.;
	informat 
		female  best12.
		agege80 best12.
		age7579 best12.
		age7074 best12.
		agelt70 best12.
		race_do best12.
		race_dn best12.
		race_da best12.
		race_dh best12.
		race_db best12.
		race_dw best12.
		count   best12.;
	input
		female  
		agege80
		age7579
		age7074 
		agelt70 
		race_do 
		race_dn 
		race_da 
		race_dh 
		race_db 
		race_dw 
		count  ;
	if race_dn=1 then delete;
	drop race_dn;
run;


data ffs.ffsptd_prevweights16;
	infile "./ffsptd_prevweights16.csv" dsd dlm="2c"x lrecl=32767 firstobs=2 missover;
	informat 
		female  best12.
		agege80 best12.
		age7579 best12.
		age7074 best12.
		agelt70 best12.
		race_do best12.
		race_dn best12.
		race_da best12.
		race_dh best12.
		race_db best12.
		race_dw best12.
		count   best12.;
	informat 
		female  best12.
		agege80 best12.
		age7579 best12.
		age7074 best12.
		agelt70 best12.
		race_do best12.
		race_dn best12.
		race_da best12.
		race_dh best12.
		race_db best12.
		race_dw best12.
		count   best12.;
	input
		female  
		agege80
		age7579
		age7074 
		agelt70 
		race_do 
		race_dn 
		race_da 
		race_dh 
		race_db 
		race_dw 
		count  ;
	if race_dn=1 then delete;
	drop race_dn;
run;

proc print data=ffs.ffsptd_prevweights16; run;
proc print data=ffs.ffsptd_prevweights17; run;
proc print data=ffs.ffsptd_incweights16; run;
proc print data=ffs.ffsptd_incweights17; run;
	