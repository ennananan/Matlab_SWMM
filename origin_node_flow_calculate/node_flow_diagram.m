function [E]=node_flow_diagram()
%基础运算依据，模型正常运算判断

%mex -setup;loadlibrary('swmm5');%每次重新打开软件都要创建一次
%————————————————原始模型运行及基础计算————————————
%node = (3); % G-Model-B
%nodes = (128); % T-Model-A
%rain=[1];%个数决定输出组数，数字代表降雨编号，此为两种思路要注意;
rain=[1,2,3,4,5,6,7,8,9,10,11];%1a-rainfall
%rain=[16,17,18,19,20,21,22,23,24,25,26];%2a-rainfall

%指定模拟时间(min)，图像横坐标
time=40;
gagetime=ones(length(rain));

%概化模型—G-Model
%locG='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_GModel_us.inp';%G-B
%locG='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_GModel_us_2node_ver.inp';%G-B
%locG='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_GModel_ms.inp';
%locG='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_GModel_ms_2node_ver.inp';
%locG='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_GModel_ms_3node_ver.inp';
%locG='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_GModel_ds_1.inp';%G-B
%locG='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_GModel_ds_1_2node_ver.inp';
%locG='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_GModel_ds_1_3node_ver.inp';
%locG='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_GModel_ds_2.inp';%G-B
%locG='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_GModel_ds_2_2node_ver.inp';
%locG='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_GModel_ds_2_3node_ver.inp';
%locG='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_GModel_ds_3.inp';%G-B
locG='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_GModel_ds_3_2node_ver.inp';
%locG='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_GModel_ds_3_3node_ver.inp';
%locG='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_GModel_ds_3_4node_ver.inp';
%locG='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_GModel_ds_3_5node_ver.inp';


%孪生模型—T-Model
%locT='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_TModel_us.inp';%T-A
%locT='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_TModel_ms.inp';%T-A
%locT='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_TModel_ds_1.inp';%T-A
%locT='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_TModel_ds_1.inp';
%locT='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_TModel_ds_2.inp';
locT='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_TModel_ds_3.inp';

%模型文件格式整理
locG_temp=strrep(locG,'.inp','temp.inp');
locG_temp_report=strrep(locG_temp,'temp.inp','temp.rpt');
copyfile(locG,locG_temp); %我真是个天才

locT_temp=strrep(locT,'.inp','temp.inp');
locT_temp_report=strrep(locT_temp,'temp.inp','temp.rpt');
copyfile(locT,locT_temp);

%根据计算要求设置预置数组及相关数据储存
steps=60*time; 
rain_count=length(rain);
A_T=ones(steps,length(rain)); % A赋值为T-Model
B_G=ones(steps,length(rain)); % B赋值为G-Model

%G-Model
for gages=1:length(rain)
    
C=ones(steps,rain_count);
gagetime(gages)=4+rain(gages);%时间标签
parameter_modify_TS(locG,locG_temp,'TS1',char('TS'+string(rain(gages))));
%parameter_modify_TS(loc,loc_temp,'TIMESERIES 1',char('TS'+string(rain(gages))));
%parameter_modify_TS(loc,loc_temp,'TIMESERIES 1','TIMESERIES 2')

%调用文件位置
calllib('swmm5','swmm_open',locG_temp,locG_temp_report,'');
calllib('swmm5','swmm_start',1);
     
for i=1:steps
    calllib('swmm5','swmm_stride',1,1);
    j = gages;
   %tip：此处输入的nodes值是在junction list里面的整体order，与数值无关
   %C(i,j)=calllib('swmm5','swmm_getValue',307,1); %G-Model-B
   C(i,j)=calllib('swmm5','swmm_getValue',307,2); %G-Model-B-2nodes.ver
   %C(i,j)=calllib('swmm5','swmm_getValue',307,3); %G-Model-B-3nodes.ver
   %C(i,j)=calllib('swmm5','swmm_getValue',307,4); %G-Model-B-4nodes.ver
   %C(i,j)=calllib('swmm5','swmm_getValue',307,5); %G-Model-B-5nodes.ver
   %C(i,j)=calllib('swmm5','swmm_getValue',307,nodes-1); % T-Model-A
end

%多场降雨数据/多个节点导出时使用
B_G(:,gages)=C(:,gages); % B赋值为G-Model

end
calllib('swmm5','swmm_close')

%T-Model
for gages=1:length(rain)
C=ones(steps,rain_count);
gagetime(gages)=4+rain(gages);%时间标签

parameter_modify_TS(locT,locT_temp,'TS1',char('TS'+string(rain(gages))));
%parameter_modify_TS(loc,loc_temp,'TIMESERIES 1',char('TS'+string(rain(gages))));
%parameter_modify_TS(loc,loc_temp,'TIMESERIES 1','TIMESERIES 2')

%调用文件位置
calllib('swmm5','swmm_open',locT_temp,locT_temp_report,'');
calllib('swmm5','swmm_start',1);
     
for i=1:steps
    calllib('swmm5','swmm_stride',1,1);
    %for j=1:nodes_count %多节点导出循环
    j = gages;
  % tip：此处输入的nodes值是在junction list里面的整体order，与数值无关
   %C(i,j)=calllib('swmm5','swmm_getValue',307,nodes-1); % T-Model-A
   C(i,j)=calllib('swmm5','swmm_getValue',307,127); % T-Model-A
