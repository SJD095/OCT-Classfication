function [tmpImage, openedImage, columnTop, columnBottom,timeResults] = generateOptimizeImage(originalImage, outputPictureType, skipThreshold,sourceImageFolderNamge, imageName,timeResults)

[originalImageRows, originalImageCols] = size(originalImage);

%?????????????
tmpImage = zeros(originalImageRows + 200, originalImageCols);
tmpImage(101:100 + originalImageRows, :) = originalImage;

[tmpImageRows, tmpImageCols] = size(tmpImage);

%??BM3D?????????
%BM3DImage = medfilt2(tmpImage, [15, 15]);
BM3Dstart = clock;
%sigma = 20;
%randn('seed', 0);
%BM3DImage = BM3DImage + (sigma/255)*randn(size(BM3DImage));

%[NA, BM3DImage] = BM3D(1, BM3DImage, sigma);
%save(fullfile('BM3Dcache',sourceImageFolderNamge ,strcat(imageName, '.mat')), 'BM3DImage');
timeResults(1,4) = timeResults(1,4) + etime(clock, BM3Dstart);
load(fullfile('BM3Dcache',sourceImageFolderNamge ,strcat(imageName, '.mat')));
%??????????????
[level, EM] = graythresh(BM3DImage);
binaryImage = im2bw(BM3DImage, level);

binaryImageForTreatment = im2bw(BM3DImage, level * 0.7);

%??????????
closeElement = strel('disk', 70);
closedImage = imclose(binaryImage, closeElement);

%??????????
openElement = strel('disk', 5);
openedImage = imopen(closedImage, openElement);

columnTop = 1;
columnBottom = tmpImageRows;
deepth = zeros(1, tmpImageCols);

%????????????????????
stop = false;

for i = 1:tmpImageRows
    for j = 1:tmpImageCols
        if openedImage(i, j) == 1 && i > deepth(j)
            for tmpDeepth = 0:skipThreshold
                if openedImage(i + tmpDeepth, j) == 0
                    deepth(j) = i + tmpDeepth;
                    break;
                end
            end
            if tmpDeepth == skipThreshold
                columnTop = i;
                stop = true;
            end
        end
        if stop
            break;
        end
    end
    if stop
        break;
    end
end

stop = false;

for i = tmpImageRows:-1:1
    for j = 1:tmpImageCols
        if openedImage(i, j) == 1
            columnBottom = i;
            stop = true;
            break;
        end
    end
    if stop
        break;
    end
end

openedImage(1:max(columnTop - 1, 1), :) = 0;
openedImage(min(columnBottom + 1, tmpImageRows):tmpImageRows, :) = 0;

%?????????
switch(outputPictureType)
case 1
    for i = 1:tmpImageRows
        for j = 1:tmpImageCols
            if openedImage(i, j) == 0
                tmpImage(i, j) = 0;
            end
        end
    end

case 2
    for i = 1:tmpImageRows
        for j = 1:tmpImageCols
            if binaryImageForTreatment(i, j) == 0 || openedImage(i, j) == 0
                tmpImage(i, j) = 0;
            end
        end
    end

case 3
    tmpImage = binaryImageForTreatment;
    for i = 1:tmpImageRows
        for j = 1:tmpImageCols
            if openedImage(i, j) == 0
                tmpImage(i, j) = 0;
            end
        end
    end

case 4
    tmpImage = BM3DImage;
    for i = 1:tmpImageRows
        for j = 1:tmpImageCols
            if openedImage(i, j) == 0
                tmpImage(i, j) = 0;
            end
        end
    end
end

if strcmp(imageName,'cropped_159.jpg')
    save('159.mat');
end

end