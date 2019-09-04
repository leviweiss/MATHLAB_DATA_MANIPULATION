% constants
global PPM;
PPM = 5;
global numberOfSamples;
numberOfSamples = 6;
global selectedIndexOfScan;
selectedIndexOfScan = 1;
global data;

% preperation
data = load('matlab.mat');

% creating the matrix of data
maxScanSize = getMaxScanSize();
allPeaks = getMatrixWithAllPeaks(maxScanSize);
[allPeaksMZ, allPeaksIntensity] = seperateIntensityFromMZ(allPeaks);

% creating the matched data
% matchedWithoutAnyProcessing = withoutAnyProcessing(allPeaksMZ, maxScanSize / 2, 1);
matchedWithConstantBuckets = processingWithConstantBuckets(allPeaksMZ, maxScanSize / 2);




% functions
function [allPeaksMZ, allPeaksIntensity] = seperateIntensityFromMZ(allPeaks)
allPeaksMZ = allPeaks(1:2:end,:);
allPeaksIntensity = allPeaks(2:2:end,:);
end




function matchedMatrix = processingWithConstantBuckets(allPeaks, maxScanSize)

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
    bucketMatchedMatrix = withoutAnyProcessing(allPeaksCutted, bucketSize, startingCounter);
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
                    for rowInternal = 1:maxScanSize
                        numberInternal = allPeaks(rowInternal, columnInternal);
                        if ~isnan(numberInternal)
                            if (numberInternal >= lowerThreshold) && (numberInternal <= upperThreshold)
                                matchedMatrix(rowInternal, columnInternal) = counter;
                            end
                        end
                    end
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


function maxSize = getMaxScanSize()

global numberOfSamples;
global data;
maxSize = 0;
for currSample = 1:numberOfSamples
    currSize = data.data{1, currSample}.scan.peaksCount;
    currSize = currSize * 2;
    if currSize > maxSize
        maxSize = currSize;
    end
end

end