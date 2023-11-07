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

* Flagging all the AD drugs of interest;
%macro pdech(minyear,maxyear);
	%do year=&minyear %to &maxyear;
		%do q=1 %to 4;
			
			proc sort data=optum.dod_r&year.q&q. out=dod_r&year.q&q.; by patid fill_dt; run;
				
			data adrx&year._q&q.;
				set dod_r&year.q&q.;
				by patid fill_dt;
				
				if anyalpha(ndc) then ndcn=.;
				else ndcn=ndc*1;
				
				donep=(find(gnrc_nm,'DONEPEZIL'));

				galan=(find(gnrc_nm,'GALANTAMINE'));
				
				meman=(find(gnrc_nm,'MEMANTINE'));
				
				rivas=(find(gnrc_nm,'RIVASTIGMINE'));
				
				ADdrug=max(donep,galan,meman,rivas);
				
				if ADdrug=1;
				
			run;
		%end;
	%end;
	
	data demdx.dementia_rx&minyear._&maxyear.;
		set %do year=&minyear. %to &maxyear.;
					%do q=1 %to 4;
						adrx&year._q&q
					%end;
				%end;;
		by patid fill_dt;
	run;
	
	proc freq data=demdx.dementia_rx&minyear._&maxyear. noprint;
		where donep=1;
		table Gnrc_Nm*brnd_nm / out=donep;
	run;

	proc freq data=demdx.dementia_rx&minyear._&maxyear. noprint;
		where galan=1;
		table Gnrc_Nm*brnd_nm / out=galan;
	run;

	proc freq data=demdx.dementia_rx&minyear._&maxyear. noprint;
		where meman=1;
		table Gnrc_Nm*brnd_nm / out=meman;
	run;

	proc freq data=demdx.dementia_rx&minyear._&maxyear. noprint;
		where rivas=1;
		table Gnrc_Nm*brnd_nm / out=rivas;
	run;

	proc print data=donep; run;
	proc print data=galan; run;
	proc print data=meman; run;
	proc print data=rivas; run;

**** Creating data level part D file;
proc sql;
	create table demdx.dementia_rxdt&minyear._&maxyear. as
	select patid, fill_dt, year(fill_dt) as year, max(ADdrug) as ADdrug, max(donep) as donep,
	max(galan) as galan, max(meman) as meman, max(rivas) as rivas, sum(days_sup) as dayssply
	from demdx.dementia_rx&minyear._&maxyear.
	where days_sup>=14
	group by patid, year, fill_dt
	order by patid, year, fill_dt;
quit;

**** Checks;
proc means data=demdx.dementia_rxdt&minyear._&maxyear. noprint;
	class year;
	var ADdrug donep galan meman rivas dayssply;
	output out=addrugs_stats (drop=_type_ _freq_) sum()= mean()= / autoname;
run;

proc freq data=demdx.dementia_rxdt&minyear._&maxyear. noprint;
	table year*patid / out=patid_byyear;
run;

proc freq data=patid_byyear noprint;
	table year / out=patid_byyear1;
run;

data stats;
	merge patid_byyear1 (in=a) addrugs_stats (in=b);
	by year;
run;

proc print data=stats; run;
	
%mend;

%pdech(2007,2019);

	
