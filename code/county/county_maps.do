* Tom R 

* July 6th 2021

* For OI Orientation.
* Produce examples of county maps for OI papers.  

* ==============================================================================

* Set up additional ado path, just for today in case you don't have access to the Dropbox! 
** Usually, it's better to just use the ado files in: 
** Opportunity Insights Shared Workspace/Research files/ado
adopath++ "${github}/maps-drafting/ado"

* ==============================================================================

* DATA IMPORT

** Struggling to read this file? I'd guess that your profile.do is not set up correctly -- let me know!
use "${github}/maps-drafting/inputs/county/county_data", clear 

* ==============================================================================

* CLEANING

** The file we imported separately lists the two digit state code (although as numeric, so missing the leading zero) 
** and a three digit county code (also as numeric). So need to convert: 
// tostring county, replace
gen county_str = string(state, "%02.0f") + string(county, "%03.0f")
drop county 
rename county_str county
destring county, replace

* ==============================================================================

* PRODUCE MAPS

* Example 1: Make a map of one variable: 

gen med_hhinc2016_rounded = round(med_hhinc2016, 1000)
mapmaker med_hhinc2016_rounded, geo(county) legdecimals(0) colorscheme("RdYlBu") ///
	savegraph("${github}/maps-drafting/outputs/stata_county_median_inc.png")

* Example 2: Loop through a bunch of variables, graphing them all

local vars_to_map poor_share2010 /// 
				  foreign_share2010 /// 
				  frac_coll_plus2010 /// 
				  share_white2000

foreach var of local vars_to_map {
	
	mapmaker `var', geo(county) colorscheme("RdYlBu") legpercent legdecimals(1) ///
		savegraph("${github}/maps-drafting/outputs/stata_county_`var'.png")

}

* ==============================================================================
* END OF CODE
