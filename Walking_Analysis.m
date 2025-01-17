%% Walking_Analysis
% Author: Lauryn Peters
% Date: April 05, 2024

% Purpose: To analyze position of a 1800 mm tall subject walking normally from 18
% markers placed on the head, spine, and feet. Secondly, to analyze the
% ground reaction forces during same trial. 

close all; clc; clear 

%% Load walking and static datasets

load('walk.mat');
load('static.mat');

%% Walking and Static Positions

time = (1:walk_0001.Frames)';
maxSize_walk = size(walk_0001.Trajectories.Labeled.Data,3);
maxSize_static = size(static.Trajectories.Labeled.Data,3);

% turn 3D array into 2D matrices 
% places all z data into columns by marker (5 head markers total)
vertical_COM_head = zeros(480,5); % preallocate zeros to define size of array
for i = 1:5
    vertical_COM_head(:,i) = reshape(walk_0001.Trajectories.Labeled.Data(i,3,:),[],1);
end

static_COM_head = zeros(725,1); % preallocate zeros to define size of vector
for i = 1:5
    static_COM_head(:,i) = reshape(static.Trajectories.Labeled.Data(i,3,:), [], 1);
end

avg_vert_COM_head = mean(vertical_COM_head, 2); % calculate average walking head COM
avg_static_COM_head = mean(static_COM_head, 2); % calculates average static head COM
avg_static_COM_head_trunc = avg_static_COM_head(1:maxSize_walk); % truncates average static head COM to align plots

% turn 3D array into vector
vertical_COM_c7 = reshape(walk_0001.Trajectories.Labeled.Data(6,3,:), [], 1); % isolate walking C7 COM
static_COM_c7 = reshape(static.Trajectories.Labeled.Data(6,3,1:maxSize_static), [], 1); % isolate static C7 COM
static_COM_c7_trunc = static_COM_c7(1:maxSize_walk); % truncates static C7 COM to align plots

% plot head and C7 movements
figure()
plot(avg_vert_COM_head)
xlabel('Frames')
ylabel('Height (mm)')
title('Walking and Static Positions')
hold on 
plot(avg_static_COM_head_trunc)
plot(vertical_COM_c7)
plot(static_COM_c7_trunc)
hold off

legend ('Walking Head COM', 'Static Head COM','Walking C7 COM', 'Static C7 COM', Location='east')

%% Calculating Forward Angle Between C7 and Head
% Note: assuming the y data is anterior/posterior

% create horizontal and vertical vectors 
horiz_head = reshape(walk_0001.Trajectories.Labeled.Data(2,1,:),[],1);
horiz_c7 = reshape(walk_0001.Trajectories.Labeled.Data(6,1,:), [], 1);

%vert_vec = vertical_COM_head(:,2) - vertical_COM_c7;
vert_vec = avg_vert_COM_head - vertical_COM_c7;
horiz_vec = horiz_head - horiz_c7;

% calcualte angle 
angle = atand(horiz_vec./vert_vec);

% calculate derivative to find where angle is increasing
dydx = gradient(angle(:)) ./ gradient(time(:));
pos_idx = find(dydx > 0);

% initialize empty array to contain continuous values of increasing angle
pos_idx_cont = [];

j = 1; % row tracker
k = 1; % column tracker

% edge case for first element, see main loop for details
if (pos_idx(2) == pos_idx(1)+1)
    pos_idx_cont(j,k) = pos_idx(1);
    j = j+1;
else 
    k = k-1; % reduce k to 0 if first element isn't used
    j = j+1;
end

% loop throgh pos_idx, except the first and last elements
for i = 2:length(pos_idx)-1
    % if the value is in the middle or at the end of a continuous string of
    % values, copy it to "pos_idx_cont" array and increase row value
    if (pos_idx(i-1) == pos_idx(i)-1) || ((pos_idx(i-1) == pos_idx(i)-1) && (pos_idx(i+1) == pos_idx(i)+1))
        pos_idx_cont(j,k) = pos_idx(i);
    % if the value is at the start of a continuous string of values, 
    % increase column value and copy it to "pos_idx_cont" array
    elseif (pos_idx(i+1) == pos_idx(i)+1)
        k = k+1;
        pos_idx_cont(j,k) = pos_idx(i);
    end 
    j = j+1; % always increase row value at the end of loop
