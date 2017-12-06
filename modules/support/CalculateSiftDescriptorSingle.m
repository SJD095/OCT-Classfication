function [pictureSparseCoding, lengthStatistic] = CalculateSiftDescriptorSingle(classificationImage, gridSpacing, patchSize, maxImageSize, nrmlThreshold)

if ndims(classificationImage) == 3,
    classificationImage = rgb2gray(classificationImage);
end

classificationImage = im2double(classificationImage);
classificationImage = cutLetterBox(classificationImage, 10);

[imageHeight, imageWidth] = size(classificationImage);

remainX = mod(imageWidth - patchSize, gridSpacing);
remainY = mod(imageHeight - patchSize, gridSpacing);

offsetX = floor(remainX / 2) + 1;
offsetY = floor(remainY / 2) + 1;

[gridX, gridY] = meshgrid(offsetX:gridSpacing:imageWidth - patchSize + 1, offsetY:gridSpacing:imageHeight - patchSize + 1);
siftValues = sp_find_sift_grid(classificationImage, gridX, gridY, patchSize, 0.8);
[siftValues, siftLength] = sp_normalize_sift(siftValues, nrmlThreshold);

pictureSparseCoding.feaArr = siftValues';
pictureSparseCoding.x = gridX(:) + patchSize / 2 - 0.5;
pictureSparseCoding.y = gridY(:) + patchSize / 2 - 0.5;
pictureSparseCoding.width = imageWidth;
pictureSparseCoding.height = imageHeight;
lengthStatistic = hist(siftLength, 100);

end