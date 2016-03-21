%% Some constants needed for analysis
% need to add the day relative to the first day to this vector each time a new data set is added.
testDays = [0,3,5,7,10,12,14,17,19];
% cell array with vectors of each of the plant numbers for cherry tomatoes
% for each treatment.
cherryPlants = {[1:8],[1:8],[1:8],[1:6],[1:6]};
beefPlants = {[9:14],[9:14],[9:14],[7:9],[7:11]};
speciesPlants = {cherryPlants,beefPlants};

%% Extract all data to matlab
%allData = csvread('D:\System Folders\Documents\GitHub\tomato-data-analysis\consolidatedData.csv',1,0);
allData = csvread('Documents/BlackCrow/tomato-data-analysis/consolidatedData.csv',1,0);

dataSet = {};

for i = 1:size(allData,1)
    row = allData(i,:);
    if row(1) == 5
        row(1) = 4;
    elseif row(1) == 6
        row(1) = 5;
    end
    % Data sets will be organized by {device, plant, head, truss, day}
    if row(4)>0
        dataSet{row(1),row(2),floor(row(3)/100),rem(row(3),100),row(length(row))} = row(4:length(row)-1);
    end
end

%% Get percentage set for a truss over time.
% percentSet will contain a vector of [day, %set, %broken] entries.
% totals will contain a vector of [day, total flowers, total set,
% total broken]
% organized by {device, plant, head, truss}
percentSetBrok = {};
totals = {};

for device = 1:size(dataSet,1)
    for plant = 1:size(dataSet,2)
        for head = 1:2
            for truss = 1:size(dataSet,4)
                percentSetBrok{device,plant,head,truss} = [];
                totals{device,plant,head,truss} = [];
                for day = 1:size(dataSet,5)
                    dayData = dataSet{device,plant,head,truss,day};
                    if ~isempty(dayData)
                        percentSet = 100*dayData(length(dayData)-1)/dayData(1);
                        percentBrok = 100*dayData(length(dayData))/dayData(1);
                        totalFlowers = dayData(1);
                        totalSet = dayData(length(dayData)-1);
                        totalBroken = dayData(length(dayData));
                        percentSetBrok{device,plant,head,truss} = [percentSetBrok{device,plant,head,truss}; day, percentSet, percentBrok];
                        totals{device,plant,head,truss} = [totals{device,plant,head,truss}; day, totalFlowers, totalSet, totalBroken];
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
% that contains the [day, total flowers, total set, total broken] for each day
averageSetBrok = {};
trussTotals = {};
% set 1 is cherry, set 2 is beefsteak
for species = 1:2
    for device = 1:size(dataSet,1)
        for truss = 1:size(dataSet,4)
            averageSetBrok{species,device,truss} = [];
            trussTotals{species,device,truss} = [];
            for day = 1:length(testDays)
                % tempPercent contains all percent data recorded for the
                % (device, truss, day)
                tempPercent = [];
                tempTotal = [];
                plantSet = speciesPlants{species};
                for plant = plantSet{device};
                    for head = 1:2
                        if ~isempty(percentSetBrok{device,plant,head,truss})
                            tempInd = find(percentSetBrok{device,plant,head,truss}(:,1)==day);
                            if ~isempty(tempInd)
                                tempPercent = [tempPercent; percentSetBrok{device,plant,head,truss}(tempInd,2:3)];
                                tempTotal = [tempTotal; totals{device,plant,head,truss}(tempInd,2:4)];
                            end
                        end
                    end
                end
                tempAv = mean(tempPercent,1);
                tempTrussTotal = sum(tempTotal,1);
                if ~isempty(tempAv)
                    averageSetBrok{species,device,truss} = [averageSetBrok{species,device,truss}; [testDays(day),tempAv]];
                    trussTotals{species,device,truss} = [trussTotals{species,device,truss};[testDays(day),tempTrussTotal]];
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
    errorbar(averageSetBrok{species,i,truss}(:,1),averageSetBrok{species,i,truss}(:,2),zeros(length(averageSetBrok{species,i,truss}(:,1)),1),averageSetBrok{species,i,truss}(:,3),'LineWidth',2)
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
    errorbar(averageSetBrok{species,i,truss}(:,1),averageSetBrok{species,i,truss}(:,2),zeros(length(averageSetBrok{species,i,truss}(:,1)),1),averageSetBrok{species,i,truss}(:,3),'LineWidth',2)
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
species = 1;
totalType = 3; % 2 for total flowers, 3 for total set, 4 for total broken

for i = 1:size(averageSetBrok,2)
    plot(trussTotals{species,i,truss}(:,1),trussTotals{species,i,truss}(:,totalType),'LineWidth',2)
end
    legend('Air Pulsing','Sound Radiation','Contact','Untreated','Bee Pollinated','Location','northwest')
    title('Cherry Tomatoes: Total Flowers')
    xlabel('Test day')
    ylabel('Number of flowers')
xlim([0, testDays(length(testDays))+1]);

