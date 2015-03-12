classdef FruitTracker < handle
    
    properties
        tracks  % Collection of tracks
        deleted_tracks  % Colelction of deleted tracks
        
        image  % Current image
        
        % An integer that will be incremented and assigned to each newly
        % created track
        track_counter
        
        % Number of fruits in each bounding box
        fruit_counts
        
        % An interger that will be incremented when track is called
        frame_counter
        
        % Total number of fruits
        total_fruit_counts
        total_fruit_counts_variance
        
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
        % param.block_size - Block size of klt tracker
        % param.corners_per_block - A parameter for calculating max corners
        % to extract
        param
        
        % Point tracker using Kanade-Lucas-Tomasi algorithm
        klt_tracker
        
        % A N-by-2 matrix represents the previous corners from the previous
        % frame and the current frame
        prev_corners
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
        debug
        verbose
        
        handles

        initialized = false;
    end
    
    properties(Dependent)
        new_tracks
        young_tracks
        valid_tracks
        num_tracks
    end
    
    methods
        % Constructor
        function self = FruitTracker(debug_status, verbose)
            if nargin < 1, debug_status = false; end
            if nargin < 2, verbose = false; end
            self.debug.status = debug_status;
            self.verbose = verbose;
            
            % Fruit tracker parameters
            % TODO: improve these parameters
            self.param.gating_thresh = 0.97;
            self.param.gating_cost = 100;
            self.param.cost_non_assignment = 10;
            self.param.time_win_size = 4;
            self.param.confidence_thresh = 0.5;
            self.param.age_thresh = 5;
            self.param.visibility_thresh = 0.6;
                        
            % KLT tracker parameters
            self.param.pyramid_levels = 4;
            self.param.block_size = [1 1] * 23;
            self.param.corners_per_block = 1.2;
            self.klt_tracker = ...
                vision.PointTracker('BlockSize', self.param.block_size, ...
                                    'NumPyramidLevels', ...
                                    self.param.pyramid_levels);
            
            self.track_counter = 0;
            self.frame_counter = 0;
            self.total_fruit_counts = 0;
            self.total_fruit_counts_variance = 0;
            self.tracks = FruitTrack.empty;
            
            % Debug stuff
            if self.debug.status
                self.handles.fig = figure();
                self.debug.axes = axes();
                % Number of matches before estimateFundamentalMatrix
                self.debug.num_matches = [];
                % Number of matches after estimateFundamentalMatrix
                self.debug.num_inliers = [];
                % All graphic handles
                self.handles.image = [];
                self.handles.detections = [];
                self.handles.new_tracks = [];
                self.handles.young_tracks = [];
                self.handles.valid_tracks = [];
                self.handles.predicted_tracks = [];
                self.handles.predictions = [];
                self.handles.flow = [];
            end
        end
        
        % Track detections
        % detections - ConnectedComponents
        function track(self, detections, image, counts)
            if self.verbose
                fprintf('========= Frame %g. =========\n', self.frame_counter);
            end
            self.frame_counter = self.frame_counter + 1;
            self.image = image;
            self.detections = detections;
            self.fruit_counts = counts;
            
            % Main tracking steps
            self.calculateOpticalFlow();
            self.predictNewLocationsOfTracks();
            self.detectionsToTracksAssignment();
            self.updateAssignedTracks();
            self.updateUnassignedTracks();
            self.deleteLostTracks();
            self.createNewTracks();
            self.updateTotalFruitCounts();
            self.displayTrackingResults(true);
        end
        
        % Optical flow
        function calculateOpticalFlow(self)
            % Make current corners previous before start
            self.prev_corners = self.curr_corners;
            if self.verbose
             fprintf('Number of old corners: %g.\n', ...
                        size(self.prev_corners, 1));
            end
            
            [m, n, c] = size(self.image);
            
            % Convert to gray scale image
            if c == 3, gray = rgb2gray(self.image); end
            
            % Calculate max corners
            max_corners = ceil(m * n / self.param.block_size(1)^2 * ...
                               self.param.corners_per_block);
            
            % Optical flow tracking
            if ~isempty(self.prev_corners)
                % KLT tracking
                [curr_points, match_ind] = self.klt_tracker.step(gray);
                prev_points = self.prev_corners(match_ind, :);
                curr_points = curr_points(match_ind, :);
                
                if self.debug.status
                    self.debug.num_matches(end + 1) = nnz(match_ind);
                end
                
                % Fundamental matrix outlier rejection
                if nnz(match_ind) > 8 * 2.5
