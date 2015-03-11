%% testDetectionConsistency.m
% You should have a dataset loaded before running this.
close all;

load('models/cs_svc.mat');

image_index = 30;
image = dataset.images{image_index};
image = rot90(image,1);

scale = 0.5;
niters = 300;

image = imresize(image,scale);

totals_bbox = [];
totals = [];
masks = [];
%time = CTimeleft(niters);
%    time.timeleft();
tic;
for i=1:niters
    [CC,counts,circles] = detectFruit(model,image,scale);
    total = sum(counts);
    totals(i) = total;
    totals_bbox(i) = CC.size();
    masks(:,:,i) = CC.image;
end

fprintf('- Finished %i iterations in %.3fs\n', niters, toc);
fprintf('- Mean count is %f\n', mean(totals));
fprintf('- Std. dev is %f\n', std(totals));
fprintf('- Mean box count is %f\n', mean(totals_bbox));
fprintf('- Std. dev (box) is %f\n', std(totals_bbox));
