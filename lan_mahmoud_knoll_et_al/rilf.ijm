//select win wait for user

waitForUser("Please OPEN one typical RGB image from the INPUT directory (the folder should contain only images). When you finish click OK.");
path = getInfo("image.directory")+File.separator+getInfo("image.filename");	
dir = getInfo("image.directory");
list = getFileList(dir);
run("Options...", "iterations=1 count=1 black");
setOption("BlackBackground", true);

folder = getDirectory("Please choose an OUTPUT Directory");
Dialog.create("Please define parameters...");
Dialog.addMessage("SEGMENTATION:");
Dialog.addCheckbox("Specify an area on the image?", false);
Dialog.addNumber("Use Median filter - Radius:", 2, 0, 0, "pxl");
Dialog.addMessage("(suggestion: use 1 for 10x, 2 for 20x...)");
Dialog.addMessage(" ");

Dialog.addMessage("ANALYSIS:");
Dialog.addString("Alveoli area (pxl^2):", "200-Infinity");
Dialog.addCheckbox("Analyze all images in one folder?", false);
Dialog.addCheckbox("Specify optimal threshold for tissue density for each image separately?", false);
Dialog.addCheckbox("Specify optimal threshold for AFOG staining for each image separately?", false);
Dialog.addMessage(" ");

Dialog.addCheckbox("Scale the image? Measure area in mm^2?", true);
Dialog.addNumber("Set the scale; 1 mm is :", 2193, 0, 4, "pxl");  
Dialog.addMessage(" ");

Dialog.addMessage("DISPLAY:");
Dialog.addCheckbox("Display results in pseudocolor?", true);    
Dialog.show();

selectArea = Dialog.getCheckbox();
filterMedian = Dialog.getNumber();
minAirspace = Dialog.getString();
AnalyzeAll = Dialog.getCheckbox();
getThrForEach = Dialog.getCheckbox();  
getAFOGThrForEach = Dialog.getCheckbox();  
scaleImage = Dialog.getCheckbox();
scaleMM = Dialog.getNumber();
displayResults = Dialog.getCheckbox();  



//..................................................................Analyze one image...........................................................................................
if (scaleImage ==true) run("Set Scale...", "distance="+scaleMM+" known=1 pixel=1 unit=mm global");
else run("Set Scale...", "distance=1 known=1 pixel=1 unit=[] global");
print("\\Clear");
titleOri=getTitle();
image=folder+titleOri;
run("Select None");
run("Clear Results");
roiManager("Reset");
setTool("freehand");
if (selectArea ==true) waitForUser("Please select the area.");
else run("Select All");
type = selectionType();
if (type==-1) waitForUser("You have selected the option to specify an area on the image", "Please select an area on the image or press Ctrl+A on the keyboard. When you select click OK.");
roiManager("Add");
roiManager("Select", 0);
roiManager("Rename", "Total_Area.zip");
run("Select None");
roiManager("Deselect");
run("Duplicate...", "title=[]");
run("Set Measurements...", "area feret's limit redirect=None decimal=3");

//Measure total analyzed area 
//title=getTitle();
run("8-bit");
run("Median...", "radius="+filterMedian);
if (scaleImage ==true) rename(titleOri+ "    total analyzed area (use Total Area measurement in mm^2, ignore the rest)");
else rename(titleOri+ "    total analyzed area (use Total Area measurement in pxl^2, ignore the rest)");
setAutoThreshold("Default");
run("Threshold...");
setThreshold(0, 254);
roiManager("Select", 0);
run("Line Width...", "line=3");
setForegroundColor(255, 255, 255);
run("Draw");
run("Select None");
roiManager("Deselect");
if (AnalyzeAll ==false) run("Analyze Particles...", "size=0-Infinity exclude summarize");

//Measure Tissue density
if (scaleImage ==true) rename("    tissue density (use Total Area in mm^2 or %Area measurement)");
else rename("    tissue density (use Total Area in pxl^2 or %Area measurement)");
setAutoThreshold("Default");


run("Threshold...");
setThreshold(0, 165);
titleTemp=getTitle();
waitForUser("Please check the maximum threshold to measure tissue density.");
selectWindow(titleTemp);

getThreshold(min, max);
roiManager("Select", 0);
setBackgroundColor(255, 255, 255);
run("Clear Outside");
run("Create Selection");
roiManager("Add");
roiManager("Select", 1);
roiManager("Rename", "Tissue-Alveoli.zip");
roiManager("Deselect");
roiManager("Save", image+" Area-Tissue-AFOG Selection.zip");
roiManager("Select", 0);
if (AnalyzeAll ==false) run("Analyze Particles...", "size=0-Infinity summarize");

