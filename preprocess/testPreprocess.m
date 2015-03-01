function test_preprocess(dataset, i)

if i < 1 || i > length(dataset.images)
    error('%d should be in [1, %d]', i, length(dataset.images));
end

image = rgb2hsv(dataset.images{i});
% image = dataset.images{i};
selection = dataset.selections{i};
mask = dataset.masks{i};

pos_mask = createLargeMask(size(image), selection, mask, 'filter', 1);
neg_mask = createLargeMask(size(image), selection, mask, 'filter', 2);
[x_pos, x_neg] = sampleExamples(image, selection, mask, 0.5);
mean(x_pos, 1)
mean(x_neg, 1)
if length(x_neg) > 2 * length(x_pos)
    step = floor(length(x_neg)/length(x_pos));
    x_neg = x_neg(1:step:end, :);
end

figure()
subplot(2, 2, 1)
imshow(image(:,:,1))
title('original image')
subplot(2, 2, 2)

% for i = 1:length(x_pos)
%     plot3(x_pos(i, 1), x_pos(i, 2), x_pos(i, 3), '.', 'Color', x_pos(i,:), 'MarkerSize', 10)
%     hold on
% end
% 
% for i = 1:length(x_neg)
%     plot3(x_neg(i, 1), x_neg(i, 2), x_neg(i, 3), 'x', 'Color', x_neg(i,:), 'MarkerSize', 10)
%     hold on
% end
scatter3(x_pos(:,1), x_pos(:,2), x_pos(:,3), 'r.');
hold on
scatter3(x_neg(:,1), x_neg(:,2), x_neg(:,3), 'bo');
xlabel('r');
ylabel('g');
zlabel('b');

subplot(2,2,3)
h = imshow(image);
set(h, 'AlphaData', pos_mask);
title('positive mask')
subplot(2,2,4)
h = imshow(image);
set(h, 'AlphaData', neg_mask);
title('negative mask')
end
