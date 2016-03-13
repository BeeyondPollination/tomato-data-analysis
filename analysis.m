%% Extract all data to matlab
allData = csvread('D:\System Folders\Documents\GitHub\tomato-data-analysis\consolidatedData.csv',1,0);

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
% percentSet will contain a vector of the percentage set each day
% organized by {device, plant, head, truss}
percentSet = {};

for device = 1:size(dataSet,1)
    for plant = 1:size(dataSet,2)
        for head = 1:2
            for truss = 1:size(dataSet,4)
                percent = [];
                for day = 1:size(dataSet,5)
                    dayData = dataSet{device,plant,head,truss,day};
                    if isempty(dayData)
                        percent(day) = 0;
                    else
                        percent(day) = 100*(dayData(length(dayData))+dayData(length(dayData)-1))/sum(dayData(2:length(dayData)));
                    end
                end
                percentSet{device,plant,head,truss} = percent;
            end
        end
    end
end

%% Plot percent set over time.
close all

testDays = [0,3,5,7,10,12,14,17];

figure
grid on
hold on
colors = ['y','m','c','r','g'];

cherrySet = {};
for plant = 1:8
    for device = 1:size(dataSet,1)
        if length(cherrySet)<device
            cherrySet{device} = [];
        end
        for truss = 1   %:size(dataSet,4)
            for head = 1:2
                cherrySet{device} = [cherrySet{device}; percentSet{device,plant,head,truss}];
            end
        end
    end
end
for i = 1:length(cherrySet)
    cherrySet{i} = mean(cherrySet{i},1);
    plot(testDays,cherrySet{i},'LineWidth',2)
    legend('Device 1','Device 2','Contact','Untreated','Control','Location','northwest')
    title('Percentage of cherry tomato flowers setting fruit over time')
    xlabel('Test day')
    ylabel('Percent set')
end


figure
grid on
hold on
colors = ['y','m','c','r','g'];

beefSet = {};
for plant = 9:14
    for device = 1:size(dataSet,1)
        if length(beefSet)<device
            beefSet{device} = [];
        end
        for truss = 1   %:size(dataSet,4)
            for head = 1:2
                beefSet{device} = [beefSet{device}; percentSet{device,plant,head,truss}];
            end
        end
    end
end
for i = 1:length(beefSet)
    beefSet{i} = mean(beefSet{i},1);
    plot(testDays,beefSet{i},'LineWidth',2)
    legend('Device 1','Device 2','Contact','Untreated','Control','Location','northwest')
    title('Percentage of beefsteak tomato flowers setting fruit over time')
    xlabel('Test day')
    ylabel('Percent set')
end

