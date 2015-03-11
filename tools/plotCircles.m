function [ h ] = plotCircles( circles )
%PLOTCIRCLES Plot a cell array of circles.
if ~iscell(circles)
    error('circles should be a cell array');
end
h = [];
for i=1:numel(circles)
    X = circles{i};
    for j=1:size(X,1)
        pts = createCirclePoints(X(j,1:2), X(j,3), 20);
        h(end+1) = plot(pts(:,1), pts(:,2));
        set(h(end),'LineWidth',2);
        set(h(end),'Color',[1 0.1 0.75]);
    end
end
end
