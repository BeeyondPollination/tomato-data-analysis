%% Some constants needed for analysis
% need to add the day relative to the first day to this vector each time a new data set is added.
% testDays = [0,3,5,7,10,12,14,17,19];
% cell array with vectors of each of the plant numbers for cherry tomatoes
% for each treatment.
cherryPlants = {[1:8],[1:8],[1:8],[1:6],[1:6]};
fourReps = {[1:2],[3:4],[4:5],[6:8]};
cherryPlantReps = {fourReps,fourReps,fourReps};
beefPlants = {[9:14],[9:14],[9:14],[7:9],[7:11]};
threeReps = {[9:10],[11:12],[13:14],0};
beefPlantReps = {threeReps,threeReps,threeReps};
speciesPlants = {cherryPlants,beefPlants};
speciesPlantReps = {cherryPlantReps,beefPlantReps};
dataLabels = {'Set', 'Broken', 'Harvestable', 'Unpollinated'};
speciesLabels = {'Cherry','Beefsteak'};

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

% Check for missing
missingData = [];
for device = 1:size(dataMultiArray,1)
    for plant = 1:size(dataMultiArray,2)
        for head = 1:2
            for truss = 1:size(dataMultiArray,4)
                recorded = false;
                for day = 1:length(testDates)
                    if ~recorded && dataMultiArray(device,plant,head,truss,day,1) ~= 0
                        recorded = true;
                    elseif recorded && dataMultiArray(device,plant,head,truss,day,1) == 0
                        missingData = [missingData; device,plant,head,truss,day];
                    end
                end
            end
        end
    end
end
missingData = sortrows(missingData,5);
letters = ['A' 'B' 'C' 'E' 'F'];

missingFile = fopen('D:\System Folders\Documents\GitHub\tomato-data-analysis\missingData.txt','w');
missingDataEasy = {};
for i = 1:size(missingData,1)
    entry = missingData(i,:);
    missingDataEasy{i} = (strcat(letters(entry(1)), num2str(entry(2)), '_', num2str(entry(3)*100+entry(4)), '_', datestr(testDates(entry(5)))));
    fprintf(missingFile, '%s\n', missingDataEasy{i});
end
fclose(missingFile);

testDays = split(between(day1,testDates,'Days'),'d')+1;

%% Get percentage set for a truss over time.
% percentSet will contain a vector of [day, %set, %broken, %harvestable, %unpollinated] entries.
% totals will contain a vector of [day, total flowers, total set,
% total broken, total harvestable, total unpollinated]
% organized by {device, plant, head, truss, day, [day, %set, %broken, %harvestable]}
percents = zeros(5,14,2,5,20,5);
totals = zeros(5,14,2,5,20,6);

for device = 1:size(dataMultiArray,1)
    for plant = 1:size(dataMultiArray,2)
        for head = 1:2
            for truss = 1:size(dataMultiArray,4)
                for day = 1:size(dataMultiArray,5)
                    dayData = dataMultiArray(device,plant,head,truss,day,:);
                    if dayData(1) ~= 0
                        percentSet = 100*dayData(6)/dayData(1);
                        percentBrok = 100*dayData(7)/dayData(1);
                        percentHarvestable = 100*(dayData(6)-dayData(8))/dayData(1);
                        percentUnpollinated = 100*dayData(8)/dayData(1);
                        totalFlowers = dayData(1);
                        totalSet = dayData(6);
                        totalBroken = dayData(7);
                        totalHarvestable = dayData(6)-dayData(8);
                        totalUnpollinated = dayData(8);
                        percents(device,plant,head,truss,day,:) = [testDays(day), percentSet, percentBrok, percentHarvestable, percentUnpollinated];
                        totals(device,plant,head,truss,day,:) = [testDays(day), totalFlowers, totalSet, totalBroken, totalHarvestable, totalUnpollinated];
                    end
                end
            end
        end
    end
end


%% Calculate average percent set for each replication block
close all

