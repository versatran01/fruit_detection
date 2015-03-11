classdef FruitTrack < handle
    
    properties
        id  % A unique integer id of this track
        
        color  % The color of the track for display purpose
        
        % A N-by-2 matrix to represent the centroids of the object with the
        % current centroid at the last row
        centroids
        
        % The number of fruit in this track
        fruit_count
        
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
        
        % Predicted centroid and bounding box in the current frame
        predicted_centroid
        predicted_bbox
        
        % Previous centroid and bounding box
        prev_centroid
        prev_bbox
    end
    
    properties(Dependent)
        % The difference between last_xxx and prev_xxx is that after
        % assignment last_xxx will be updated to curr_xxx while prev_xxx
        % will always be the in the previous frame
        last_bbox
        last_centroid
    end
    
    methods
        % Constructor
        function self = FruitTrack(id, centroid, bbox, score, count)
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
            self.prev_centroid = centroid;
            self.prev_bbox = bbox;
            self.fruit_count = count;
        end
        
        % Predict new location of centroid and bounding box
        function predict(self, prev_corners, optical_flow, block_size)
            % Predict new centroid based on optical flow?
            % Get the previous bonding box and centroid on this track
            self.prev_centroid = self.last_centroid;
            self.prev_bbox = self.last_bbox;
            % Search for all the corners around the last centroid within
            % the block size
            if size(optical_flow, 1) == 1
                offset = optical_flow;
            else
                offset = calculateOffset(self.prev_centroid, ...
                                         prev_corners, ...
                                         optical_flow, block_size);
            end
            % Predict the centroid
            self.predicted_centroid = self.prev_centroid + offset;
                
            % Shift the bounding box so that its center is at the
            % predicted centroid
            self.predicted_bbox = ...
                [self.predicted_centroid - self.prev_bbox(3:4) / 2, ...
                 self.prev_bbox(3:4)];
        end
        
        % Update assigned track with new centroid and bounding box
        % If stabilize is bigger than 0, this will take the average of up
        % to that number of frames with the new one and append it to the
        % track
        function updateAssigned(self, centroid, bbox, count, stabilize)
            if nargin < 4, stabilize = 0; end
            
            if stabilize
                n = min(self.age, stabilize);
                w = mean([self.bboxes(end - n + 1:end, 3); bbox(3)]);
                h = mean([self.bboxes(end - n + 1:end, 4); bbox(4)]);
                self.bboxes(end + 1, :) = [centroid - [w, h]/2, w, h];
            else
                self.bboxes(end + 1, :) = bbox;
            end
            
            % Update age
            self.incAge();
            % Update count in this track
            self.fruit_count = horzcat(self.fruit_count, count);
            % Update visibility if this is an assigned track
            self.incVisibleCount();
            self.scores(end + 1, :) = 1; % detection score is 1
            self.centroids(end + 1, :) = centroid;
            % After all the previous assignment, calling last_bbox and
            % last_centroid will give you the current bbox and centroid
        end
        
        function updateUnassigned(self)
            self.incAge();
            self.centroids(end + 1, :) = self.predicted_centroid;
            self.bboxes(end + 1, :) = self.predicted_bbox;
            self.scores(end + 1, :) = 0;
            % After all the previous assignment, calling last_bbox and
            % last_centroid will give you the current bbox and centroid
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
if i <= 2
    offset = mean(flow, 1);
    return;
end

% Find the closest corner to the centroid
distances_squared = sum(bsxfun(@minus, corners, centroid).^2, 2);
[~, min_distance_ind] = min(distances_squared, [], 1);
offset = flow(min_distance_ind, :);

end

function inlier_ind = findCornersWithinBlock(centroid, corners, block_size)
block_size = block_size / 2;
inlier_ind = ...
    (centroid(1) < (corners(:, 1) + block_size)) & ...
    (centroid(1) > (corners(:, 1) - block_size)) & ...
    (centroid(2) < (corners(:, 2) + block_size)) & ...
    (centroid(2) > (corners(:, 2) - block_size));
end
