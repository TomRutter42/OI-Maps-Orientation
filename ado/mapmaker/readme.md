### Introduction

This is a set of scripts/tools to generate [choropleths](http://bl.ocks.org/mbostock/4060606)  of the USA. 
A choropleth is a map where the color assigned to each unit (say, county or commuting-zone) is determined by a numerical value associated with that unit (say, ice-cream sold per day). 

The tool uses a  [Python](https://www.python.org/) script to parse arguments; uses [D3.js](http://d3js.org/) to draw scalable [SVG](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) maps; and [phantom.js](http://phantomjs.org/) to convert the SVG drawings into static images.

### Installation

You need [Python](https://www.python.org/) to run the python script. No other installation is required. Just download the directory and CD into trunk.

In fact, it is possible to produce the maps _without_ python, by just using a browser and manually modifying a configuration file.  (See the Appendix on how to do this). 

### Usage
There are two ways to specify parameters to this tool:

* Via a Python script (map_maker.py)
* Via a configuration file (map_settings.json)

The python script is a thin wrapper around the configuration file; it reads the command-line parameters you pass it, checks them for errors, and writes them into the configuration file. 

For the rest of this document (unless otherwise specified) we'll discuss using the python script. The Browser + File method is discussed in the appendix, and can be useful in situations where you're fine-tuning rarely used parameters, e.g. the size of the legend boxes. 

#### Help 
After downloading the sources directory, CD into it on the cmd line / terminal and type:

`python map_maker.py`

This will bring up a quick-help on usage. To see more detailed help instructions, type:

`python map_maker.py --help`

Go through the output of the above command to get an idea of the tool's parameters. Notice that most parameters have two-lettered shorthands; typing the full name is equivalent to typing the shorthand (e.g.,  `--help` is the same as `-h`) and the two are used interchangeably below.


#### Basic Usage

For the rest of this document we're going to use an example file (sampledata/czdata.csv) that comes bundled with the tools. Here's what it looks like:

*sampledata/czdata.csv*
	
	CZ, 	IceCreamSold
	13000,	0.50968397		
	13101,	1.49217		
	13102,	1.322314
	13103,	1.8327607
	13200,	1.4238676
	13300,	2.0447438
	13400,	2.4581349
	13501,	2.5879631
	
	
To generate a map that takes these CZ (commuting zone) values and colors each CZ by the _decile_ its ice cream sales fall in, type:

`python map_maker.py --dataFile sampledata/czdata.csv --geoType cz`

By default, this will create a static png file named _dataFile__dataColumn_.png, or in this case, czdata_iceCreamSold.png. You can specify another name for the output file yourself, like so:

`python map_maker.py --dataFile sampledata/czdata.csv --geoType cz --output outputmap.png`

Similarly, to plot a map of county-wise unemployment rates (made up values), type:
`python map_maker.py --dataFile sampledata/countydata.csv --geoType county --output outputmap.png`
 
Some important points to note:
	
* `--geoType` (same as `-gt`) and `--dataFile` (same as `-df`) are the only *_required_* parameters to this tool; all others are optional.
* Currently, geoType can be 'county', 'cz' (commuting zone) or 'zip' (5 digit zip code). Support for states is coming soon.
* It is okay to have empty values for a county/CZ/Zip, and it's okay to have counties/CZs/Zips missing altogether.
* Counties/CZs have to be specified by their FIPS codes. Zips are expected to be 5 digit strings.
* The output image is always a .png file.   

By default, the first column is assumed to be the ID (`idColumn`) and the second to be the value we wish to map (`dataColumn`). But this can easily be overridden using the `idColumn` (or `-id`) and `dataColumn` (`-dc`) parameters. 
For example, if czdata looked like this: 

*sampledata/czdata_wide.csv*

	Serial,	IceCreamSold,	AvgAdultWt,	CZ
	1,		0.50968397,		60,			13000
	2,		1.49217,		70,			13101
	3,		1.322314,		80,			13102
	4,		1.8327607,		60,			13103
	5,		1.4238676,		70,			13200
	6,		2.0447438,		80,			13300
	7,		2.4581349,		60,			13400
	...

We could plot ice cream sales by cz by typing:

`python map_maker.py --dataFile sampledata/czdata_wide.csv --geoType cz --idColumn CZ --dataColumn IceCreamSold --output outputmap.png`

or

`python map_maker.py -df sampledata/czdata_wide.csv -gt cz -id CZ -dc IceCreamSold -op outputmap.png`



#### Splitting Data

By default, the tool partitions data into deciles (10-percentiles). If you want to split data into quartiles or some other n-tile for n between 2 and 10, you can specify the `--parts` (`-pt`) parameter:
	
`python map_maker.py -df sampledata/czdata.csv -gt cz --parts 4 -op outputmap.png`

Suppose you do not want to compute percentiles/n-tiles, but want to give your own custom cutoffs to split the data by; then you can do so by providing `--cutoffs` (`-ct`) yourself:

`python map_maker.py -df sampledata/czdata.csv -gt cz --cutoffs "0.12, 2.35, 14" -op outputmap.png`

Note:

* The no. of cutoffs cannot be more than 9 (i.e., data can be split into at most 10 parts)
* `--cutoffs` and `--parts` are mutually exclusive parameters; you can only specify one of them.

#### Color Options

The mapmaker tool uses [ColorBrewer](http://colorbrewer2.org/) to pick colors. ColorBrewer is a standard JavaScript library that carefully chooses each color scheme's hues to make them as distinguishable from each other as possible. (See [here](http://www.personal.psu.edu/cab38/ColorBrewer/ColorBrewer_updates.html) for details). 

The default color scheme is "YlOrRd"; that is, the hue shifts from Yellow to Orange to Red as the data value increases. You can replace it with other ColorBrewer schemes like so:

`python map_maker.py -df sampledata/czdata.csv -gt county  -op outputmap.png --colorScheme "YlOrBr"`

The full list of allowed schemes is nicely illustrated [here](http://bl.ocks.org/mbostock/5577023). But you'll notice a problem: most schemes (with gradually changing hues) support at most 9 hues; but we frequently need to split data into 10 parts. To allow this, I've artificially extended the colorbrewer library to support 10 hues for the following schemes:

**Note:** These names are case-sensitive.
 
* YlGn
* YlOrRd
* YlOrBr
* Purples
* Blues
* Greens
* Oranges
* Reds
* Greys

Thus, if you wish to split your data in 10 parts (which is the default) you can use one of these schemes only; I cannot guarantee that the new hue is scientifically the best possible value. But for fewer parts, other colorbrewer schemes should work fine. 

Irrespective of the scheme, by default darker hues correspond to higher values. But sometimes we might want the opposite instead. For example, while plotting educational attainment by county we might want darker hues to represent lower values, not higher ones. 
You can invert the colorscheme by adding the `--invertColors` flag:

`python map_maker.py -df sampledata/czdata.csv -gt cz  -op outputmap.png --invertColors`


#### Legend options

The `-nl` (or `--noLegend`) flag is self explanatory; it draws the map but leaves out the legend.

`python map_maker.py -df sampledata/czdata.csv -gt cz  -op outputmap.png --noLegend`
	
The `--formatStr` option specifies how numbers in the legend should be formatted. The format string option gives you immense flexibility and control over formatting, such as the decimal places you want the numbers rounded to; whether you want numbers padded or cut to a fixed width; etc. See [here](https://github.com/mbostock/d3/wiki/Formatting) for a specification of the language or [here](http://koaning.s3-website-us-west-2.amazonaws.com/html/d3format.html) for a great interactive tutorial.

The default format is ".2f", which means all numbers are rounded to 2 decimal points. If you want numbers rounded to 3 decimal places instead, for example, you could type:

`python map_maker.py -df sampledata/czdata.csv -gt cz --formatStr .3f -op outputmap.png`

	
The following legend options are only available in the settings file and not exposed through the python wrapper:

* `legendHeight` and `legendWidth` allow you to specify the dimensions of each box in the legend
* `legendLabels` lets you override the generated label strings with your own strings. Each string replaces the label starting from bottom-up. (e.g. ["lowest decile", "second lowest decile", ...])
* `labelForMissingData` lets you specify the legend text associated with the "Missing data" box, at the bottom of the legend. 

### Known Issues

Please report bugs, issues and feature requests to the author at(firstname.lastname@gmail.com)

#### Known Bugs
* JPG output produces a black background
* PDF output has colors shifted to the right 
* `--cutoffs` parameter doesn't work

#### Planned Features
* Support for States
* Expose LegendTitle in the python script
* Legend scale proportional to the length of each quantile (e.g. [this](http://bl.ocks.org/mbostock/5144735))
* Ability to zoom in on particular counties/CZs; possibly with an inset map of the whole country in a corner.

### Appendix

#### How the tool works: an outline

1. The Python script takes parameters from the cmd line
2. Python script reads a pre-baked configuration-file (settings_template.json) and overwrites default values with those specified by the user on the cmd line; the result is written to the configuration-file map_settings.json
3. map_template.html reads map_settings.json to produce an HTML/SVG image; but since this is HTML, the file needs to be *served* by a server for the map to get drawn. (Think of this as the step where the actual drawing on your screen happens) 
4. python script calls [phantom.js](http://phantomjs.org/) (a headless browser) to serve the image and capture it as an image  


#### Other  ways to generate the map
To generate the map without using Python or Firefox, do the following:

1. Modify the configuration file (map_settings.json) by hand. The parameters here have the same meaning as they did on the Python command line. Do *_NOT_* add or remove any parameter; just modify the values of the ones you're interested in. 
2. Open filepaths.js. Set "dataFile" to be the path to the file that contains your CSV data.
3. Run phantom.js as shown below to produce the final image:

`$ bin\win.phantomjs.exe rasterize.js map_template.html outputfile.png`

If you're on a mac instead of a windows machine, type:

`$ bin/mac.phantomjs rasterize.js map_template.html outputfile.png`

If you have Firefox but no Python, you can preview the SVG/html by simply opening map_template.html in it (after you've completed steps #1 and #2 above). This method works for Firefox because it "serves" (renders) the SVG on its own, unlike other browsers. 

To preview the HTML/SVG in Chrome or IE, you'll need Python to start a local server that can "serve" (or render) this page. To do this, cd into the directory that contains map_template.html, and type:

`$ Python -m http.server` (Python 3)
  or
`$ Python -m SimpleHTTPServer` (Python 2)

Once you've started this process on a cmd line, leave it alone. (Don't kill it!)
Now you can go to  _any_ browser and type the address below to preview your map:

`http://localhost:8000/map_template.html`

Note: if you're running this on a machine that's already a server, there port 8000 might already be occupied. In this case, you can pass a port number as an argument to the above cmd (e.g  `Python -m SimpleHTTPServer 8010` and then browse localhost:8010 to view your HTML/SVG page) 

### Acknowledgements:

* The code uses [D3.js](http://d3js.org/) to draw vector graphics [SVG], and draws heavily from Mike Bostock's examples. 
* [ColorBrewer](http://www.personal.psu.edu/cab38/ColorBrewer/ColorBrewer_updates.html) is used for generating color schemes
* [Phanton.js](http://phantomjs.org/) for "serving" the SVG and capturing it as an image
