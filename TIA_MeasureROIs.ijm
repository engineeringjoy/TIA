/*
 * TIA_MeasureROIs.ijm
 * Created by JFranco, 31 MAR 2024
 * 
 * This .ijm is a basic Tool for Image Analysis. It makes measuring the mean grey value of a manually defined  
 * ROI easier and less repetitive. It takes the user through:
 * 1. Identifying the file to analyze
 * 2. Generating a maximum projection image from the z-stack
 * 3. Allowing the user to manually draw ROIs and add them to the ROI manager.
 * 4. Measuring the mean grey value of the ROI within the specified channels
 * 5. Storing ROIs in a .zip folder for future use.
 * 6. Storing measured values for every ROI in a .csv file
 * 
 * Users are strongly urged to store raw image files in a subdirectory called "RawImages" or similar
 * within a folder that is dedicated to this analysis. 
 */
 
  /* 
 ************************** Required User Input ******************************
 */
 // Enter the name of the folder where the images are stored
 //  do not include the path to the folder
fdSave = "CZIs"

 
 /* 
 ************************** TIA_MeasureROIs.ijm ******************************
 */
 
 // *** HOUSEKEEPING ***
run("Close All");										// Close irrelevant images
roiManager("reset");									// Reset ROI manager
timeStamp = getTimeStamp();								// Time stamp for saving multiple versions

// *** GET THE FILE TO ANALYZE ***
Dialog.create("Welcome to TIA_MeasureROIs");
Dialog.addMessage("This macro will open your z-stack of choice\n"+
	"and guide you through the ROI measurement process.\n"+
	"When presented with the BioFormats opener, use default settings,.\n"+
	"but make sure to not use a virtual stack & don't split channels.\n"+
	"Click 'OK' when you're ready to choose an image.");
Dialog.show();
impath = File.openDialog("Choose image to open");    	// Ask user to find file 
open(impath);											// Open the image	

// *** SETUP VARIABLES BASED ON FILENAME & PATH ***
fn = File.name;											// Save the filename (with extension)
fnBase = File.getNameWithoutExtension(impath);			// Get image name
fnROIs = fnBase+".ROIs."+timeStamp+".zip";				// Filename for ROI set generated
fnSS = fnBase+".SS";									// Filename for substack generated
fnMP = fnBase+".MP";									// Filenmae for max projection generated
fnMD = fnBase+".MD.csv";								// Filename for metadata from the tracing process
wd = File.getDirectory(impath);							// Gets path to where the image is stored
rootInd = lastIndexOf(wd, fdSave);					    // Gets index in string for where root directory ends
root = substring(wd, 0, rootInd);						// Creates path to root directory
dirTIA = root+"/TIA_MeasureROIs.Results/";				// Main directory for all things generated via TIA_MeasureROIs
dirROIs = dirTIA+"ROIs/";								// Subdirectory for all ROI.zip files generated from each tracing session
dirSRs = dirTIA+"SingleROIViews/";						// Subdirectory for single ROI views saved as .tif 
dirMD = dirTIA+"Metadata/";								// Subdirectory for metadata related to each tracing session
dirSSs = dirTIA+"Substacks/";							// Subdirectory for substacks generated for each original z-stack
dirMPs = dirTIA+"MaxProjections/";						// Subdirectory for max projections generated for each original z-stack

// *** SETUP DIRECTORIES IF APPLICABLE ***
// Make directory for storing new files
if (!File.isDirectory(dirTIA)) {
	File.makeDirectory(dirTIA);
	if (!File.isDirectory(dirROIs)) {
		// Create subdirectories
		File.makeDirectory(dirROIs);
		File.makeDirectory(dirSRs);
		File.makeDirectory(dirMD);
		File.makeDirectory(dirSSs);
		File.makeDirectory(dirMPs);
	}
}

// Create a metadata sheet for the image -- Current code assumes image has not yet been traced and will save over existing
//       This approach will be changed in the future to instead just update the sheet if it exists
initResTable(dirMD+fnMD);


// *** HAVE USER MAKE SUBSTACK ***
Stack.getDimensions(width, height, channels, slices, frames);
/*
for (i = 0; i <= channels; i++) {
	Stack.setChannel(i);
	run("HiLo");
}
*/

waitForUser("Examine the Z-stack and choose which images to include in the max projection.\n"+
	"You will enter the specifications in the next dialog box.");
	
// Create dialog box	
Dialog.create("Create Substack");
Dialog.addMessage("Choose the channels and slices to include in the tracing process.");
Dialog.addString("Channel Start","1");
Dialog.addString("Channel End",channels);
Dialog.addString("Slice Start","1");
Dialog.addString("Slice End", slices);
Dialog.addString("Channel to use for tracting", "4");
Dialog.show();
// Read in values from dialog box
chStart = Dialog.getString();
chEnd = Dialog.getString();
slStart = Dialog.getString();
slEnd = Dialog.getString();
chTrace = Dialog.getString();

