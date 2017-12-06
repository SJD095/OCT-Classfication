function [originalImage] = cutLetterBox(originalImage, halfWindowWidth)

windowWidth = halfWindowWidth * 2;
[row, col] = size(originalImage);

windowImage = zeros(row + windowWidth, col + windowWidth);
windowImage(halfWindowWidth + 1:halfWindowWidth + row, halfWindowWidth + 1: halfWindowWidth + col) = originalImage;

for i = 1:row
    for j = 1:col
        if windowImage(i + halfWindowWidth, j + halfWindowWidth) == 255
            whiteCount = 0;
            for tmpRow = i - halfWindowWidth:i + halfWindowWidth
                for tmpCol = j - halfWindowWidth: j + halfWindowWidth
                    if windowImage(tmpRow + halfWindowWidth, tmpCol + halfWindowWidth) == 255
                        whiteCount = whiteCount + 1;
                    end
                end
            end
            if whiteCount >= 2 * halfWindowWidth * halfWindowWidth
                originalImage(i, j) = 0;
            end
        end
    end
end

end