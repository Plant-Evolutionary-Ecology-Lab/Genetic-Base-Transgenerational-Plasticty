//--------------------------------------------------
// 		SPIRA v2.2
// 		Image Analysis Duckweed
//
// 		Marie Sarazova
// 		for AG Xu
// 		Institute of Evolution and Biodiversity
// 		WWU Münster
//
//		February 2021
//
//--------------------------------------------------

print("---");
print("SPIRA v2.2 started");
print("");

//two options for starting the script: from scratch or continuing working on an existing analysis
startOptions=newArray(4);
startOptions[0] = "New Analysis";
startOptions[1] = "Continue Existing Analysis";
startOptions[2] = "Re-Analyze Frond Area (beta)";
startOptions[3] = "Edit Frond Counts";

Dialog.create("Start from...");
Dialog.addChoice("", startOptions);
Dialog.show();

startChoice = Dialog.getChoice();
print("Start choice: " + startChoice);

//in case we already have a started analysis, we have to point to the folder
//if starting ew, then this has to be set upt and image data have to be copied there

if(startChoice == startOptions[0])
{
	//analysisFolderPath instead of in and out folder
	//like it was for ML. Is then Quite easy to oversee and make changes
	parentFolderPath = getDirectory("Choose a location for your analysis folder. All analysis related data will be stored there:");
	
	Dialog.create("Analysis folder name");
	Dialog.addMessage("Type in the name for your analysis project:");
	Dialog.addString("","", 35);
	Dialog.show;
	analysisFolderName=Dialog.getString();
	analysisFolderPath=parentFolderPath + analysisFolderName;
	File.makeDirectory(analysisFolderPath);
	
	print("");
	print("Analysis project name: " + analysisFolderName);
	print("All analysis project data will be stored here: " + analysisFolderPath);
	
	imgFolderPath = analysisFolderPath + File.separator + "img";
	File.makeDirectory(imgFolderPath);
	print("Created folder: " + imgFolderPath);
	
	waitForUser("Please copy all your image data into this folder: \n" + imgFolderPath);
	
	
	//getting filelist from the infolder
	//(also checking if there are any, if not, reatempt)
	QCcopy = "wrong";
	while(QCcopy =="wrong")
	{
		imgList=getFileList(imgFolderPath);
		if(imgList.length==0)
		{
			waitForUser("0 files copied. Try again, please.\nPlease copy all your image data into this folder: \n" + imgFolderPath);
		}
		else if(imgList.length>0)
		{
			print("Dataset contains " + imgList.length + " files:" );
			QCcopy = "correct";
		}
		imgList=getFileList(imgFolderPath);
	}

	print("Files in the \"img\" folder:");
	for (i = 0; i < imgList.length; i++) 
	{
		print(imgList[i]);
	}

	startFromImg = imgList[0];
	//because it is a newly started project, analysis will start from the first image on the list

	drawAreasReturned = drawAndFrondArea(analysisFolderPath, startFromImg);
	print(drawAreasReturned);
}


else if(startChoice == startOptions[1])
{
	//print("Continue existing analysis");
	
	analysisFolderPath = getDirectory("Choose your analysis folder:");
	//check analysis folder - is there img folder?
	//if not, complain and quit
	//if yes, "look" inside and find img and roi files
	analysisFolderName = File.getName(analysisFolderPath);
	
	analysisFolderList = getFileList(analysisFolderPath);

	print("Analysis folder contents:");
	for (i=0; i<analysisFolderList.length; i++)
	{
		print(analysisFolderList[i]);
	}

	imgFolderFound=0;

	for (i=0; i<analysisFolderList.length; i++)
	{
		if(indexOf(analysisFolderList[i], "img")>-1)
		{
			imgFolderFound = 1;
		}
	}

	if (imgFolderFound == 0)
	{
		exit ("\"img\" folder not found! Make sure you have selected the right analysis folder. Script will abort.")
	}

	imgFolderPath = analysisFolderPath + File.separator + "img";
	imgFolderFullList = getFileList(imgFolderPath);

	//sorting rois files out into a list
	//evaluate where to start 

	//RATHER look for lonely file
	
	for (i=0; i<imgFolderFullList.length; i++ )
	{
		//look for images == non-zip files
		//if it does not have zip in the name, it is an image
		if (indexOf(imgFolderFullList[i], ".zip")==-1)
		{	
			print("image " + i + ": " +imgFolderFullList[i]);
			lookForRoi = substring(imgFolderFullList[i], 0, indexOf(imgFolderFullList[i], ".")) + ".zip "; //only based on a dot in filename, will not be too universal
			print("matching roi: " +lookForRoi);
			
			lookForRoiPath = imgFolderPath + File.separator + lookForRoi;
			print("path to matching roi: " + lookForRoiPath);
					
			if (File.exists(lookForRoiPath) == 0) //menas there is no roi to the given img
			{
				startFromImg = imgFolderFullList[i];
				print("First image without rois: " + startFromImg);		
				//and we will set I to max, so that the for loop exits:
				i  =imgFolderFullList.length;
			}
		}	
	}

	print("Drawing will resume from " + startFromImg);
	waitForUser("Drawing will resume from " + startFromImg);

	drawAreasReturned = drawAndFrondArea(analysisFolderPath, startFromImg); //calling a user defined funtion
	print(drawAreasReturned);
}