end

% edge case for last element
if(pos_idx(end-1) == pos_idx(end)-1)
    pos_idx_cont(j,k) = pos_idx(end);
end

% plot changes in angle/angular velocity
figure()
subplot(2,1,1); 
plot(time, angle) % plot angle between head and C7
xlabel('Frames')
ylabel(['Angle (' char(176) ')'])
title('Forward Walking Angle')
hold on

% plot time periods when head is nodding forward
for m = 1:size(pos_idx_cont,2)
    temp_idx = pos_idx_cont(:,m) ~= 0;
    plot(time(pos_idx(temp_idx)), angle(pos_idx(temp_idx)), 'r')
end

legend('Head/C7 Angle', 'Head Nodding', 'Location', 'southeast', 'FontSize', 7)


subplot(2,1,2); % plot angular velocity
plot(time, dydx);
hold on
plot(time, zeros(length(dydx)))
title('Forward Walking Angular Velocity');
xlabel('Frames');
ylabel(['Angular Velocity (' char(176) '/s)']);

%% Ground Reaction Force Analysis 

% determine forces from each force plate 
fs = 1000; % sampling frequency of the force plate
time_analog = 0:1/fs:(length(walk_0001.Analog.Data)-1)/1000;

% calibration matrix, from force plate manual
Cal = [0.6485, 0.6521, 2.5563, 12.9919, 13.1118, 6.0207; 
    0.6497, 0.6495, 2.5486, 13.0447, 13.0377, 6.01;
    0.6525, 0.6544, 2.5651, 13.1717, 13.1335, 6.1528;
    0.6468, 0.6482, 2.547, 13.0682, 13.0502, 5.9438];

% other variables from force plate manual
excitation = 2.0000e-06;
gain = 2000;

% labels for struct 
orderplate = {'ForceP1', 'ForceP2', 'ForceP3', 'ForceP4'};
order = {'Fx', 'Fy', 'Fz','Mx','My','Mz'};

% split and calibrate data. Add into walk_0001 struct as struct called 
% "Cal" for each force plate
count = 1;
for p = 1:numel(orderplate)
    for q = 1:numel(order)
        % convert voltage (electrical data) into Newtons (force data) using calibration matrix 
        walk_0001.Cal.(char(orderplate(p)))(:,q) = walk_0001.Analog.Data(count, :)*Cal(p,q)./(excitation*gain);
        count = count + 1;
    end
end 

% plot GRFs on all four force plates
figure()
suba = subplot(2,2,1);
plot(time_analog, walk_0001.Cal.ForceP1(:,1))
title('FP1')
xlabel('Time (s)')
ylabel('Force (N)')
hold on
plot(time_analog, walk_0001.Cal.ForceP1(:,2))
plot(time_analog, walk_0001.Cal.ForceP1(:,3))

subb = subplot(2,2,2);
plot(time_analog, walk_0001.Cal.ForceP2(:,1))
title('FP2')
xlabel('Time (s)')
ylabel('Force (N)')
hold on
plot(time_analog, walk_0001.Cal.ForceP2(:,2))
plot(time_analog, walk_0001.Cal.ForceP2(:,3))

subc = subplot(2,2,3);
plot(time_analog, walk_0001.Cal.ForceP3(:,1))
title('FP3')
xlabel('Time (s)')
ylabel('Force (N)')
hold on
plot(time_analog, walk_0001.Cal.ForceP3(:,2))
plot(time_analog, walk_0001.Cal.ForceP3(:,3))

subd = subplot(2,2,4);
plot(time_analog, walk_0001.Cal.ForceP4(:,1))
title('FP4')
xlabel('Time (s)')
ylabel('Force (N)')
hold on
plot(time_analog, walk_0001.Cal.ForceP4(:,2))
plot(time_analog, walk_0001.Cal.ForceP4(:,3))

linkaxes([suba,subb,subc,subd], 'y')

%% Plot Single Step on Each Force Plate

