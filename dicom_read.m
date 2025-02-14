%A matlab program to read an RT DICOM plan and then print out the
%transformations of source for a brachytherapy plan in SagiPlan
clc
clear 

rt_plan = dicominfo("path/to/rtplan/dicom");

channel_sequence = rt_plan.ApplicationSetupSequence.Item_1.ChannelSequence;

num_of_applicators = length(fieldnames(channel_sequence));
applicators = fieldnames(channel_sequence);

%dwell times
source_weights = []; %source weights to be divided by 1000 to get time in s
count = 1;

% Loop through each applicator
%source coordinates stores coordinates for all applicators

for i = 1:num_of_applicators;
    applicator_num = applicators{i}; %item number of applicator
    applicator = channel_sequence.(applicator_num); %select applicator
    applicator_name = applicator.SourceApplicatorName; %name of the applicator
    

    num_control_points = length(fieldnames(applicator.BrachyControlPointSequence)); %number of dwell pos for that applicator
    dwell_sequence = fieldnames(applicator.BrachyControlPointSequence); %dwell sequence of that applicator
    
    
    for j = 1:num_control_points;
         control_point_num = dwell_sequence{j};
         control_point = applicator.BrachyControlPointSequence.(control_point_num); %selecting dwell position
         position = sprintf('position%d', j);
         source_coodinates.(applicator_num).dwell_positions.(position) = control_point.ControlPoint3DPosition; %Storing dwell position coordinates in one struct
         orientation = sprintf('orientation%d',j); % %d indicates conversion base 10 (integer)
         source_coodinates.(applicator_num).source_orientation.(orientation) = control_point.ControlPointOrientation;
         source_weights(count) = control_point.CumulativeTimeWeight/1000; %CumulativeTimeWight does not give actual time but cumulative time
         count = count+1
    end

end


item_names = fieldnames(source_coodinates); % All items (applicators in source_coordinates)
num_of_items = length(item_names); % Number of items

% Open the file once outside the loop
transformations = fopen('source_transformations.txt, 'w');

for k = 1:num_of_items
    position_table = struct2table(source_coodinates.(item_names{k}).dwell_positions);
    position_table = table2array(position_table); % Converting to table to array since struct cannot directly be converted to array
    orientation_table = struct2table(source_coodinates.(item_names{k}).source_orientation);
    orientation_table = table2array(orientation_table);

    num_of_dwell_pos = length(fieldnames(source_coodinates.(item_names{k}).dwell_positions)); % Number of dwell pos in each applicator

    for m = 1:num_of_dwell_pos
        fprintf(transformations, ':start transformation:\n');
        fprintf(transformations, '   translation = %.3f %.3f %.3f\n', position_table(:, m) / 10); % Translation in mm, convert to cm
        fprintf(transformations, '   rotation = %.3f %.3f %.3f\n', orientation_table(:, m));
        fprintf(transformations, ':stop transformation:\n\r'); % \n for newline, \r for space after new line
    end
end

% Close the file after the loop
fclose(transformations);


dwell_times = fopen('source_weights.txt','w');
fprintf(dwell_times,'%.3f ',source_weights);
fclose(dwell_times);


%Note: The RTPlan Dicom stores the dwell position coordinates twice for
%each position, hence the transformation txt file contains double the
%number of coordinates than the actual number of dwell positions.