else if (startChoice == startOptions[2] )
{
	//print("Re-analysis of total frond area and pre-segmentation based on drawn borders but using other thresholding parameters");

	//where is the folder and first QC
	analysisFolderPath = getDirectory("Choose your analysis folder:");

	imgFolderPath = analysisFolderPath + File.separator + "img";
	if (File.exists (imgFolderPath) == 0)
	{
		exit ("\"img\" folder not found! Make sure you have selected the right analysis folder. Script will abort.")
	}

	//QC in img folder: are all rois present?
	imgFolderFullList = getFileList(imgFolderPath);

	//QC in img folder: are all rois present?

	noRoi = 0;
	noImg = 0;
	imgList =newArray(0);
	
	for (i=0; i<imgFolderFullList.length; i++)
	{
		if(indexOf(imgFolderFullList[i], ".zip")>-1)
		{
			noRoi++;
		}
		else if (indexOf(imgFolderFullList[i], ".zip")==-1)
		{
			noImg++;
			//also, image file will be added to the list for analysis
			toAdd=newArray(1);
			toAdd[0] = imgFolderFullList[i];
			imgList = Array.concat(imgList,toAdd);
		}
	}

	//exit("noRoi = " + noRoi + ", noImg = " + noImg);

	if (noImg == 0)
	{
		exit ("There are no images. Script will exit.");
	}

	else if (noRoi == noImg)
	{
		print("QC passed, number of zips = number of images.");
	}
	else
	{
		exit("Incomplete dataset: some rois might be missing. Please complete drawing first.");
	}

	//now referring to the function of re-analysis
	waitForUser("Attention: Old analysis will be overwriten by new one.");
	reAnalyseAreaReturned = reAnalyseArea(analysisFolderPath);
	print (reAnalyseAreaReturned);
}


else if(startChoice == startOptions[3])
{
	//print("Editing fronds");
	
	analysisFolderPath = getDirectory("Choose your analysis folder:");
	//check analysis folder - is there img folder?
	//if not, complain and quit
	//if yes, "look" inside and find img and roi files

	imgFolderPath = analysisFolderPath + File.separator + "img";
	if (File.exists (imgFolderPath) == 0)
	{
		exit ("\"img\" folder not found! Make sure you have selected the right analysis folder. Script will abort.")
	}

	//QC in img folder: are all rois present?
	imgFolderFullList = getFileList(imgFolderPath);

	//QC in img folder: are all rois present?

	noRoi = 0;
	noImg = 0;
	imgList =newArray(0);
	
	for (i=0; i<imgFolderFullList.length; i++)
	{
		if(indexOf(imgFolderFullList[i], ".zip")>-1)
		{
			noRoi++;
		}
		else if (indexOf(imgFolderFullList[i], ".zip")==-1)
		{
			noImg++;
			//also, image file will be added to the list for analysis
			toAdd=newArray(1);
			toAdd[0] = imgFolderFullList[i];
			imgList = Array.concat(imgList,toAdd);
		}
	}

	//exit("noRoi = " + noRoi + ", noImg = " + noImg);

	if (noImg == 0)
	{
		exit ("There are no images. Script will exit.");
	}

	else if (noRoi == noImg)
	{
		print("QC passed, number of zips = number of images.");
	}
	else
	{
		exit("Incomplete dataset: some rois might be missing. Please complete drawing first.");
	}

	editFrondsReturned = editFronds(analysisFolderPath);
	print(editFrondsReturned);
}

print("");
print("THE END.");
print("");


selectWindow("Log");
//logFolder = getDirectory("Choose a folder for saving the LOG:"); //old version
logFolder = analysisFolderPath;
saveAs("Text", logFolder + File.separator + "Log.txt");
//clearing the log
print("\\Clear");
	
