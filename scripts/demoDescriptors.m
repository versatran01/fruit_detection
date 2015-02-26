%% demoDescriptors.m
init;

%% load images
images = loadImages(DATASET_PATH,[]);

%% load descriptors
load('descriptors/kmeans.mat');
displayPatches(models{1}.weights, true);

%% apply descriptors
filtered = applyDescriptors(images{1}, models{1});

%% preview image (14,41,12,25)
figure;
imshow(filtered(:,:,14));
