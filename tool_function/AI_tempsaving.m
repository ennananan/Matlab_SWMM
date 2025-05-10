file_path = '/Users/enna_macbook/Documents/graduate/大论文/nodesCount5_1aT_result_sorted.mat';
load(file_path);  
length = T_result_sorted{2:end,1};
selected_data = T_result_sorted{:, {'Length', 'Width','NSE'}}; % 通过列名

figure;
scatter(selected_data(:,1), selected_data(:,2), 40, selected_data(:,3), 'filled');
colorbar;
xlabel('Length');
ylabel('Width');
title('局部细化搜索结果热力图');
colormap(turbo);  % 或使用你自定义的 colormap
grid on;
set(gca, 'FontSize', 12);
clim([0.5 1]);

% 设置图像尺寸与导出分辨率
set(gcf, 'Position', [100 100 800 600]);  % 可选设置图像尺寸

% 保存为 PNG，300 dpi 分辨率
output_file = 'search_result_heatmap.png';
exportgraphics(gcf, output_file, 'Resolution', 300);
