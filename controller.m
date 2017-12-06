%SDCS of SYSU Victor Sun
%2017.6.24 szy@sunzhongyang.com

%清除工作空间的所有变量、函数、MEX文件
clear all;
%清除全部命令窗口内容
clc;

%将存储各模块代码的文件夹加入工作路径
addpath(genpath('modules'));

%源图片路径，存储未经预处理的原始图片
sourceImageDir = fullfile('images', 'sourceImage');
%预处理图片路径，存储经过预处理的图片
pretreatedImageDir = fullfile('images', 'pretreatedImage');
%SIFT数据路径，存储所有预处理图片计算得到的SIFT值，方便重复使用
siftDataDir = fullfile('data', 'siftData');
%字典数据路径，存储计算得到的字典数据，方便重复使用
dictionaryDataDir = fullfile('data', 'dictionaryData');
%用于命名字典数据文件，指明字典类别
dictionaryCategory = 'OCT';

%是否运行图片预处理
runImagePretreatment = false;

%是否计算SIFT值
runCalculateSift = true;
%每个用于计算SIFT值的patch的大小，单位为像素
patchSize = 16;
%两个patch之间的间隔，单位为像素
gridSpacing = 8;
%默认图片最大尺寸
maxImageSize = 1000;
%计算过程中用到的阈值
nrmlThreshold = 1;

%是否重新随机选择一批图片
runRamdom = false;

%是否计算字典
runDictionaryTraining = true;
%是否使用SC编码默认字典
useSparseDictiroary = false;
%字典长度
dictionaryLength = 1024;
%用于训练字典的训练集图片数量
trainedPatchCount = 100000;
beta = 1e-5;
%训练字典迭代次数
iterationCount = 5;

%是否计算稀疏编码
runCalculateSparse = true;
%是否使用LLC编码
usingLLC = true;
%SPM分层参数
pyramid = [1, 2, 4];
%LLC选取近邻点的个数
LLCKnn = 15;
gamma = 0.15;
%如果SCKnn为0，则使用原始SC，否则使用改进后的SC
SCKnn = 0;

%是否运行SVM
runSvm = true;

%是否进行分类
runClassification = true;

%是否固定用于训练的图片个数
fixedCount = false;
%固定个数情况下用于训练的图片个数
fixedTrainedCount = 10;
%如果不固定训练图片的个数，则按比例从数据集中选取图片进行训练
trainedRate = 1 / 5;
%图片文件类型
filetype = 'jpg';

%获取数据集图片个数和训练集图片个数
[pictureCount, trainedPictureCount] = resolvePretreatedDir(pretreatedImageDir, fixedCount, fixedTrainedCount, trainedRate);

%根据已有参数信息，命名各个数据文件
randomFile = fullfile(dictionaryDataDir, 'randomIndex');
dictionaryFile = fullfile(dictionaryDataDir, strcat('dict_', dictionaryCategory, '_', num2str(dictionaryLength)));
sparseCodingFile = fullfile(dictionaryDataDir, strcat('Sparse_', dictionaryCategory, '_', num2str(dictionaryLength), '.mat'));
svmFile = fullfile(dictionaryDataDir, 'svm.mat');

%进行分类的迭代次数，迭代多次则可取得更精确的结果
repeatIterationCount = 10;
%构造用于记录分类结果的数据结构
accuracyRatingResult = zeros(repeatIterationCount + 1, size(pictureCount, 2));
%是否在运行结束后关机
shutdownAfterExecute = false;

%构造用于记录时间结果的数据结构
timesResult = zeros(repeatIterationCount + 1, 3);

if runImagePretreatment
    %记录运行图片预处理的起始时间
    imageTreatmentTimeStart = clock;

    %运行图片预处理，获得有关统计信息
    [averageImagePretreatmentTime, averageWidth, averageHeight] = OCTImagePretreatment(sourceImageDir, pretreatedImageDir);

    %计算预处理部分花费的时间，并存储有关信息
    timeData.imageTreatmentTime = etime(clock, imageTreatmentTimeStart);
    save('imagePretreatmentLog.mat', 'averageImagePretreatmentTime',  'averageImageWidth',  'averageImageHeight');
else
    disp('skip image pretreatment');
    timeData.imageTreatmentTime = 'None';
end

if runCalculateSift
    %记录运行计算SIFT值的起始时间
    calculateSIFTTimeStart = clock;

    %计算SIFT值
    [siftDataIndex, lengthStat, patchNumberToatal, patchNumberPerImage] = CalculateSiftDescriptor(pretreatedImageDir, siftDataDir, gridSpacing, patchSize, maxImageSize, nrmlThreshold);

    %计算得到SIFT值所花费的时间，并存储有关信息
    timeData.SIFTTime = etime(clock, calculateSIFTTimeStart);
else
    siftDataIndex = resolveSiftData(siftDataDir);
    timeData.SIFTTime = 'None';
end

