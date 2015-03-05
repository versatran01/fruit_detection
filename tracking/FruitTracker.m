classdef FruitTracker < handle
    
    properties
        tracks  % Collection of tracks
        
        % An integer that will be incremented and assigned to each newly
        % created track
        track_counter
        
        % An integer that represents the total number of valid tracks, this
        % will be the same number as the entire fruit count
        num_valid_tracks
        
        % param.gating_thresh - A threshold to reject a candidate match 
        % between a detection and a track
        % param.gating_cost - A large value for the assignment cost matrix
        % that enforces the rejection of a candidate match
        % param.cost_of_non_assignment - A tuning parameter to control the
        % likelihood of creation of a new track
        % param.time_win_size - A tunning parameter to specify the number
        % of frames required to stabilize the confidence score of a track
        param
        
        detections
        assignments
        unassigned_tracks
        unassigned_detections
    end
    
    properties(Dependent)
        num_tracks
        initialized
    end
    
    methods
        % Constructor
        function self = FruitTracker()
            % disable gating for now
            self.param.gating_thresh = 1;
            self.param.gating_cost = 100;
            self.param.cost_of_non_assignment = 10;
            self.param.time_win_size = 5;
            self.param.age_thresh = 5;
            self.param.visibility_thresh = 0.6;
            self.param.confidence_thresh = 2;
            self.track_counter = 1;
            self.tracks = FruitTrack.empty;
        end
        
        % Track detections
        % detections - ConnectedComponents
        function track(self, detections)
            self.detections = detections;
            self.predictNewLocationsOfTracks();
            self.detectionsToTracksAssignment();
            self.updateAssignedTracks();
            self.updateUnassignedTracks();
            self.deleteLostTracks();
            self.createNewTracks();
            self.displayTrackingResults();
        end
        
        % Predict new locations of each track using kalman filter
        function predictNewLocationsOfTracks(self)
            for i = 1:self.num_tracks
                track = self.tracks(i);
                % Predict the current location of the track
                % predicted_centroid = predict(track.kalman_filter);
                track.kfPredict();
            end 
        end
        
        % Assign detections to tracks
        % Compute overlaop ratio between predicted boxes and detected boxes
        % Compute the cost of assigning each detection to each track
        function detectionsToTracksAssignment(self) 
            % Compute the overlap ratio between the predicted bounding
            % boxes and the detected bounding boxes, and compute the cost
            % of assigning each detection to each track. The cost is
            % minimum when the predicted bbox is perfectly aligned with the
            % detected boox (overlap ratio is 1)
            if ~self.initialized, 
                self.unassigned_detections = ...
                    1:size(self.detections.Centroid, 1);
                return;
            end
            predicted_bboxes = reshape([self.tracks(:).predicted_bbox], ...
                                        4, [])';
            cost = 1 - bboxOverlapRatio(predicted_bboxes, ...
                                        self.detections.BoundingBox);
            
            % Force the optimization step to ignore some matches by setting
            % the associated cost to be a large number.
            cost(cost > self.param.gating_thresh) = ...
                1 + self.param.gating_cost;
            
            % Solve the assignment problem
            [self.assignments, ...
             self.unassigned_tracks, ...
             self.unassigned_detections] = ...
             assignDetectionsToTracks(cost, ...
                                      self.param.cost_of_non_assignment);
        end
       
        % Updates each assigned track with the corresponding dtection
        % Kalman filter correction
        % Save the new bounding box
        % Increase the age and total visible count of each track
        function updateAssignedTracks(self)
            num_assigned_tracks = size(self.assignments, 1);
            for i = 1:num_assigned_tracks
                track_idx = self.assignments(i, 1);
                detection_idx = self.assignments(i ,2);
                
                track = self.tracks(track_idx);
                centroid = self.detections.Centroid(detection_idx, :);
                bbox = self.detections.BoundingBox(detection_idx, :);
                
                % Correct the estimate of the object's location using  the
                % new detection
                track.kfCorrect(centroid);
                
                % Stabilize the bounding box by taking the average of the
                % size [?]
                track.updateAssigned(centroid, bbox, 4);
                
                % Adjust track confidence score based on the maximum
                % detection score in the past few frames
                track.adjustConfidence(self.param.time_win_size);
                
                % TODO: maybe merge the above two methods?
            end
        end
        
        % Marks each unassigned track as invisible, increases its age by 1
        % Appends the predicted bounding box to the track
        % The confidence is set to zero
        function updateUnassignedTracks(self)
            num_unassigned_tracks = length(self.unassigned_tracks);
            for i = 1:num_unassigned_tracks;
                track_idx = self.unassigned_tracks(i);
                track = self.tracks(track_idx);
                track.updateUnassigned();
                track.adjustConfidence(self.param.time_win_size);
            end
        end
        
        % Delete traks that have been invisible for too many consecutive
        % frames. It also deletes recently created tracks that have benn
        % invisible for many frames overall
        % 1. The object was tracked for a short time
        % 2. The track was marked invisible for most of the frames
        % 3. It failed to receive a strong detection within the past few
        % frames
        function deleteLostTracks(self)
            if ~self.initialized, return; end
            
            % Compute the fraction of the track's age for which it was
            % visible
            ages = [self.tracks(:).age]';
            visible_counts = [self.tracks(:).visible_count]';
            visibility = visible_counts ./ ages;
            
            % Check the maxium detection confidence score
            confidences = reshape([self.tracks(:).confidence], 2, [])';
            max_confidence = confidences(:, 1);
            
            % Find the indices of 'lost' tracks
            lost_idx = (ages <= self.param.age_thresh) & ...
                       (visibility <= self.param.visibility_thresh) & ...
                       (max_confidence <= self.param.confidence_thresh);
            
            % Delete lost tracks
            self.tracks = self.tracks(~lost_idx);
        end
        
        % Create new tracks for unassigned detections
        % Assume that any unassigned detection is a start of new track.
        function createNewTracks(self)
            num_unassigned_detections = length(self.unassigned_detections);
            
            unassigned_centroids = ...
                self.detections.Centroid(self.unassigned_detections, :);
            unassigned_bboxes = ...
                self.detections.BoundingBox(self.unassigned_detections, :);
            
            
            for i = 1:num_unassigned_detections
                centroid = unassigned_centroids(i, :);
                bbox = unassigned_bboxes(i, :);
                score = 1;
                
                % Create a new track    
                new_track = FruitTrack(self.track_counter, centroid, ...
                                       bbox, score);
                % TODO: change these parameters here
                new_track.kalman_filter = ...
                    configureKalmanFilter('ConstantVelocity', centroid, ...
                                          [2, 1], [5, 5], 100);
                % Add it to the array of tracks
                self.tracks(end + 1) = new_track;
                self.track_counter = self.track_counter + 1;
            end
        end
        
        % Draws a colored bounding box for each track on the frame
        function displayTrackingResults(self)
            if isempty(self.tracks), return; end
            for i = 1:self.num_tracks
                track = self.tracks(i);
                track.visualize();
            end
        end
        
        % Getter: num_tracks
        function n = get.num_tracks(self)
            n = numel(self.tracks);
        end
        
        % Getter: initialized
        function init = get.initialized(self)
            init = ~isempty(self.tracks);
        end
    end
    
end
