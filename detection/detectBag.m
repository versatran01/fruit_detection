function detectBag(topic)
% DETECTBAG Play a bag file with color images and apply detector

if nargin < 1, topic = '/color/image_raw'; end

[bagfile_name, bagfile_path] = uigetfile('*.bag', ...
	                                     'Select bag file');
if ~bag_file_name
	error('No bag file selected');
end

% Create a rosbag and check if this bag contains color
bag = ros.Bag([bagfile_path, bagfile_name]);
if ~nnz(find(bag.topics, topic))
	error('Bag file does not contain topic [%s]', topic)
end
bag.resetView(topic)

while bag.hasNext()
	% todo: read image topic from bag file

end


end