%多次分类，结果取平均值
for repeatIteration = 1:repeatIterationCount
    disp(['================================================== ', num2str(repeatIteration), ' ==================================================']);

    if runRamdom
        %构造存储随机图片的数据结构
        randomIndex = zeros(size(pictureCount, 2), max(pictureCount));
        %随机选取图片
        for indexCount = 1:size(pictureCount, 2)
            randomIndex(indexCount, 1:pictureCount(indexCount)) = randperm(pictureCount(indexCount), pictureCount(indexCount));
        end
        %存储随机选取图片有关信息的数据结构
        save(strcat(randomFile, '_',  num2str(repeatIteration), '.mat'), 'randomIndex');
    else
        load(strcat(randomFile, '_', num2str(repeatIteration)));
    end

    if runDictionaryTraining
        %记录计算字典的起始时间
        dictTimeStart = clock;

        %根据随机信息得到训练集图片，并选取这部分图片的SIFT值
        siftForTrain = selectSiftForTrain(siftDataIndex, trainedPatchCount, randomIndex, trainedPictureCount);

        %如果默使用SC默认字典
        if useSparseDictiroary
            [dictionary, trainedSparseCoding, statistic] = reg_sparse_coding(siftForTrain, dictionaryLength, eye(dictionaryLength), beta, gamma, iterationCount);
        else
        %使用kmeans字典进行训练
            [idx, dictionary] = kmeans(siftForTrain', dictionaryLength, 'Start', 'sample', 'Replicates', 5, 'Display', 'iter', 'MaxIter', 40);
            %得到的字典需要转置以符合后续函数的要求
             dictionary = dictionary';
        end

        %计算用于训练字典的时间，并保存
        timesResult(repeatIteration, 1) = etime(clock, dictTimeStart);
        save(strcat(dictionaryFile, '_', num2str(repeatIteration), '.mat'), 'dictionary');
    else
        load(strcat(dictionaryFile, '_', num2str(repeatIteration)));
        %计算字典长度
        dictionaryLength = size(dictionary, 2);
    end

    if runCalculateSparse
        sparseTimeStart = clock;

        sparseRepresent = sum(dictionaryLength * pyramid .^ 2);
        trainedPictureSparseRepresent = zeros(sparseRepresent, sum(trainedPictureCount));
        trainedPictureLabel = zeros(sum(trainedPictureCount), 1);

        disp('calculating trained pictures sparse representation');

        tmpPictureCount = 0;

        for i = 1:size(trainedPictureCount, 2)
            for j = 1:trainedPictureCount(i)
                tmpPictureCount = tmpPictureCount + 1;
                if mod(tmpPictureCount, 50),
                    fprintf('.');
                else
                    fprintf('.\n');
                end

                imagePath = siftDataIndex.path{i, randomIndex(i, j)};
                load(imagePath);

                if usingLLC
                    trainedPictureSparseRepresent(:, tmpPictureCount) = LLCPooling(feaSet, dictionary, pyramid, LLCKnn);
                elseif SCKnn
                    trainedPictureSparseRepresent(:, tmpPictureCount) = sc_approx_pooling(feaSet, dictionary, pyramid, gamma, SCKNN);
                else
                    trainedPictureSparseRepresent(:, tmpPictureCount) = sc_pooling(feaSet, dictionary, pyramid, gamma);
                end

                trainedPictureLabel(tmpPictureCount) = feaSet.label;
            end
        end

        timesResult(repeatIteration, 2) = etime(clock, sparseTimeStart);
    else
        load(sparseCodingFile);
    end

    save(sparseCodingFile, 'trainedPictureLabel', 'trainedPictureSparseRepresent');

    if runSvm
        lambda = 0.1;
        svmTimeStart = clock;

        [w, b, class_name] = li2nsvm_multiclass_lbfgs(trainedPictureSparseRepresent', trainedPictureLabel, lambda);

        timesResult(repeatIteration, 3) = etime(clock, svmTimeStart);
        save(svmFile, 'w', 'b', 'class_name');
    else
        load(svmFile);
    end

    if runClassification
        parfor i = 1:length(trainedPictureCount)
            for j = trainedPictureCount(i) + 1:pictureCount(i)
                picturePath = siftDataIndex.path{i, randomIndex(i, j)};
                picturePath = strrep(picturePath, siftDataDir, pretreatedImageDir);
                picturePath = strrep(picturePath, 'mat', filetype);

                classificationImage = imread(picturePath);

                disp(strcat('classification picture: ', picturePath));

                [pictureSparseCoding, lengthStatistic] = CalculateSiftDescriptorSingle(classificationImage, gridSpacing, patchSize, maxImageSize, nrmlThreshold);

                if usingLLC
                    pictureSparseRepresentation = LLCPooling(pictureSparseCoding, dictionary, pyramid, LLCKnn);
                elseif SCKnn
                    pictureSparseRepresentation = sc_approx_pooling(pictureSparseCoding, dictionary, pyramid, gamma, SCKNN);
                else
                    pictureSparseRepresentation = sc_pooling(pictureSparseCoding, dictionary, pyramid, gamma);
                end

                [C, Y] = li2nsvm_multiclass_fwd(pictureSparseRepresentation', w, b, class_name);
                disp(strcat('result: ', siftDataIndex.cname(C)));

                if C == i
                    accuracyRatingResult(repeatIteration, i) = accuracyRatingResult(repeatIteration, i) + 1;
                end
            end
        end
    else
        disp('skip run classification');
    end
end

for k = 1:repeatIterationCount
    accuracyRatingResult(k, :) = accuracyRatingResult(k, :) ./ (pictureCount - trainedPictureCount);
end
accuracyRatingResult(repeatIterationCount + 1, :) = sum(accuracyRatingResult) / repeatIterationCount;
timesResult(repeatIterationCount + 1, :) = sum(timesResult) / repeatIterationCount;

save('allWorkspaceResult');

%如果选择运行结束后关闭计算机，则发出关机指令
if shutdownAfterExecute
    system('shutdown -s');
end
