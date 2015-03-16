%% calculateCountRange.m
load('row_1_to_26');

N = numel(row_1_to_26); % num rows

all_counts = [];
for i=1:N
    counts = row_1_to_26(i).counts_per_image;
    counts = counts{1};
    all_counts = vertcat(all_counts, [counts.counts]');
end

med = median(all_counts);
low = 0;
high = med + iqr(all_counts);

idx = all_counts <= high & all_counts >= low;
fprintf('Low: %f, high: %f\n', low, high);
fprintf('In range: %i / %i\n', nnz(idx), numel(idx));
