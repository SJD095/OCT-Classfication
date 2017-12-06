function [averageImagePretreatmentTime, averageImageWidth, averageImageHeight, heightVector]= OCTImagePretreatment(sourceImageDir, outputImageDir)

%?BM3D?????????
addpath('BM3D');

imageType = 'jpg';
outputPictureType = 1;
skipThreshold = 70;
halfWindowWidth = 10;
        timeResults = zeros(1,4);
totalImageCount = 0;
pictureWidthSum = 0;
pictureHeightSum = 0;
pictureTimeSum = 0;

disp('Image Pretreatment Start');

%??????????????????
sourceImageFolders = dir(sourceImageDir);

%?????????????
for sourceImageFolderCounter = 1:length(sourceImageFolders)
    %????????????
    sourceImageFolderNamge = sourceImageFolders(sourceImageFolderCounter).name;

    if ~strcmp(sourceImageFolderNamge, '.DS_Store') && ~strcmp(sourceImageFolderNamge, '.') && ~strcmp(sourceImageFolderNamge, '..')

        %?????????????????
        images = dir(fullfile(sourceImageDir, sourceImageFolderNamge, strcat('*.', imageType)));

        imageCount = length(images);
        totalImageCount = totalImageCount + imageCount;
        outPutImageFolder = fullfile(outputImageDir, sourceImageFolderNamge);

        %??????????????????
        if ~isdir(outPutImageFolder)
            mkdir(outPutImageFolder)
        end

        for imageCounter = 1:imageCount
            imagePath = fullfile(sourceImageDir, sourceImageFolderNamge, images(imageCounter).name);
startTime = clock;
            disp(imagePath);

            %????????
            originalImage = imread(imagePath);

            pretreatmentStartTime = clock;
            
            if ndims(originalImage) == 3
                originalImage = rgb2gray(originalImage);
            end

            originalImage = cutLetterBox(originalImage, halfWindowWidth);

            %???double?????MATLAB????
            originalImage = im2double(originalImage);
optimizeTime = clock;
            [tmpImage, openedImage, columnTop, columnBottom,timeResults] = generateOptimizeImage(originalImage, outputPictureType, skipThreshold,sourceImageFolderNamge, images(imageCounter).name,timeResults);
timeResults(1,2) = timeResults(1,2) + etime(clock, optimizeTime);
flattenTime = clock;
            [outputImage] = flattenImage(tmpImage, openedImage, columnTop, columnBottom, skipThreshold);
timeResults(1,3) = timeResults(1,3) + etime(clock, flattenTime);
            imwrite(outputImage, fullfile(outPutImageFolder, strcat('aligned_', images(imageCounter).name)));

            [outputWidth, outputHeight] = size(outputImage);
            pictureWidthSum = pictureWidthSum + outputWidth;
            pictureHeightSum = pictureHeightSum + outputHeight;
            pictureTimeSum = pictureTimeSum + etime(clock, pretreatmentStartTime);
timeResults(1,1) = timeResults(1,1) + etime(clock, startTime);            
        end
    end
end

averageImgFlattentime = pictureTimeSum / totalImageCount;
averageHeight = pictureHeightSum / totalImageCount;
averageWidth = pictureWidthSum / totalImageCount;
save('result.mat','timeResults');
end
