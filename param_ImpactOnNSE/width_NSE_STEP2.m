%% 程序简化，数据读取——resultsaving后的一步
file_path = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\7-运行结果储存\widthNSE_Nodes1-2-3-4-5-6-7-8_20250418_163105';
load(file_path);  % 加载后变量 R, Length_Param 等将直接可用
%% 极值判断

R_page_means = mean(R, [1,2]); % 三维每页有一个值
R_page_means = squeeze(R_page_means); %一个列向量

R_row_Means = mean(R, 2); %三维数组每页每行求均值
R_row_Means = squeeze(R_row_Means); % 每列为页，每行为行均值

%% NSE结果到参数索引
[~, sorted_R_pages_indices] = sort(R_page_means, 'descend'); % 1 * k
% 索引节点
new_nodesCount = nodesCount(sorted_R_pages_indices(1:4));

% 管长索引
rowOverallMeans = mean(R_row_Means, 2); % 按行方向（维度2）求均值
% 按行均值从高到低排序，并获取原始行索引
[sorted_R_length_Means, sorted_R_length_Indices] = sort(rowOverallMeans, 'descend');

selected_data = sorted_R_length_Indices((1:4),:);
rows_means = round(mean(selected_data(:)));

new_lengthParam = Length_Param(rows_means - 2:rows_means + 2) ;

%% 根据索引的新取值，扫描漫流宽度，注意尺寸和速度控制
% 根据节点索引对应G_Model文件，T_Model 结果A_T可以继续使用
% 形成参数组合矩阵
[Length_grid, Width_grid] = meshgrid(new_lengthParam, Width_Param);
% 组合矩阵：管长 * 5，width * 15
param_combinations = [Length_grid(:), Width_grid(:)];
total_combinations = size(param_combinations, 1); % 参数组合总数
 
% G_Model文件遍历 
R_width = zeros(total_combinations, length(rain), size(new_nodesCount,2));

for node_idx  = 1: size(new_nodesCount,2)
    % 参数指定
    current_NC = new_nodesCount(:,node_idx);
    
    % 生成动态文件路径
    current_file = fullfile(output_dir, sprintf(file_template, current_NC)); % 原文件

    locG = current_file;
    locG_temp = strrep(locG,'.inp','temp1.inp');
    locG_temp_report = strrep(locG_temp,'temp1.inp','temp1.rpt');
    copyfile(locG,locG_temp); %此句之后的文件均用temp
    % 管道模型run
    % 管长写入

    %B_G = zeros(steps, length(rain), size(new_lengthParam,2));
    B_G = zeros(steps, length(rain), total_combinations);
    
    for combo_idx = 1:total_combinations

        current_TL = param_combinations(combo_idx, 1);  % 当前管长
        current_W = param_combinations(combo_idx, 2);   % 当前宽度
    % 管道参数修改
    % drain_file_generate(locG , node , LOC_CONDUITS , LOC_JUNCTIONS_1st, LOC_JUNCTIONS_2nd , G_Length , G_Height)
     drain_file_generate(locG_temp , current_NC , 52 , 18, 29 , current_TL , 9.1); % 关键词寻找已经内置

    % 漫流宽度写入
    sectionLine=findInpSectionLine(locG_temp, 'SUBCATCHMENTS');
    width_file_generate(locG_temp ,locG_temp , sectionLine ,current_W );

    % 步骤4：运行模型
    % SWMM_model_running(inputfile, report_file, rain, current_NC) 形成2400 * 11的结果矩阵
    %                    输入文件， 运行需要， 降雨数量，节点指定
    B_G(:,:,combo_idx) = SWMM_model_running(locG_temp ,locG_temp_report ,rain, current_NC);
    % B_G = (steps ,length(rain) ,param_num) = (2400, 11, NC)
    end
%% 求NSE
 R_width(:,:,node_idx) = NSE_calculation_3d_opticalvision(B_G, A_T); 
% 注意输入矩阵的规模匹配
end
R_width
% R_width
%% 极值判断

% 节点索引
R_page_means = mean(R_width, [1,2]); % 三维每页有一个值
R_page_means = squeeze(R_page_means); %一个列向量
[sorted_R_pages_values, sorted_R_pages_indices] = sort(R_page_means, 'descend'); % 1 * k

max_page = new_nodesCount(sorted_R_pages_indices(1)) % 节点数目确定
% R_width(:, :, sorted_R_pages_indices(1)) %演算

