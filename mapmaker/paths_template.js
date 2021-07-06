/* 
 * These file settings are in a .js instead of a .json file so that they can be loaded in map.html's 
 * header instead of its body. D3.queue can then be used to load these files in the body, asynchronously.
 */
 
var filePaths = {
	"mapFile" : "MAPFILE", //The path to a topojson file that defines the map's geography (cz, state, country, whatever)
	"dataFile" : "DATAFILE", //The path to a csv file that contains a numeric value for each unit in that geography.	
	"settingsFile" : "SETTINGSFILE" //The path the a .json file that contains settings on how to render the map.
};