% --------------------------------------------------------
% Copyright (c) Zhiding Yu
% Licensed under The MIT License [see LICENSE for details]
%
% Intro:
% This script is used to:
% 1. Perform data augmentation on SBD with slightly thickened category-aware semantic edges generated multiple scales
% 2. Generate the .bin edge labels that can be read by CASENet for training
% 3. Create caffe filelists for the augmented data
% --------------------------------------------------------

function demo_preprocess()

clc; clear; close all;

%% Parameters
dataRoot = '../data_orig/benchmark_RELEASE/dataset';
genDataRoot = '../data_aug';
scaleSet = [0.5 0.75 1 1.25 1.5]; % Set of scales to be augmented on SBD
numCls = 20; % Number of defined semantic classes in SBD
radius = 2; % Defined search radius for label changes (related to edge thickness)
edge_type = 'regular';

%% Setup Parallel Pool
numWorker = 20; % Number of matlab workers for parallel computing
matlabVer = version('-release');
if( str2double(matlabVer(1:4)) > 2013 || (str2double(matlabVer(1:4)) == 2013 && strcmp(matlabVer(5), 'b')) )
    delete(gcp('nocreate'));
    parpool('local', numWorker);
else
    if(matlabpool('size')>0) %#ok<*DPOOL>
        matlabpool close
    end
    matlabpool open 8
end

%% Generate Preprocessed Dataset
setList = {'train', 'val'};
for setID = 1:length(setList)
    setName = setList{setID};
 
    % Create output directories
    if(strcmp(setName, 'train'))
        for scale = scaleSet
            % Train
            if(exist([genDataRoot '/image/train/scale_' num2str(scale)], 'file')==0)
                mkdir([genDataRoot '/image/train/scale_' num2str(scale)]);
            end
            if(exist([genDataRoot '/label/train/scale_' num2str(scale)], 'file')==0)
                mkdir([genDataRoot '/label/train/scale_' num2str(scale)]);
            end
        end
    else
        % Test (correspond to val set in the original SBD Dataset)
        if(exist([genDataRoot '/image/test'], 'file')==0)
            mkdir([genDataRoot '/image/test']);
        end
        if(exist([genDataRoot '/label/test'], 'file')==0)
            mkdir([genDataRoot '/label/test']);
        end
    end
    
    fidIn = fopen([dataRoot '/' setName '.txt']);
    fileName = fgetl(fidIn);
    fileList = cell(1,1);
    countFile = 0;
    while ischar(fileName)
        countFile = countFile + 1;
        fileList{countFile} = fileName;
        fileName = fgetl(fidIn);
    end
    fclose(fidIn);
    
    % Compute boundaries and write labels
    disp(['Computing ' setName ' set boundaries'])
    parfor_progress(countFile);
    parfor idxFile = 1:countFile
        fileName = fileList{idxFile};
        if(strcmp(setName, 'train'))
            scaleSetRun = scaleSet;
        else
            scaleSetRun = 1;
        end

        for idxScale = 1:length(scaleSetRun)
            scale = scaleSetRun(idxScale);
            img = imread([dataRoot '/img/' fileName '.jpg']);
            imgScale = imresize(img, scale, 'bicubic');
            gt = load([dataRoot '/cls/' fileName '.mat']);
            seg = gt.GTcls.Segmentation;
            segScale = imresize(seg, scale, 'nearest');
            [height, width, chn] = size(segScale);
            assert(chn==1, 'Incorrect label. Input label must have single channel.');
            labelEdge = zeros(height, width, 'uint32');
            for idx_cls = 1:numCls
                idxSeg = segScale == idx_cls;
                if(sum(idxSeg(:))~=0)
                    idxEdge = seg2edge(idxSeg, radius, [], edge_type);
                    labelEdge(idxEdge) = labelEdge(idxEdge) + 2^(idx_cls-1);
                end
            end

            if(strcmp(setName, 'train'))
                % Write image file
                imwrite(imgScale, [genDataRoot '/image/train/scale_' num2str(scale) '/' fileName '.png'], 'png')
                % Write label file
                fidLabel = fopen([genDataRoot '/label/train/scale_' num2str(scale) '/' fileName '.bin'], 'w');
                fwrite(fidLabel, labelEdge', 'uint32'); % Important! Transpose input matrix to become row major.
                fclose(fidLabel);
            else
                % Write image file
                imwrite(imgScale, [genDataRoot '/image/test/' fileName '.png'], 'png')
                % Write label file
                fidLabel = fopen([genDataRoot '/label/test/' fileName '.bin'], 'w');
                fwrite(fidLabel, labelEdge', 'uint32'); % Important! Transpose input matrix to become row major.
                fclose(fidLabel);
            end

        end
        parfor_progress();
    end
    parfor_progress(0);

    % Write file lists
    disp(['Creating ' setName ' set file lists'])
    if(strcmp(setName, 'train'))
        fidListTrainAug = fopen([genDataRoot '/list_train_aug.txt'], 'w');
        fidListTrain = fopen([genDataRoot '/list_train.txt'], 'w');
    else
        fidListTest = fopen([genDataRoot '/list_test.txt'], 'w');
    end
    
    parfor_progress(countFile);
    for idxFile = 1:countFile
        fileName = fileList{idxFile};
        if(strcmp(setName, 'train'))
            scaleSetRun = scaleSet;
        else
            scaleSetRun = 1;
        end
        for idxScale = 1:length(scaleSetRun)
            scale = scaleSetRun(idxScale);
            if(strcmp(setName, 'train'))
                % Add to train_aug list
                fprintf(fidListTrainAug, ['/image/train/scale_' num2str(scale) '/' fileName '.png '...
                    '/label/train/scale_' num2str(scale) '/' fileName '.bin\n']);
                if(scale == 1)
                    % Add to train list
                    fprintf(fidListTrain, ['/image/train/scale_' num2str(scale) '/' fileName '.png '...
                        '/label/train/scale_' num2str(scale) '/' fileName '.bin\n']);
                end
            else
                % Add to test list
                fprintf(fidListTest, ['/image/test/' fileName '.png /label/test/' fileName '.bin\n']);
            end
        end
        parfor_progress();
    end
    parfor_progress(0);
    
    if(strcmp(setName, 'train'))
        fclose(fidListTrainAug);
        fclose(fidListTrain);
    else
        fclose(fidListTest);
    end
end

end