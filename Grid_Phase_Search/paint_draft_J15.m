
file_path = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\7-运行结果储存\node_net_results\J10-2-1a_T_result_combinedsorted.mat';

load(file_path);  
length = T_result_sorted{2:end,1};
selected_data = T_result_sorted{:, {'Length', 'Width','NSE'}}; % 通过列名

%% 绘制参数搜索热力图（Length vs Width）
% 定义缩放比例
scale = 0.7;  % 调整此值控制整体缩放比例
figure;

hold on;
% 所有点
% 转换为倍数（相对原点）
x_coord_ratio = Length_all_combined / ave_length;
y_coord_ratio = Width_all_combined  / C_width;

% 仅保留 score >= 0 的点
valid_idx = score_combined >= 0.1;

x_coord_ratio_valid = x_coord_ratio(valid_idx);
y_coord_ratio_valid = y_coord_ratio(valid_idx);
score_valid = score_combined(valid_idx);

% 绘图
scatter(x_coord_ratio_valid, y_coord_ratio_valid, 50 * scale, score_valid, 'filled');


%scatter(x_coord_ratio, y_coord_ratio, 50 * scale, score_combined, 'filled');
 %scatter(Length_all_combined, Width_all_combined, 40, NSE_combined, 'filled');
% 找出 >=0.97 的点索引
idx_high = find(NSE_combined >= 0.975 & score_combined >= 0.82);

% 保存高分点进一步分析
length_high_score = Length_all_combined(idx_high);
width_high_score = Width_all_combined(idx_high);
NSE_high_score = NSE_combined(idx_high);
high_score = score_combined(idx_high);

high_score_result = [length_high_score, width_high_score, NSE_high_score, high_score];

%fprintf('第 %d 页没有位于边界且 NSE≥0.95 & Score ≥ 0.78 的点。\n', k);

T_high_score_result = table(length_high_score, width_high_score, NSE_high_score, high_score, ...
    'VariableNames', {'Length', 'Width', 'NSE', 'Score'});
nodename = num2str(nodesCount);

output_basicpath = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\7-运行结果储存\node_net_results';
mat_path = fullfile(output_basicpath, ['J17-',nodename, '-',p '-high_score_result_save.mat']);
save(mat_path, 'high_score_result', 'T_high_score_result', 'nodesCount','p', ...
    'ave_length', 'C_width','length_high_score','width_high_score','high_score', ...
    'NSE_high_score');
disp(['MAT文件已保存至: ' mat_path]);

% 高分点强调显示
scatter(x_coord_ratio(idx_high), y_coord_ratio(idx_high), ...
    5 * scale,  score_combined(idx_high), 'h', ...
   'LineWidth', 0.5 , ...
    'MarkerEdgeColor', 'r', ...
    'MarkerFaceColor', 'flat');

% 图形修饰
% 设置 y 轴边距
y_min = min(y_coord_ratio);
y_max = max(y_coord_ratio);
ylim([y_min, y_max + y_max/6]);

custom_colors = [
143  83   98    % #8f5362 深紫色
185 101  112    % #b96570 红褐色
211 123  109    % #d37b6d 橙褐色
224 169  129    % #e0a981 浅橙色
236 208  156    % #ecd09c 浅黄色
212 218  161    % #d4daa1 浅绿色
163 200  164    % #a3c8a4 绿色
121 180  160    % #79b4a0 深绿色
104 136  165    % #6888a5 蓝色
112 109  148    % #706d94 深蓝色
200  36   35]/255;   % #c82423 胭脂红

nColors = 400;
x = linspace(1, size(custom_colors,1), nColors);   % 插值位置
xi = 1:size(custom_colors,1);                      % 原始颜色位置

% 分别对 R、G、B 通道插值
cmap_interp = [
    interp1(xi, custom_colors(:,1), x)', ...
    interp1(xi, custom_colors(:,2), x)', ...
    interp1(xi, custom_colors(:,3), x)'
];

colormap(cmap_interp);  % 应用新 colormap
colorbar;
 
cb = colorbar;
cb.Label.String = 'Score'; % 设置颜色条标签
cb.Label.FontSize = 12 * scale;     % 可选：调整字体大小
cb.Label.Rotation = 270;    % 可选：控制旋转角度（默认是垂直）
cb.Label.VerticalAlignment = 'middle';
cb.Label.Position(1) = cb.Label.Position(1) + 0.9 * scale; % 可选：微调标签位置
cb.Label.Position(2) = 0.7 * cb.Ticks(end) ;  % 将标签放在色条中点附近
      
clim([0.25 0.835]);            % 可集中在高分区间

% 标题位置上移
%title('参数搜索热力图（NSE≥0.975 & Score >= 0.83）', 'Units', 'normalized', 'Position', [0.6, 1.02]);
%title('参数搜索热力图（NSE≥0.975 & Score >= 0.83）', ...
   % 'Units', 'normalized', 'Position', [0.6, 1.02], 'FontSize', 14 * scale);

xlabel('Ave-Length.Factor', 'FontSize', 12 * scale);
ylabel('C-Width.Factor', 'FontSize', 12 * scale);
grid on;
set(gca , 'FontSize', 12 * scale);

% 设置图像尺寸与导出分辨率
% 固定边距（归一化单位防止错位）
% gcf调图形位置，gca调内部
set(gca, 'Units', 'normalized', 'Position', [0.12 0.12 0.6 0.7]*1.1);

% 指定300 dpi 分辨率的png图像保存
save_path = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5.7-参数算法结果图\节点网格寻优';
output_png = 'J11.png';
output_fig = 'J11.fig';
output_svg = 'J11';
output_emf = 'J11.emf';

% 保存 PNG 文件
full_png_path = fullfile(save_path, output_png);
exportgraphics(gca, full_png_path, 'Resolution', 600);
disp(['png文件已保存至: ' full_png_path]);

% 保存 FIG 文件（正确方式）
full_fig_path = fullfile(save_path, output_fig);
savefig(gcf, full_fig_path);
disp(['fig文件已保存至: ' full_fig_path]);

% 保存矢量图svg格式
full_svg_path = fullfile(save_path, output_svg);
saveas(gcf, full_svg_path,'svg');

% 保存矢量图emf格式
full_emf_path = fullfile(save_path, output_emf);
exportgraphics(gca, full_emf_path, 'Resolution', 300);
