classdef FruitTracker < handle
    
    properties
        tracks
    end
    
    methods
        % Constructor
        function self = FruitTracker()
            
        end
        
        % Track detections
        % detections - ConnectedComponents
        function track(self, detections)
        end
        
        % Predict new locations of each track using kalman filter
        function predictNewLocationsofTracks(self)
        end
        
        % Assign detections to tracks
        % Compute overlaop ratio between predicted boxes and detected boxes
        % Compute the cost of assigning each detection to each track
        function detectionsToTrackAssignment(self) 
        end
       
        % Updates each assigned track with the corresponding dtection
        % Kalman filter correction
        % Save the new bounding box
        % Increase the age and total visible count of each track
        function updateAssignedTracks(self)
        end
        
        % Marks each unassigned track as invisible, increases its age by 1
        % Appends the predicted bounding box to the track
        % The confidence is set to zero
        function updateUnassignedTracks(self)
        end
        
        % Delete traks that have been invisible for too many consecutive
        % frames. It also deletes recently created tracks that have benn
        % invisible for many frames overall
        % 1. The object was tracked for a short time
        % 2. The track was marked invisible for most of the frames
        % 3. It failed to receive a strong detection within the past few
        % frames
        function deleteLostTracks(self)
        end
        
        % Create new tracks for unassigned detections
        % Assume that any unassigned detection is a start of new track.
        function createnewTracks(self)
        end
        
        % Draws a colored bounding box for each track on the frame
        function displayTrackingResults(self)
        end
    end
    
end
