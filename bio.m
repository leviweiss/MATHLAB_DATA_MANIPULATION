% constants
global PPM;
PPM = 5;

% basic variables
selectedDataSample = data{1, 1};
numberOfScans = size(selectedDataSample.scan, 1);

% creating the sorted frame of data
maxScanSize = getMaxScanSize(numberOfScans, selectedDataSample.scan);
allPeaks = getMatrixWithAllPeaks(selectedDataSample, numberOfScans, maxScanSize);
allPeaksSorted = sort(allPeaks);

% creating the matched data
% matchedWithoutAnyProcessing = withoutAnyProcessing(allPeaksSorted, maxScanSize, numberOfScans, 1);
matchedWithConstantBuckets = processingWithConstantBuckets(allPeaksSorted, maxScanSize, numberOfScans);




% functions
function matchedMatrix = processingWithConstantBuckets(allPeaksSorted, maxScanSize, numberOfScans)

matchedMatrix = NaN(maxScanSize, numberOfScans);
bucketSize = 100;
numberOfBuckets = maxScanSize / bucketSize;
startingRow = 1;
endingRow = bucketSize;
startingCounter = 1;
for currBucketNumber = 1:numberOfBuckets
    allPeaksSortedCutted = allPeaksSorted(startingRow:endingRow, :);
    [bucketMatchedMatrix, startingCounter] = withoutAnyProcessing(allPeaksSortedCutted, bucketSize, numberOfScans, startingCounter);
    matchedMatrix(startingRow:endingRow, :) = bucketMatchedMatrix;
    startingRow = startingRow + bucketSize;
    endingRow = endingRow + bucketSize;
end

reminder = rem(maxScanSize, bucketSize);
if reminder ~= 0
    
end

end


function [matchedMatrix, counter] = withoutAnyProcessing(allPeaksSorted, maxScanSize, numberOfScans, startingCounter)

global PPM;
counter = startingCounter;
matchedMatrix = NaN(maxScanSize, numberOfScans);
    for column = 1:numberOfScans
        for row = 1:maxScanSize
            number = allPeaksSorted(row, column);
            counterInMatchedMatrix = matchedMatrix(row, column);
            if isnan(counterInMatchedMatrix) && ~isnan(number)
                matchedMatrix(row, column) = counter;
                lowerThreshold = number - number * PPM / 10 .^ 6;
                upperThreshold = number + number * PPM / 10 .^ 6;
                for columnInternal = (column+1):numberOfScans
                    for rowInternal = 1:maxScanSize
                        numberInternal = allPeaksSorted(rowInternal, columnInternal);
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



function allPeaks = getMatrixWithAllPeaks(selectedDataSample, numberOfScans, maxScanSize)

allPeaks = NaN(maxScanSize, numberOfScans);
for currScan = 1:numberOfScans
    currPeaks = selectedDataSample.scan(currScan).peaks.mz;
    delta = maxScanSize - size(currPeaks, 1);
    currPeaksWithCorrectSize = [currPeaks; NaN(delta, 1)];
    allPeaks(:, currScan) = currPeaksWithCorrectSize;
end
    
end


function maxSize = getMaxScanSize(numberOfScans, scans)

maxSize = 0;
for currScan = 1:numberOfScans
    currPeaks = scans(currScan).peaks.mz;
    currSize = size(currPeaks, 1);
    if currSize > maxSize
        maxSize = currSize;
    end
end

end