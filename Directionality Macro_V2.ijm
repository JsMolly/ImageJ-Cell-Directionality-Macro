
scripttitle= "VesselCellOrientation";
version= "0.2";
date= "31-04-2022";
description= "Description";

print("FIJI Macro: "+scripttitle);
print("Version: "+version+" Version Date: "+date);
getDateAndTime(year, month, week, day, hour, min, sec, msec);
print("Script Run Date: "+day+"/"+(month+1)+"/"+year+"  Time: " +hour+":"+min+":"+sec);
print("");

//Directory Location
path = getDirectory("Choose Source Directory ");
list = getFileList(path);
getDateAndTime(year, month, week, day, hour, min, sec, msec);

ext = ".tif";
Dialog.create("Settings");
Dialog.addString("File Extension: ", ext);
Dialog.addMessage("(For example .czi  .lsm  .nd2  .lif  .ims)");
Dialog.addNumber("Size of POI Radius", 50);
Dialog.show();
ext = Dialog.getString();
POIRadius = Dialog.getNumber();
start = getTime();

print("File Extension Selected = "+ext);
print("POI Radius Chosen = "+POIRadius);

//Creates Directory for output images/logs/results table
resultsDir = path+"_Results_"+"_"+year+"-"+month+"-"+day+"_at_"+hour+"."+min+"/"; 
File.makeDirectory(resultsDir);
print("Working Directory Location: "+path);
summaryFile = File.open(resultsDir+"Results_"+"_"+year+"-"+month+"-"+day+"_at_"+hour+"."+min+".csv");
print(summaryFile,"Image Name, Image Number, Number of POIs Found, POI ID, POI X-CoORD, POI Y-CoORD, Number of points found within POI (Count), Number of points found within POI (Int Dent), Maximum Count (POI), Maximum Integrated Density (POI)");


for (z=0; z<list.length; z++) {
if (endsWith(list[z],ext)){
		setBatchMode(false);
		run("Bio-Formats Importer", "open=["+path+list[z]+"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
		run("Clear Results");
		roiManager("reset");
		windowtitle = getTitle();
		windowtitlenoext = replace(windowtitle, ext, "");
		print("Opening File: "+(z+1)+" of "+list.length+"  Filename: "+windowtitle);
		run("Hide Overlay");

		roiManager("reset");
		roiManager("Open", path+windowtitlenoext+"RoiSet.zip");
              
		roiManager("deselect");
		roiManager("measure"); 
		getPixelSize(unit, pixelWidth, pixelHeight);
				       
		getDimensions(width, height, channels, slices, frames);
		newImage("tempStack", "8-bit black", width, height, nResults);
		run("Properties...", "channels=1 slices="+nResults+" frames=1 pixel_width="+pixelWidth+" pixel_height="+pixelHeight+" voxel_depth=1.0000000");      
				             
		desiredLength = width;
		setForegroundColor(255, 255, 255);
		setBackgroundColor(0, 0, 0);
       
       
		                       
		for (i = 0; i < roiManager("count"); i++) {         
		    selectWindow("tempStack");
			setSlice(i+1);
		       
			x1 = getResult('FeretX', i);
			y1 = getResult('FeretY', i);
			Fangle = getResult("FeretAngle",i);
			Flength = getResult("Feret", i);
		//	print(Fangle);
			
			
			if(Fangle<90){
				lineAngle = (Fangle*(PI/180));
			//	print(lineAngle);
				x2= x1 + desiredLength * (cos(lineAngle));
				y2= y1 - desiredLength * (sin(lineAngle));
				drawLine(x1, y1, x2, y2);
			}
			
			if(Fangle>90){
				lineAngle = (180-Fangle)*(PI/180);
			//	print(lineAngle);
				x2= x1 + desiredLength * (cos(lineAngle));
				y2= y1 + desiredLength * (sin(lineAngle));
				drawLine(x1, y1, x2, y2);
			}
		}
		
		run("Subtract...", "value=254 stack");
		run("Z Project...", "projection=[Sum Slices]");
		rename("POIs");
		setAutoThreshold("Default dark");
		//run("Threshold...");
		setOption("BlackBackground", false);
		run("Convert to Mask");
		run("Find Maxima...", "prominence=1 strict light output=List");
		
		nPOI = nResults;
		xPOI = newArray(nResults);  
		yPOI = newArray(nResults);
		count = newArray(nResults);
		sumIntDent = newArray(nResults);
		for (k = 0; k < nResults(); k++) {
		    xPOI[k] = getResult('X', k);
		    yPOI[k] = getResult('Y', k);
		}
		
		POIsize = 50;
		POIoffset = POIsize/2;
		maxCount = 0;
		maxCountPOI = 0;
		maxIntDent = 0;
		maxIntDentPOI = 0;
		print("Current Max Count = "+maxCount+" @ POI: "+maxCountPOI+" Current Max Integrated Density = "+maxIntDent+" @ POI "+maxIntDentPOI);
		setBatchMode(true);
		
		for (j = 0; j<nPOI;j++){
			makeEllipse(xPOI[j]-POIoffset, yPOI[j]-POIoffset, xPOI[j]+POIoffset, yPOI[j]+POIoffset, 1);
			run("Clear Results");
			run("Measure");
			
			sumIntDent[j] = getResult("RawIntDen", 0) /255;
			run("Clear Results");
			//roiManager("add");
			run("Find Maxima...", "prominence=1 light output=Count");
			count[j]=getResult("Count",0);
			if(count[j]>maxCount){
				maxCount = count[j];
				maxCountPOI = (j+1);
				//print("\\Update[n-1]:New Max Count found = "+maxCount);
			}
				if(sumIntDent[j]>maxIntDent){
				maxIntDent = sumIntDent[j];
				maxIntDentPOI = (j+1);
				//print("New Max Integrated Density found = "+maxIntDent);
			}
			print("\\Update:"+"Current Max Count = "+maxCount+" Current Max Integrated Density = "+maxIntDent);
			
			
			run("Clear Results");
		}
		for (k = 0; k<nPOI;k++){
			print(summaryFile, windowtitle+","+(z+1)+","+nPOI+","+(k+1)+","+xPOI[k]+","+yPOI[k]+","+count[k]+","+sumIntDent[k]+","+maxCount+"("+maxCountPOI+")"+","+maxIntDent+"("+maxIntDentPOI+")");
		}
		



       





		selectWindow("POIs");
		saveAs("Tiff", resultsDir+ windowtitlenoext+"POI_output.tif");
		while(nImages>0){close();}
	}
}
		selectWindow("Log");
		saveAs("Text", resultsDir+"Log.txt");
//exit message to notify user that the script has finished.
title = "Batch Completed";
waitForUser(title);
