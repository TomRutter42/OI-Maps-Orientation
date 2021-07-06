###############Imports##################
import re
import os
import argparse
import json
from sys import platform
import subprocess
################Globals#################

#Template files that will be used/populated by this program
pathsTemplateFile = r"paths_template.js"
settingsTemplateFile = r"settings_template.json"
map_html_file = r"map_template.html"
zoom_html_file = r"map_zoom.html"

#Geo Files
czFile = "geos/usa_county_cz_zip.json"
geoFileFmt = "geos/{0}_topo.json"

#Names of the output files generated after populating the templates
pathsFile = "filepaths.js"
settingsFile = "map_settings.json"


#The paths to phantomjs & rasterize files
phantom_macpath = "./bin/mac.phantomjs"
phantom_winpath = "./bin/win.phantomjs.exe"
rasterfile = "rasterize.js"

#Strings this script looks to replace in the paths template file
mapFileTempStr = "MAPFILE"
dataFileTempStr = "DATAFILE"
settingsFileStr = "SETTINGSFILE"
#############Functions####################

#Get and parse cmd line arguments.
#NOTE: Do NOT specify defaults here. Defaults are read from the settings template file.
def getMapArgs():

	parser = argparse.ArgumentParser()
	
	#Options for inputting data.
	csv_group = parser.add_argument_group("Data Input", "Options for reading the csv data.")
	csv_group.add_argument('-df', "--dataFile", required = True, help="Path to the CSV file containing the data to be mapped")
	csv_group.add_argument("-gt", "--geoType", choices=["cz", "county", "zip", "state"], help="The geographical units the data represents.", required = True)
	csv_group.add_argument("-id", "--idColumn", help="The name of the ID column in the csv file (case sensitive). If unspecified, it's assumed to be the 1st column")
	csv_group.add_argument("-dc", "--dataColumn", help="The name of the csv column to plot (case sensitive). If unspecified, it's assumed to be the 2nd column")
	#csv_group.add_argument("-st", "--state", choices=["illi", "newy", "newj", "mass", "wash", "texa", "cali"])
	
	#Options on splitting the data into ranges	
	parts_group = parser.add_mutually_exclusive_group()
	parts_group.add_argument("-pt", "--parts", type=int, choices=range(2,10), help="The number of equally-sized percentiles to split your data in. For example, '--parts 4' will split your data into quartiles and assign a different color to each quartile. Default is 10")
	parts_group.add_argument("-ct", "--cutoffs", help ="A comma separated list of values (enclosed in quotes) to cut the data by. E.g. --cutoffs '0.5,0.8,1.8'")

	#Options for coloring
	colors_group = parser.add_argument_group("Color settings", "Options for setting the color scheme")
	colorscheme_group =  colors_group.add_mutually_exclusive_group()
	colorscheme_group.add_argument("-cs", "--colorScheme", help="The colorBrewer scheme to use. See http://bl.ocks.org/mbostock/5577023 for allowed values.")
	colorscheme_group.add_argument("-cl", "--colors", help="Comma sperated list of colors you wish to use, starting from the color corresponding to the lowest (first) cutoff. The number of colors should be the same as the no. of parts you want the data split into. E.g (for 3 parts): --colors '#FFFFGG,#000000,#AAABBB'") 
	colors_group.add_argument("-ic", "--invertColors",  help="Reverse the color scheme, for e.g., to make smaller numbers correspond to darker colors", action="store_true")
	
	#Options for drawing the map
	#dimensions_group = parser.add_mutually_exclusive_group()
	#dimensions_group.add_argument("-cw", "--canvasWidth", type=int, help="The width of the map to be rendered. Height is adjusted accordingly")
	#dimensions_group.add_argument("-ch", "--canvasHeight", type=int, help="The height of the map to be rendered. Width is adjusted accordingly")

	#Options for exporting the map
	output_group = parser.add_argument_group("Output", "Options for producing output")
	output_group.add_argument("-zr", "--zoomToRegion",  help="If this flag is set, the output map is zoomed to focus only on the subregion of the map that contains data (useful for plotting a particular county, for example)", action="store_true")
	output_group.add_argument("-ni", "--noImage",  help="If this flag is set, an ouput img file is *not* generated. The script only modifies the settings files (filepaths & map_settings) and stops. (Used for debugging)", action="store_true")
	output_group.add_argument("-op", "--output", help="The path to the output file. If not specified, the image will get exported to <dataFile>_<dataColumn>.png and overwrite any existing file.")
	output_group.add_argument("-tt", "--tooltips", help ="A comma separated list of column names to be rendered as tooltips in the HTML map. --tooltips 'cz,iceCreamSold'. By default, this list is empty and tooltips are not rendered.")
	
	#Options for the legend
	legend_group = parser.add_argument_group("Legend", "Options for setting properties of the legend. These options are ignored if -noLegend is set to true")
	legend_group.add_argument("-nl", "--noLegend", help="Do NOT draw a legend for the map (A legend is included by default)", action="store_true")
	legend_group.add_argument("-fs", "--formatStr", help = "A valid format string that describes how to display the numbers on the labels. See https://github.com/mbostock/d3/wiki/Formatting for the language specification.")
	legend_group.add_argument("-lw", "--legendWidth", help = "The width of the legend box, in pixels")
	legend_group.add_argument("-lh", "--legendHeight", help = "The height of the legend box, in pixels")
	legend_group.add_argument("-lm", "--labelForMissingData", help = "The label text associated with the 'Missing/No Information' box in the legend. NOTE: If you don't want a legend entry drawn for missing data, set this value to the string 'leave_out'")
	legend_group.add_argument("-ls", "--legendStyle", choices={"basic", "jama", "slice_under", "slice_side"}, help = "The style of legend to draw. Defaults to 'basic'")

	args = parser.parse_args()
	#print(args)
	return args;

