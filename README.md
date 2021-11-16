# Internship-at-the-Bern-University-of-Applied-Sciences
Internship where I had to code in MATLAB to incorporate a data pipeline into the Health Department repository at the University. The purpose was to automate the conversion of the output default data from the Zebris Pressure Distribution Treadmill (.xml) into NifTi data format (.nii).

This part of the project was carried out together with my internship supervisor Dr. Patric Eichelberger. The whole project aims to implement an AI algorithm that is capable of identifying gait disorders from pressure data obtained from the treadmill.

The conversion from .xml to .nii data format happens in the zebrisData.m file. A main loop is created to go through each "event" (steps) of the participant, with a nested loop that loops through the "quants" (time frames) of the step rollover in the .xml file. After extracting the current "quant" to one variable called "quantdata", this will be stored in the "stepdata" variable chronologically adding a third dimension (time) to the two dimensional "quantdata". When both loops finish, a volumetric data file will be written for each of the "events" or steps of that participant that can be converted to NifTi data format.

The StepData.m file is a container for working with the already processed 3D zebris plantar pressure data in zebrisData.m. The niftiwrite MATLAB function allows the conversion of the volumetric data into NifTi data files, more convenient for the long-term AI implementation purposes.
