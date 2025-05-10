function node_flow_diagram_test
%mex -setup;loadlibrary('swmm5');%每次重新打开软件都要创建一次
%node=(3); 
% G-Model-B
nodes=(128); % T-Model-A

rain=[1,2,3,4,5,6,7,8,9,10,11];%1a-rainfall

%指定模拟时间(min)，图像横坐标
time=40;

%概化模型—G-Model
locG='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_GModel_ds_3_2node_ver.inp';

%孪生模型—T-Model
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

%设定参数跨度
G_width=2334.2;
paramgap=40;
lowmultiple=0.1;
upmultiple=2;
multipliers=linspace(lowmultiple,upmultiple,paramgap);
G_width_Param=G_width*multipliers;
G_width_Param=round(G_width_Param*10000)/10000;


%G-Model
C=ones(steps,paramgap,rain_count);
D=ones(steps,paramgap,rain_count);
B_G=ones(steps,paramgap,rain_count);% B赋值为G-Model
A_T=ones(steps,paramgap,rain_count);% A赋值为T-Model

%小节位置寻找
sectionLine=findInpSectionLine(locG_temp, 'SUBCATCHMENTS');
%gagetime(gages)=4+rain(gages);%时间标签
%降雨序列更换
%parameter_modify_TS(locG,locG_temp,'TS1',char('TS'+string(rain(gages))));
for k=1:rain_count
    parameter_modify_TS(locG,locG_temp,'TS1',char('TS'+string(rain(k))));
    for j=1:paramgap 
        %广域漫流宽度参数更改
        replaceInpColumnValue(locG,locG_temp, sectionLine, G_width_Param(j));
        %调用G-Model文件位置
        calllib('swmm5','swmm_open',locG_temp,locG_temp_report,'');
        calllib('swmm5','swmm_start',1);
        for i=1:steps
            calllib('swmm5','swmm_stride',1,1);
            %tip：此处输入的nodes值是在junction list里面的整体order，与数值无关
            %C(i,j)=calllib('swmm5','swmm_getValue',307,1); %G-Model-B
            C(i,j,k)=calllib('swmm5','swmm_getValue',307,2); %G-Model-B-2nodes.ver
            %C(i,j)=calllib('swmm5','swmm_getValue',307,3); %G-Model-B-3nodes.ver
            %C(i,j)=calllib('swmm5','swmm_getValue',307,nodes-1); % T-Model-A
        end
        %模型数据导出保存
        B_G(:,j,k)=C(:,j,k); % B赋值为G-Model
    end
end
calllib('swmm5','swmm_close');

for k = 1:rain_count

    parameter_modify_TS(locT, locT_temp, 'TS1', char('TS'+string(rain(k)))); 

    calllib('swmm5','swmm_open', locT_temp, locT_temp_report, '');
    calllib('swmm5','swmm_start', 1);
    tempResult = ones(steps, 1);  % 临时存储单参数结果
    for i = 1:steps
        calllib('swmm5','swmm_stride', 1, 1);
        tempResult(i) = calllib('swmm5','swmm_getValue', 307, nodes-1);
    end
    % 将结果复制到所有参数位置（保持规模一致）
    A_T(:, :, k) = repmat(tempResult, 1, paramgap);
end
calllib('swmm5','swmm_close');