% averageRepPercents contains a 2D vector for each (device, rep, truss) combination that contains the
% [day, average %set, average %brok, average %harvestable, average %unpollinated, std dev %set, std dev %broken, std dev %harvestable, std dev %unpollinated] for each day.
avgRepPercents = zeros(2,5,5,4,length(testDays),8);
% set 1 is cherry, set 2 is beefsteak
for species = 1:2
    for device = 1:3
        for truss = 1:size(dataMultiArray,4)
            for rep = 1:4
                for day = 1:length(testDays)
                    % tempPercent contains all percent data recorded for the
                    % (device, truss, rep, day)
                    tempPercent = [];
                    tempTotal = [];
                    speciesSet = speciesPlantReps{species};
                    plantSet = speciesSet{device};
                    for plant = plantSet{rep};
                        if plant ~= 0
                            for head = 1:2
                                if percents(device,plant,head,truss,day,1) ~= 0
                                    tempPercent = [tempPercent; percents(device,plant,head,truss,day,2:end)];
                                    tempTotal = [tempTotal; totals(device,plant,head,truss,day,2:end)];
                                end
                            end
                        end
                    end
                    tempAv = mean(tempPercent,1);
                    tempTrussTotal = sum(tempTotal,1);
                    if ~isempty(tempAv)
                        stdDevRep = [std(squeeze(tempPercent(:,1))) std(squeeze(tempPercent(:,2))) std(squeeze(tempPercent(:,3))) std(squeeze(tempPercent(:,4)))];
                        avgRepPercents(species,device,truss,rep,day,:) = [squeeze(tempAv)' stdDevRep];
                    end
                end
            end
        end
    end
end

%% Plot comparison between replication blocks
close(figure(1))
figure(1)
grid on
hold on

% change this to plot a different truss level.
truss = 1;
data = 3; % 1 - percent set, 2 - percent broken, 3 - percent harvestable, 4 - percent unpollinated

% Cherry tomatoes
species = 1;
day = 13;

groupedRepData = [];
groupedRepError = [];
for device = 1:3
    groupedRepData = [groupedRepData; squeeze(avgRepPercents(species,device,truss,:,day,data))'];
    groupedRepError = [groupedRepError; squeeze(avgRepPercents(species,device,truss,:,day,data+4))'];
end

bar(groupedRepData,'grouped','BarWidth',1);
title(strcat(speciesLabels(species), {' Tomatoes: Comparison between Replication Blocks on Day '},num2str(testDays(day))),'FontSize',16);
xlabel('Device','FontSize',14,'FontWeight','bold');
ylabel(strcat({'Percentage '},dataLabels(data)),'FontSize',14,'FontWeight','bold');
lh = legend('Replication 1','Replication 2','Replication 3');
set(lh,'FontSize',12);
set(gca,'XTick',1:5,'XTickLabel',{'Pulsed Air','Sound','Contact Vibration'},'FontSize',12)

groupwidth = min(0.8, 4/(4+1.5));
for i = 1:4
    x = (1:3) - groupwidth/2 + (2*i-1) * groupwidth / (2*4);
    errorbar(x, groupedRepData(:,i), groupedRepError(:,i), 'k', 'linestyle', 'none');
end

%% Calculate average percent set

% averagePercents contains a 2D vector for each (device, truss) combination that contains the
% [day, average %set, average %brok, average %harvestable, average %unpollinated, std dev %set, std dev %broken, std dev %harvestable, std dev %unpollinated] for each day.
% trussTotals contains a 2D vector for each (device, truss) combination
% that contains the [total flowers, total set, total broken, total harvestable, total unpollinated] for each day
averagePercents = zeros(2,5,5,length(testDays),8);
trussTotals = zeros(2,5,5,length(testDays),5);
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
                        if percents(device,plant,head,truss,day,1) ~= 0
                            tempPercent = [tempPercent; percents(device,plant,head,truss,day,2:end)];
                            tempTotal = [tempTotal; totals(device,plant,head,truss,day,2:end)];
                        end
                    end
                end
                tempAv = mean(tempPercent,1);
                tempTrussTotal = sum(tempTotal,1);
                if ~isempty(tempAv)
                    stdDevRep = [std(squeeze(tempPercent(:,1))) std(squeeze(tempPercent(:,2))) std(squeeze(tempPercent(:,3))) std(squeeze(tempPercent(:,4)))];
                    averagePercents(species,device,truss,day,:) = [squeeze(tempAv)' stdDevRep];
                    trussTotals(species,device,truss,day,:) = tempTrussTotal;
                end
            end
        end
    end
end

%% Plot data for truss 1, cherry, error is broken
for species = 1:2
    figure
    grid on
    hold on
    colors = ['y','m','c','r','g'];
    
    % change this to plot a different truss level.
    truss = 1;
    
    for i = 1:size(averagePercents,2)
        errorbar(testDays,averagePercents(species,i,truss,:,1),zeros(length(averagePercents(species,i,truss,:,1)),1),averagePercents(species,i,truss,:,2),'LineWidth',2)
    end
    lh = legend('Air Pulsing','Sound Radiation','Contact','Untreated','Bee Pollinated','Location','northwest');
    set(lh,'FontSize',12);
    title(strcat(speciesLabels(species),{' Tomatoes: Rate of Setting'}),'FontSize',16);
    xlabel('Test day','FontSize',14,'FontWeight','bold');
    ylabel('Percentage set','FontSize',14,'FontWeight','bold');
    xlim([0, testDays(length(testDays))+1]);
end

%% Plot data for truss 1, cherry, error is STDDEV
for species = 1:2
    figure
    grid on
    hold on
    
    % change this to plot a different truss level.
    truss = 1;
    
    for i = 1:size(averagePercents,2)
        errorbar(testDays,averagePercents(species,i,truss,:,1),averagePercents(species,i,truss,:,5),'LineWidth',2)
    end
    lh = legend('Air Pulsing','Sound Radiation','Contact','Untreated','Bee Pollinated','Location','northwest');
    set(lh,'FontSize',12);
    title(strcat(speciesLabels(species),{' Tomatoes: Rate of Setting'}),'FontSize',16);
    xlabel('Test day','FontSize',14,'FontWeight','bold');
    ylabel('Percentage set','FontSize',14,'FontWeight','bold');
    xlim([0, testDays(length(testDays))+1]);
end

%% Plot data for truss 1, beefsteak, error is broken
figure
grid on
hold on
colors = ['y','m','c','r','g'];

% change this to plot a different truss level.
truss = 1;
species = 2;

for i = 1:size(averagePercents,2)
    errorbar(testDays,averagePercents(species,i,truss,:,1),zeros(length(averagePercents(species,i,truss,:,1)),1),averagePercents(species,i,truss,:,2),'LineWidth',2)
end
lh = legend('Air Pulsing','Sound Radiation','Contact','Untreated','Bee Pollinated','Location','northwest');
set(lh,'FontSize',12);
title('Beefsteak Tomatoes: Rate of Setting','FontSize',16);
xlabel('Test day','FontSize',14,'FontWeight','bold');
ylabel('Percentage set','FontSize',14,'FontWeight','bold');
xlim([0, testDays(length(testDays))-12]);
set(gca,'FontSize',12);

%% Plot totals data, cherry
for species = 1:2
    figure
    grid on
    hold on
    colors = ['y','m','c','r','g'];
    
    truss = 1;
    totalType = 1; % 1 for total flowers, 2 for total set, 3 for total broken
    
    for i = 1:size(averagePercents,2)
        plot(testDays,squeeze(trussTotals(species,i,truss,:,totalType)),'LineWidth',2)
    end
    legend('Air Pulsing','Sound Radiation','Contact','Untreated','Bee Pollinated','Location','northwest')
    title(strcat(speciesLabels(species),{' Tomatoes: Total Flowers'}))
    xlabel('Test day')
    ylabel('Number of flowers')
    xlim([0, testDays(length(testDays))+1]);
end
%% Plot bar chart comparison of devices on a day
for species = 1:2
    figure
    grid on
    hold on
    
    % change this to plot a different truss level.
    truss = 1;
    day = 14;
    data = 3; % 1 - percent set, 2 - percent broken, 3 - percent harvestable, 4 - percent unpollinated
    
    bar([1:5],averagePercents(species,:,truss,day,data),'LineWidth',2);
    errorbar([1:5],squeeze(averagePercents(species,:,truss,day,data)),squeeze(averagePercents(species,:,truss,day,data+4)),'.','LineWidth',2)
    title(strcat(speciesLabels(species),{' Tomatoes: Percent '}, dataLabels(data), {' on Day '}, num2str(testDays(day))),'FontSize',16)
    xlabel('Test Device','FontSize',14,'FontWeight','bold')
    ylabel(strcat({'Percentage '}, dataLabels(data)),'FontSize',14,'FontWeight','bold')
    set(gca,'XTick',1:5,'XTickLabel',{'Pulsed Air','Sound','Contact Vibration','Untreated','Bee Pollinated'},'FontSize',12)
end