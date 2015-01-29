%% init.m
clear;
close all;
home;
dbstop error;

DATASET_PATH = '/Users/gareth/Public/Dropbox/agriculture_state_of_art/Field Data/Selected images';

addpath('./descriptors');
addpath('./kmeans');
addpath('./labeling');
addpath('./scripts');
addpath('./tools');
addpath('./vendor/fkmeans');
