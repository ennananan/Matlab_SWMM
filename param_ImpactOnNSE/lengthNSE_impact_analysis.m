%% 计算管道长度对模型NSE的影响
% 更改降雨序列，根据文件名识别节点数，计算NSE变化规律
% SWMM_model_running输出一个2400 * 11的结果矩阵
% 上程序内置timeseries_file_generate(locG, rain, LOC_RAIN, newValue)

% mex -setup;loadlibrary('swmm5');%每次重新打开软件都要创建一次

%% 参数确认
rain = [1,2,3,4,5,6,7,8,9,10,11];% 1a - rainfall
nodesCount = [2,3,4,5,6,7];
ave_length = 112.4;
node_T = 127;

%指定模拟时间(min)，图像横坐标
time = 40;
steps = 40 * 60;

% 管长数据计算
paramgap = 15;
lowmultiple = 0.5;
upmultiple = 5;
multipliers = linspace(lowmultiple, upmultiple, paramgap);
Length_Param = ave_length * multipliers;
Length_Param = round(Length_Param * 1000) / 1000;


% G-Model 文件路径
base_path = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\';
file_template = 'UR_GModel_ds_3_%dnode_ver.inp'; % %d为节点数占位符
output_dir = fullfile(base_path);


% T-Model 文件路径
% 文件查找和运行
version_match = regexp(file_template, 'ds_(\d+)', 'tokens');
if isempty(version_match)
    error('模板文件名格式错误，未找到ds_版本号');
end
ds_version = version_match{1}{1};  % 提取到'3'

% 生成目标路径（自动继承版本号）
new_filename = sprintf('UR_TModel_ds_%s.inp', ds_version);  % 动态插入版本号
output_path = fullfile(base_path, new_filename);
% current_file1 = fullfile(output_dir, sprintf(file_template, current_NC));


%T-Model 计算
locT = output_path;
locT_temp = strrep(locT, '.inp', 'temp.inp');
locT_temp_report = strrep(locT_temp, 'temp.inp', 'temp.rpt');
copyfile(locT, locT_temp);

% SWMM_model_running(inputfile, report_file, rain, param_num, param_index, current_NC)
A_T = SWMM_model_running(locT_temp ,locT_temp_report ,rain, node_T);
% A = (steps ,length(rain) ,param_num) = (2400, 11, 1)
A_T;
size(A_T);

R = zeros(size(Length_Param,2), size(rain,2), size(nodesCount,2));

% G_Model文件遍历
for node_idx  = 1: size(nodesCount,2)

    % 参数指定
    current_NC = nodesCount(:,node_idx);
    current_W = 2114;
    % 生成动态文件路径
    current_file = fullfile(output_dir, sprintf(file_template, current_NC));

    locG = current_file;
    locG_temp = strrep(locG,'.inp','temp.inp');
    locG_temp_report = strrep(locG_temp,'temp.inp','temp.rpt');
    copyfile(locG,locG_temp); %此句之后的文件均用temp

    % 漫流宽度写入
    sectionLine=findInpSectionLine(locG_temp, 'SUBCATCHMENTS');
    width_file_generate(locG_temp ,locG_temp , sectionLine ,current_W );

    % 管道模型run

    B_G = zeros(steps, length(rain), size(Length_Param,2));

    for len_idx = 1:size(Length_Param,2)

    current_TL = Length_Param(:,len_idx);

    % 管道参数修改
    % drain_file_generate(locG , node , LOC_CONDUITS , LOC_JUNCTIONS_1st, LOC_JUNCTIONS_2nd , G_Length , G_Height)
     drain_file_generate(locG_temp , current_NC , 52 , 18, 29 , current_TL , 9.1);

    % 步骤4：运行模型
    % SWMM_model_running(inputfile, report_file, rain, current_NC) 
    %                    输入文件， 运行需要， 降雨数量，节点指定
    B_G(:,:,len_idx) = SWMM_model_running(locG_temp ,locG_temp_report ,rain, current_NC);
    % B_G = (steps ,length(rain) ,param_num) = (2400, 11, NC)
    end

%% 求NSE
 R(:,:,node_idx) = NSE_calculation_3d_opticalvision(B_G, A_T);
% 注意输入矩阵的规模匹配
end
% R

%% 绘图

figure('Name','管道长度对NSE的影响分析','NumberTitle','off');
set(gcf, 'Position', [100 100 1600 900], 'Color', 'w');
colorMatrix = absorption_palette().colors;

%% 智能布局计算（无函数封装）
numNodes = length(nodesCount);
% 固定两行布局规则
rows = 2;                       
cols = ceil(numNodes / rows);  % 计算所需列数
% 优化列数以减少空白
while (rows*cols - numNodes) >= cols
    cols = cols - 1;
end

%% 主绘图循环（修改后）
for nodeIdx = 1:numNodes
    currentNodes = nodesCount(nodeIdx);
    % 动态子图位置计算
    subplotRow = ceil(nodeIdx / cols);
    subplotCol = mod(nodeIdx-1, cols) + 1;
    subplot(rows, cols, (subplotRow-1)*cols + subplotCol);
    
    %% 数据提取与校验
    try
        currentData = R(:,:,nodeIdx);
        if size(currentData,1) ~= length(Length_Param)
            error('维度不匹配: 管长参数数量%d ≠ 数据长度%d',...
                  length(Length_Param), size(currentData,1));
        end
    catch ME
        warning('节点%d数据异常: %s', currentNodes, ME.message);
        continue; 
    end

    %% 可视化绘制
    hold on
    for rainIdx = 1:length(rain)
        plot(Length_Param, currentData(:,rainIdx),...
            'Color', colorMatrix(rainIdx,:),...
            'LineWidth', 1.6,...
            'Marker', 's',...
            'MarkerSize', 5,...
            'MarkerFaceColor', 'w')
    end
    hold off
    
    %% 图形标注
    grid on
    title(sprintf('节点数: %d', currentNodes), 'FontSize', 10)
    xlabel('管道长度 (m)', 'FontSize', 9)
    ylabel('NSE', 'FontSize', 9)
    xlim([min(Length_Param), max(Length_Param)])
    ylim([floor(min(currentData(:))*20)/20, 1.01])

    % 计算全局最大值
    maxValue = max(currentData(:));
    
    % 绘制最大值参考线（红色虚线）
    line([min(Length_Param) max(Length_Param)], [maxValue maxValue],...
        'LineStyle', '--', 'Color', 'r', 'LineWidth', 1.2);
    
    % 在y轴右侧添加标签
    ax = gca;
    text(...
        max(Length_Param)*1.02, ...       % X位置：稍微超出右边界
        maxValue, ...                     % Y位置：最大值高度
        sprintf('Max= %.2f', maxValue),...% 文本内容
        'Color', 'r',...
        'FontSize', 8,...
        'VerticalAlignment', 'middle',...
        'HorizontalAlignment', 'left',...
        'Clipping', 'off'...              % 允许显示在坐标轴外
    ); 
end
    % 添加智能图例---------------------------------------------------------
    if numNodes <= 10  % 仅在小数量时显示图例
    lgd = legend(arrayfun(@(r) sprintf('Rainfall %d min',r), rain, 'UniformOutput',false));
    lgd.Position = [0.93 0.35 0.04 0.3];
    lgd.FontSize = 8;
    lgd.Title.String = '降雨事件';
    end
%% 布局优化
set(findall(gcf,'Type','axes'), 'LooseInset',[0.05 0.05 0.03 0.03]);