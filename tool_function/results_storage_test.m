%% 文件保存test-部分格式指定

% mex -setup;loadlibrary('swmm5');%每次重新打开软件都要创建一次
%文件保存地址
output_basicpath = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\7-运行结果储存';

%% 参数确认
rain = [1,2,3,4,5,6,7,8,9,10,11];% 1a - rainfall
nodesCount = [5]; % R的页数
ave_length = 112.4;
C_width = 2334.4;
node_T = 127;

%指定模拟时间(min)，图像横坐标
time = 40;
steps = 40 * 60;

% 管长数据计算
paramgap = 15; %后续参数指定部分
lowmultiple = 0.5;
upmultiple = 5;
multipliers = linspace(lowmultiple, upmultiple, paramgap);
Length_Param = ave_length * multipliers;
Length_Param = round(Length_Param * 100) / 100; % R的行数

% 漫流宽度计算
paramgap = 15; %后续参数指定部分
lowmultiple = 0.1;
upmultiple = 1.5;
multipliers = linspace(lowmultiple, upmultiple, paramgap);
Width_Param = C_width * multipliers;
Width_Param = round(Width_Param * 100) / 100; % R的行数

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
    % =====重点研究的部分======
    current_W = 2114;
    % ========================

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

    B_G = zeros(steps, length(rain), size(Length_Param,2)); % 很妙的位置选择，避免了使用四维数组来储存的问题
    for combo_idx = 1:size(Length_Param,2)

    current_TL = Length_Param(:,combo_idx);

    % 管道参数修改
    % drain_file_generate(locG , node , LOC_CONDUITS , LOC_JUNCTIONS_1st, LOC_JUNCTIONS_2nd , G_Length , G_Height)
     drain_file_generate(locG_temp , current_NC , 52 , 18, 29 , current_TL , 9.1);

    % 步骤4：运行模型
    % SWMM_model_running(inputfile, report_file, rain, current_NC) 
    %                    输入文件， 运行需要， 降雨数量，节点指定
    B_G(:,:,combo_idx) = SWMM_model_running(locG_temp ,locG_temp_report ,rain, current_NC);
    % B_G = (steps ,length(rain) ,param_num) = (2400, 11, NC)
    end

%% 求NSE
 R(:,:,node_idx) = NSE_calculation_3d_opticalvision(B_G, A_T);
 % 数据结构描述：管长 * 降雨 * 节点数
% 注意输入矩阵的规模匹配
end

%% 保存为 .mat 和 .csv 文件（文件名包含节点数和时间戳）
% 生成节点数列表的字符串（例如：'1-2-3-4-5-6-7-8'）
nodes_str = strjoin(string(nodesCount), '-');  % 将节点数数组转换为短横线连接的字符串

% 生成时间戳字符串（例如：'20231025_153025'）
timestamp = datestr(now, 'yyyymmdd_HHMMSS');

% 动态生成文件名
results_mat_file = fullfile(output_basicpath, ...
    sprintf('NSE_Results_Nodes%s_%s.mat', nodes_str, timestamp));
results_csv_file = fullfile(output_basicpath, ...
    sprintf('NSE_Results_Nodes%s_%s.csv', nodes_str, timestamp));

%% 保存为 .mat 文件（高效调用）
save(results_mat_file, 'R', 'Length_Param', 'Width_Param', 'nodesCount', 'rain', 'time', 'steps');
fprintf('MAT 文件已保存：%s\n', results_mat_file);

%% 保存为 .csv 文件（直接存储三维数组结构）
fid = fopen(results_csv_file, 'w', 'n', 'UTF-8');

% 写入元数据（参数信息）
fprintf(fid, ' ===== 参数信息 =====\n');

% 1. 节点数列表
fprintf(fid, ' 节点数列表:\n ');
nodes_str = strjoin(cellstr(num2str(nodesCount(:), '%d')), '   '); % 三个空格分隔整数
fprintf(fid, '%s\n', nodes_str);

% 2. 管长参数（保留两位小数）
fprintf(fid, ' 管长参数(m):\n ');
length_str = strjoin(cellstr(num2str(Length_Param(:), '%.2f')), '   '); % 三个空格分隔浮点数
fprintf(fid, '%s\n', length_str);

% 3. 漫流宽度参数（保留两位小数）
fprintf(fid, ' 漫流宽度参数(m):\n ');
width_str = strjoin(cellstr(num2str(Width_Param(:), '%.2f')), '   '); % 三个空格分隔浮点数
fprintf(fid, '%s\n', width_str);

% 4. 降雨编号（整数）
fprintf(fid, ' 降雨编号:\n ');
rain_str = strjoin(cellstr(num2str(rain(:), '%d')), '   '); % 三个空格分隔整数
fprintf(fid, '%s\n', rain_str);

% 数据格式说明
fprintf(fid, ' ===== 数据格式 =====\n');
fprintf(fid, ' 三维数组 R 结构: [管长参数 × 降雨编号 × 节点数]\n');

% 按「页」（节点数维度）写入数据
for node_idx = 1:length(nodesCount)
    fprintf(fid,'\n ===== nodescount(:, :, %d) =====\n', ...
        node_idx);
    current_page = R(:, :, node_idx);
    
    % 定义固定宽度格式（正数前补空格，总宽度9字符）
    format_str = '% 9.4f';  % 正数显示为 " 123.4567"，负数显示为 "-123.4567"
    
    for len_idx = 1:size(current_page, 1)
        % 转换为固定宽度的字符串
        formatted_values = arrayfun(@(x) sprintf(format_str, x), ...
            current_page(len_idx, :), 'UniformOutput', false);
        
        % 用逗号+空格连接字符串
        row_str = strjoin(formatted_values, ', ');
        fprintf(fid, '%s\n', row_str);
    end
end
fclose(fid);
fprintf('CSV 文件已保存：%s\n', results_csv_file);