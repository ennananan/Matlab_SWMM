function node_flow_diagram_NSE_regionwide
% 在更改降雨序列的同时更改漫流宽度，并进行两个模型NSE的计算
% 在一场雨下，进行批量的漫流宽度更改

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
G_width = 2334.2;
paramgap = 20;
lowmultiple = 0.1;
upmultiple = 2;
multipliers = linspace(lowmultiple, upmultiple, paramgap);
G_width_Param = G_width * multipliers;
G_width_Param = round(G_width_Param * 1000) / 1000;

%数组初始化

C = ones(steps, paramgap, rain_count);
B_G = ones(steps, paramgap, rain_count);% B赋值为G-Model
A_T = ones(steps, paramgap, rain_count);% A赋值为T-Model

%G-Model
%小节位置寻找
sectionLine=findInpSectionLine(locG_temp, 'SUBCATCHMENTS');
%gagetime(gages)=4+rain(gages);%时间标签

for k=1:rain_count
    %降雨序列更换
    timeseries_file_generate(locG_temp, rain, 59, k)
    
    for j=1:paramgap 
        %广域漫流宽度参数更改
        replaceInpValue_write_in(locG_temp, locG_temp, sectionLine, 1, 70, G_width_Param(j))
        
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
%B_G

%T-Model
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
%A_T

%求NSE
R=NSE_calculation_3D(A_T,B_G);

%强制清理
clear C D A_T B_G;

%% NSE参数敏感性分析绘图
figure('Name','NSE-Width变化分析','NumberTitle','off');

% 生成颜色映射（每个降雨事件一种颜色）
%colors = parula(length(rain));  % 使用parula色系，颜色数与降雨事件数一致
%colors = turbo(length(rain));
%colors = lines(length(rain));

%示例1: 获取全部颜色矩阵
pal = absorption_palette();
colorMatrix = pal.colors; % 11×3的RGB矩阵

% 绘制每个降雨事件的NSE曲线
hold on
for k = 1:length(rain)
    % 提取当前降雨事件的所有参数对应的NSE值
    y = R(:, k);
    x = G_width_Param;
    % 绘制曲线
    plot(x, y,...
        'LineWidth', 1.5,...
        'Color', pal.get(k),...
        'Marker', 'o',...
        'MarkerSize', 4,...
        'MarkerFaceColor', 'w');
        %'Color', colors(k,:),...     
end
hold off

% 图形美化
grid on;
xlabel('漫流宽度参数 (m)', 'FontWeight','bold', 'FontSize',12);
ylabel('纳什效率系数 (NSE)', 'FontWeight','bold', 'FontSize',12);
%title('G-Width对NSE的影响', 'FontSize',14);

% 添加图例
legendLabels = arrayfun(@(r) sprintf('降雨历时 %d min', r), rain+4, 'UniformOutput', false);
legend(legendLabels,...
    'Location', 'bestoutside',...
    'FontSize', 10,...
    'NumColumns', 2);  % 分两列显示图例

% 设置坐标轴范围
xlim([min(G_width_Param), max(G_width_Param)]);
ylim([-1.1, 1]);  % NSE理论范围[-∞,1]，实际常用[-1,1]
set(gca, 'YTick', -1:0.2:1);









