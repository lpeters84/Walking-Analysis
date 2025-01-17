# Walking-Analysis
Position, angle, force, and moment analysis of a person walking

| Anatomical Positions | Head vs. C7 Angle |
:-:|:-:
 <img src="https://github.com/user-attachments/assets/45cbebf9-e5a8-4617-b7a8-39a3d86aeb1b" width="475"> |  <img src="https://github.com/user-attachments/assets/ba931fb0-d8cd-446a-bb97-0cf741030ef6" width="475">
 
| Ground Reaction Forces | Center of Pressure Map |
:-:|:-:
<img src="https://github.com/user-attachments/assets/f0f37601-2a97-4ddc-965a-344601ecb871" width="475"> | <img src="https://github.com/user-attachments/assets/8189102a-e626-44df-81a1-7b87c202c918" width="475">


# Data Description
walk.mat is a matlab struct containing data collected from a single trial where the subject walks over four force plates wearing motion capture markers. The relevant data within walk.mat are the "Trajectories" struct - containg all data collected by the 3D markers, and the "Analog" struct - containing all the force and moment data from the force plates. 

static.mat is a matlab struct containing data collected from a single trial where the subject stands normally on a force plate (FP4). The relevant data within static.mat are the "Trajectories" and "Analog" structs, containing the same information as the walk.mat structs. 

# Code Description
After loading both datasets, the z (vertical) coordinates of the data are extracted for the 5 markers placed on the head as well the the one placed on the C7 vertebrae. These are used to compare the height of the head center of mass and C7 center of mass while walking vs. standing. 

Then, the x (anterior/posterior) coordinates are extracted from the walking data. These are used in conjuction with the z coordinates to determine the angle between the head and the C7 while walking. The angular velocity is calculated and used to determine when the head is nodding forward. 

For the force and moment analyses, the force values are calibrated to convert raw voltage values into force values with a calibration matrix along with voltage excitation and gain values. These are used to plot the x, y, and z forces on each force plate, as well as the x, y, and z moments on one force plate (FP3). The vertical forces are also used to calculate the subject's mass

Finally, the forces and moments are used to create a map of the Centre of Pressure during one full step on a force plate (FP3)
