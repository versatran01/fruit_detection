%% init.m
clear;
close all;
home;

% Path for raw images
DATASET_PATH = getenv('BOOTH_DATASET_PATH');

% path for generated observation dataset
OBSERVATION_PATH = getenv('BOOTH_OBSERVATION_PATH');

addpath('./descriptors');
addpath('./kmeans');
addpath('./labeling');
addpath('./predict');
addpath('./scripts');
addpath('./tools');
addpath('./train');
addpath('./vendor/fkmeans');
addpath('./vendor/liblinear/matlab')
addpath('./vendor/libsvm/matlab');

% Re-seed random
rng('shuffle', 'twister');

