% width-length参数差异分析绘图代码
%% 文件load
% ###########################更改字段##############################
NAME = 'J17';
p = '1a';
nodesCount = (5); % 长度 = R的页数，概化范围总支管范围
nodename = num2str(nodesCount);
ave_length = 104.19;
C_width = 2334.37;
outlet_height = 9.1;
% ###########################更改字段##############################
rain = [1,2,3,4,5,6,7,8,9,10,11];% 1a - rainfall
save_path = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5.7-参数算法结果图\param_impact';
lengthname = num2str(ave_length);
widthname = num2str(C_width);
mat_path = fullfile(save_path, ['NSE-Width-length-', NAME,'-',nodename, '-', lengthname, '-', widthname, '.mat']);
load(mat_path); 

%% 绘图设置
unique_L = unique(param_combinations(:,1));  % 提取所有 Length 值
num_L = length(unique_L);
num_rain = size(R, 2);  % 雨型数量
min_R = min(R);
min_NSE = min(min_R);
subplot_labels = arrayfun(@(x) ['(', char(96 + x), ')'], 1:num_L, 'UniformOutput', false);

colors = absorption_palette().colors;  % 颜色设置

%% 创建 tiledlayout 图窗
figure;
t = tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

% 添加总标题
sgtitle(t, 'NSE vs Width for Different Lengths', ...
    'FontSize', 14, ...
    'FontName', 'Times New Roman');

%% 绘制每个子图
for i = 1:num_L
    ax = nexttile(i);  % 获取子图句柄
    hold(ax, 'on');
    grid(ax, 'on');

    current_L = unique_L(i);
    idx = param_combinations(:,1) == current_L;
    W_vals = param_combinations(idx, 2);
    R_vals = R(idx, :);

    [W_sorted, sort_idx] = sort(W_vals);
    R_sorted = R_vals(sort_idx, :);

    for j = 1:num_rain
        plot(ax, W_sorted, R_sorted(:, j), '-o', ...
             'Color', colors(j,:), 'LineWidth', 1.2);
    end

    % 添加最大 NSE 虚线
    max_R = max(R_sorted(:));
    yline(ax, max_R, 'r--', ['Max NSE: ', num2str(round(max_R, 3))], ...
          'FontSize', 8, 'FontName', 'Times New Roman', ...
          'LabelHorizontalAlignment', 'right', ...
          'LabelVerticalAlignment', 'bottom');

    % 坐标设置
    title(ax, [subplot_labels{i}, ' Length = ', num2str(current_L)], ...
          'FontSize', 12, 'FontName', 'Times New Roman');
    xlabel(ax, 'Width', 'FontSize', 12, 'FontName', 'Times New Roman');
    ylabel(ax, 'NSE', 'FontSize', 12, 'FontName', 'Times New Roman');
    set(ax, 'FontSize', 10, 'FontName', 'Times New Roman');
    ylim(ax, [min(R(:)), 1]);

    % 图例只加一次
    if i == 6
        legend_labels = arrayfun(@(x) ['Rain-', num2str(x), ' min'], rain + 4, 'UniformOutput', false);
        lgd = legend(ax, legend_labels, 'Location', 'eastoutside');
        set(lgd, 'FontSize', 8, 'FontName', 'Times New Roman');
    end
end
