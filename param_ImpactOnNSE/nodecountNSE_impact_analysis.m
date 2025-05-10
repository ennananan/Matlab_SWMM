%% 计算节点数量对模型过程流量NSE的影响
% 更改降雨序列，根据文件名识别节点数，计算NSE变化规律
% SWMM_model_running输出一个2400 * 11的结果矩阵
% 上程序内置timeseries_file_generate(locG, rain, LOC_RAIN, newValue)

% mex -setup;loadlibrary('swmm5');%每次重新打开软件都要创建一次

rain = [1,2,3,4,5,6,7,8,9,10,11];% 1a - rainfall
nodesCount = [1:25];

%指定模拟时间(min)，图像横坐标
time = 40;
steps = 40 * 60;

% G-Model 文件路径
base_path = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\';
file_template = 'UR_GModel_ds_3_%dnode_ver.inp'; % %d为节点数占位符
output_dir = fullfile(base_path);
B_G = zeros(steps, length(rain));

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
node_T = 127;
locT = output_path;
locT_temp = strrep(locT, '.inp', 'temp.inp');
locT_temp_report = strrep(locT_temp, 'temp.inp', 'temp.rpt');
copyfile(locT, locT_temp);

for rain_num = 1:length(rain)
    
    % SWMM_model_running(inputfile, report_file, rain, param_num, param_index, current_NC)
     A_T = SWMM_model_running(locT_temp ,locT_temp_report ,rain, node_T);
     % A = (steps ,length(rain) ,param_num) = (2400, 11, 1)
end
A_T;
size(A_T);

% G_Model文件遍历
for i = 1: size(nodesCount,2)

    %参数指定
    current_NC = i;
    current_W = 2114;
    current_TL = 112;

    % 生成动态文件路径
    current_file = fullfile(output_dir, sprintf(file_template, current_NC));
    locG = current_file;
    locG_temp = strrep(locG,'.inp','temp.inp');
    locG_temp_report = strrep(locG_temp,'temp.inp','temp.rpt');
    copyfile(locG,locG_temp); %此句之后的文件均用temp

    % 漫流宽度写入
    sectionLine=findInpSectionLine(locG_temp, 'SUBCATCHMENTS');
    width_file_generate(locG_temp ,locG_temp , sectionLine ,current_W );
    % 管道数据写入
    % drain_file_generate(locG , node , LOC_CONDUITS , LOC_JUNCTIONS_1st, LOC_JUNCTIONS_2nd , G_Length , G_Height)
     drain_file_generate(locG_temp , current_NC , 52 , 18, 29 , current_TL , 9.1);
    % 步骤4：运行模型
    % SWMM_model_running(inputfile, report_file, rain, current_NC) 
    %                    输入文件， 运行需要， 降雨数量，节点指定
    % 节点数量索引
    
    result = SWMM_model_running(locG_temp ,locG_temp_report ,rain, current_NC);
    B_G(:,:,i) = result;
    % B_G = (steps ,length(rain) ,param_num) = (2400, 11, NC)
end


%% 求NSE
R = NSE_calculation_3d_opticalvision(B_G, A_T)
% 注意输入矩阵的规模匹配

%% NSE参数敏感性分析绘图
figure('Name','NSE-nodesCount变化分析','NumberTitle','off');

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
    x = nodesCount;
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
xlabel('管道节点', 'FontWeight','bold', 'FontSize',12);
ylabel('纳什效率系数 (NSE)', 'FontWeight','bold', 'FontSize',12);
%title('G-Width对NSE的影响', 'FontSize',14);

% 添加图例
legendLabels = arrayfun(@(r) sprintf('降雨历时 %d min', r), rain+4, 'UniformOutput', false);
legend(legendLabels,...
    'Location', 'bestoutside',...
    'FontSize', 10,...
    'NumColumns', 2);  % 分两列显示图例

% 设置坐标轴范围
xlim([min(nodesCount), max(nodesCount)]);
ylim([-0.8, 1]);  % NSE理论范围[-∞,1]，实际常用[-1,1]
set(gca, 'YTick', -1:0.2:1);

      
