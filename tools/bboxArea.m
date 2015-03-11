function [ area ] = bboxArea( bboxes )
%BBOXAREA Areas of bounding boxes.
area = bboxes(:,3) .* bboxes(:,4);
end
