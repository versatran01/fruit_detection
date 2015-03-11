%% testDetectionConsistency.m
% You should have a dataset loaded before running this.
close all;

load('models/cs_svc.mat');

image_index = 200;
image = dataset.images{image_index};
image = rot90(image,1);

scale = 0.5;
niters = 100;

image = imresize(image,scale);

totals = [];
time = CTimeleft(niters);
for i=1:niters
    [CC,counts,circles] = detectFruit(model,image,scale);
    total = sum(counts);
    totals(end+1) = total;
    time.timeleft();
end

fprintf('- Mean count is %f\n', mean(totals));
fprintf('- Std. dev is %f\n', std(totals));
