function [pictureSparseRepresentation] = LLCPooling(siftData, dictionary, pyramid, knn)

LLCCodes = fastLLCCoding(dictionary', siftData.feaArr', knn);
LLCCodes = LLCCodes';

dictionaryLength = size(dictionary, 2);
siftDataNumber = size(siftData, 2);

imageWidth = siftData.width;
imageHeight = siftData.height;

pyramidHeight = length(pyramid);
pBins = pyramid .^ 2;
tBins = sum(pBins);

pictureSparseRepresentation = zeros(dictionaryLength, tBins);
binId = 0;

for i = 1:pyramidHeight
	nBins = pBins(i);

	binWidth = imageWidth / pyramid(i);
	binHeight = imageHeight / pyramid(i);

	xBelong = ceil(siftData.x / binWidth);
    yBelong = ceil(siftData.y / binHeight);
    finalBelong = (yBelong - 1) * pyramid(i) + xBelong;

    for j = 1:nBins,     
        binId = binId + 1;
        finalIndex = find(finalBelong == j);
        if isempty(finalIndex),
            continue;
        end      
        pictureSparseRepresentation(:, binId) = max(LLCCodes(:, finalIndex), [], 2);
    end
end

pictureSparseRepresentation = pictureSparseRepresentation(:);
pictureSparseRepresentation = pictureSparseRepresentation./sqrt(sum(pictureSparseRepresentation .^ 2));

end