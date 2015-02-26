%% init.m
clear;
close all;
home;

% Path for raw images
IMAGE_PATH = getenv('BOOTH_IMAGE_PATH');

% path for generated observation dataset
DATASET_PATH = getenv('BOOTH_DATASET_PATH');

addpath('./descriptors');
addpath('./kmeans');
addpath('./labeling');
addpath('./scripts');
addpath('./tools');
addpath('./train');
addpath('./vendor/fkmeans');

% Re-seed random
rng('shuffle', 'twister');

