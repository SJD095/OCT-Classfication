function [tmpImage, openedImage, columnTop, columnBottom, timeResults] = directlyOptimizeImage(originalImage, skipThreshold, imageName, timeResults)

[originalImageRows, originalImageCols] = size(originalImage);

segmentatedImage = imread(fullfile('images/segmentatedImage/', imageName));
segmentatedImage = imresize(segmentatedImage, [originalImageRows, originalImageCols]);

for i = 1:originalImageRows
    for j = 1:originalImageCols
        if segmentatedImage(i, j) >= 128
            segmentatedImage(i, j) = 1;
        else
            segmentatedImage(i, j) = 0;
            originalImage(i, j) = 0;
        end
    end
end

tmpImage = zeros(originalImageRows + 200, originalImageCols);
tmpImage(101:100 + originalImageRows, :) = originalImage;

[tmpImageRows, tmpImageCols] = size(tmpImage);
           
openedImage = zeros(originalImageRows + 200, originalImageCols);
openedImage(101:100 + originalImageRows, :) = segmentatedImage;

columnTop = 1;
columnBottom = tmpImageRows;
deepth = zeros(1, tmpImageCols);

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