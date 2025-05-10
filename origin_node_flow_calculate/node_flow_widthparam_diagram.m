function node_flow_widthparam_diagram
% 函数说明：对指定概化模型（节点，管长），对指定扫描步长的漫流宽度进行流量过程线3D图像绘制

% mex -setup;loadlibrary('swmm5');%每次重新打开软件都要创建一次
% node = (3); 
% G-Model-B
nodes = (128); % T-Model-A

rain = [1,2,3,4,5,6,7,8,9,10,11];%1a-rainfall

%指定模拟时间(min)，图像横坐标
time = 40;
gagetime = ones(length(rain));

%概化模型—G-Model
locG = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_GModel_ds_3_2node_ver.inp';

%孪生模型—T-Model
locT = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_TModel_ds_3.inp';

%模型文件格式整理
locG_temp = strrep(locG, '.inp', 'temp.inp');
locG_temp_report = strrep(locG_temp, 'temp.inp', 'temp.rpt');
copyfile(locG, locG_temp); %我真是个天才

locT_temp = strrep(locT, '.inp', 'temp.inp');
locT_temp_report = strrep(locT_temp, 'temp.inp', 'temp.rpt');
copyfile(locT, locT_temp);


%根据计算要求设置预置数组及相关数据储存

steps = 60*time; 
rain_count = length(rain);
A_T = ones(steps,length(rain)); % A赋值为T-Model
B_G = ones(steps,length(rain)); % B赋值为G-Model

%设定参数跨度
G_width=2334.2;
%G_width_st=817.0295;
paramgap=20;
lowmultiple=0.1;
upmultiple=2;
multipliers=linspace(lowmultiple,upmultiple,paramgap);
G_width_Param=G_width*multipliers;
G_width_Param=round(G_width_Param*1000)/1000;


%G-Model

C=ones(steps,paramgap);
sectionLine=findInpSectionLine(locG_temp, 'SUBCATCHMENTS');
%gagetime(gages)=4+rain(gages);%时间标签
%parameter_modify_TS(locG,locG_temp,'TS1',char('TS'+string(rain(gages))));


for j=1:paramgap  

    %广域更改漫流宽度参数
    % replaceInpColumnValue(locG, locG_temp, sectionLine, G_width_Param(j));
    replaceInpValue_write_in(locG, locG_temp, sectionLine, 1, 70, G_width_Param(j))

    %调用文件位置
    calllib('swmm5','swmm_open',locG_temp,locG_temp_report,'');
    calllib('swmm5','swmm_start',1);
    for i=1:steps
        calllib('swmm5','swmm_stride',1,1);
        %tip：此处输入的nodes值是在junction list里面的整体order，与数值无关
        %C(i,j)=calllib('swmm5','swmm_getValue',307,1); %G-Model-B
        C(i,j)=calllib('swmm5','swmm_getValue',307,2); %G-Model-B-2nodes.ver
        %C(i,j)=calllib('swmm5','swmm_getValue',307,3); %G-Model-B-3nodes.ver
        %C(i,j)=calllib('swmm5','swmm_getValue',307,nodes-1); % T-Model-A
    end
end
C;
%% 三维曲面绘制
% 生成时间分钟数据（假设每个step代表1秒）
time_min = (1:steps)/60;  % 将步数转换为分钟

% 生成网格坐标矩阵
[X, Y] = meshgrid(time_min, G_width_Param);  % X轴-分钟，Y轴-参数值

% 创建三维曲面图
figure('Name','参数-时间-流量关系','NumberTitle','off');
surf(X', Y', C);  % 转置矩阵对齐维度(时间分钟 x 参数值 x 流量值)

% 设置坐标轴刻度
xt = 0:5:ceil(max(time_min));  % 每5分钟一个主刻度
set(gca, 'XTick', xt);         % 强制设置刻度位置
xlim([0 max(time_min)]);       % 限制坐标轴范围

% 美化图形
shading interp;                % 平滑着色
colormap(parula);              % 使用parula色系（更科学）
h = colorbar;
h.Label.String = '流量 (LPS)'; % 颜色条标签
h.Label.FontWeight = 'bold';    % 标签加粗
alpha(0.85);                   % 调整透明度

% 坐标轴标签
xlabel('模拟时间 (min)', 'FontWeight','bold', 'FontSize',12);
ylabel('漫流宽度 (m)', 'FontWeight','bold', 'FontSize',12);
zlabel('节点流量 (LPS)', 'FontWeight','bold', 'FontSize',12);

% 视角优化
view(30,15);                  % 调整观测角度
light('Position',[1 0 0]);      % 添加左侧光源
material dull;                 % 减少镜面反射

% 添加辅助网格
grid on;
set(gca, 'GridAlpha',0.4);     % 网格透明度
box on;                        % 显示坐标框