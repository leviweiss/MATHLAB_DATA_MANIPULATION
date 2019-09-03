allPeaks = getMatrixWithAllPeaks(data);

function allPeaks = getMatrixWithAllPeaks(data)
selectedDataSample = data{1, 1};
numberOfScans = size(selectedDataSample.scan, 1);
maxScanSize = getMaxScanSize(numberOfScans, selectedDataSample.scan);
allPeaks = zeros(maxScanSize, numberOfScans);
for currScan = 1:numberOfScans
    currPeaks = selectedDataSample.scan(currScan).peaks.mz;
    delta = maxScanSize - size(currPeaks, 1);
    currPeaksWithCorrectSize = [currPeaks; zeros(delta, 1)];
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