function [beta] = sc_approx_pooling(feaSet, B, pyramid, gamma, knn)
%================================================
%多分块SPM程序
%===============================================

dSize = size(B, 2);%the number of bases
nSmp = size(feaSet.feaArr, 2);%interesting points of the image
img_width = feaSet.width;
img_height = feaSet.height;
idxBin = zeros(nSmp, 1);

sc_codes = zeros(dSize, nSmp);

% compute the local feature for each local feature
D = feaSet.feaArr'*B;
IDX = zeros(nSmp, knn);
for ii = 1:nSmp,
    d = D(ii, :);
    [dummy, idx] = sort(d, 'descend');
    IDX(ii, :) = idx(1:knn);% knn IDX??????????????????????????????????????????????
end

for ii = 1:nSmp,
    y = feaSet.feaArr(:, ii);
    idx = IDX(ii, :);
    BB = B(:, idx);%??????????????????????????????????????????????
    sc_codes(idx, ii) = feature_sign(BB, y, 2*gamma);
end

sc_codes = abs(sc_codes);

% spatial levels
pLevels = length(pyramid);
% spatial bins on each level
pBins = pyramid.^2;%[1 4 16]
% total spatial bins
tBins = sum(pBins)+10;%21

beta = zeros(dSize, tBins);
bId = 0;

for iter1 = 1:pLevels,
    
    nBins = pBins(iter1);
    
    wUnit = img_width / pyramid(iter1);
    hUnit = img_height / pyramid(iter1);
    
    % find to which spatial bin each local descriptor belongs
    xBin = ceil(feaSet.x / wUnit);
    yBin = ceil(feaSet.y / hUnit);
    idxBin = (yBin - 1)*pyramid(iter1) + xBin;
    idxBin_annex1 = idxBin;
    if iter1==2
        nBins=nBins+1;
        [hh,ww]=size(idxBin);
        idxBin_annex1(ceil(hh*0.25):ceil(hh*0.75),ceil(ww*0.25):ceil(ww*0.75))=5;
    elseif iter1 ==3
            nBins= nBins+9;
            [hh,ww]=size(idxBin);
            idxBin_annex1(ceil(hh*0.125):ceil(hh*0.375),ceil(ww*0.125):ceil(ww*0.375))=17;
            idxBin_annex1(ceil(hh*0.125):ceil(hh*0.375),ceil(ww*0.375):ceil(ww*0.625))=18;
            idxBin_annex1(ceil(hh*0.125):ceil(hh*0.375),ceil(ww*0.625):ceil(ww*0.875))=19;
            idxBin_annex1(ceil(hh*0.375):ceil(hh*0.625),ceil(ww*0.125):ceil(ww*0.375))=20;
            idxBin_annex1(ceil(hh*0.375):ceil(hh*0.625),ceil(ww*0.375):ceil(ww*0.625))=21;
            idxBin_annex1(ceil(hh*0.375):ceil(hh*0.625),ceil(ww*0.625):ceil(ww*0.875))=22;
            idxBin_annex1(ceil(hh*0.625):ceil(hh*0.875),ceil(ww*0.125):ceil(ww*0.375))=23;
            idxBin_annex1(ceil(hh*0.625):ceil(hh*0.875),ceil(ww*0.375):ceil(ww*0.625))=24;
            idxBin_annex1(ceil(hh*0.625):ceil(hh*0.875),ceil(ww*0.625):ceil(ww*0.875))=25;
    end
    
    if iter1==1
        for iter2 = 1:nBins,
            bId = bId + 1;
            sidxBin = find(idxBin == iter2);%search by column,return all indices of elements in idxBin which value equals to iter2
            if isempty(sidxBin),
                continue;
            end
            beta(:, bId) = max(sc_codes(:, sidxBin), [], 2);%max pooling,beta = zeros(dSize, tBins);
        end
    elseif iter1==2
        for iter2 = 1:nBins,
            bId = bId + 1;
            if iter2==5
                 sidxBin = find(idxBin_annex1 == iter2);%search by column,return all indices of elements in idxBin which value equals to iter2
                if isempty(sidxBin),
                    continue;
                end
                beta(:, bId) = max(sc_codes(:, sidxBin), [], 2);%max pooling,beta = zeros(dSize, tBins);
            else
                sidxBin = find(idxBin == iter2);%search by column,return all indices of elements in idxBin which value equals to iter2
                if isempty(sidxBin),
                    continue;
                end
                beta(:, bId) = max(sc_codes(:, sidxBin), [], 2);%max pooling,beta = zeros(dSize, tBins);
            end
        end
    else
        for iter2 = 1:nBins,
            bId = bId + 1;
            if  iter2>=17
                 sidxBin = find(idxBin_annex1 == iter2);%search by column,return all indices of elements in idxBin which value equals to iter2
                if isempty(sidxBin),
                    continue;
                end
                beta(:, bId) = max(sc_codes(:, sidxBin), [], 2);%max pooling,beta = zeros(dSize, tBins);
            else
                sidxBin = find(idxBin == iter2);%search by column,return all indices of elements in idxBin which value equals to iter2
                if isempty(sidxBin),
                    continue;
                end
                beta(:, bId) = max(sc_codes(:, sidxBin), [], 2);%max pooling,beta = zeros(dSize, tBins);
            end
        end
    end
end

if bId ~= tBins,
    error('Index number error!');
end

beta = beta(:);% convert into one dimension
beta = beta./sqrt(sum(beta.^2));
