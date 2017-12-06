function [pictureCount, trainedPictureCount] = resolvePretreatedDir(pretreatedImageDir, fixedCount, fixedTrainedCount, trainedRate)

subFolders = dir(pretreatedImageDir);
folderCount = 0;

for i = 1:length(subFolders)
	if ~strcmp(subFolders(i).name, '.DS_Store') && ~strcmp(subFolders(i).name, '.') && ~strcmp(subFolders(i).name, '..')
		folderCount = folderCount + 1;
	end
end

pictureCount = zeros(1, folderCount);
trainedPictureCount = zeros(1, folderCount);
k = 0;

for i = 1:length(subFolders)
	if ~strcmp(subFolders(i).name, '.DS_Store') && ~strcmp(subFolders(i).name, '.') && ~strcmp(subFolders(i).name, '..')
		k = k + 1;
		images = dir(fullfile(pretreatedImageDir, subFolders(i).name));
		imageCount = 0;

		for j = 1:length(images)
			if ~strcmp(images(j).name, '.DS_Store') && ~strcmp(images(j).name, '.') && ~strcmp(images(j).name, '..')
				imageCount = imageCount + 1;
			end
		end

		pictureCount(k) = imageCount;
	end
end

for i = 1:folderCount
	if fixedCount
		trainedPictureCount(i) = fixedTrainedCount;
	else
		trainedPictureCount(i) = max(1, min(ceil(pictureCount(i) * trainedRate), pictureCount(i)));
	end
end

end