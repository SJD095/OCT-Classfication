function [siftDataIndex] = resolveSiftData(siftDataDir);

disp('resolve the siftDataIndex');

siftDataIndex = []

siftDataIndex.imnum = 0;
siftDataIndex.cname = {};
siftDataIndex.path = {};
siftDataIndex.nclass = 0;

subFolders = dir(siftDataDir);

for i = 1:length(subFolders)
	if ~strcmp(subFolders(i).name, '.DS_Store') && ~strcmp(subFolders(i).name, '.') && ~strcmp(subFolders(i).name, '..')
		siftDataIndex.nclass = siftDataIndex.nclass + 1;
		siftDataIndex.cname{siftDataIndex.nclass} = subFolders(i).name;

		siftData = dir(fullfile(siftDataDir, subFolders(i).name, '*.mat'));
        siftDataCount = length(siftData);
        siftDataIndex.imnum(siftDataIndex.nclass) = siftDataCount;

        for j = 1:siftDataCount,
            [filePath, siftDataName] = fileparts(siftData(j).name);
            siftDataPath = fullfile(siftDataDir, subFolders(i).name, strcat(siftDataName, '.mat'));
            siftDataIndex.path{siftDataIndex.nclass, j} = siftDataPath;
        end;
	end
end

disp('resolve siftDataIndex finish');

end