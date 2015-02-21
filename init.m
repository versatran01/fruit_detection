%% init.m
clear;
close all;
home;

DATASET_PATH = '/Volumes/External/Datasets/booth_photo';

addpath('./descriptors');
addpath('./kmeans');
addpath('./labeling');
addpath('./scripts');
addpath('./tools');
addpath('./vendor/fkmeans');

%% Load dataset images
[dataset_images, dataset_paths] = loadImages(DATASET_PATH,[],...
    'verbose', true);
