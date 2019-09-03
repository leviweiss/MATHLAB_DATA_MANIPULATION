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
matchedMatrix = withoutAnyProcessing(allPeaksSorted, maxScanSize, numberOfScans);






% functions
function matchedMatrix = withoutAnyProcessing(allPeaksSorted, maxScanSize, numberOfScans)
global PPM;
counter = 1;
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