function [LLCCoding] = fastLLCCoding(dictionary, siftData, knn, betaValue)

if ~exist('betaValue', 'var') || isempty(betaValue),
	beta = 1e-4;
end

siftData(:, find(sum(siftData, 1) == 0)) = [];

siftDataCount = size(siftData, 1);
dictionaryLength = size(dictionary, 1);

siftDataSum = sum(siftData .* siftData, 2);
dictionarySum = sum(dictionary .* dictionary, 2);

correlation  = repmat(siftDataSum, 1, dictionaryLength)- 2 * siftData * dictionary' + repmat(dictionarySum', siftDataCount, 1);
index = zeros(siftDataCount, knn);
for i = 1:siftDataCount
	c = correlation(i,:);
	[sortedC, idx] = sort(c, 'ascend');
	index(i, :) = idx(1:knn);
end

LLCCoding = zeros(siftDataCount, dictionaryLength);
identityMatrix = eye(knn, knn);
for i = 1:siftDataCount
	idx = index(i, :);
	z = dictionary(idx, :) - repmat(siftData(i, :), knn, 1);
	C = z*z';
	C = C + identityMatrix * beta * trace(C);
	w = C\ones(knn, 1);
	w = w/sum(w);
	LLCCoding(i, idx) = w';
end

end