#Combine user-specified arguments and defaults from a template to generate the final settings
def getSettings(args):
	f_template = open(settingsTemplateFile, "r")
	settings = json.load(f_template)
	f_template.close()

	#Get the args as a dictionary	
	args_dict = vars(args)

	#Record which parameters are meant to be lists/arrays.
	array_type_params = [x for x in settings.keys() if isinstance(settings[x], list)]

	#If values are provided in args, overwrite the defaults.
	for key in args_dict:
		if key in settings:
			if (args_dict[key] and not str(args_dict[key]).isspace()):
				settings[key] = args_dict[key]

	#Some groups are mutually exclusive. If the user has provided one of these values, 
	#the other should be set to empty.
	#TODO: Right now we check for each mutually exclusive group manually. 
	#Must find an automatic way to do this.
	args_set = set([x for x in args_dict.keys() if args_dict[x]])
	exclusive_groups = [["colors", "colorScheme"], ["parts", "cutoffs"]]
	for group in exclusive_groups:
		#Check if any one element of the groups has been specified. 
		#If yes, set the other to empty. Otherwise, let the defaults remain. 
		if set(group) - args_set == set(group):
			continue #Neither of the arguments have been specified; do nothing
		leftovers = set(group) - args_set
		for leftover in leftovers:
			settings[leftover] = ""
		#If "cutoffs" has been specified, we need to set scale_type to "threshold"
		if "cutoffs" in args_set:
			settings["scaleType"] = "threshold"

	#Handle array-type parameters
	for param in array_type_params:
		if isinstance(settings[param], str) and settings[param]!="":
			settings[param] = [str.strip(x) for x in settings[param].split(",")]

	#If idColumn and dataColumn are not specified, these are assumed to be the 
	#first and second cols respectively of the csv.
	
	f_csv = open(args.dataFile, "r")
	header = f_csv.readline();
	f_csv.close()

	colNames = [x.strip(" \"'") for x in header.split(',')]	
	if(not settings['idColumn'] or settings['idColumn'].isspace()):
		settings['idColumn'] = colNames[0].strip()
	if(not settings['dataColumn'] or settings['dataColumn'].isspace()):
		settings['dataColumn'] = colNames[1].strip()
	return settings;

#Write the Choropleth settings to an op file.
def writeSettings(settings, path):
	f_out = open(path, "w")
	json.dump(settings, f_out, indent=1)
	f_out.close()	
	
#Replace contents of a template file to produce the "paths" file
def generatePathsFileFromTemplate(args):
	global czFile
	global pathsTemplateFile
	global settingsFile
	
	f_template = open(pathsTemplateFile, "r")
	fileContents = f_template .read();
	f_template.close()
	
	#Replace backward slashes with forward slashes to make paths 
	#compatible across OS's
	#if(args.state):
	#	czFile = str.format(geoFileFmt, args.state)
	if(args.zoomToRegion):
		czFile = "geos/usa_county_cz_zip_2.json"#HACK! TODO: Fix this
	else:
		czFile = re.sub(r"[\\\/]+", "/", czFile)

	args.dataFile = re.sub(r"[\\\/]+", "/", args.dataFile)
	settingsFile = re.sub(r"[\\\/]+", "/", settingsFile)
	
	fileContents = fileContents.replace(dataFileTempStr, args.dataFile)
	#FOR NOW, WE DEFAULT TO CZ
	fileContents = fileContents.replace(mapFileTempStr, czFile)
	fileContents = fileContents.replace(settingsFileStr,  settingsFile)
 
	f_out = open(pathsFile, "w")
	f_out.write(fileContents)
	f_out.close()
	
	return;

############MAIN#################

#Get the arguments
args = getMapArgs()
#print(args)

#Generate the files required by map.html
settings = getSettings(args)

#Finally, write these settings out
writeSettings(settings, settingsFile)

#Get and Write the paths to 3 files that map.html needs:
#   - DataFile (provided as an argument)
#   - mapFile (depends on the geo chosen)
#   - settingsFile (the file to which all settings are written)
generatePathsFileFromTemplate(args) 

#If produceImage has been specified, we call the phantom.js to create the file
output_filename = args.output

if (not args.noImage):
	if (not output_filename) or (not output_filename.endswith(".png")):
		df_basename = os.path.splitext(os.path.basename(args.dataFile))[0]
		output_filename = df_basename + "_" + settings['dataColumn'] + ".png"
		#TODO: Check if output_filename is a valid path
	
	html_code_file = map_html_file
	if(args.zoomToRegion):
		html_code_file = zoom_html_file
		
	#Call the appropriate phantomjs depending on the os
	retcode = 1 #Error, by default
	if(platform.startswith("win")):
		retcode = subprocess.call([phantom_winpath, rasterfile, html_code_file, output_filename])
	else:
		retcode = subprocess.call([phantom_macpath, rasterfile, html_code_file, output_filename])

	if(not retcode):
		print("The command executed successfully. Map written to " + output_filename)
	else:
		print("The command executed unsuccessfully with error code: " + retcode)
	

