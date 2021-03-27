%% constant
maxEnhanceLevel=20;
maxVipLevel=20;

%% initialization
data = xlsread('.\EQU_advance.xlsx','data');
enhanceCost = [-data(1:maxEnhanceLevel,2);0];

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
%% Exam
sumEnhancCount = 0;
vipLevel = 0
simSteps = 10000
endEnhanceLevel = 20
levelVipData = vipData(vipLevel+1,:);
vip_rate_info = vipRateInfo(rateInfo,levelVipData);
couneData = zeros(simSteps,1);
parfor i = 1:simSteps
        currentCouneData = zeros(simSteps,1);
        enhanceLevel = 0;
        enhancCount = 0;
        count = zeros(20,1);
        while enhanceLevel < endEnhanceLevel
            level_rate_info = vip_rate_info(enhanceLevel+1,:);
            %level_rate_info = vip_rate_info(enhanceLevel+1,:);
            [enhanceLevel, enhancCount] = enhance(level_rate_info,enhanceLevel,enhancCount);
        end
        currentCouneData(i) = enhancCount;
        couneData = couneData + currentCouneData;
end
averageEnhancCount = mean(couneData)
stdEnhancCount = std(couneData)
minEnhancCount = min(couneData)
maxEnhancCount = max(couneData)

function [enhanceLevel, enhancCount] = enhance(rateInfo,currentEnhanceLevel,currentCount)
    preLevel = currentEnhanceLevel;
    if rand(1) <= rateInfo(1) %success
        enhanceLevel = currentEnhanceLevel + 1;
    else
       if rand(1) <= rateInfo(3) %broke
           enhanceLevel = 0;
       else
           if rand(1) <= rateInfo(2) %reduce
               enhanceLevel = currentEnhanceLevel - 1;
           else %faile
               enhanceLevel = currentEnhanceLevel;
           end
       end
    end
    enhancCount = currentCount + preLevel;
end
    
 function vip_rate_info = vipRateInfo(rateInfo,levelVipData)
    rateInfo(:,1) = min(rateInfo(:,1) * (1 + levelVipData(1)),1);
    isDam = (1:21 >levelVipData(2))';
    rateInfo(:,3) = rateInfo(:,3).*isDam;
    vip_rate_info = rateInfo;
end
