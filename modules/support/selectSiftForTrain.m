function [siftForTrain] = selectSiftForTrain(siftDataIndex, trainedPatchCount, randomIndex, trainedPictureCount);

totalImageNumber = sum(trainedPictureCount);
patchPerImage = round(trainedPatchCount / totalImageNumber);
trainedPatchCount = patchPerImage * totalImageNumber;

load(siftDataIndex.path{1, 1});
sparseRepresent = size(feaSet.feaArr, 1);
siftForTrain = zeros(sparseRepresent, trainedPatchCount);

count = 0;

for i = 1:size(trainedPictureCount, 2)
	for j = 1:trainedPictureCount(i)
		siftDataPath = siftDataIndex.path{i, randomIndex(i, j)};
		load(siftDataPath);

        feaSet.feaArr(:, find(sum(feaSet.feaArr, 1) == 0)) = [];
        
		siftCount = size(feaSet.feaArr, 2);
		randomBook = randperm(siftCount);
		siftForTrain(:, count + 1:count + patchPerImage) = feaSet.feaArr(:, randomBook(1:patchPerImage));
		count = count + patchPerImage;
	end
end

end