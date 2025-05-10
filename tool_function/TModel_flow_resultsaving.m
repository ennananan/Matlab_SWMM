%% 将T-Model的运行结果进行文件储存，注意文件路径与目标模型一致

% mex -setup;loadlibrary('swmm5');%每次重新打开软件都要创建一次
rain = [1,2,3,4,5,6,7,8,9,10,11];% 1a - rainfall
p = '1a';
node_T = 127;

%指定模拟时间(min)，图像横坐标
time = 40;
steps = 40 * 60;
%% *************注意文件路径与目标结果要一致**********
output_basicpath = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\7-运行结果储存';
base_path = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\';

% G-Model 文件路径
file_template = 'UR_GModel_ds_3_%dnode_ver.inp'; % 此处更改可以指定模型
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

%% 保存结果部分
% 生成基础文件名（去除扩展名）
filename_base = strrep(new_filename, '.inp', '');

% 确保输出目录存在
if ~exist(output_basicpath, 'dir')
    mkdir(output_basicpath);
end

%% 保存.mat文件
mat_path = fullfile(output_basicpath, [filename_base, '_',p '_Results.mat']);
save(mat_path, 'A_T', 'rain', 'new_filename');
disp(['MAT文件已保存至: ' mat_path]);

%% 保存.csv文件
csv_path = fullfile(output_basicpath, [filename_base, '_',p '_Results.csv']);

% 写入CSV文件头
fid = fopen(csv_path, 'w');
if fid == -1
    error('无法创建CSV文件');
end

% 第一行写入模型名称
fprintf(fid, 'ModelName,%s\n', new_filename);

% 第二行写入雨量值（列标题）
fprintf(fid, 'Rainfall(mm),');
fprintf(fid, '%g,', rain(1:end-1));
fprintf(fid, '%g\n', rain(end));

fclose(fid);

% 追加写入数据（保留4位小数）
dlmwrite(csv_path, A_T, '-append', 'delimiter', ',', 'precision', '%.4f');
disp(['CSV文件已保存至: ' csv_path]);