// Make the substack to spec and save
run("Make Substack...", "channels="+chStart+"-"+chEnd+" slices="+slStart+"-"+slEnd);
saveAs("Tiff",dirSSs+fnSS+".tif");
Stack.getDimensions(width, height, channels, slices, frames);					// Update dimensions

// Create the max projection to be used as a tracing guide
run("Z Project...", "projection=[Max Intensity]");
saveAs("Tiff",dirMPs+fnMP+".tif");												

// Close unneccessary images
close("\\Others");

// *** BEGIN TRACING PROCESS
Stack.setChannel(chTrace);

// Explain to the user how to add neurite traces to the ROI manager
waitForUser("Select your tracing tool of choice icon in the toolbar (oval or freehand are suggested for somata).\n"+
	"In the ROI Manager window select 'Show All' and 'Labels'.\n"+
	"After this you'll begin tracing ROIs and adding them to the ROI manager.\n"+
	"Use the shortcut keys 'Ctrl+t' or 'CMD+t' to quickly add the ROIs.");
	
// Trace and save the ROI, create the Single ROI View
//setTool("oval");
waitForUser("Trace an then add it the ROI to the manager.\n"+
			"Trace as many ROIs as desired, then click 'OK' to save the set.");

// *** BEGIN PROCESSING TRACES ***

// Split the max projection stack into seperate images
//    This was the only way I could get run(grays) and plotting to work
selectWindow(fnMP+".tif");
run("Split Channels");			

// Revert look up table to greys rather than HiLo						
for (j = 0; j < channels; j++) {
	selectWindow("C"+toString(j+1)+"-"+fnMP+".tif");
    run("Grays");
}

// Begin iterating through the traces/ROIs
n = roiManager('count');
for (i = 0; i < n; i++) {
	
	roiManager('select', i);
	area = Roi.size;
	
	// Update results table for this specific ROI 	
	setResult("image_name", i, fnBase);
	setResult("timestamp", i, timeStamp);
	setResult("slice_start",i, slStart);
	setResult("slice_end",i, slEnd);
	setResult("roi",i, "ROI_"+i);					// ROI ID is saved based on index
	setResult("roiArea", i, area);
	updateResults();

    // Iterate through the channels and measure the grey values for the ROI
    for (j = 0; j < channels; j++) {
 		selectWindow("C"+toString(j+1)+"-"+fnMP+".tif");
 		roiManager('select', i);
 		cMean = getValue("Mean");
 		setResult("c"+toString(j+1)+"_grey",i,cMean);	
    }

}
// Save all of the ROIs in one zip file that can be reopened using the ROI manager
roiManager("save", dirROIs+fnROIs);

// Save the metadata from tracing
selectWindow("Results");
saveAs("Results", dirMD+fnMD);

waitForUser("Take a screenshot of the max projection with all ROIs shown then click 'OK' to exit.");
close("*");
exit;

/*
 * ************************	 	FUNCTION DEFINITIONS		**********************	
 */
function getTimeStamp(){
	print("\\Clear");
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	month++;
	if (month<10) {month = "0"+toString(month);}
	if (dayOfMonth<10) {month = "0"+toString(dayOfMonth);}
	date = toString(year)+ month + dayOfMonth;
	if (hour<10) {hour = "0"+toString(hour);}
	if (minute<10) {minute = "0"+toString(minute);}
	time = toString(hour)+"h"+toString(minute) +"m";
	arrDateTime = Array.concat(date + "_"+ time);
	Array.print(arrDateTime);
	strDateTime = toString(getInfo("log"));
	strDateTime = substring(strDateTime, 0, lengthOf(strDateTime)-1);
	return strDateTime;
}

function initResTable(fPathMD){
// FUNCTION RUNS IF THIS IS THE FIRST TIME SETTING UP DIRECTORIES

	// Setup MD Results Table based on list of images in ProcessedWCS directory
	run("Clear Results");											 
	setResult("image_name", 0, 'TBD');
	setResult("timestamp", 0, 'TBD');
	setResult("slice_start", 0, 'TBD');
	setResult("slice_end", 0, 'TBD');
	setResult("roi", 0, 'TBD');
	setResult("roiArea", 0, 'TBD');
	setResult("channels",0,'TBD');
	setResult("slices",0,'TBD');
	setResult("frames",0,'TBD');
	setResult("c1_grey",0,'TBD');
	setResult("c2_grey",0,'TBD');
	setResult("c3_grey",0,'TBD');
	setResult("c4_grey",0,'TBD');
	updateResults();
		
	// Immediately create a saved copy of the MD file
	selectWindow("Results");
	saveAs("Results", fPathMD);
}