% 参数组合索引
R_row_Means = mean(R_width, 2); %每页每行求均值
R_row_Means = squeeze(R_row_Means); % 每列为页，每行为行均值
rowOverallMeans = mean(R_row_Means, 2); % 按行方向（维度2）求均值
% 按行均值从高到低排序，并获取原始行索引
[sorted_paramcon_Means, sorted_parmcon_Indices] = sort(rowOverallMeans, 'descend');

% 从这里即可获得相对最好的参数组合了,对这两个参数求均值，即可获得最佳参数
max_length = param_combinations(sorted_row_means_indices(1:10),1);
max_width = param_combinations(sorted_row_means_indices(1:10),2);
best_length = mean(max_length)
best_width = mean(max_width)


%% 模拟结果分析及绘图
% param_confirm(:,:,1)，第一行的每个元素为所有length取值；
% param_confirm(:,:,2)，第一列的每个元素为所有width取值；
param_confirm = reshape(param_combinations, [length(Width_Param), length(new_lengthParam), 2])

% R_result，每页为一个降雨，每页尺寸与param_confirm每页尺寸一致，及两参数组合获取的R结果
R_result = reshape(R_width(:,:,sorted_R_pages_indices(1)), [length(Width_Param), length(new_lengthParam), length(rain)])

%% 结果可视化（动态布局，标记最大值）
% 获取参数数量
num_lengths = length(new_lengthParam);

% 动态计算行列数（每行最多3个子图）
max_cols = 3; % 每行最多显示3个子图
nRows = ceil(num_lengths / max_cols); % 行数
nCols = min(num_lengths, max_cols);   % 列数

% 创建figure（根据行数调整窗口高度）
figure('Position', [100, 100, 1600, 400*nRows]); 
set(gcf, 'Color', 'w');

% 生成颜色方案（使用absorption_palette的colors属性）
color_palette = absorption_palette().colors; % 直接调用颜色矩阵

% 遍历每个new_lengthParam
for length_idx = 1:num_lengths
    % 创建子图（动态行列布局）
    subplot(nRows, nCols, length_idx);
    hold on;
    
    % 获取当前length对应的数据
    current_data = squeeze(R_result(:, length_idx, :)); % Width × rain
    
    % 计算全局最大值
    global_max = max(current_data(:));
    
    % 绘制所有降雨情景的曲线
    for rain_idx = 1:length(rain)
        y_data = current_data(:, rain_idx);
        plot(Width_Param, y_data,...
            'LineWidth', 1.5,...
            'Color', color_palette(rain_idx, :),...
            'Marker', 'o',...
            'MarkerSize', 4);
    end

    % 标记最大值
    yline(global_max, '--r', 'LineWidth', 1.8);
     % 在y轴右侧添加标签
    ax = gca;
    text(...
        max(Width_Param)*1.02, ...       % X位置：稍微超出右边界
        global_max, ...                     % Y位置：最大值高度
        sprintf('Max= %.2f', global_max),...% 文本内容
        'Color', 'r',...
        'FontSize', 8,...
        'VerticalAlignment', 'middle',...
        'HorizontalAlignment', 'left',...
        'Clipping', 'off'...              % 允许显示在坐标轴外
    ); 
    
    % 图形修饰
    title(sprintf('Length = %.1f', new_lengthParam(length_idx)));
    xlabel('Width');
    ylabel('NSE');
    grid on;
    xlim([min(Width_Param), max(Width_Param)]);
    % ylim([floor(min(current_data(:))*10)/10, ceil(global_max*1.1)]);
    ylim([floor(min(current_data(:))*20)/20, 1.01])
    hold off;
end

% 添加共享图例（位于右下角空白区域）
if num_lengths < nRows*nCols
    legend_pos = [0.85, 0.1, 0.1, 0.2]; % 右下角
else
    legend_pos = [0.92, 0.3, 0.05, 0.4]; % 右侧
end
legend_labels = arrayfun(@(x) sprintf('Rainfall %d', x), rain, 'UniformOutput', false);
lgd = legend(subplot(nRows, nCols, num_lengths), legend_labels, 'Position', legend_pos);

% 添加总标题
annotation('textbox', [0.4, 0.95, 0.2, 0.05],...
    'String', 'NSE vs Width for Different Lengths',...
    'HorizontalAlignment', 'center',...
    'FontSize', 14,...
    'EdgeColor', 'none');

% 保存图形
saveas(gcf, fullfile(output_dir, 'Dynamic_Layout_Width_NSE.png'));