//Measure Alveoli density
if (scaleImage ==true) rename("    Alveoli density (use Count, Total Area in mm^2, %Area, or Feret measurement in mm)");
else rename("    Alveoli density (use Count, Total Area in pxl^2, %Area, or Feret measurement in pxl)");
setThreshold(max, 255);
roiManager("Select", 0);
setForegroundColor(0, 0, 0);
run("Line Width...", "line=3");
run("Draw");
roiManager("Select", 0);
roiManager("Reset");
if (AnalyzeAll ==false) run("Analyze Particles...", "size="+minAirspace+" pixel summarize add");
else run("Analyze Particles...", "size="+minAirspace+" pixel add");
roiManager("Save", image+" Alveoli selection.zip");
roiManager("Reset");
roiManager("Open", image+" Area-Tissue-AFOG Selection.zip");
close();

//Measure AFOG staining
run("Colour Deconvolution", "vectors=[Masson Trichrome]");//
selectWindow(titleOri+"-(Colour_3)");
close();
selectWindow(titleOri+"-(Colour_2)");
close();
selectWindow("Colour Deconvolution");
close();
selectWindow(titleOri+"-(Colour_1)");

run("Median...", "radius="+filterMedian/2);
setAutoThreshold("Default");
run("Threshold...");
setThreshold(0, 150);
titleTemp2=getTitle();
waitForUser("Please check the threshold for AFOG staining");
selectWindow(titleTemp2);
getThreshold(minAFOG, maxAFOG);
selectWindow(titleOri+"-(Colour_1)");
if (scaleImage ==true) rename("    AFOG staining (use Total Area in mm^2 or %Area)");
else rename("    AFOG staining (use Total Area in pxl^2 or %Area)");
roiManager("Select", 0);
run("Clear Outside");
run("Create Selection");
roiManager("Add");
roiManager("Select", 2);
roiManager("Rename", " AFOG staining.zip");
roiManager("Deselect");
roiManager("Save", image+" Area-Tissue-AFOG Selection.zip");
roiManager("Select", 0);
if (AnalyzeAll ==false) run("Analyze Particles...", "size=0-Infinity summarize");
close();

//Display
if (displayResults ==false) {
    selectWindow(titleOri);
    roiManager("Show All");
    roiManager("Select", 1);
    waitForUser("Please check results and the ROI Manager selection");
}

if (displayResults ==true) {

    roiManager("Deselect");
    run("Line Width...", "line=3");
    run("Select None");

    //Display Tissue Dens.
    run("Duplicate...", " ");
    roiManager("Select", 0);
    setForegroundColor(255, 0, 255);
    run("Draw");
    roiManager("Select", 1);
    setForegroundColor(0, 0, 0);
    run("Fill", "slice");
    run("Select None");
    rename("Tissue Density (black)");

    //Display Alveoli Dens.
    selectWindow(titleOri);
    roiManager("Select", 0);
    setForegroundColor(255, 0, 255);
    run("Draw");
    roiManager("Reset");	
    roiManager("Open", image+" Alveoli selection.zip");
    setForegroundColor(255, 0, 0);
    roiManager("Show All");
    run("Flatten");
    rename("Alveoli selection (yellow)");
    roiManager("Reset");
    roiManager("Open", image+" Area-Tissue-AFOG Selection.zip");

    //Display AFOG		
    selectWindow(titleOri);
    run("Duplicate...", " ");
    title=getTitle();
    selectWindow(title);
    roiManager("Select", 0);
    setForegroundColor(255, 0, 255);
    run("Draw");
    roiManager("Select", 2);
    setForegroundColor(0, 0, 255);
    run("Fill", "slice");
    wait(200);
    run("Select None");
    rename("AFOG staining (blue)");
    selectWindow(titleOri);
    if (selectArea==true) rename("Original image with analyzed area (magenta)");
    else rename("Original image");
    run("Images to Stack", "name=Stack title=[] use");
    run("Make Montage...", "columns=2 rows=2 scale=1 first=1 last=4 increment=1 border=2 font=55 label");
}

//note - pix. and how to recalculate




//..................................................................Analyze all images in one folder...........................................................................................

