%% testDetection.m
close all;

detector = @(image)detectFruit(model, image);
tester = DetectionTester(dataset, detector);
tester.setCurrentImage(3);

while tester.hasNext()
    tester.processNext();
    pause;
end