run("Close All");//closing all windows (does not work that well...)
	
String.copy(analysisFolderPath);// putting the path to the analysis folder to the clipboard
waitForUser("Finished! \n \nThe analysis folder is here: \n" + analysisFolderPath + "\n(Path is in the clipboard)" );




//--- USER DEFINED FUNCTIONS ---

function drawAndFrondArea(analysisFolderPath, startFromImg)
{
	Dialog.create("Set threshold for frond identification");
	Dialog.addNumber("Min", 0);
	Dialog.addNumber("Min", 230);
	Dialog.addNumber("Size ex", 50);
	Dialog.addCheckbox("Watershed", true);
	Dialog.addMessage("Default: 0, 230, 50 + WS");
	Dialog.show();

	threMin = Dialog.getNumber();
	threMax = Dialog.getNumber();
	sizeEx = Dialog.getNumber();
	isWatershed = Dialog.getCheckbox();

	print("Settings for thresholding:");
	print("Min " + threMin);
	print("Max " + threMax);
	print("Size exclusion " + sizeEx + " px");
	
	clearOutFolderPath = analysisFolderPath + File.separator + "clearOut";
	if(File.exists(clearOutFolderPath)==0)
	//that is for a newly created project
	{
		File.makeDirectory(clearOutFolderPath);
		print("Created folder: " + clearOutFolderPath);
	}
	
	print("");
	
	flatFolderPath = analysisFolderPath + File.separator + "flat";
	if(File.exists(flatFolderPath)==0)
	{
		File.makeDirectory(flatFolderPath);
		print("Created folder: " + flatFolderPath);
	}
	
	print("");

	imgFolderPath = analysisFolderPath + File.separator + "img";
	//must be there because that is tehe first thing one makes when creating a project
	if(File.exists(imgFolderPath)==0)
	{
		exit("Can't fine image folder: " + imgFolderPath + "\nscript will abort");	
	}
	roiSaveFolder = imgFolderPath; //saving rois of diagonals in the img folder
	
	//open roi manager + basic setings
	run("ROI Manager...");
	roiManager("Show All without labels");
	
	print("");
	//initiating a result table file (txt file with results)
	//making a headder for the table
	resultFileName = analysisFolderName + "-results-area.txt";
	resultFilePath = analysisFolderPath + File.separator + resultFileName;



	//refreshing full list and fishing out the actual imgLIst to analyze
	//(in some cases somwhat doubled)
	imgFolderFullList = getFileList(imgFolderPath);
	imgList=newArray(0); //this will also reset old image lists
	startIncluding = 0;
	for(i = 0; i < imgFolderFullList.length; i++)
	{
		if (imgFolderFullList[i] == startFromImg)
		{
			startIncluding = 1; //flip the switch
		}
		if ((startIncluding==1) && (indexOf(imgFolderFullList[i], ".zip")==-1))
		{
			toAdd = newArray(1);
			toAdd[0] = imgFolderFullList[i];
			imgList = Array.concat(imgList, toAdd); //all folowing images will be added to the list for analysis
		}
	}

	//defining result file path
	resultFileName = analysisFolderName + "-results-area.txt";
	resultFilePath = analysisFolderPath + File.separator + resultFileName;
	print("Result table will be stored in " + resultFilePath);

	if(startFromImg == imgFolderFullList[0])
	// for new Analysis "from the top" initiating a result table file (txt file with results)
	//making a headder for the table
	{
		headder = "Image\tPixel_size[mm]\tFrond area[mm2]";
		File.append(headder, resultFilePath);
	}
	else 
	File.append("---New Section ---", resultFilePath);
	
	
	for (i = 0; i < imgList.length; i++) 
	{
		print("");
		print("Opening " + imgList[i]);
		open(imgFolderPath + File.separator + imgList[i]);
		imgTitle = getTitle();
	
		//line tool will be preset
		setTool("line");
	
		print("Draw diagonal(s)... ");
		//prompt
		waitForUser("Step 1: Draw a diagonal on calibration stone (inner square). Then press OK.");
	
		//adding to ROI manager
		roiManager("Add");
		roiManager("select", 0)
		roiManager("rename", "Diagonal-1");
	
		//prompt
		waitForUser("Step 2: Draw the other diagonal on calibration stone (inner square). Then press OK.");
	
		roiManager("Add");
		roiManager("select", 1)
		roiManager("rename", "Diagonal-2");
	
		print("\\Update:Draw diagonals...done");
	
		//rois will be saved under same name but with _cal-dia.zip
	
		print("Scale calibration...");
		//measuring the length of the diagonal(s) and averaging them
		roiManager("select", newArray(0,1));
		roiManager("measure");
		//print("nResults= " + nResults);
	
		//averaging the diagonals
		
		//initial length
		sumLengthDiagonal=0;
	
		//add all measurements
		for (j = 0; j < nResults; j++)
		{
			toAdd = getResult("Length", j);
			//print("toAdd " + toAdd);
			print ("Diagonal " + j+1 +": " + toAdd + "px");
			sumLengthDiagonal = sumLengthDiagonal + toAdd;
		}
		//aget average by dividing sum by number of results
		avgLengthDiagonal = sumLengthDiagonal / nResults;
		//print ("sum : " + sumLengthDiagonal);
		print ("avg : " + avgLengthDiagonal);
	
		//cleaning up the results table
	
		run("Clear Results");
	
		//calibration / scale of picture
		realSquareSideMM = 10; //the calibration stone is 10x10 mm
		realDiagonal = sqrt(2 * realSquareSideMM * realSquareSideMM); //its diagonal in real
	
		//calculating pixel width based on the measured distance
		pixel_width=realDiagonal/avgLengthDiagonal;
		pixel_height=pixel_width; //same in both x and y
		voxel_depth=pixel_width; //in z we dont really care, but pro forma
		
		//NOT via set scale, because that does not write it into image properties after saving. That is a setting of the current imageJ session
		run("Properties...", "channels=1 slices=1 frames=1 unit=mm pixel_width="+pixel_width+" pixel_height="+pixel_height+" voxel_depth="+voxel_depth);
		
		print("\\Update:Scale calibration...Done");
		print("Calculated pixel size is " +  pixel_width + " mm");
		//waitForUser("after calibration");
		
		//saving resulting scaled image in new folder (name as original, but "calibrated at the end)
		/*
		calImgSaveName = substring(imgList[i], 0, lengthOf(imgList[i])-4) + "_cal.jpg";
		saveAs("JPG", calFolderPath + File.separator + calImgSaveName);
		*/
		//I will not save the picture as calibrated one because it is acting funny. Seems not to be part of the image, rather part of the imageJ settings
	
	
		//step3: drawing aproximately the frond area.
		//later in this area, thresholding will be done and fronds counted
		setTool("polygon");
		print("Draw aproximate frond area...");
		waitForUser("Step 3: Roughly draw area containing leaves. Avoid calibration stone and cup contours.");
		
		roiManager("add");
		roiManager("select", 2);
		roiManager("rename", "Fronds-aprox");
	
		print("\\Update:Draw aproximate frond area...done");
	
		//waitForUser("after renaming");
		//clearing the outside
		setBackgroundColor(255, 255 , 255);
		run("Clear Outside");
	
		clearOutImgSaveName = substring(imgList[i], 0, lengthOf(imgList[i])-4) + "_clearOut.jpg";
		saveAs("JPG", clearOutFolderPath + File.separator + clearOutImgSaveName);
	
		print("Outside cleared and saved.");
	
		run("8-bit");
	
		print("Analyze frond area...");
				
		setThreshold(threMin, threMax);
		run("Convert to Mask");
		//this will make a black an white mask, on which we can analyze the particles, and save the outlines of the  mask by "create selection" to the ROI manager
	
		//run("Analyze Particles...", "size="+sizeEx+"-Infinity pixel show=Masks include");
		run("Analyze Particles...", "size="+sizeEx+"-Infinity pixel show=Masks");
	
		//converting the result into the selection
		run("Create Selection");
	
		roiManager("Add");
		roiManager("Select", 3);
		roiManager("rename", "Fronds-thresholded");
	
		//measuring Frond area
		roiManager("select", 3);
		roiManager("measure");
		area = getResult("Area", 0);
	
		print("\\Update:Analyze frond area...Done");
		print("Area = " + area + "  mm2");
		
		print("Analyze frond count...");
		//not sure if it would work like this here, we already once analyzed particles above
		run("Convert to Mask");
		//this will make a black an white mask, on which we can analyze the particles, and save the outlines of the  mask by "create selection" to the ROI manager

		if (isWatershed == true)
		{
			run("Watershed");
			//this is an algorythm which separates touching particles
		}
						
		//run("Analyze Particles...", "size="+sizeExCH1+"-Infinity pixel show=Masks");
		run("Analyze Particles...", "size="+sizeEx+"-Infinity pixel include add");
	
		//to count how many particles there are:
		//clear the measurement table
		run("Clear Results");
		//deselect all in the roi manager, that way measurement will be done on all
		roiManager("deselect");
		roiManager("measure");
		//count number of rows in measurement table = nResults
		count = nResults - 4; //there are 4 previous rois, so substract them
		run("Clear Results");
		
		print("\\Update:Analyze frond count...Done");
		print("Counted fronds: " + count);
		
		//renaming based on ID in the roi manager, for better searching
		for (j = 4; j < roiManager("count"); j++)
		{
			roiManager("select", j);
			roiManager("rename", "frond " + j-3);
		}
	
		//rois will be saved under same name but with _cal-dia.zip
		roiSaveName = substring(imgList[i], 0, lengthOf(imgList[i])-4) + ".zip";
		//print("saving under " + roiSaveName);
		//roiManager("select", newArray(0,1,2,3));
		roiManager("deselect"); //would again save everything, maybe not necessary because already deselected from before

		//change of color! Also for later viewing
		roiManager("Show All with labels");
		roiManager("Set Color", "red"); //red line best visible. Not sure how it is with drawing, if it stays yellow
		roiManager("Set Line Width", 1);
	
		roiManager("save", roiSaveFolder + File.separator + roiSaveName);
	
		//closing all and reopening the originalimage to make a flattened picture
		run("Close All");
		open(imgFolderPath + File.separator + imgList[i]);

		roiManager("Show All with labels");
		roiManager("Set Color", "red"); //red line best visible. Not sure how it is with drawing, if it stays yellow
		roiManager("Set Line Width", 1);

		//flattening the image for documentation (easier quick walk through)
		run("Flatten");
		flatImgSaveName = substring(imgList[i], 0, lengthOf(imgList[i])-4) + "_flat.jpg";
		saveAs("JPG", flatFolderPath + File.separator + flatImgSaveName);
		close(); //flat image will be closed right after
	
		//cleaning up the roi manager
		roiManager("deselect");
		roiManager("delete");
		
		run("Close All");
	
		//Patching together a row in the result table, appending to already existing result rows
		//resultLine = imgList[i] + "\t" + pixel_width + "\t" + area + "\t" + count;
		resultLine = imgList[i] + "\t" + pixel_width + "\t" + area;
		File.append(resultLine, resultFilePath);
		print("Frond area results saved.");
	}
	print("");
	return "Drawing and frond area measurement completed.";
}

 

