%% constant
maxEnhanceLevel=20;
maxVipLevel=20;

%% initialization
data = xlsread('.\EQU_advance.xlsx','data');
enhanceCost = [-data(1:maxEnhanceLevel,2);0];
transmissionCoefficient = -ones(maxEnhanceLevel + 1, 1);

vipData = data(1:maxVipLevel+1,11:12);
rateInfo = [data(1:maxEnhanceLevel,3:5);zeros(1,3)];

damStartLevel = 0;
for i = 1:maxEnhanceLevel + 1
   if rateInfo(i,3) == 0
       damStartLevel = damStartLevel + 1;
   else
       break
   end
end
vipData(:,2) = vipData(:,2) + damStartLevel;

%% calculation
operationTimeExpect = expectMatrix(transmissionCoefficient,rateInfo,vipData,maxEnhanceLevel,maxVipLevel,false);
costExpect = expectMatrix(enhanceCost,rateInfo,vipData,maxEnhanceLevel,maxVipLevel,false);
brokeExpect = expectMatrix("broke",rateInfo,vipData,maxEnhanceLevel,maxVipLevel,true);

result = [operationTimeExpect;costExpect;brokeExpect];

xlswrite('.\result.xlsx',result)
winopen('.\result.xlsx')

%% functions

function expect_matrix = expectMatrix(coefficient,rateInfo,vipData,maxEnhanceLevel,maxVipLevel,countingBroke)
    expect_matrix = zeros(maxEnhanceLevel,maxVipLevel + 1);
    parfor vipLevel = 0:maxVipLevel
        levelVipData = vipData(vipLevel+1,:);
        vip_rate_info = vipRateInfo(rateInfo,levelVipData,maxEnhanceLevel);
        vip_transmission_matrix = transmissionMatrix(vip_rate_info,maxEnhanceLevel);
        if countingBroke == true
            expect_matrix = expect_matrix + levelExpectMatrix(vip_transmission_matrix,maxEnhanceLevel,-vip_rate_info(:,3),maxVipLevel,vipLevel);
        else
            expect_matrix = expect_matrix + levelExpectMatrix(vip_transmission_matrix,maxEnhanceLevel,coefficient,maxVipLevel,vipLevel);
        end
    end
end

function vip_rate_info = vipRateInfo(rateInfo,levelVipData,maxEnhanceLevel)
    rateInfo(:,1) = min(rateInfo(:,1) * (1 + levelVipData(1)),1);
    isDam = (1:21 >levelVipData(2))';
    rateInfo(:,3) = rateInfo(:,3).*isDam;
    
	failRate = 1 - rateInfo(:,1);
    failRate(maxEnhanceLevel + 1,:) = 0;
    rateInfo(:,3) = failRate .* rateInfo(:,3);
    rateInfo(:,2) = (failRate - rateInfo(:,3)) .* rateInfo(:,2);
    rateInfo(:,4) = failRate - rateInfo(:,2) - rateInfo(:,3);
    vip_rate_info = rateInfo;
end

function expect_matrix = levelExpectMatrix(vip_transmission_matrix,maxEnhanceLevel,coefficient,maxVipLevel,vipLevel)
    expect_matrix = zeros(maxEnhanceLevel,maxVipLevel + 1);
    parfor currentLevel = 2:maxEnhanceLevel + 1
        current_expect_matrix = zeros(maxEnhanceLevel,maxVipLevel + 1);
        currentLevelTransmission = vip_transmission_matrix(1:currentLevel , 1:currentLevel);
        currentLevelTransmission(currentLevel , :) = 0;
        currentLevelTransmission(currentLevel , currentLevel ) = 1;
        currentLevelexpect = currentLevelTransmission\[coefficient(1:currentLevel-1);0];
        current_expect_matrix(currentLevel-1,vipLevel+1) = currentLevelexpect(1);
        expect_matrix = expect_matrix + current_expect_matrix;
    end
end

function transmission_matrix = transmissionMatrix(rateInfo,maxEnhanceLevel)
    sucRate = rateInfo(:,1);
    reduceRate = rateInfo(:,2);
    failRate = rateInfo(:,4);
	transmission_matrix = [rateInfo(:,3),zeros(maxEnhanceLevel + 1,maxEnhanceLevel)];
    parfor enhanceLevel = 1:maxEnhanceLevel
        current_matrix = zeros(maxEnhanceLevel + 1);
        current_matrix(enhanceLevel, enhanceLevel+1) = sucRate(enhanceLevel);
        current_matrix(enhanceLevel+1, enhanceLevel) = reduceRate(enhanceLevel+1);
        current_matrix(enhanceLevel, enhanceLevel) = failRate(enhanceLevel) - 1;
        transmission_matrix = transmission_matrix + current_matrix;
    end
    transmission_matrix(maxEnhanceLevel + 1,maxEnhanceLevel + 1) = -1;
end