%                     [Fest, inlier_ind, status] = estimateFundamentalMatrix(...
%                         prev_points, curr_points, ...
%                         'Method', 'MSAC', ...
%                         'NumTrials', 500, ...
%                         'Confidence', 99.5, ...
%                         'DistanceThreshold', 0.64, ...
%                         'OutputClass', 'single', ...
%                         'DistanceType', 'Sampson');
                    [F,inlier_ind] = findFundamentalMat(double(prev_points),...
                        double(curr_points), 1, 0.99);
                    prev_points = prev_points(inlier_ind, :);
                    curr_points = curr_points(inlier_ind, :);
                    self.flow = curr_points - prev_points;
                    % Update prev corners so that its size matches that of
                    % flow
                    self.prev_corners = prev_points;
                    self.curr_corners = curr_points;
                else 
                    self.flow = mean(self.flow, 1);
                    inlier_ind = match_ind;
                end
                
                if self.debug.status
                    self.debug.num_inliers(end + 1) = nnz(inlier_ind);
                end
                
                % DEBUG_START %
                if self.verbose
                    fprintf('Number of flow: %g\n', size(self.flow, 1));
                end
                % Plot optical flow
                if self.debug.status
                    self.handles.flow = ...
                        plotQuiverOnAxes(self.debug.axes, ...
                                         self.handles.flow, ...
                                         self.prev_corners, ...
                                         self.curr_corners, ...
                                         'm');
                end
            end
            
            % Extract new features at every frame
            new_corners = detectMinEigenFeatures(gray, ...
                                                 'MinQuality', 0.1);
            new_corners = new_corners.selectStrongest(max_corners);
            % Assign new corners to tracked
            self.curr_corners = new_corners.Location;
            % Reinitialize klt_tracker
            self.klt_tracker.release();
            self.klt_tracker = ...
                vision.PointTracker('BlockSize', self.param.block_size, ...
                                    'NumPyramidLevels', ...
                                    self.param.pyramid_levels);
            self.klt_tracker.initialize(self.curr_corners, gray);
            
            if self.verbose
                fprintf('Number of new corners: %g.\n', ...
                    size(self.curr_corners, 1));
            end
        end
        
        % Predict new locations of each track using kalman filter
        function predictNewLocationsOfTracks(self)
            if self.verbose
             fprintf('Predicting new locations for %g tracks.\n', ...
                    self.num_tracks);
            end
            for i = 1:self.num_tracks
                track = self.tracks(i);
                % Predict the current location of the track
                track.predict(self.prev_corners, self.flow, 10);
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
            if ~self.initialized && ~self.detections.isempty()
                self.unassigned_detections = 1:self.detections.size();
                self.initialized = true;
                return;
            end
            
            % Handle 0 detections
            if self.detections.isempty()
                self.assignments = [];
                self.unassigned_tracks = 1:numel(self.tracks);
                self.unassigned_detections = [];
                return;
            end
            
            predicted_bboxes = reshape([self.tracks.predicted_bbox], ...
                                       4, [])';
            cost = 1 - bboxOverlapRatio(predicted_bboxes, ...
                                        self.detections.BoundingBox);
            
            % Force the optimization step to ignore some matches by setting
            % the associated cost to be a large number.
            cost(cost > self.param.gating_thresh) = ...
                1 + self.param.gating_cost;
            
            % Solve the assignment problem
            if self.verbose
                fprintf('Assigning %g detections to %g tracks.\n', ...
                        self.detections.size(), ...
                        self.num_tracks);
            end
                
            [self.assignments, ...
             self.unassigned_tracks, ...
             self.unassigned_detections] = ...
                assignDetectionsToTracks(cost, ...
                                         self.param.cost_non_assignment);
                             
            if self.verbose
                fprintf('%g detections assgined to %g tracks.\n', ...
                        size(self.assignments, 1), size(self.assignments, 1));
                fprintf('%g unassigned tracks, %g unassigned detections.\n' , ...
                        numel(self.unassigned_tracks), ...
                        numel(self.unassigned_detections));
            end
        end
        
        % Updates each assigned track with the corresponding detection
        % Save the new bounding box
        % Increase the age and total visible count of each track
        function updateAssignedTracks(self)
            num_assigned_tracks = size(self.assignments, 1);
            centroids = self.detections.Centroid();
            bboxes = self.detections.BoundingBox();
            for i = 1:num_assigned_tracks
                track_idx = self.assignments(i, 1);
                detection_idx = self.assignments(i ,2);
                
                track = self.tracks(track_idx);
                centroid = centroids(detection_idx, :);
                bbox = bboxes(detection_idx, :);
                fruit_count = self.fruit_counts(detection_idx);
                
                % Stabilize the bounding box by taking the average of the
                % size [?], don't stablize for now
                track.updateAssigned(centroid, bbox, fruit_count, 0);
                
                % Adjust track confidence score based on the maximum
                % detection score in the past few frames
                track.adjustConfidence(self.param.time_win_size);
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
            if isempty(self.tracks), return; end
            
            % Compute the fraction of the track's age for which it was
            % visible
            ages = [self.tracks.age]';
            visible_counts = [self.tracks.visible_count]';
            visibility = visible_counts ./ ages;
                
            % Check whether the last centroid is out of image boundary
            last_centroids = reshape([self.tracks.last_centroid], 2, [])';
            out_of_image = last_centroids(:, 1) < 0 | ...
                           last_centroids(:, 2) < 0 | ...
                           last_centroids(:, 1) > size(self.image, 2) | ...
                           last_centroids(:, 2) > size(self.image, 1);
            
            % Check the maxium detection confidence score
            confidences = reshape([self.tracks.confidence], 2, [])';
            ave_confidences = confidences(:, 2);
            
            % Find the indices of 'lost' tracks
            % The criteria for 'lost' is 
            % 1. for tracks that are young, we check its visibility and
            % delete those that are not detected sufficiently enough.
            % 2. for tracks that are old, whe check its average confidence
            % or whether it's outside the image
            lost_idx_1 = ages <= self.param.age_thresh & ...
                         visibility < self.param.visibility_thresh;
            lost_idx_2 = ages > self.param.age_thresh & ...
                         (out_of_image | ...
                         ave_confidences < self.param.confidence_thresh);
            lost_idx = lost_idx_1 | lost_idx_2;
                  
            if self.verbose
                fprintf('Number of tracks to delete: %g.\n', nnz(lost_idx));
            end
            
            % Collect deleted tracks
            self.deleted_tracks = self.tracks(lost_idx);
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
            unassigned_counts = ...
                self.fruit_counts(self.unassigned_detections, :);
            
            for i = 1:num_unassigned_detections
                centroid = unassigned_centroids(i, :);
                bbox = unassigned_bboxes(i, :);
                score = 1;
                count = unassigned_counts(i, :);
                
                % Create a new track
                new_track = FruitTrack(self.track_counter, centroid, ...
                                       bbox, score, count);
                % Add it to the array of tracks
                self.tracks(end + 1) = new_track;
                self.track_counter = self.track_counter + 1;
            end
        end
        
        % Update total valid tracks id
        function updateTotalFruitCounts(self)
            if isempty(self.deleted_tracks), return; end;
            ages = [self.deleted_tracks.age]';
            % get all tracks which meet age threshold
            count_indices = ages >= self.param.age_thresh;
            countable_tracks = self.deleted_tracks(count_indices);
            self.countTracks(countable_tracks);
        end
        
        function countTracks(self, countable_tracks)
            tracks_count = 0;
            tracks_var = 0;
            
            % take all the counts from this track and combine them
            for i=1:numel(countable_tracks)
                total = mean(countable_tracks(i).fruit_count);
                variance = var(countable_tracks(i).fruit_count);
                
                % increment both count and the variance
                tracks_count = tracks_count + total;
                tracks_var = tracks_var + variance;
            end
            self.total_fruit_counts = self.total_fruit_counts + ...
                                      tracks_count;
            self.total_fruit_counts_variance = self.total_fruit_counts_variance + ...
                tracks_var;
        end
        
        % Delete all existing counts and add it to total fruit counts
        function finish(self)
            if self.debug.status, close(self.handles.fig); end
            if isempty(self.tracks), return; end
            self.countTracks(self.tracks);          
        end
        
        % Draws a colored bounding box for each track on the frame
        function displayTrackingResults(self, show_predict)
            if nargin < 2, show_predict = false; end
            
            if self.debug.status
                self.handles.image = ...
                    plotImageOnAxes(self.debug.axes, self.handles.image, ...
                                    self.image);
               % set(self.debug.axes, 'YDir', 'Normal');
                % Plot current detections in purple
                if ~self.detections.isempty()
                    self.handles.detections = ...
                        plotCentroidsOnAxes(self.debug.axes, ...
                                            self.handles.detections, ...
                                            self.detections.Centroid, 'm+', 3);
                end
            end
            
            if isempty(self.tracks), return; end   
            
            if self.debug.status
                
                if show_predict
                    % Plot predicted bounding box in yellow
                   predicted_bboxes = ...
                       reshape([self.tracks.predicted_bbox], 4, [])';
                   self.handles.predicted_tracks = ...
                       plotBboxesOnAxes(self.debug.axes, ...
                                        self.handles.predicted_tracks, ...
                                        predicted_bboxes, 'b', 0, 1);
                   prev_centroids = ...
                       reshape([self.tracks.prev_centroid], 2, [])';
                   last_centroids = ...
                       reshape([self.tracks.last_centroid], 2, [])';
                   self.handles.predictions = ...
                       plotQuiverOnAxes(self.debug.axes, ...
                                        self.handles.predictions, ...
                                        prev_centroids, last_centroids, ...
                                        'b');
                end
                
                % Plot new tracks bounding box in red
                young_bboxes = reshape([self.young_tracks.last_bbox], ...
                                       4, [])';
                self.handles.young_tracks = ...
                    plotBboxesOnAxes(self.debug.axes, ...
                                     self.handles.young_tracks, ...
                                     young_bboxes, 'r', 0, 1);
                
                % Plot valid tracks in cyan
                valid_bboxes = reshape([self.valid_tracks.last_bbox], ...
                                       4, [])';
                self.handles.valid_tracks = ...
                    plotBboxesOnAxes(self.debug.axes, ...
                                     self.handles.valid_tracks, ...
                                     valid_bboxes, 'c', 0, 1);
                
                % Display total count
                title_str = ...
                    sprintf('frame: %g, total count: %.2f, detections: %g', ...
                            self.frame_counter, ...
                            self.total_fruit_counts, ...
                            self.detections.size());
                title(self.debug.axes, title_str);
                drawnow
            end
        end
        
        % Getter: num_tracks
        function n = get.num_tracks(self)
            n = numel(self.tracks);
        end
        
        % Getter: new_tracks
        function new_tracks = get.new_tracks(self)
            new_tracks_idx = [self.tracks.age] == 1;
            new_tracks = self.tracks(new_tracks_idx);
        end
        
        % Getter: valid_tracks
        function valid_tracks = get.valid_tracks(self)
            valid_tracks_idx = ...
                [self.tracks.age] >= self.param.age_thresh;
            valid_tracks = self.tracks(valid_tracks_idx);
        end
        
        % Getter: young_tracks
        function young_tracks = get.young_tracks(self)
            young_tracks_idx = ...
                [self.tracks.age] < self.param.age_thresh;
            young_tracks = self.tracks(young_tracks_idx);
        end
    end
    
end

function handle = plotQuiverOnAxes(ax, handle, xy1, xy2, color)
uv = xy2 - xy1;
if isempty(handle) || ~isgraphics(handle)
    hold(ax, 'on');
    handle = quiver(ax, xy1(:, 1), xy1(:, 2), uv(:, 1), uv(:, 2), 0, ...
                    'Color', color);
    hold(ax, 'off');
else
    set(handle, 'XData', xy1(:, 1), 'YData', xy1(:, 2), ...
        'UData', uv(:, 1), 'VData', uv(:, 2));
end
end