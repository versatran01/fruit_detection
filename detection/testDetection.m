%% testDetection.m
close all;
home;

viz = true;

scale = 0.7;
detector = @(image,s)detectFruit(model, image, s);
tester = DetectionTester(dataset, detector, viz);
tester.rotate = true;
tester.scale = scale;

times = [];
while tester.hasNext()
    tic;
    tester.processNext();
    times(end+1) = toc;
end

if ~viz
    fprintf('Processing time per image: %f\n', mean(times));
end

%% output results
% metrics = sum(tester.metrics);
% tp = metrics(1);
% fp = metrics(2);
% fn = metrics(3);
% 
% acc = tp / (tp+fp+fn);    % accuracy
% pre = tp / (tp + fp);     % precision
% rec = tp / (tp + fn);     % recall
% 
% fprintf('Accuracy: %f\n', acc);
% fprintf('Precision (fruit / total detections): %f\n', pre);
% fprintf('Recall (fruit / possible fruit): %f\n', rec);