% plot forces from Force Plate 3
figure()
plot(time_analog, walk_0001.Cal.ForceP3(:,1)) 
xlabel('Time (s)')
ylabel('Force (N)')
title('Ground Reaction Forces on Force Plate 3')
hold on 
plot(time_analog, walk_0001.Cal.ForceP3(:,2))
plot(time_analog, walk_0001.Cal.ForceP3(:,3))
legend ('Fx', 'Fy', 'Fz')

% plot moments from Force Plate 3
figure()
plot(time_analog, walk_0001.Cal.ForceP3(:,4))
xlabel('Time (s)')
ylabel('Moments (Nm)')
title('Moments on Force Plate 3')
hold on
plot(time_analog, walk_0001.Cal.ForceP3(:,5))
plot(time_analog, walk_0001.Cal.ForceP3(:,6))
legend('Mx', 'My', 'Mz')


%% Plot Static Force Plate Data

static_time_analog = 0:1/fs:(length(static.Analog.Data)-1)/1000;

% labels for struct 
static_orderplate = {'sForceP1', 'sForceP2', 'sForceP3', 'sForceP4'};
static_order = {'sFx', 'sFy', 'sFz','sMx','sMy','sMz'};

% split and calibrate data. Add into walk_0001 struct as struct called 
% "Cal" for each force plate
static_count = 1;
for r = 1:numel(static_orderplate)
    for s = 1:numel(static_order)
        % convert voltage (electrical data) into Newtons (force data) using calibration matrix 
        static.Cal.(char(static_orderplate(r)))(:,s) = static.Analog.Data(static_count, :)*Cal(r,s)./(excitation*gain);
        static_count = static_count + 1;
    end
end 

% plot GRFs on all four force plates to determine which force plate was
% used
figure()
sub1 = subplot(2,2,1);
plot(static_time_analog, static.Cal.sForceP1(:,1))
title('FP1')
xlabel('Time (s)')
ylabel('Force (N)')
hold on
plot(static_time_analog, static.Cal.sForceP1(:,2))
plot(static_time_analog, static.Cal.sForceP1(:,3))

sub2 = subplot(2,2,2);
plot(static_time_analog, static.Cal.sForceP2(:,1))
title('FP2')
xlabel('Time (s)')
ylabel('Force (N)')
hold on
plot(static_time_analog, static.Cal.sForceP2(:,2))
plot(static_time_analog, static.Cal.sForceP2(:,3))

sub3 = subplot(2,2,3);
plot(static_time_analog, static.Cal.sForceP3(:,1))
title('FP3')
xlabel('Time (s)')
ylabel('Force (N)')
hold on
plot(static_time_analog, static.Cal.sForceP3(:,2))
plot(static_time_analog, static.Cal.sForceP3(:,3))

sub4 = subplot(2,2,4);
plot(static_time_analog, static.Cal.sForceP4(:,1))
title('FP4')
xlabel('Time (s)')
ylabel('Force (N)')
hold on
plot(static_time_analog, static.Cal.sForceP4(:,2))
plot(static_time_analog, static.Cal.sForceP4(:,3))

linkaxes([sub1, sub2, sub3, sub4], 'y')

%% Calculate Subject Mass 

% find greatest magnitude of vertical force (Fz) by locating the local 
% maxima of the inverted vertical force graph. 
[midstance, midstance_idx] = findpeaks(-walk_0001.Cal.ForceP3(:,3), MinPeakProminence=200); 

% visulaize findpeaks() output
figure()
findpeaks(-walk_0001.Cal.ForceP3(:,3), MinPeakProminence=200)
mass = -midstance(1)/9.81; % in kg

%% Center of Pressure Analysis

% find indices of Fz > 10 N to remove baseline noise from analysis 
valid_forces = find(walk_0001.Cal.ForceP3(:,3) > 10); 
% calculate centre of pressure for the x and y axes
COPx = -(walk_0001.Cal.ForceP3(valid_forces, 5) ./ walk_0001.Cal.ForceP3(valid_forces, 3)); % COPx = -My / Fz
COPy = -(walk_0001.Cal.ForceP3(valid_forces, 4) ./ walk_0001.Cal.ForceP3(valid_forces, 3)); % COPy = -Mx / Fz

figure()
plot(COPx, COPy)
xlabel('Medial/Laterial COP')
ylabel('Anterior/Posterior COP')
title('COP During Step')
