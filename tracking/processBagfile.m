function [ tracker ] = processBagfile( path, scale, model_name, duration )
%PROCESSBAGFILE Process a bagfile.
% todo: call this from test_tracker...
if nargin < 4, 
    duration = [0.0 double(intmax())];
end
if nargin < 3
    % default to support vector classification
    model_name = 'cs_svc';
end
if scale <= 0 || scale > 1
    error('Scale must be in range (0,1]');
end

assert(duration(1) < duration(2), 'Invalid duration');

bag = ros.Bag(path);
duration = duration + bag.time_begin;
bag.resetView(bag.topics, duration(1), duration(2));

topic_name = '/color/image_rect_color';
idx = ismember(bag.topics, topic_name);
if ~nnz(idx)
    error('Did not find topic %s - did you rectify this bag file?', topic_name);
end

load(['models/', model_name]);

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
    elapsed_time = toc;
    
    fprintf('frame: %g, Time per iteration: %.3f, total counts: %.1f.\n', ...
            image_count, elapsed_time, tracker.total_fruit_counts);
end
tracker.finish();
end