function reAnalyseArea(analysisFolderPath)
{
	Dialog.create("Set threshold for frond identification");
	Dialog.addNumber("Min", 0);
	Dialog.addNumber("Min", 230);
	Dialog.addNumber("Size ex", 50);
	Dialog.addCheckbox("Watershed", true);
	Dialog.addMessage("Default: 0, 230, 50 + WS");
	Dialog.show();

	threMin = Dialog.getNumber();
	threMax = Dialog.getNumber();
	sizeEx = Dialog.getNumber();
	isWatershed = Dialog.getCheckbox();

	print("Settings for thresholding:");
	print("Min " + threMin);
	print("Max " + threMax);
	print("Size exclusion " + sizeEx + " px");
	
	clearOutFolderPath = analysisFolderPath + File.separator + "clearOut";
	if(File.exists(clearOutFolderPath)==0)
	//that is for a newly created project
	{
		File.makeDirectory(clearOutFolderPath);
		print("Created folder: " + clearOutFolderPath);
		print("");
	}
	
	flatFolderPath = analysisFolderPath + File.separator + "flat";
	if(File.exists(flatFolderPath)==0)
	{
		File.makeDirectory(flatFolderPath);
		print("Created folder: " + flatFolderPath);
	}
	
	print("");

	imgFolderPath = analysisFolderPath + File.separator + "img";
	
	//must be there because that is tehe first thing one makes when creating a project
	if(File.exists(imgFolderPath)==0)
	{
		exit("Can't find image folder: " + imgFolderPath + "\nscript will abort");	
	}
	roiSaveFolder = imgFolderPath; //saving rois of diagonals in the img folder
	
	//open roi manager + basic setings
	run("ROI Manager...");
	roiManager("Show All without labels");
	
	print("");




	
	//refreshing full list and fishing out the actual imgLIst to analyze
	//(in some cases somwhat doubled)
	imgFolderFullList = getFileList(imgFolderPath);
	imgList=newArray(0); //this will also reset old image lists
	
	//startIncluding = 0; //we will always reanalyze all images, therefore no worry abou where to start
	for(i = 0; i < imgFolderFullList.length; i++)
	{
		if (indexOf(imgFolderFullList[i], ".zip")==-1)
		{
			toAdd = newArray(1);
			toAdd[0] = imgFolderFullList[i];
			imgList = Array.concat(imgList, toAdd); //all folowing images will be added to the list for analysis
		}
	}


 	//defining result file path
	analysisFolderName = File.getName(analysisFolderPath);
	resultFileName = analysisFolderName + "-results-area.txt";
	resultFilePath = analysisFolderPath + File.separator + resultFileName;
	print("Result table will be stored in " + resultFilePath);
	
	//making a headder for the table

	// I think there will always be a result file. But still.
	if(File.exists(resultFilePath)!=1)
	{
		headder = "Image\tPixel_size[mm]\tFrond area[mm2]";
		File.append(headder, resultFilePath);
	}
	else 
	File.append("---New Section ---", resultFilePath);
	
	
	for (i = 0; i < imgList.length; i++) 
	{
		print("");
		print("Opening " + imgList[i]);
		open(imgFolderPath + File.separator + imgList[i]);
		imgTitle = getTitle();

		roiToLookFor = substring(imgList[i], 0 , indexOf(imgList[i], ".")) + ".zip";
		open(imgFolderPath + File.separator + roiToLookFor );

		//first we delete all before drawn / automatically segmented fronds
		print("Delete previous fronds...");
		toDelete = newArray(0);
		noRois = roiManager("count");

		for (j = 3; j < noRois; j++) 
		{
			toAdd = newArray(1);
			toAdd[0] = j;
			toDelete = Array.concat(toDelete,toAdd);
		}
	
		roiManager("select", toDelete);
		roiManager("delete");
		
		//only diagonals and aproximate area will remain
		//waitForUser;
		print("\\Update:Delete previous fronds...Done");

		//now based on what we already drawn
		print("Scale calibration...");
		//measuring the length of the diagonal(s) and averaging them
		roiManager("select", newArray(0,1));
		roiManager("measure");
		//print("nResults= " + nResults);
	
		//averaging the diagonals
		
		//initial length
		sumLengthDiagonal=0;
	
		//add all measurements
		for (j = 0; j < nResults; j++)
		{
			toAdd = getResult("Length", j);
			//print("toAdd " + toAdd);
			print ("Diagonal " + j+1 +": " + toAdd + "px");
			sumLengthDiagonal = sumLengthDiagonal + toAdd;
		}
		//aget average by dividing sum by number of results
		avgLengthDiagonal = sumLengthDiagonal / nResults;
		//print ("sum : " + sumLengthDiagonal);
		print ("avg : " + avgLengthDiagonal);
	
		//cleaning up the results table
	
		run("Clear Results");
	
		//calibration / scale of picture
		realSquareSideMM = 10; //the calibration stone is 10x10 mm
		realDiagonal = sqrt(2 * realSquareSideMM * realSquareSideMM); //its diagonal in real
	
		//calculating pixel width based on the measured distance
		pixel_width=realDiagonal/avgLengthDiagonal;
		pixel_height=pixel_width; //same in both x and y
		voxel_depth=pixel_width; //in z we dont really care, but pro forma
		
		//NOT via set scale, because that does not write it into image properties after saving. That is a setting of the current imageJ session
		run("Properties...", "channels=1 slices=1 frames=1 unit=mm pixel_width="+pixel_width+" pixel_height="+pixel_height+" voxel_depth="+voxel_depth);
		
		print("\\Update:Scale calibration...Done");
		print("Calculated pixel size is " +  pixel_width + " mm");
		//waitForUser("after calibration");
		
		//saving resulting scaled image in new folder (name as original, but "calibrated at the end)
		/*
		calImgSaveName = substring(imgList[i], 0, lengthOf(imgList[i])-4) + "_cal.jpg";
		saveAs("JPG", calFolderPath + File.separator + calImgSaveName);
		*/
		//I will not save the picture as calibrated one because it is acting funny. Seems not to be part of the image, rather part of the imageJ settings
	
		roiManager("select", 2); //is tha approximate area drawn before
	
		//waitForUser("after renaming");
		//clearing the outside
		setBackgroundColor(255, 255 , 255);
		run("Clear Outside");
	
		clearOutImgSaveName = substring(imgList[i], 0, lengthOf(imgList[i])-4) + "_clearOut.jpg";
		saveAs("JPG", clearOutFolderPath + File.separator + clearOutImgSaveName);
	
		print("Outside cleared and saved.");
	
		run("8-bit");
	
		print("Analyze frond area...");
				
		setThreshold(threMin, threMax);
		run("Convert to Mask");
		//this will make a black an white mask, on which we can analyze the particles, and save the outlines of the  mask by "create selection" to the ROI manager
	
		//run("Analyze Particles...", "size="+sizeEx+"-Infinity pixel show=Masks include");
		run("Analyze Particles...", "size="+sizeEx+"-Infinity pixel show=Masks");
	
		//converting the result into the selection
		run("Create Selection");
	
		roiManager("Add");
		roiManager("Select", 3);
		roiManager("rename", "Fronds-thresholded");
	
		//measuring Frond area
		roiManager("select", 3);
		roiManager("measure");
		area = getResult("Area", 0);
	
		print("\\Update:Analyze frond area...Done");
		print("Area = " + area + "  mm2");
		
		print("Analyze frond count...");
		//not sure if it would work like this here, we already once analyzed particles above
		run("Convert to Mask");
		//this will make a black an white mask, on which we can analyze the particles, and save the outlines of the  mask by "create selection" to the ROI manager

		if (isWatershed == true)
		{
			run("Watershed");
			//this is an algorythm which separates touching particles
		}
						
		//run("Analyze Particles...", "size="+sizeExCH1+"-Infinity pixel show=Masks");
		run("Analyze Particles...", "size="+sizeEx+"-Infinity pixel include add");
	
		//to count how many particles there are:
		//clear the measurement table
		run("Clear Results");
		//deselect all in the roi manager, that way measurement will be done on all
		roiManager("deselect");
		roiManager("measure");
		//count number of rows in measurement table = nResults
		count = nResults - 4; //there are 4 previous rois, so substract them
		run("Clear Results");
		
		print("\\Update:Analyze frond count...Done");
		print("Counted fronds: " + count);
		
		//renaming based on ID in the roi manager, for better searching
		for (j = 4; j < roiManager("count"); j++)
		{
			roiManager("select", j);
			roiManager("rename", "frond " + j-3);
		}
	
		//rois will be saved under same name but with _cal-dia.zip
		roiSaveName = substring(imgList[i], 0, lengthOf(imgList[i])-4) + ".zip";
		//print("saving under " + roiSaveName);
		//roiManager("select", newArray(0,1,2,3));
		roiManager("deselect"); //would again save everything, maybe not necessary because already deselected from before

		//change of color! Also for later viewing
		roiManager("Show All with labels");
		roiManager("Set Color", "red"); //red line best visible. Not sure how it is with drawing, if it stays yellow
		roiManager("Set Line Width", 1);
	
		roiManager("save", roiSaveFolder + File.separator + roiSaveName);
	
		//closing all and reopening the originalimage to make a flattened picture
		run("Close All");
		open(imgFolderPath + File.separator + imgList[i]);

		roiManager("Show All with labels");
		roiManager("Set Color", "red"); //red line best visible. Not sure how it is with drawing, if it stays yellow
		roiManager("Set Line Width", 1);

		//flattening the image for documentation (easier quick walk through)
		run("Flatten");
		flatImgSaveName = substring(imgList[i], 0, lengthOf(imgList[i])-4) + "_flat.jpg";
		saveAs("JPG", flatFolderPath + File.separator + flatImgSaveName);
		close(); //flat image will be closed right after
	
		//cleaning up the roi manager
		roiManager("deselect");
		roiManager("delete");
		
		run("Close All");
	
		//Patching together a row in the result table, appending to already existing result rows
		//resultLine = imgList[i] + "\t" + pixel_width + "\t" + area + "\t" + count;
		resultLine = imgList[i] + "\t" + pixel_width + "\t" + area;
		File.append(resultLine, resultFilePath);
		print("Frond area results saved.");
	}
	
	print("");
	return "Re-analyzed based on changed thresholding and segmentation parameters.";
}

