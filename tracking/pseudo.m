% Initialize FruitTracker with some options
fruit_tracker = FruitTracker(options);

% Detect fruit
[mask, CC] = detectFruit(image);

% Main tracking function
tracker.track(CC);


%% Inside tracker.track
predictNewLocationsOfTracks()
[assignments, unassignedTracks, unassignedDetections] = ...
        detectionToTrackAssignment();

updateAssignedTracks();
updateUnassignedTracks();
deleteLostTracks();
createNewTracks();
displayTrackingResults();

%% Inside each of the above function
function predictNewLocationsOfTracks()
% Predict new location of each track using kalman filter
for each track in tracks:
	track.predictNewLocation()
	% Get the last bounding box on this track
	% Predict the current location of the track
	% Shift the bounding box
end

function detectionToTrackAssignment()
% Compute overlap ratio between predicted boxes and the detected boxes
% Compute the cost of assigning each detection to each track [a better way?]
cost = 1 - bboxOverlapRatio(predBboxes, bboxes);
% What do these outputs mean?
[assignments, unassignedTracks, unassignedDetections] = ...
            assignDetectionsToTracks(cost, option.costOfNonAssignment);

function updateAssignedTracks()
% Updates each assigned track with the corresponding detection
% Kalman filter correction
% Save the new bounding box [smartly]
% Increase the age and total visible count or each track
num_assigned_tracks = size(assignments, 1);
for i = 1:num_assigned_tracks
	track_idx = assignments(i, 1);
	detection_idx = assignments(i, 2);
	centroid
	bbox
	% Kalman filter correction
	% Update age and visibility
	% Adjust confidence score based on some criteria
end

function updateUnassignedTracks()
% Marks each unassigned track as invisible, increases its age by 1
% Appends the predicted bounding box to the track.
% The confidence is set to zero
for i = 1:length(unassignedTracks)
	track_idx = unassignedTracks(i)
	% Increment age, append bounding box and append score = 0
	% Adjust confidence
end

function deleteLostTracks()
% Deletes tracks that have been invisible for too many consecutive frames
if isempty(tracks)
    return;
end
visibility = totalVisibleCounts ./ ages;
max_confidence
% Calculate lost_idx based on age, visibility and max_confidence
tracks = tracks(~lost_idx)

function createNewTracks()
% Create new tracks from unassigned detections
for i = 1:length(unassignedDetections)
	% Configure kalman filter
	% Create new track
end

function displayTrackingResults(image)
for each track in tracks
	track.show()
	% Edge color shows age
	% Edge width shows confidence? or maybe alpha data
	% Id at the upper left corner
	% maybe use insertShape and insertText for drawing bounding boxes
	% instead of patch?
end

