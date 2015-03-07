classdef FruitTracker < handle
    
    properties
        tracks  % Collection of tracks
        
        image  % Current image
        
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
        % param.cost_non_assignment - A tuning parameter to control the
        % likelihood of creation of a new track
        % param.time_win_size - A tunning parameter to specify the number
        % of frames required to stabilize the confidence score of a track
        % param.age_thresh
        % param.visibility_thresh
        % param.confidence_thresh
        
        % param.pyramid_levels - Number of pyramid levels in klt tracker
        % param.block_size - TODO
        % param.corners_per_block - TODO
        % param.extract_thresh - TODO
        param
        
        % Point tracker using Kanade-Lucas-Tomasi algorithm
        klt_tracker
        
        % A N-by-2 matrix represents the previous corners from the previous
        % frame.
        prev_corners
        
        % A N-by-2 matrix represents the corners that are successfully
        % tracked from previous frame to the current frame
        curr_corners
        
        % A N-by-2 matrix represents the flow vector at the tracked corners
        flow
        
        % An object of ConnectedComponents class
        detections
        
        % Assignment stuff
        assignments
        unassigned_tracks
        unassigned_detections
        
        % Debug
        debug_axes
        debug_image
    end
    
    properties(Dependent)
        num_tracks
        initialized
    end
    
    methods
        % Constructor
        function self = FruitTracker()
            % disable gating for now
            
            % Fruit tracker parameters
            self.param.gating_thresh = 0.9;
            self.param.gating_cost = 100;
            self.param.cost_non_assignment = 10;
            self.param.time_win_size = 4;
            self.param.confidence_thresh = 0.5;
            self.param.age_thresh = 5;
            self.param.visibility_thresh = 0.6;
            
            
            % KLT tracker parameters
            self.param.pyramid_levels = 3;
            self.param.block_size = [1 1] * 21;
            self.param.corners_per_block = 2;
            self.param.extract_thresh = 0.4;
            self.klt_tracker = ...
                vision.PointTracker('BlockSize', self.param.block_size, ...
                'NumPyramidLevels', ...
                self.param.pyramid_levels);
            
            self.track_counter = 1;
            self.tracks = FruitTrack.empty;
            
            % Debug stuff
            figure(2);
            self.debug_axes = axes();
        end
        
        % Track detections
        % detections - ConnectedComponents
        function track(self, detections, image)
            fprintf('========== Starting a new frame. ==========\n');
            self.detections = detections;
            
            self.calculateOpticalFlow(image);
            self.predictNewLocationsOfTracks();
            self.detectionsToTracksAssignment();
            self.updateAssignedTracks();
            self.updateUnassignedTracks();
            self.deleteLostTracks();
            self.createNewTracks();
                self.displayTrackingResults();
        end
        
        % Optical flow
        function calculateOpticalFlow(self, image)
            self.image = image;
            % Make current corners previous before start
            self.prev_corners = self.curr_corners;
            
            [m, n, c] = size(image);
            
            % Convert to gray scale image
            if c == 3, gray = rgb2gray(image); end
            
            % DEBUG_START %
            % Plot original image
            imshow(image, 'Parent', self.debug_axes);
            set(self.debug_axes, 'YDir', 'normal');
            drawnow
            % Plot current detections in yellow
            [X, Y] = bboxToPatchVertices(self.detections.BoundingBox);
            patch(X, Y, 'y', 'Parent', self.debug_axes, ...
                  'EdgeColor', 'y', 'FaceAlpha', 0.1);
            % DEBUG_STOP %
            
            % Calculate max corners
            max_corners = ceil(m * n / self.param.block_size(1)^2 * ...
                               self.param.corners_per_block);
            
            % Optical flow tracking
            if ~isempty(self.prev_corners)
                % KLT tracking
                [curr_points, match_ind] = self.klt_tracker.step(gray);
                prev_points = self.prev_corners(match_ind, :);
                curr_points = curr_points(match_ind, :);
                % Fundamental matrix outlier rejection
                [~, inlier_ind, status] = ...
                    estimateFundamentalMatrix(prev_points, curr_points);
                prev_points = prev_points(inlier_ind, :);
                curr_points = curr_points(inlier_ind, :);
                self.flow = curr_points - prev_points;
                % Update prev corners so that its size matches that of
                % flow
                self.prev_corners = prev_points;
                self.curr_corners = curr_points;
                
                % DEBUG_START %
                fprintf('Number of flow: %g\n', size(self.flow, 1));
                % Plot optical flow
                %{
                hold on
                plot(self.debug_axes, self.prev_corners(:, 1), ...
                     self.prev_corners(:, 2), 'b.');
                plot(self.debug_axes, self.curr_corners(:, 1), ...
                     self.curr_corners(:, 2), 'r.');
                quiver(self.debug_axes, ...
                       prev_points(:, 1), prev_points(:, 2), ...
                       self.flow(:, 1), self.flow(:, 2), 0, ...
                       'm');
                drawnow;
                %}
                % DEBUG_STOP %
            end
            
            % Extract new features at every frame
            new_corners = detectFASTFeatures(gray );
            new_corners = new_corners.selectStrongest(max_corners);
            % Assign new corners to tracked
            self.curr_corners = ...
                new_corners.selectStrongest(max_corners).Location;
            % Reinitialize klt_tracker
            self.klt_tracker.release();
            self.klt_tracker.initialize(self.curr_corners, gray);
            
            % DEBUG_START %
            fprintf('Number of new corners: %g.\n', ...
                    size(self.curr_corners, 1));
            hold on
            plot(self.debug_axes, self.curr_corners(:, 1), ...
                self.curr_corners(:, 2), 'b.');
            drawnow
            % DEBUG_STOP %
        end
        
        % Predict new locations of each track using kalman filter
        function predictNewLocationsOfTracks(self)
            fprintf('Predicting new locations for %g tracks.\n', ...
                    self.num_tracks);
            for i = 1:self.num_tracks
                track = self.tracks(i);
                % Predict the current location of the track
                % Pass in the debug_axes for debugging
                track.predict(self.prev_corners, self.flow, ...
                              self.param.block_size(1), self.debug_axes);
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
            fprintf('Assigning %g detections to %g tracks.\n', ...
                    size(self.detections.BoundingBox, 1), ...
                    self.num_tracks);
            [self.assignments, ...
             self.unassigned_tracks, ...
             self.unassigned_detections] = ...
                assignDetectionsToTracks(cost, ...
                                         self.param.cost_non_assignment);
            fprintf('%g detections assgined to %g tracks.\n', ...
                    size(self.assignments, 1), size(self.assignments, 1));
            fprintf('%g unassigned tracks, %g unassigned detections.\n' , ...
                    numel(self.unassigned_tracks), ...
                    numel(self.unassigned_detections));
        end
        
        % Updates each assigned track with the corresponding detection
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
                
                % Stabilize the bounding box by taking the average of the
                % size [?]
                track.updateAssigned(centroid, bbox, 0, self.debug_axes);
                
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
                
            % Check whether the last centroid is out of image boundary
            last_centroids = reshape([self.tracks(:).last_centroid], ...
                                     2, [])';
            out_of_image = last_centroids(:, 1) < 0 | ...
                           last_centroids(:, 2) < 0 | ...
                           last_centroids(:, 1) > size(self.image, 2) | ...
                           last_centroids(:, 2) > size(self.image, 1);
            
            % Check the maxium detection confidence score
            confidences = reshape([self.tracks(:).confidence], 2, [])';
            ave_confidences = confidences(:, 2);
            
            % Find the indices of 'lost' tracks
            % The criteria for 'lost' is 
            lost_idx_1 = (ages <= self.param.age_thresh & ...
                          visibility < self.param.visibility_thresh) | ...
                         (ave_confidences < self.param.confidence_thresh);
            lost_idx_2 = ages > self.param.age_thresh & out_of_image;
            lost_idx = lost_idx_1 | lost_idx_2;
                          
            fprintf('Number of tracks to delete: %g.\n', nnz(lost_idx));
            
            tracks_to_delete = self.tracks(lost_idx);
            % Delete lost tracks
            self.tracks = self.tracks(~lost_idx);
            
            % DEBUG_START %
            % Plot tracks to delte
            
            delete_centroids = reshape([tracks_to_delete.last_centroid], ...
                                       2, [])';
            if ~isempty(delete_centroids)
                
                plot(self.debug_axes, ...
                    delete_centroids(:, 1), delete_centroids(:, 2), 'm+', ...
                    'MarkerSize', 10);
                drawnow
            end
            % DEBUG_STOP %
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