function editFronds(analysisFolderPath)
{
	//result file - is there or not?
	analysisFolderName = File.getName(analysisFolderPath);
	resultFileName = analysisFolderName + "-results-frondNumber.txt";
	resultFilePath = analysisFolderPath + File.separator + resultFileName;

	headder = "Image\tFrond Number (automated segmentation)\tFrond number (edited)";

	if(File.exists(resultFilePath)==0)
	//if there is not yet a result file, there was also no header
	{
		File.append(headder, resultFilePath);
	}
	else
	{
		File.append("---New Section ---", resultFilePath);
		//t use as a divider to know, that it has been started several times
	}

	imgFolderPath = analysisFolderPath + File.separator + "img";
	imgFolderFullList = getFileList(imgFolderPath); 

	frondEditPath = analysisFolderPath + File.separator + "frondEdit";
	if(File.exists(frondEditPath)==1)
	//there already is a frondCount folder, that is analysis have already been started
	{
		frondEditList = getFileList(frondEditPath);
		if(frondEditList.length == 0)
		{
			startFromImg = imgFolderFullList[0];
		}
		else if (imgFolderFullList.length == 2*frondEditList.length)
		{
			exit("All fronds have been edited. Script will exit.");
		}
		else
		{
			startFromImg = imgFolderFullList[2*frondEditList.length];
			waitForUser("Editing will resume from " + startFromImg);
			print("Editing fronds will resume from " + startFromImg);
		}
		//either its empty and then starting from beginning
		//or it has edited zips inside ant then 
	}
	else
	//there's no frondCount folder yet and we will create it 
	{
		File.makeDirectory(frondEditPath);
		startFromImg = imgFolderFullList[0];
	}

	print("Images to analyze:");

	imgList = newArray(0);

	startIncluding=0;

	for(i = 0; i < imgFolderFullList.length; i++)
	{
		if (imgFolderFullList[i] == startFromImg)
		{
			startIncluding = 1; //flip switch
		}
		if ((startIncluding==1) && (indexOf(imgFolderFullList[i], ".zip")==-1))
		{
			toAdd = newArray(1);
			toAdd[0]= imgFolderFullList[i];
			imgList = Array.concat(imgList , toAdd);
		}
	}

	
	for (i = 0; i < imgList.length; i++)
	{
		print(imgList[i]);
	}
	print("Total " + imgList.length + " images.");	

	//waitForUser;

	for (i = 0; i < imgList.length; i++)
	{
		print("");
		print("Opening " + imgList[i]);
		open(imgFolderPath + File.separator + imgList[i]);
		imgTitle = getTitle();
		
		roiToLookFor = substring(imgList[i], 0, lengthOf(imgList[i])-4) + ".zip";
		print("Opening corresponding " + roiToLookFor);
		open(imgFolderPath + File.separator + roiToLookFor);

		nonFronds = newArray(0,1,2,3);
		roiManager("select", nonFronds);
		roiManager("delete");
		
		//waitForUser;
		originalCount = roiManager("count");
		print("Fronds counted by segmentation: " + originalCount);

		//renaming rois and adjusting the display options

		roiManager("show all with labels");
		setTool("oval");

		nextChoices = newArray("Yes. Recount fronds and show next image.", "No. Back to editing this image.");
		chosen=nextChoices[1];
		while (chosen != nextChoices[0]) //until we chose that we are done
		{
			waitForUser("Please edit fronds: Delete from the ROI Manager or add new by drawing and pressing the Add button.\n When you are done editing, press OK in this window.");
			nextChoices = newArray("Yes. Recount fronds and move to next image.", "No. Update ROI manager and go back to editing this image.");
			Dialog.create("Done editing?");
			Dialog.addRadioButtonGroup("", nextChoices, 2, 1, nextChoices[0]);
			Dialog.show();
			chosen = Dialog.getRadioButton();

			//refreshing the naming after each editing round
			totalRois = roiManager("count");
			
			for (k = 0; k<totalRois; k++)
			{
				roiManager("select", k);
				roiManager("rename", "frond " + k+1);
			}
			roiManager("show all with labels");
		}
		
		//re-counting the number of ROIS
		finalCount = roiManager("count");
		print("Fronds after editing: " + finalCount);

		//appending to the result file
		//saving the edited rois into the frondEdit folder (should be separated from teh area counts)
		
		print("Done editing. Next image.");
		//print("");

		//saving edited rois under somewhere
		roiSaveName = substring(roiToLookFor, 0, indexOf(roiToLookFor, ".zip")) + "-frondEdit.zip";
		roiSavePath = frondEditPath + File.separator + roiSaveName;

		//not sure if necessary
		roiManager("Show All with labels");
		roiManager("Set Color", "red"); //red line best visible. Not sure how it is with drawing, if it stays yellow
		roiManager("Set Line Width", 1);
	
		roiManager("save", roiSavePath);
		
		//cleaning the RoiManager
		roiManager("deselect");
		roiManager("delete");

		//close images
		run("Close All");


		//appending the counts to the table
		resultLine = imgList[i] + "\t" + originalCount + "\t" + finalCount;
		File.append(resultLine, resultFilePath);
		print("Results saved.");

		//for now not saving the edit. but this should come
	}
	
	return "Editing fronds completed.";
}