if (AnalyzeAll ==true)
{

    for (NoImages=0; NoImages<list.length; NoImages++) {
	run("Close All");
	showProgress(NoImages, list.length);
	open(dir+list[NoImages]);
	titleOri=getTitle();
	image=folder+titleOri;
	run("Select None");
	run("Clear Results");
	roiManager("Reset");
	setTool("freehand");
	if (selectArea ==true) waitForUser("Please select the area.");
	else run("Select All");
	type = selectionType();
	if (type==-1) waitForUser("You have selected the option to specify an area on the image", "Please select an area on the image or press Ctrl+A on the keyboard. When you select click OK.");
	roiManager("Add");
	roiManager("Select", 0);
	roiManager("Rename", "Total_Area.zip");
	run("Select None");
	roiManager("Deselect");
	run("Duplicate...", "title=[]");


	//Measure total analyzed area 
	title=getTitle();
	run("8-bit");
	run("Median...", "radius="+filterMedian);
	if (scaleImage ==true) rename(titleOri+ "    total analyzed area (use Total Area measurement in mm^2, ignore the rest)");
	else rename(titleOri+ "    total analyzed area (use Total Area measurement in pxl^2, ignore the rest)");
	setAutoThreshold("Default");
	run("Threshold...");
	setThreshold(0, 254);
	roiManager("Select", 0);
	run("Line Width...", "line=3");
	setForegroundColor(255, 255, 255);
	run("Draw");
	run("Select None");
	roiManager("Deselect");
	run("Analyze Particles...", "size=0-Infinity exclude summarize");

	//Measure Tissue density
	if (scaleImage ==true) rename("    tissue density (use Total Area in mm^2 or %Area measurement)");
	else  rename("    tissue density (use Total Area in pxl^2 or %Area measurement)");
	setAutoThreshold("Default");

	if (getThrForEach==false) {
	    run("Threshold...");
	    setThreshold(min, max);
	}
	else
	{
	    titleTemp=getTitle();
	    setThreshold(min, max);
	    waitForUser("Please check the maximum threshold to measure tissue density.");
	    selectWindow(titleTemp);	
	}
	roiManager("Select", 0);
	run("Clear Outside");
	run("Create Selection");
	roiManager("Add");
	roiManager("Select", 1);
	roiManager("Rename", "Tissue-Alveoli.zip");
	roiManager("Deselect");
	roiManager("Save", image+" Area-Tissue-AFOG Selection.zip");
	roiManager("Select", 0);
	run("Analyze Particles...", "size=0-Infinity summarize");

	//Measure Alveoli density
	if (scaleImage ==true) rename("    Alveoli density (use Count, %Area, or Feret measurement in mm)");
	else rename("    Alveoli density (use Count, %Area, or Feret measurement in mm)");
	setThreshold(max, 255);
	roiManager("Select", 0);
	setForegroundColor(0, 0, 0);
	run("Line Width...", "line=3");
	run("Draw");
	roiManager("Select", 0);
	roiManager("Reset");
	run("Analyze Particles...", "size="+minAirspace+" pixel summarize add");
	roiManager("Save", image+" Alveoli selection.zip");
	roiManager("Reset");
	roiManager("Open", image+" Area-Tissue-AFOG Selection.zip");
	close();

	//Measure AFOG staining
	run("Colour Deconvolution", "vectors=[Masson Trichrome]");//
	selectWindow(titleOri+"-(Colour_3)");
	close();
	selectWindow(titleOri+"-(Colour_2)");
	close();
	selectWindow("Colour Deconvolution");
	close();
	selectWindow(titleOri+"-(Colour_1)");

	run("Median...", "radius="+filterMedian/2);
	setAutoThreshold("Default");
	run("Threshold...");

	if (getAFOGThrForEach==false) {
	    run("Threshold...");
	    setThreshold(minAFOG, maxAFOG);
	}
	else
	{
	    titleTemp=getTitle();
	    setThreshold(minAFOG, maxAFOG);
	    waitForUser("Please check the maximum threshold to measure AFOG staining.");
	    selectWindow(titleTemp);	
	}

	selectWindow(titleOri+"-(Colour_1)");
	if (scaleImage ==true) rename("    AFOG staining (use Total Area in mm^2 or %Area)");
	else rename("    AFOG staining (use Total Area in pxl^2 or %Area)");
	roiManager("Select", 0);
	run("Clear Outside");
	run("Create Selection");
	roiManager("Add");
	roiManager("Select", 2);
	roiManager("Rename", " AFOG staining.zip");
	roiManager("Deselect");
	roiManager("Save", image+" Area-Tissue-AFOG Selection.zip");
	roiManager("Select", 0);
	run("Analyze Particles...", "size=0-Infinity summarize");
	close();

	//Display
	if (displayResults ==false) {
	    selectWindow(titleOri);
	    roiManager("Show All");
	    roiManager("Select", 1);
	}

	if (displayResults ==true) {

	    roiManager("Deselect");
	    run("Line Width...", "line=3");
	    run("Select None");

	    //Display Tissue Dens.
	    run("Duplicate...", " ");
	    roiManager("Select", 0);
	    setForegroundColor(255, 0, 255);
	    run("Draw");
	    roiManager("Select", 1);
	    setForegroundColor(0, 0, 0);
	    run("Fill", "slice");
	    run("Select None");
	    rename("Tissue Density (black)");

	    //Display Alveoli Dens.
	    selectWindow(titleOri);
	    roiManager("Select", 0);
	    setForegroundColor(255, 0, 255);
	    run("Draw");
	    roiManager("Reset");	
	    roiManager("Open", image+" Alveoli selection.zip");
	    setForegroundColor(255, 0, 0);
	    roiManager("Show All");
	    run("Flatten");
	    rename("Alveoli selection (yellow)");
	    roiManager("Reset");
	    roiManager("Open", image+" Area-Tissue-AFOG Selection.zip");

	    //Display AFOG		
	    selectWindow(titleOri);
	    run("Duplicate...", " ");
	    title=getTitle();
	    selectWindow(title);
	    roiManager("Select", 0);
	    setForegroundColor(255, 0, 255);
	    run("Draw");
	    roiManager("Select", 2);
	    setForegroundColor(0, 0, 255);
	    run("Fill", "slice");
	    wait(200);
	    run("Select None");
	    rename("AFOG staining (blue)");
	    selectWindow(titleOri);
	    if (selectArea==true) rename("Original image with analyzed area (magenta)");
	    else rename("Original image");
	    run("Images to Stack", "name=Stack title=[] use");
	    run("Make Montage...", "columns=2 rows=2 scale=1 first=1 last=4 increment=1 border=2 font=55 label");
	    saveAs("Tiff", image+" Mask.tif");
	}

    }


}

