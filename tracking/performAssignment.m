function [ matches ] = performAssignment( cost )
%PERFORMASSIGNMENT Given MxN `cost` matrix, find the optimal assignment of
% rows to columns.
%
% Matches is a Kx2 vector, where K = min(M,N). The values in the first
% column correspond to rows while the second column correspond to columns.

assignment = munkres(cost); % hungarian assignment method
idx = assignment ~= 0;
matches = [find(idx); assignment(idx)]';
end
