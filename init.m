%% init.m
clear;
close all;
home;

DATASET_PATH = '/home/chao/Workspace/bag/booth_feb2';

addpath('./descriptors');
addpath('./kmeans');
addpath('./labeling');
addpath('./scripts');
addpath('./tools');
addpath('./vendor/fkmeans');

% Re-seed random
rng('shuffle', 'twister');

