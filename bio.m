% constants
global PPM;
PPM = 5;
global numberOfSamples;
numberOfSamples = 100;
global selectedIndexOfScan;
selectedIndexOfScan = 1;
global data;

% preperation
data = load('matlab.mat');

% creating the matrix of data
[maxScanSize, longestColumnIndex] = getMaxScanSize();
allPeaks = getMatrixWithAllPeaks(maxScanSize);
[allPeaksMZ, allPeaksIntensity] = seperateIntensityFromMZ(allPeaks);

% creating the matched data
% [matchedWithoutAnyProcessing, numberOfComponenets] = withoutAnyProcessing(allPeaksMZ, maxScanSize / 2, 1);
% [matchedWithConstantBuckets, numberOfComponenets] = processingWithConstantBuckets(allPeaksMZ, maxScanSize / 2);
[matchedWithoutAnyProcessing, numberOfComponenets] = processingWithRangesOfLongestColumn(allPeaksMZ, maxScanSize / 2, longestColumnIndex);



% computing the final matrix
numberOfComponenets = numberOfComponenets - 1;
finalMatrix = buildTheFinalMatrix(matchedWithoutAnyProcessing, allPeaksIntensity, numberOfComponenets);



% functions
function [matchedMatrix, counter] = processingWithRangesOfLongestColumn(allPeaks, maxScanSize, longestColumnIndex)
global numberOfSamples;
global PPM;
matchedMatrix = NaN(maxScanSize, numberOfSamples);
% lowMZ = data.data{1, currSample}.scan.lowMz;
% highMZ = data.data{1, currSample}.scan.highMz;
startingCounter = 1;
numberOfBuckets = 10;
startAndEndBucketMZ = getStartAndEndBucketMZ(allPeaks(:, longestColumnIndex), numberOfBuckets, maxScanSize);
startAndEndIndex = getStartAndEndIndex(allPeaks, startAndEndBucketMZ, numberOfBuckets);
counter = startingCounter;
for bucketNumber = 1:numberOfBuckets
    for column = 1:numberOfSamples
        startingIndex = 1;
        if bucketNumber ~= 1
            startingIndex = startAndEndIndex(bucketNumber, column) + 1;
        end
        rowsForIteration = startingIndex:startAndEndIndex(bucketNumber + 1, column);
        for row = rowsForIteration
            number = allPeaks(row, column);
            counterInMatchedMatrix = matchedMatrix(row, column);
            if isnan(counterInMatchedMatrix) && ~isnan(number)
                matchedMatrix(row, column) = counter;
                lowerThreshold = number - number * PPM / 10 .^ 6;
                upperThreshold = number + number * PPM / 10 .^ 6;
                for columnInternal = (column+1):numberOfSamples
                    startingIndexForChecking = 1;
                    if bucketNumber ~= 1
                        startingIndexForChecking = startAndEndIndex(bucketNumber, columnInternal) + 1;
                    end
                    rowsForChecking = startingIndexForChecking:startAndEndIndex(bucketNumber + 1, columnInternal);                    
                    columnData = allPeaks(rowsForChecking, columnInternal);
                    rowFound = find(columnData >= lowerThreshold & columnData <= upperThreshold);
                    if ~isempty(rowFound)
                        addToRowIndex = 0;
                        if bucketNumber ~= 1
                            addToRowIndex = startAndEndIndex(bucketNumber, columnInternal);
                        end
                        matchedMatrix(rowFound + addToRowIndex, columnInternal) = counter;
                    end
                end
                counter = counter + 1;
            end
        end
    end    
end
end


function startAndEndIndex = getStartAndEndIndex(allPeaks, startAndEndBucketMZ, numberOfBuckets)
global numberOfSamples;
global PPM;
startAndEndIndex = NaN(numberOfBuckets, numberOfSamples);
startAndEndIndex(1, :) = 1;
for bucketNumber = 1:numberOfBuckets
    startingMZ = startAndEndBucketMZ(bucketNumber, 1);
    thresholdFromBelow = startingMZ - startingMZ * PPM / 10 .^ 6;
    endingMZ = startAndEndBucketMZ(bucketNumber, 2);
    thresholdFromAbove = endingMZ + endingMZ * PPM / 10 .^ 6;
    for sampleNumber = 1:numberOfSamples
        lastRowMatched = find(allPeaks(:, sampleNumber) >= thresholdFromBelow & allPeaks(:, sampleNumber) <= thresholdFromAbove, 1, 'last');
        startAndEndIndex(bucketNumber + 1, sampleNumber) = lastRowMatched;
    end
end
end


function startAndEndBucketMZ = getStartAndEndBucketMZ(columnPeaks, numberOfBuckets, maxScanSize)
startAndEndBucketMZ = NaN(numberOfBuckets, 2);
numberOfRowsInBucket = floor(maxScanSize / numberOfBuckets);
reminder = rem(maxScanSize, numberOfBuckets);
startingRow = 1;
endingRow = startingRow + numberOfRowsInBucket - 1;
for row = 1:(numberOfBuckets - 1)
    startAndEndBucketMZ(row, 1) = columnPeaks(startingRow);
    startAndEndBucketMZ(row, 2) = columnPeaks(endingRow);
    startingRow = endingRow + 1;
    endingRow = startingRow + numberOfRowsInBucket - 1;
