% 漫流宽度更改的扫描型三维曲面绘制
%node=(3); 
% G-Model-B
nodes=(128); % T-Model-A
rain=[1,2,3,4,5,6,7,8,9,10,11];%1a-rainfall

%指定模拟时间(min)，图像横坐标
time=40;
gagetime=ones(length(rain));

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
A_T=ones(steps,length(rain)); % A赋值为T-Model
B_G=ones(steps,length(rain)); % B赋值为G-Model

%设定参数跨度
G_width=2334.2;
%G_width_st=817.0295;
paramgap=20;
lowmultiple=0.1;
upmultiple=2;
multipliers=linspace(lowmultiple,upmultiple,paramgap);
G_width_Param=G_width*multipliers;
G_width_Param=round(G_width_Param*10000)/10000;
%%

%G-Model

C=ones(steps,paramgap);
sectionLine=findInpSectionLine(locG_temp, 'SUBCATCHMENTS');
%gagetime(gages)=4+rain(gages);%时间标签
%parameter_modify_TS(locG,locG_temp,'TS1',char('TS'+string(rain(gages))));


for j=1:paramgap  

    %广域更改漫流宽度参数
    width_file_generate(locG_temp,locG_temp, sectionLine, G_width_Param(j));

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
% 生成网格坐标矩阵
[X, Y] = meshgrid(1:steps, G_width_Param);  % X轴-时间步长，Y轴-参数值
% 创建三维曲面图
figure('Name','参数-时间-流量关系','NumberTitle','off');
surf(X', Y', C);  % 转置矩阵对齐维度(时间步长 x 参数值 x 流量值)
% 美化图形
shading interp;          % 平滑着色
colormap jet;            % 使用彩虹色系
colorbar;                % 显示颜色条
alpha(0.8);              % 设置透明度（0-1）
light; lighting gouraud; % 添加光照效果
material shiny;          % 设置材质反光属性

% 坐标轴标签
xlabel('模拟时间步长 (steps)', 'FontWeight','bold');
ylabel('漫流宽度参数 (mm)', 'FontWeight','bold');
zlabel('节点流量 (m³/s)', 'FontWeight','bold');

% 视角调整
view(-30,30);  % 方位角-30°, 仰角30°
grid on;
axis tight;

