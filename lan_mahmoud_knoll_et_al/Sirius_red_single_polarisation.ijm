waitForUser("Dear Mahmoud, please open the polarisation image and click OK");
title= getTitle();
run("Duplicate...", "title=dupl duplicate");
run("Split Channels");
close();
close();
run("Grays");
roiManager("Reset");
run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");

//positive area
run("Threshold...");
setAutoThreshold("Default dark");
getThreshold(min, max);
setThreshold(500, max);
titleTemp= getTitle();
waitForUser("Please check the threshold for Polarisation area");
selectWindow(titleTemp);
run("Set Measurements...", "area limit display redirect=None decimal=6");
rename(title+" Polarisation area");
run("Analyze Particles...", "size=1-Infinity pixel summarize add");
close();

//total area
waitForUser("Dear Mahmoud, please open the normal transmitted light image and click OK");
title= getTitle();
selectWindow(title);
call("ij.ImagePlus.setDefault16bitRange", 12);
setSlice(1);
resetMinAndMax();
setSlice(2);
resetMinAndMax();
setSlice(3);
resetMinAndMax();
run("RGB Color");
run("8-bit");
run("Invert");
run("Subtract Background...", "rolling=400");
run("Gaussian Blur...", "sigma=10");
run("Threshold...");
setAutoThreshold("Default dark");
setThreshold(28, 255);
rename(title+" Total area");
waitForUser("Please check the threshold for Total area");
run("Analyze Particles...", "size=1-Infinity pixel summarize");

//display
run("Create Selection");
roiManager("Add");
close();
roiManager("Show All");