end

startAndEndBucketMZ(numberOfBuckets, 1) = columnPeaks(startingRow);
startAndEndBucketMZ(numberOfBuckets, 2) = columnPeaks(endingRow + reminder);
end


function finalMatrix = buildTheFinalMatrix(matchedMatrix, allPeaksIntensity, numberOfComponenets)

global numberOfSamples;
finalMatrix = NaN(numberOfComponenets, numberOfSamples);
for componentNumber = 1:numberOfComponenets
    [rowsArray, columnsArray] = find(matchedMatrix == componentNumber);
    for index = 1:length(rowsArray)
        finalMatrix(componentNumber, columnsArray(index)) = allPeaksIntensity(rowsArray(index), columnsArray(index));
    end
end

end


function [allPeaksMZ, allPeaksIntensity] = seperateIntensityFromMZ(allPeaks)
allPeaksMZ = allPeaks(1:2:end,:);
allPeaksIntensity = allPeaks(2:2:end,:);
end


function [matchedMatrix, startingCounter] = processingWithConstantBuckets(allPeaks, maxScanSize)

global numberOfSamples;
matchedMatrix = NaN(maxScanSize, numberOfSamples);
bucketSize = 100;
numberOfBuckets = maxScanSize / bucketSize;
startingRow = 1;
endingRow = bucketSize;
startingCounter = 1;
for currBucketNumber = 1:numberOfBuckets
    allPeaksCutted = allPeaks(startingRow:endingRow, :);
    [bucketMatchedMatrix, startingCounter] = withoutAnyProcessing(allPeaksCutted, bucketSize, startingCounter);
    matchedMatrix(startingRow:endingRow, :) = bucketMatchedMatrix;
    startingRow = startingRow + bucketSize;
    endingRow = endingRow + bucketSize;
end

reminder = rem(maxScanSize, bucketSize);
if reminder ~= 0
    endingRow = startingRow + reminder - 1;
    bucketSize = reminder;
    allPeaksCutted = allPeaks(startingRow:endingRow, :);
    [bucketMatchedMatrix, startingCounter] = withoutAnyProcessing(allPeaksCutted, bucketSize, startingCounter);
    matchedMatrix(startingRow:endingRow, :) = bucketMatchedMatrix;
end

end


function [matchedMatrix, counter] = withoutAnyProcessing(allPeaks, maxScanSize, startingCounter)

global PPM;
global numberOfSamples;
counter = startingCounter;
matchedMatrix = NaN(maxScanSize, numberOfSamples);
    for column = 1:numberOfSamples
        for row = 1:maxScanSize
            number = allPeaks(row, column);
            counterInMatchedMatrix = matchedMatrix(row, column);
            if isnan(counterInMatchedMatrix) && ~isnan(number)
                matchedMatrix(row, column) = counter;
                lowerThreshold = number - number * PPM / 10 .^ 6;
                upperThreshold = number + number * PPM / 10 .^ 6;
                for columnInternal = (column+1):numberOfSamples
                    columnData = allPeaks(:, columnInternal);
                    rowFound = find(columnData >= lowerThreshold & columnData <= upperThreshold);
                    if ~isempty(rowFound)
                        matchedMatrix(rowFound, columnInternal) = counter;
                    end
                    
                    
%                     for rowInternal = 1:maxScanSize
%                         numberInternal = allPeaks(rowInternal, columnInternal);
%                         if ~isnan(numberInternal)
%                             if (numberInternal >= lowerThreshold) && (numberInternal <= upperThreshold)
%                                 matchedMatrix(rowInternal, columnInternal) = counter;
%                                 break
%                             end
%                         end
%                     end
                    
                end
                counter = counter + 1;
            end
        end
    end
end


function allPeaks = getMatrixWithAllPeaks(maxScanSize)

global numberOfSamples;
global data;
global selectedIndexOfScan;
allPeaks = NaN(maxScanSize, numberOfSamples);
for currSample = 1:numberOfSamples
    currPeaks = data.data{1, currSample}.scan(selectedIndexOfScan).peaks.mz;
    delta = maxScanSize - size(currPeaks, 1);
    currPeaksWithCorrectSize = [currPeaks; NaN(delta, 1)];
    allPeaks(:, currSample) = currPeaksWithCorrectSize;
end
    
end


function [maxSize, index] = getMaxScanSize()

global numberOfSamples;
global data;
maxSize = 0;
index = 0;
for currSample = 1:numberOfSamples
    currSize = data.data{1, currSample}.scan.peaksCount;
    currSize = currSize * 2;
    if currSize > maxSize
        maxSize = currSize;
        index = currSample;
    end
end

end