selectWindow("Summary");
saveAs("Results", folder+"Summary of Results.xls");

//________________________________________________________Report______________________________________________________________________________________________________________________________________________________________________________________
//_______________________________________________________________________________________________________________________________________________________________________________________________________________________________________________

if (selectArea==true) print("The area was selected on each image and the analysis was performed only within each selection.");
print("Images were tranformed to 8-bit and filtered using the Median Filter with the radius set to "+filterMedian+".");
if (getThrForEach==false) print("Threshold used to analyze tissue density was set to "+min+" and "+max+".");
else print("Optimal threshold to analyze tissue density was defined for each image separately.");
print("Threshold used to analyze alveoli was set to "+max+" and 255.");
print("The range of alveoli area was set to "+minAirspace+" pxl^2.");
if (getAFOGThrForEach==false) print("To analyze blue AFOG staining images were color deconvolved, median filtered (radius="+filterMedian/2+") and threshold was set to "+minAFOG+" and "+maxAFOG+".");
else print("To analyze blue AFOG staining images were color deconvolved, median filtered (radius="+filterMedian/2+") and optimal threshold was defined for each image separately.");
if (scaleImage ==true) print("Images were scaled ("+scaleMM+" pxl / mm) and areas were measured in mm^2.");
else print("Images were not scaled, thus areas were measured in pxl^2.");
if (AnalyzeAll==true ) print("All the images in the folder were analyzed with the same settings, using the same threshold.");	
if (displayResults==true) print("Images were displayed as a montage with the selecton of the analysed area (magenta), selection of tissue density (black), alveoli (yellow) and AFOG (blue)." ); 
print("____________________________________________________________________________________________________________________________________________________________________________________________________"); 														
print("This macro was developed in Light Microscopy Facility, DKFZ, Heidelberg, Germany.");
print("The licence is the 'GNU General Public License' http://www.gnu.org/licenses/gpl.html - in short - you are free to use, share or modify - we do not provide any warranty.");
print("");    
print("If you use this macro for your publication please acknowledge us." );
print("");  
print("Best regards," );
print("Damir Krunic, Dr." );		

