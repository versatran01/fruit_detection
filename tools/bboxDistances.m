function [ dist ] = bboxDistances( bboxes )
%BBOXDISTANCES Calculate perpendicular distance between bounding boxes.

halfw = bboxes(:,3)*0.5;
halfh = bboxes(:,4)*0.5;
midx = bboxes(:,1) + halfw;
midy = bboxes(:,2) + halfh;

distx = pdist2(midx, midx, 'cityblock');
disty = pdist2(midy, midy, 'cityblock');

% subtract width
distx = bsxfun(@minus, distx, halfw);
distx = bsxfun(@minus, distx, halfw');
distx = max(distx, 0);

% subtract heights
disty = bsxfun(@minus, disty, halfh);
disty = bsxfun(@minus, disty, halfh');
disty = max(disty, 0);

dist = max(distx,disty);

end
