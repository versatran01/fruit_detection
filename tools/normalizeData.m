function [ X ] = normalizeData( X )
%NORMALIZEDATA Normalize into range [0,1]
big = max(X(:));
small = min(X(:));
X = (X - small) / (big - small);
end