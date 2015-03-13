function [ cost, gating ] = overlapCost( previous_bbox, predicted_bbox, CC )
%OVERLAPCOST Calculate overlap cost.
% `previous_bbox` is bounding boxes of last frame.
% `predicted_bbox` is bounding boxes of new frame.
% `CC` is detections of new frame.
cost = 1 - bboxOverlapRatio(predicted_bbox, CC.BoundingBox);
gating = true;
end