end

%数组A用于从C中提取流量信息
%A(:,gages)=C(:,1);%数据导出重要字段**

%多场降雨数据/多个节点导出时使用
A_T(:,gages)=C(:,gages); % A赋值为T-Model
end
calllib('swmm5','swmm_close')

%求NSE
E=NSE_calculation(A_T,B_G);

%——————————————————————————————————————————————————
%————————————————————数据整理和计算————————————————
%降雨总量check
stormwatertotal_T=sum(A_T)';
stormwatertotal_G=sum(B_G)';
totalratio=stormwatertotal_T./stormwatertotal_G

%最大流量线，流量峰值和峰现时间及百分比数据导出
columns_num=3; %指定需要保存的曲线数目
[maxValues_A_T,rowIndices_A_T]=max(A_T);%导出演算
[maxValues_B_G,rowIndices_B_G]=max(B_G);
[sortedMaxvalues_A_T,sortedIndices_A_T]=sort(maxValues_A_T,'descend');%只有1行，所以导出的是列索引
[sortedMaxvalues_B_G,sortedIndices_B_G]=sort(maxValues_B_G,'descend');
topnum_Values_A_T=sortedMaxvalues_A_T(:,1); %当前重现期序列下的最大值
%topnum_ColIndices=sortedIndices(1:3);

%峰值与峰现时间
peakTime_A_T=rowIndices_A_T/60;
peakTime_B_G=rowIndices_B_G/60;
rain_time=rain+4;
peakValue_Time_A_T=[maxValues_A_T',peakTime_A_T',rain_time'];
peakValue_Time_B_G=[maxValues_B_G',peakTime_B_G',rain_time'];
peakValue_Ratio=maxValues_B_G'./maxValues_A_T';
peakValue_RatioDiff=1-peakValue_Ratio;
peakValue=[peakValue_Ratio,rain',peakValue_RatioDiff]

%最高三条线选择与合并
topnum_A_T=A_T(:,sortedIndices_A_T(1:columns_num)); %steps行3列
topnum_B_G=B_G(:,sortedIndices_A_T(1:columns_num)); %注意序列的对应选择
%指定拟合数据百分比数量，以及行列数据划分
Values_persent=linspace(0.3,0.8,15);
line_num=length(Values_persent);
persentExpanded=permute(Values_persent,[1,3,2]);
persentLine=persentExpanded.*topnum_Values_A_T; %获得划线,1行1列7页
fstnonzeroIndice=zeros(line_num,columns_num);
lstnonzeroIndice=fstnonzeroIndice;
cutnum_A_T=ones(size(topnum_A_T,1),size(topnum_A_T,1));
for i=1:line_num
    cutnum_A_T(topnum_A_T<persentLine(:,:,i))=0;
    for j=1:columns_num
        fstnonzeroIndice(i,j)=find(cutnum_A_T(:,j)~=0,1,'first');
        lstnonzeroIndice(i,j)=find(cutnum_A_T(:,j)~=0,1,'last');
     end
end
%cutnum_A_T=topnum_A_T(fstnonzeroIndice(1,1):lstnonzeroIndice(1,1),1)
%峰值元胞空间创建和数据储存
%combinedAB=cat(3,topnum_A_T,topnum_B_G); %steps行3列2页
linedcombingAB=cell(line_num,columns_num,2);%7行3列2页，每1行列页单个元胞中是steps行1列的矩阵
%linedcombingAB=cell(line_num,1,2); %7行1列2页，每1行列页单个元胞里中是steps行3列的矩阵
for i=1:columns_num 
    for j=1:line_num 
        linedcombingAB{j,i,1}=topnum_A_T(fstnonzeroIndice(j,i):lstnonzeroIndice(j,i),i);
        linedcombingAB{j,i,2}=topnum_B_G(fstnonzeroIndice(j,i):lstnonzeroIndice(j,i),i);
    end
end
%局部NSE计算
for i=1:line_num
    for j=1:columns_num
    tempstoreValueA_T=linedcombingAB{i,j,1};
    tempstoreValueB_G=linedcombingAB{i,j,2};
    peakNSE(i,j)=NSE_calculation(tempstoreValueA_T,tempstoreValueB_G);
    end
end
peakNSE


%根据指定的时间范围绘图
t1 = datenum('00:00:01');
tmax=char("00:"+string(time)+":00");
t2 = datenum(tmax);
t=linspace(t1,t2,steps);
labels={};
labels_B_G={};
labels_A_T={};
lineHandles=[];
lineHandles_B_G=[];
lineHandles_A_T=[];

for k=1:length(rain)
    line_B_G=plot(t,B_G(:,k),'r','linewidth',0.8); % G-Model-B
    labels_B_G{end+1}=sprintf('G-Model %dmin',gagetime(k));
    lineHandles_B_G(end+1)=line_B_G;
    hold on
    line_A_T=plot(t,A_T(:,k),'k','linewidth',0.8); % T-Model-A
    labels_A_T{end+1}=sprintf('T-Model %dmin', gagetime(k));
    lineHandles_A_T(end+1)=line_A_T;
end
labels=[labels_A_T,labels_B_G];
lineHandles=[lineHandles_A_T,lineHandles_B_G];
legend(lineHandles,labels, 'Orientation', 'vertical','NumColumns',1);
datetick('x',13);
xlabel('Time');
ylabel('Runoff(LPS)');
end