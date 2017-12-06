function [outputImage] = flattenImage(tmpImage, openedImage, columnTop, columnBottom, skipThreshold)

[tmpImageRows, tmpImageCols] = size(tmpImage);
finalTmpImage = zeros(tmpImageRows, tmpImageCols);
finalOpenedImage = zeros(tmpImageRows, tmpImageCols);

xHigth = sum(openedImage);
higthThreshold = max(xHigth) / 5;
xCoordinateTag = ones(1, tmpImageCols);

for i = 1:tmpImageCols
    if xHigth(i) < skipThreshold || xHigth(i) < higthThreshold
        xCoordinateTag(i) = 0;
    end
end

xCoordinateTagCount = sum(xCoordinateTag, 2);
yMiddleCoordinate = zeros(1, xCoordinateTagCount, 'double');
yBottomCoordinate = zeros(1, xCoordinateTagCount, 'double');

xCoordinateCounter = 0;

for i = 1:tmpImageCols
    if xCoordinateTag(i) == 1
        xCoordinateCounter = xCoordinateCounter + 1;
    else
        continue;
    end

    yCoordinateSum = 0;
    yCoordinateCounter = 0;

    for j = columnTop:columnBottom
        if openedImage(j, i) == 1
            yCoordinateSum = yCoordinateSum + j;
            yCoordinateCounter = yCoordinateCounter + 1;
        end
    end

    yMiddleCoordinate(1, xCoordinateCounter) = yCoordinateSum / yCoordinateCounter;
end

xCoordinateCounter = 0;
for i = 1:tmpImageCols
    if xCoordinateTag(i) == 1
        xCoordinateCounter = xCoordinateCounter + 1;
    else
        continue;
    end

    tmpCoordinate = columnBottom;
    while(openedImage(tmpCoordinate, i) ~= 1)
        tmpCoordinate = tmpCoordinate - 1;
    end

    yBottomCoordinate(1, xCoordinateCounter) = tmpCoordinate;
end

xCoordinate = find(xCoordinateTag);

linearFitMiddle = polyfit(xCoordinate, yMiddleCoordinate, 1);
linearFitBottom = polyfit(xCoordinate, yBottomCoordinate, 1);

parabaloFitMiddle = polyfit(xCoordinate, yMiddleCoordinate, 2);
parabaloFitBottom = polyfit(xCoordinate, yBottomCoordinate, 2);

%?????????????????
if parabaloFitMiddle(1, 1) > 0
    usingLinearFit = linearFitBottom;
    usingParabaloFit = parabaloFitBottom;
    usingDataSet = yBottomCoordinate;
else
    usingLinearFit = linearFitMiddle;
    usingParabaloFit = parabaloFitMiddle;
    usingDataSet = yMiddleCoordinate;
end

LinearFitValue = polyval(usingLinearFit, xCoordinate);
ParabaloFitValue = polyval(usingParabaloFit, xCoordinate);

LinearFitCoef = corrcoef(LinearFitValue, usingDataSet);
ParabaloFitCoef = corrcoef(ParabaloFitValue, usingDataSet);

if LinearFitCoef(1, 2) >= ParabaloFitCoef(1, 2) || usingParabaloFit(1, 1) >= 0
    linearAngle = atand(usingLinearFit(1, 1));

    finalTmpImage = imrotate(tmpImage, linearAngle, 'bilinear', 'crop');

    finalOpenedImage = imrotate(openedImage, linearAngle, 'bilinear', 'crop');
else
    parabaloAxsis = (-usingParabaloFit(1, 2)) / (2 * usingParabaloFit(1, 1));

    if parabaloAxsis <= 1
        vertex = usingParabaloFit(1, 1) + usingParabaloFit(1, 2) + usingParabaloFit(1, 3)
    elseif parabaloAxsis >= tmpImageCols
        vertex = usingParabaloFit(1, 1) * tmpImageCols * tmpImageCols + usingParabaloFit(1, 2) * tmpImageCols + usingParabaloFit(1, 3)
    else
        vertex = (4 * usingParabaloFit(1, 1) * usingParabaloFit(1, 3) - usingParabaloFit(1, 2) * usingParabaloFit(1, 2)) / (4 * usingParabaloFit(1, 1));
    end

    vector = zeros(1, tmpImageCols);

    for col = 1:tmpImageCols
        yCoordinateValue = usingParabaloFit(1, 1) * col * col + usingParabaloFit(1, 2) * col + usingParabaloFit(1, 3);

        vector(1, col) = round(vertex - yCoordinateValue);
    end

    for row = 1:tmpImageRows
        for col = 1:tmpImageCols
            if row - vector(1, col) >= 1
                finalTmpImage(row, col) = tmpImage(row - vector(1, col), col);
                finalOpenedImage(row, col) = openedImage(row - vector(1, col), col);
            end
        end
    end
end

stop = false;
for row = 1:tmpImageRows
    for col = 1:tmpImageCols
        if finalOpenedImage(row, col) == 1
            columnTop = row;
            stop = true;
            break;
        end
    end

    if stop
        break;
    end
end

stop = true;
for row = tmpImageRows:-1:1
    for col = 1:tmpImageCols
        if finalOpenedImage(row, col) == 1
            columnBottom = row;
            stop = true;
            break;
        end
    end

    if stop
        break;
    end
end

outputImage = imcrop(finalTmpImage, [1 columnTop - 5 (tmpImageCols - 1) (columnBottom - columnTop + 10)]);

end