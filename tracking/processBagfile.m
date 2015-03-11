function [ tracker ] = processBagfile( path, scale, model )
%PROCESSBAGFILE Process a bagfile.
% todo: call this from test_tracker...
if nargin < 3
    % default to support vector classification
    load('models/cs_svc.mat');
end
if scale <= 0 || scale > 1
    error('Scale must be in range (0,1]');
end

bag = ros.Bag(path);
bag.resetView(bag.topics);

topic_name = '/color/image_rect_color';
idx = find(ismember(bag.topics, topic_name));
if isempty(idx)
    error('Did not find topic %s - did you rectify this bag file?', topic_name);
end

image_count = 0;
tracker = FruitTracker(false);  % hide gui

while bag.hasNext()
    [msg, meta] = bag.read();
    if ~strcmp(meta.topic, topic_name)
        continue; 
    end
    image_count = image_count + 1;
    
    image = rosImageToMatlabImage(msg);
    image = imresize(image, scale);
    image = flipud(image);
    
    tic;
    [CC,counts,~] = detectFruit(model, image, scale);
    tracker.track(CC, image, counts);
    T = toc;
    
    fprintf('Time per iteration: %.3f\n', T);
end
tracker.finish();
end
