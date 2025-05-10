%% 流量过程线验证程序
% 快速找到指定文件，写入指定参数，进行过程线导出，并计算NSE，对效果进行验证

% SWMM_model_running输出一个2400 * 11的结果矩阵
% 上程序内置timeseries_file_generate(locG, rain, LOC_RAIN, newValue)

% mex -setup;loadlibrary('swmm5');%每次重新打开软件都要创建一次

%% 参数确认
rain = [1,2,3,4,5,6,7,8,9,10,11];% 1a - rainfall
nodesCount = (5);
drainlength = 500;
width = 4000;
node_T = 127;

%指定模拟时间(min)，图像横坐标
time = 40;
steps = 40 * 60;

% 管长数据
%Length_Param = length * multipliers;

Length_Param = drainlength;
Length_Param = round(Length_Param * 1000) / 1000;
current_NC = nodesCount;
current_W = width;
current_TL = drainlength;

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

% G_Model文件run
    % 参数指定
    % 生成动态文件路径
    current_file = fullfile(output_dir, sprintf(file_template, current_NC));

    locG = current_file;
    locG_temp = strrep(locG,'.inp','temp.inp');
    locG_temp_report = strrep(locG_temp,'temp.inp','temp.rpt');
    copyfile(locG,locG_temp); %此句之后的文件均用temp

    % 漫流宽度写入
    sectionLine=findInpSectionLine(locG_temp, 'SUBCATCHMENTS');
    width_file_generate(locG_temp ,locG_temp , sectionLine ,current_W );

    % 管道参数修改
    % drain_file_generate(locG , node , LOC_CONDUITS , LOC_JUNCTIONS_1st, LOC_JUNCTIONS_2nd , G_Length , G_Height)
     drain_file_generate(locG_temp , current_NC , 52 , 18, 29 , current_TL , 9.1);

    % 步骤4：运行模型
    % SWMM_model_running(inputfile, report_file, rain, current_NC) 
    %                    输入文件， 运行需要， 降雨数量，节点指定
    B_G = SWMM_model_running(locG_temp ,locG_temp_report ,rain, current_NC);
    % B_G = (steps ,length(rain) ,param_num) = (2400, 11, NC)
    
    flow_mean_G = mean(B_G, 2);
%% 求NSE
 R = NSE_calculation1(A_T,B_G)
 %R = NSE_calculation_un2(A_T,B_G)
 % 注意输入矩阵的规模匹配

%% 流量过程线评价
% 计算残差（模拟与观测的差异）
residual = abs(A_T - B_G);

% 计算残差的标准差和变异系数
SD_residual = std(residual);
CV_residual = SD_residual ./ mean(abs(residual)); % 使用绝对残差均值更稳健
CV_Total = mean(CV_residual);
 
for i = length(rain)

    peak_temp = abs((max(B_G(1)) ./ max(A_T)) - 1);
end

%% 流量过程线绘图（双模型对比版）

figure('Name','流量过程线验证','NumberTitle','off', 'Position', [200 200 1400 800]);

% 生成时间轴（分钟）
time_min = linspace(0, time, steps);

% 设置透明度参数（事件1最透明，事件11最不透明）
alpha_values = linspace(0.5, 1, length(rain)); 

% 创建颜色映射
model_colors = [0 0 0;  % 黑色代表T模型
                1 0 0]; % 红色代表G模型

% 绘制各降雨事件的双模型曲线
hold on
for rain_idx = 1:length(rain)

    % 当前透明度
    current_alpha = alpha_values(rain_idx);
    
    % 绘制T模型曲线
    plot(time_min, A_T(:,rain_idx),...
        'Color', [model_colors(1,:) current_alpha],... % 黑色+透明度
        'LineWidth', 1.5,...
        'LineStyle', '-')
    
    % 绘制G模型曲线
    plot(time_min, B_G(:,rain_idx),...
        'Color', [model_colors(2,:) current_alpha],... % 红色+透明度
        'LineWidth', 1.5,...
        'LineStyle', '-')


end

hold off

% 图形美化
grid on
xlabel('模拟时间 (分钟)', 'FontSize', 11, 'FontWeight', 'bold')
ylabel('流量 (L/s)', 'FontSize', 11, 'FontWeight', 'bold')
title(sprintf('%d node - 流量过程线', current_NC), 'FontSize', 13)

%% 修改后的图例代码（参数化标签）
% 生成动态图例标签
legend_labels = cell(1, 2*length(rain));  % 预分配内存
line_handles = gobjects(1, 2*length(rain));  % 图形句柄数组

% 创建虚拟图形对象并生成标签
hold on
for i = 1:length(rain)
    % T模型曲线句柄（实线）
    line_handles(2*i-1) = plot(NaN, NaN,...
        'Color', model_colors(1,:),...
        'LineWidth', 2,...
        'LineStyle', '-');
    
    % G模型曲线句柄（虚线）
    line_handles(2*i) = plot(NaN, NaN,...
        'Color', model_colors(2,:),...
        'LineWidth', 2,...
        'LineStyle', '-');
    
    % 生成带参数的标签
    param_value = rain(i) + 4;  % 计算参数值
    legend_labels{2*i-1} = sprintf('T-Model-%dmin', param_value);
    legend_labels{2*i} = sprintf('G-Model-%dmin', param_value);
end
hold off
%% 优化后的图例代码（模型分类集中）
% 生成分类的图例标签和句柄
model_types = {'T-Model', 'G-Model'};
line_handles = gobjects(length(rain)*2, 1);  % 预分配句柄数组
legend_labels = cell(length(rain)*2, 1);    % 预分配标签数组

% 先创建所有T模型条目，再创建所有G模型条目
color_idx = 1;  % T模型颜色索引
for m = 1:length(model_types)
    hold on
    for r = 1:length(rain)
        % 计算当前索引
        idx = (m-1)*length(rain) + r;
        
        % 统一模型颜色（T:黑，G:红）
        line_color = model_colors(m,:);
        
        % 创建虚拟线（T用实线，G用虚线）
        line_style = '-';
        if strcmp(model_types{m}, 'G-Model')
            line_style = '-';
        end
        
        line_handles(idx) = plot(NaN, NaN,...
            'Color', line_color,...
            'LineWidth', 2,...
            'LineStyle', line_style);
        
        % 生成标签（示例：T_Model-11min）
        param_value = rain(r) + 4;
        legend_labels{idx} = sprintf('%s-%dmin', model_types{m}, param_value);
    end
    hold off
end

% 创建分栏图例
lgd = legend(line_handles, legend_labels,...
    'Location', 'northeastoutside',...
    'FontSize', 10,...
    'NumColumns', 2);  % 按模型类型分栏


% 优化图例布局
lgd.Title.String = '模型-降雨历时';
lgd.Title.FontSize = 9;
set(lgd, 'ItemTokenSize', [15, 18]);  % 缩小图例项间距

% 坐标轴优化
set(gca, 'FontSize', 10, 'LineWidth', 1.2)
xlim([0 time])
xticks(0:5:time)