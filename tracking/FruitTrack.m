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
        
        % A Kalman filterobject used for motion-based tracking which tracks
        % the center point of the object in image
        kalman_filter
        
        age  % The number of frames since the track was initialized
        
        % The total number of frames in which the object was detected
        visible_count   
        
        % A pair of two numbers to represent how confident we trust the
        % track. It stores the maximum and the average detection scores in
        % hte past within a predefined time window
        confidence
        
        predicted_centroid
        predicted_bbox  % The predicted bounding box in the next frame
    end
    
    properties(Dependent)
        last_bbox
    end
    
    methods
        % Constructor
        function self = FruitTrack(id, centroid, bbox, score)
            self.id = id;
            self.color = 255 * rand(1, 3);
            self.centroids = centroid;
            self.bboxes = bbox;
            self.age = 1;
            self.visible_count = 1;
            self.confidence = [score, score];
            self.predicted_centroid = centroid;
            self.predicted_bbox = bbox;
            self.kalman_filter = ...
                    configureKalmanFilter('ConstantVelocity', centroid, ...
                                          [10, 5], [5, 5], 1);
        end
        
        % Kalman filter prediction step
        function kfPredict(self)
            self.predicted_centroid = predict(self.kalman_filter);
            % Get the last bonding box on this track
            last_bbox = self.last_bbox;
            % Shift the bounding box so that its center is at the
            % predicted centroid
            self.predicted_bbox = ...
                [self.predicted_centroid - last_bbox(3:4)/2, ...
                 last_bbox(3:4)];
        end
        
        % Kalman filter correction step
        function kfCorrect(self, measured_centroid)
            correct(self.kalman_filter, measured_centroid);
        end
        
        % Update assigned track with new centroid and bounding box
        % If stabilize is bigger than 0, this will take the average of up
        % to that number of frames with the new one and append it to the
        % track
        function updateAssigned(self, centroid, bbox, stabilize)
            if nargin < 4, stabilize = 0; end
            
            if stabilize
                n = min(self.age, stabilize);
                w = mean([self.bboxes(end - n + 1:end, 3); bbox(3)]);
                h = mean([self.bboxes(end - n + 1:end, 4); bbox(4)]);
                self.bboxes(end + 1, :) = [centroid - [w, h]/2, w, h];
            else
                self.bboxes(end + 1, :) = bbox;
            end
            
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
        
        % Visualize this track, not impelemented
        function visualize(self)
        end
    end
    
end
