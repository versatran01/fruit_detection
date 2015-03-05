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
        
        predicted_bbox  % The predicted bounding box in the next frame
    end
    
    methods
        % Constructor
        function self = FruitTrack(id, centroid, bbox, score)
            self.id = id;
            self.color = 255*rand(1, 3);
            self.centroids = centroid;
            self.bboxes = bbox;
            self.age = 1;
            self.visible_count = 1;
            self.confidence = [score, score];
            self.predicted_bbox = bbox;
        end
        
        % Kalman filter prediction step
        function predicted_centroid = kfPredict(self)
            predicted_centroid = predict(self.kalman_filter);
        end
        
        % Kalman filter correction step
        function kfCorrect(self, centroid)
            correct(self.kalman_filter, centroid);
        end
        
        % Update assigned  track with new centroid and bounding box
        % If stabilize is bigger than 0, this will take the average of up
        % to that number of frames with the new one and append it to the
        % track
        function updateTrack(self, assigned, centroid, bbox, stabilize)
            if nargin < 5, stabilize = 0; end
            if ~assigned, stabilize = 0; end
            
            if assigned
                if stabilize
                    n = min(self.age, stabilize);
                    w = mean([self.bboxes(end - n + 1:end, 3); bbox(3)]);
                    h = mean([self.bboxes(end - n + 1:end, 4); bbox(4)]);
                    self.bboxes(end + 1, :) = [centroid - [w, h]/2, w, h];
                else
                    self.bboxes(end + 1, :) = bbox;
                end
                
                % Update visibility if this is an assigned track
                self.incVisibleCount();
                self.scores(end + 1, :) = 1; % detection score is 1
            else
                self.bboxes(end + 1, :) = self.predicted_bbox;
                self.scores(end + 1, :) = 0;  % detection score is 0
            end
            
            self.incAge();
            self.centroids(end + 1, :) = centroid;
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
        
        % Visualize this track, not impelemented
        function visualize(self)
        end
    end
    
end
