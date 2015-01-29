%% init.m
clear;
close all;
home;
dbstop error;

DATASET_PATH = '/Volumes/External/Datasets/booth_photo';

addpath('./descriptors');
addpath('./kmeans');
addpath('./labeling');
addpath('./scripts');
addpath('./tools');
addpath('./vendor/fkmeans');

%% Load dataset images
dataset_images = loadImages(DATASET_PATH,[],true);