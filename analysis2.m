%% Some constants needed for analysis
% need to add the day relative to the first day to this vector each time a new data set is added.
% testDays = [0,3,5,7,10,12,14,17,19];
% cell array with vectors of each of the plant numbers for cherry tomatoes
% for each treatment.
cherryPlants = {[1:8],[1:8],[1:8],[1:6],[1:6]};
beefPlants = {[9:14],[9:14],[9:14],[7:9],[7:11]};
speciesPlants = {cherryPlants,beefPlants};

%% Extract all data to matlab
%allData = csvread('D:\System Folders\Documents\GitHub\tomato-data-analysis\consolidatedData.csv',1,0);
dataFile = uigetfile('*.csv');
allData = csvread(dataFile,1,0);

% dataMultiArray contains the data collected for each day with indices
% {device, plant, head, truss, test day, count type}
dataMultiArray = zeros(5,14,2,5,20,8);

day1 = datetime(allData(1,12:14));
testDates = day1;

for i = 1:size(allData,1)
    % Each row contains
    %         DEVICE
    %         PLANT
    %         TRUSS
    %         TOTAL FLOWERS
    %         BUDDING
    %         TRANSITION
    %         OPEN
    %         CLOSED
    %         SETTING
    %         BROKEN
    %         OUT_OF_SEQUENCE
    %         YEAR
    %         MONTH
    %         DAY
    row = allData(i,:);
    
    % get the date from the last 3 values in the row.
    testDate = datetime(row(length(row)-2:length(row)));
    
    % if the data is from a day we haven't seen yet, add it to the test
    % days vector.
    if isempty(find(testDates==testDate,1))
        testDates = [testDates testDate];
    end
    % Data sets will be organized by {device, plant, head, truss, day}
    if row(4)==0 && length(testDates) > 1
        if dataMultiArray(row(1),row(2),floor(row(3)/100),rem(row(3),100),length(testDates)-1,1) ~= 0
            display('Data missing for:')
            display([row(1:3) row(length(row)-2:length(row))])
        end
    end
    
    if row(4)>0
        % if there is already data entered for this row, flag it.
        if dataMultiArray(row(1),row(2),floor(row(3)/100),rem(row(3),100),length(testDates),1) ~= 0
            % display('Data already exists for:')
            % display([row(1:3) row(length(row)-2:length(row))])
        % otherwise enter the data for that day
        else     
            dataMultiArray(row(1),row(2),floor(row(3)/100),rem(row(3),100),length(testDates),:) = row(4:11);
        end
    end
end

testDays = split(between(day1,testDates),'d')+1;

%% Get percentage set for a truss over time.
% percentSet will contain a vector of [day, %set, %broken] entries.
% totals will contain a vector of [day, total flowers, total set,
% total broken]
% organized by {device, plant, head, truss, day, [day, %set, %broken]}
percentSetBrok = zeros(5,14,2,5,20,3);
totals = zeros(5,14,2,5,20,4);

for device = 1:size(dataMultiArray,1)
    for plant = 1:size(dataMultiArray,2)
        for head = 1:2
            for truss = 1:size(dataMultiArray,4)
                for day = 1:size(dataMultiArray,5)
                    dayData = dataMultiArray(device,plant,head,truss,day,:);
                    if dayData(1) ~= 0
                        percentSet = 100*dayData(6)/dayData(1);
                        percentBrok = 100*dayData(7)/dayData(1);
                        totalFlowers = dayData(1);
                        totalSet = dayData(6);
                        totalBroken = dayData(7);
                        percentSetBrok(device,plant,head,truss,day,:) = [testDays(day), percentSet, percentBrok];
                        totals(device,plant,head,truss,day,:) = [testDays(day), totalFlowers, totalSet, totalBroken];
                    end
                end
            end
        end
    end
end

%% Plot percent set over time.
close all

% averageSetBrok contains a 2D vector for each (device, truss) combination that contains the
% [day, average %set, average %brok] for each day.
% trussTotals contains a 2D vector for each (device, truss) combination
% that contains the [total flowers, total set, total broken] for each day
averageSetBrok = zeros(2,5,5,length(testDays),2);
trussTotals = zeros(2,5,5,length(testDays),3);
% set 1 is cherry, set 2 is beefsteak
for species = 1:2
    for device = 1:5
        for truss = 1:size(dataMultiArray,4)
            for day = 1:length(testDays)
                % tempPercent contains all percent data recorded for the
                % (device, truss, day)
                tempPercent = [];
                tempTotal = [];
                plantSet = speciesPlants{species};
                for plant = plantSet{device};
                    for head = 1:2
                        if percentSetBrok(device,plant,head,truss,day,1) ~= 0
                                tempPercent = [tempPercent; percentSetBrok(device,plant,head,truss,day,2:end)];
                                tempTotal = [tempTotal; totals(device,plant,head,truss,day,2:end)];
                        end
                    end
                end
                tempAv = mean(tempPercent,1);
                tempTrussTotal = sum(tempTotal,1);
                if ~isempty(tempAv)
                    averageSetBrok(species,device,truss,day,:) = tempAv;
                    trussTotals(species,device,truss,day,:) = tempTrussTotal;
                end
            end
        end
    end
end

%% Plot data for truss 1, cherry
figure
grid on
hold on
colors = ['y','m','c','r','g'];

% change this to plot a different truss level.
truss = 1;
species = 1;

for i = 1:size(averageSetBrok,2)
    errorbar(testDays,averageSetBrok(species,i,truss,:,1),zeros(length(averageSetBrok(species,i,truss,:,1)),1),averageSetBrok(species,i,truss,:,2),'LineWidth',2)
end
legend('Air Pulsing','Sound Radiation','Contact','Untreated','Bee Pollinated','Location','northwest')
title('Cherry Tomatoes: Rate of Setting')
xlabel('Test day')
ylabel('Percent set')
xlim([0, testDays(length(testDays))+1]);

%% Plot data for truss 1, beefsteak
figure
grid on
hold on
colors = ['y','m','c','r','g'];

% change this to plot a different truss level.
truss = 1;
species = 2;

for i = 1:size(averageSetBrok,2)
    errorbar(testDays,averageSetBrok(species,i,truss,:,1),zeros(length(averageSetBrok(species,i,truss,:,1)),1),averageSetBrok(species,i,truss,:,2),'LineWidth',2)
end
legend('Air Pulsing','Sound Radiation','Contact','Untreated','Bee Pollinated','Location','northwest')
title('Beefsteak Tomatoes: Rate of Setting')
xlabel('Test day')
ylabel('Percent set')
xlim([0, testDays(length(testDays))+1]);

%% Plot totals data, cherry
figure
grid on
hold on
colors = ['y','m','c','r','g'];

truss = 1;
species = 2;
totalType = 1; % 1 for total flowers, 2 for total set, 3 for total broken

for i = 1:size(averageSetBrok,2)
    plot(testDays,squeeze(trussTotals(species,i,truss,:,totalType)),'LineWidth',2)
end
legend('Air Pulsing','Sound Radiation','Contact','Untreated','Bee Pollinated','Location','northwest')
title('Cherry Tomatoes: Total Flowers')
xlabel('Test day')
ylabel('Number of flowers')
xlim([0, testDays(length(testDays))+1]);

