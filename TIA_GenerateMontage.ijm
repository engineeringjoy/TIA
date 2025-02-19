/*
 * AISS_GenerateMontage.ijm
 * JFRANCO
 * Created 20220505
 * Update 20220505
 * 
 * The purpose of this macro is to generate montage images that are optimized for using 
 * the Measure Line plugin.
 */

/* 
 ************************** MACRO AISS_FrequencyMapper.ijm ******************************
 */

 /*
 * 	ENTER USER SPECIFIC INFORMATION
 */
 // Requires user specific changes
dirMain = "/Users/joyfranco/Dropbox (Partners HealthCare)/JF_Shared/Data/WSS/";		// Path to main data subdirectory 


// Close irrelevant images that might be open
run("Close All");			
														
// Location for dialog boxes
x_d = 260;							// x position of dialog boxes
y_d = 125;							// y position of dialog boxes 
// Location for images
x_iw = 260;							// x position of image window
y_iw = 300; 						// y position of image window

/*	
 * GET PREP, IMAGING, SAMPLING, AND WCS INFORMATION FROM USER
 */

choice = getUserChoice();
index = 0;
while (choice[0] != 'EXIT') {
	batchID = choice[1];
	sampID = choice[2];
	
	// Set Directory 
	dirID = dirMain+"WSS_"+batchID+"/";
	dirSV = dirID+"FrequencyMapping/";
	
	// Open Images
	n = 3;
	for (i = 0; i < n; i++) {
		turn = i+1;
		id = "WSS_"+batchID+sampID+".T"+turn+".01.Zs.1C.MPI";
		//id = "WSS_"+batchID+sampID+".T"+turn+".01.Zs.1C.MPI";
		//id = "WSS_"+batchID+sampID+".T"+turn+".01.Zs.2C.MPI";
		dirIms = dirID+"Raw_10x/MPIs/"+id+"/";
		imID = id+".png";
		//imID = id+"_c1+2.png";
		//imID = id+"_c1+2+3.png";
		//imID = id+"_c2.png";
		//imID = id+".png";
		open(dirIms+imID);
		
	
	}
	
	// Make, adjust, and save montage
	run("Images to Stack", "name=Stack title=[] use");
	run("Stack Sorter");
	
	waitForUser("Adjust stack order as necessary.\n Click 'ok' when done or 'cancel' to exit.");
	run("Make Montage...", "columns=3 rows=1 scale=1");
	
	svID = "WSS_"+batchID+sampID;
	saveAs("PNG", dirSV+svID+".Montage.png");
	
	close("*");

	// Restart Process
	choice = getUserChoice();
}
/*
 * ******************************	 MACRO END		******************************	
 */



/*
 * ************************	 	FUNCTION DEFINITIONS		**********************	
 */ 

function getUserChoice() {
// SETUP GUI FOR USER TO EITHER QUIT OR SELECT NEXT IMAGE FOLDER
	options = Array.concat("CONTINUE", "EXIT");
	Dialog.create("Frequencing Mapping");
	Dialog.addChoice("Proceed with freq. mapping?", options);
	Dialog.addString("Batch Number",'050');
	Dialog.addString("Sample Number",'.01');
	Dialog.setLocation(x_d,y_d);
	Dialog.show();
	
	// Read in values from dialog box
	check = Dialog.getChoice();
	batchID = Dialog.getString();
	sampID = Dialog.getString();
	
	ids = Array.concat(check,batchID,sampID);
	
	
	// GET AND RETURN USER INPUT ONCE USER HITS 'OK' ON DIALOG BOX
	return ids;
} 
 
 
 
 
 
 
 
 
 
 
 
 