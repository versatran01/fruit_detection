function tracker = processBagfile(path, scale, model_name, duration, verbose)
%PROCESSBAGFILE Process a bagfile.
% todo: call this from test_tracker...
if nargin < 5, verbose = false; end;
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

assert(duration(1) <= duration(2), 'Invalid duration');

bag = ros.Bag(path);
duration_unix = duration + bag.time_begin;

if duration(2) == 0
    bag.resetView(bag.topics);
else
    bag.resetView(bag.topics, duration_unix(1), duration_unix(2));
end

topic_name = '/color/image_rect_color';
idx = ismember(bag.topics, topic_name);
if ~nnz(idx)
    error('Did not find topic %s - did you rectify this bag file?', topic_name);
end

load(['models/', model_name]);

image_count = 0;
tracker = FruitTracker(verbose);  % hide gui

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
    tracker.track(CC, image, msg.header.stamp, counts);
    elapsed_time = toc;
    
    if verbose
        fprintf('frame: %g, Time per iteration: %.3f, total counts: %.1f.\n', ...
                image_count, elapsed_time, tracker.total_fruit_counts);
    end
end
tracker.finish();
end
