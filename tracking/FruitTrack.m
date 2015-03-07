classdef FruitTrack < handle
    
    properties
        id  % A unique integer id of this track
        
        color  % The color of the track for display purpose
        
        % A N-by-2 matrix to represent the centroids of the object with the
        % current centroid at the last row
        centroids
        
        % A N-by-4 matrix to represent the bounding boxes of the object 
        % with the current box at the last row
        bboxes
        
        % A N-by-1 vector to record the calssification score from the fuit
        % detector with the current detection score at the last row
        scores
        
        age  % The number of frames since the track was initialized
        
        % The total number of frames in which the object was detected
        visible_count   
        
        % A pair of two numbers to represent how confident we trust the
        % track. It stores the maximum and the average detection scores in
        % the past within a predefined time window
        confidence
        
        predicted_centroid
        predicted_bbox  % The predicted bounding box in the next frame
    end
    
    properties(Dependent)
        last_bbox
        last_centroid
    end
    
    methods
        % Constructor
        function self = FruitTrack(id, centroid, bbox, score)
            self.id = id;
            self.color = 255 * rand(1, 3);
            self.centroids = centroid;
            self.bboxes = bbox;
            self.scores = score;
            self.age = 1;
            self.visible_count = 1;
            self.confidence = [score, score];
            self.predicted_centroid = centroid;
            self.predicted_bbox = bbox;
        end
        
        % Predict new location of centroid and bounding box
        function predict(self, prev_corners, optical_flow, block_size, debug_axes)
            % Predict new centroid based on optical flow?
            % Get the last bonding box and centroid on this track
            last_bbox = self.last_bbox;
            last_centroid = self.last_centroid;
            % Search for all the corners around the last centroid within
            % the block size
            offset = calculateOffset(last_centroid, prev_corners, ...
                                     optical_flow, block_size);
                                 
            % Predict the centroid
            self.predicted_centroid = last_centroid + offset;
                
            % Shift the bounding box so that its center is at the
            % predicted centroid
            self.predicted_bbox = ...
                [self.predicted_centroid - last_bbox(3:4)/2, ...
                 last_bbox(3:4)];
            
            % DEBUG_START %
            % Plot last centroid
            hold on
            plot(debug_axes, ...
                 last_centroid(1), last_centroid(2), 'co');
           text(last_centroid(1), last_centroid(2), num2str(self.id), ...
                'Color', 'c');
            % Plot predicted bounding box in red
            [X, Y] = bboxToPatchVertices(self.predicted_bbox);
            patch(X, Y, 'r', 'Parent', debug_axes, 'EdgeColor', 'r', ...
                  'FaceAlpha', 0.1);
            plot(debug_axes, ...
                 [last_centroid(1), self.predicted_centroid(1)], ...
                 [last_centroid(2), self.predicted_centroid(2)], 'r');
            % Plot all previous centroid in cyan
            plot(debug_axes, ...
                 self.centroids(:,1), self.centroids(:,2), '-.c', ...
                 'LineWidth', 1);
            drawnow
            % DEBUG_STOP %
        end
        
        % Update assigned track with new centroid and bounding box
        % If stabilize is bigger than 0, this will take the average of up
        % to that number of frames with the new one and append it to the
        % track
        function updateAssigned(self, centroid, bbox, stabilize, debug_axes)
            if nargin < 4, stabilize = 0; end
            
            if stabilize
                n = min(self.age, stabilize);
                w = mean([self.bboxes(end - n + 1:end, 3); bbox(3)]);
                h = mean([self.bboxes(end - n + 1:end, 4); bbox(4)]);
                self.bboxes(end + 1, :) = [centroid - [w, h]/2, w, h];
            else
                self.bboxes(end + 1, :) = bbox;
            end
            
            % DEBUG_START %
            % Plot assigned detections in green
            hold on
            [X, Y] = bboxToPatchVertices(bbox);
            patch(X, Y, 'g', 'Parent', debug_axes, 'EdgeColor', 'g', ...
                  'FaceAlpha', 0.2);
            plot(debug_axes, ...
                 [self.last_centroid(1), centroid(1)], ...
                 [self.last_centroid(2), centroid(2)], 'g');
            drawnow
            % DEBUG_STOP %
            
            self.incAge();
            % Update visibility if this is an assigned track
            self.incVisibleCount();
            self.scores(end + 1, :) = 1; % detection score is 1
            self.centroids(end + 1, :) = centroid;
        end
        
        function updateUnassigned(self)
            self.incAge();
            self.centroids(end + 1, :) = self.predicted_centroid;
            self.bboxes(end + 1, :) = self.predicted_bbox;
            self.scores(end + 1, :) = 0;
        end
        
        % Adjust the track confidence score
        function adjustConfidence(self, time_win_size)
            n = min(time_win_size, length(self.scores));
            scores_in_window = self.scores(end - n + 1:end);
            self.confidence = [max(scores_in_window), ...
                               mean(scores_in_window)];
        end
        
        % Increment age by 1
        function incAge(self)
            self.age = self.age + 1;
        end
        
        % Increment visible count by 1
        function incVisibleCount(self)
            self.visible_count = self.visible_count + 1;
        end
        
        % Getter: last_bbox
        function bbox = get.last_bbox(self)
            bbox = self.bboxes(end, :);
        end
        
        % Getter: last_centroid
        function centroid = get.last_centroid(self)
            centroid = self.centroids(end, :);
        end
        
        % Visualize this track, not impelemented
        function visualize(self)
        end
    end

end

function offset = calculateOffset(centroid, corners, flow, block_size)
% Increase block size until we find some flow within
i = 0;
while true
    i = i + 1;
    inlier_ind = findCornersWithinBlock(centroid, corners, block_size * i);
    if nnz(inlier_ind), break; end
end

corners = corners(inlier_ind, :);
flow = flow(inlier_ind, :);

% Just take the average if block_size is small enough
if i == 1
    offset = mean(flow, 1);
    return;
end

% Find the closest corner to the centroid
distances_squared = sum(bsxfun(@minus, corners, centroid).^2, 2);
[~, min_distance_ind] = min(distances_squared, [], 1);
offset = flow(min_distance_ind, :);

end

function inlier_ind = findCornersWithinBlock(centroid, corners, block_size)
inlier_ind = ...
    (centroid(1) < corners(:, 1) + block_size) & ...
    (centroid(1) > corners(:, 1) - block_size) & ...
    (centroid(2) < corners(:, 2) + block_size) & ...
    (centroid(2) > corners(:, 2) - block_size);
end
