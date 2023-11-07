/*********************************************************************************************/
TITLE1 'Base';

* AUTHOR: Patricia Ferido;

* DATE: 8/20/2020;

* PURPOSE: Limit sample to 66+ and making an age calculation to match Optum age where only year is available;

options compress=yes nocenter ls=160 ps=200 errors=5  errorcheck=strict mprint merror
	mergenoby=warn varlenchk=error dkricond=error dkrocond=error msglevel=i;
/*********************************************************************************************/

***** Formats;
proc format;
	value $raceft
		"0"="Unknown"
		"1"="Non-Hispanic White"
		"2"="Black"
		"3"="Other"
		"4"="Asian/Pacific Islander"
		"5"="Hispanic"
		"6"="American Indian/Alaska Native"
		"7"="All Races";
	value $sexft
		"1"="Male"
		"2"="Female";
	value agegroup
		low-<75 = "1. <75"
		75-84  = "2. 75-84"
		85 - high = "3. 85+";
	value agegroupa
		low-<70 = "1. <70  "
		70-74 = "2. 70-74"
		75-79  = "2. 75-89"
		80 - high = "3. 80+";
run;

data base.samp_1yrffsptd_0620_66plus;
	set base.samp_1yrffsptd_0620;
	array insamp [2006:2020] insamp2006-insamp2020;
	array age_beg [2006:2020] age_beg2006-age_beg2020;
	array age_group [2006:2020] age_group2006-age_group2020;
	array age_groupa [2006:2020] age_groupa2006-age_groupa2020;

	yrdob=year(birth_date);
	do yr=2006 to 2020;
		age_beg[yr]=yr-yrdob;
		age_group[yr]=put(age_beg[yr],agegroup.);
		age_groupa[yr]=put(age_beg[yr],agegroupa.);
		if age_beg[yr]<66 then insamp[yr]=0; * requiring everyone in sample to be at least 66;
	end;
run;

data base.samp_1yrmaptd_0620_66plus;
	set base.samp_1yrmaptd_0620;
	array insamp [2006:2020] insamp2006-insamp2020;
	array age_beg [2006:2020] age_beg2006-age_beg2020;
	array age_group [2006:2020] age_group2006-age_group2020;
	array age_groupa [2006:2020] age_groupa2006-age_groupa2020;

	yrdob=year(birth_date);
	do yr=2006 to 2020;
		age_beg[yr]=yr-yrdob;
		age_group[yr]=put(age_beg[yr],agegroup.);
		age_groupa[yr]=put(age_beg[yr],agegroupa.);
		if age_beg[yr]<66 then insamp[yr]=0; * requiring everyone in sample to be at least 66;
	end;
run;

