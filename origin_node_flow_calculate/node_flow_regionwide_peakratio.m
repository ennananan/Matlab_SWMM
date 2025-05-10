function node_flow_regionwide_peakratio

% 计算T和G模型的流量峰值比，以判断对峰值流量的模拟效果，三维*11条线
 mex -setup;loadlibrary('swmm5');%每次重新打开软件都要创建一次
%node=(3); 
% G-Model-B


nodes=(128); % T-Model-A

rain=[1,2,3,4,5,6,7,8,9,10,11];%1a-rainfall

%指定模拟时间(min)，图像横坐标
time=40;
gagetime=ones(length(rain));

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

steps = 60*time; 
rain_count = length(rain);
A_T = ones(steps,length(rain)); % A赋值为T-Model
B_G  = ones(steps,length(rain)); % B赋值为G-Model

%设定参数跨度
G_width = 2334.2;
paramgap = 40;
lowmultiple = 0.1;
upmultiple = 2;
multipliers = linspace(lowmultiple, upmultiple, paramgap);
G_width_Param = G_width * multipliers;
G_width_Param = round(G_width_Param * 1000)/1000;

%数组初始化
C = ones(steps, paramgap, rain_count);
D = ones(steps, paramgap, rain_count);
B_G = ones(steps, paramgap, rain_count);% B赋值为G-Model
A_T = ones(steps, paramgap, rain_count);% A赋值为T-Model

%G-Model

%小节位置寻找
sectionLine = findInpSectionLine(locG_temp, 'SUBCATCHMENTS');
%gagetime(gages)=4+rain(gages);%时间标签

%降雨序列更换
%parameter_modify_TS(locG,locG_temp,'TS1',char('TS'+string(rain(gages))));
for k=1:rain_count
    parameter_modify_TS(locG,locG_temp,'TS1',char('TS'+string(rain(k))));

    for j=1:paramgap 
    %for j=1

        %广域漫流宽度参数更改
         % replaceInpColumnValue(locG,locG_temp, sectionLine, G_width_Param(j)); 
         % 经过验证，replaceInpColumnValue是在写入过程中会产生错误的参数修改，后续不使用
         replaceInpValue_write_in(locG, locG_temp, sectionLine, 1, 70, G_width_Param(j))

        %调用文件位置
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
calllib('swmm5','swmm_close')

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

% 峰值相似度计算
% 提取每个参数&降雨情景下的流量峰值
max_A_T = squeeze(max(A_T,[],1)); % [paramgap × rain_count]
max_B_G = squeeze(max(B_G,[],1)) % [paramgap × rain_count]


% 计算相似度矩阵（T-Model与G-Model峰值比）
 similarity = max_A_T ./ max_B_G;

% 找到最优参数索引（每个降雨情景下相似度最接近1的参数）
%[~,optimal_idx] = min(abs(similarity - 1), [], 1);

%% 三维垂线绘制
figure('Name','参数-降雨-峰值比三维视图','Renderer','OpenGL');
hold on;

% 参数配置
density = 20;        % 垂线密度（插值倍数）
line_alpha = 0.18;   % 垂线透明度
base_z = 0;          % 垂线基准高度

cmap = parula(rain_count); % 颜色映射

% 预存储最近点矩阵
closest_points = zeros(rain_count, 3); % [x,y,z]

for k = 1:rain_count
    % 原始数据
    x_orig = G_width_Param;
    y_val = rain(k);
    z_orig = similarity(:,k)';
    
    % 样条插值扩展数据
    %x_interp = linspace(min(x_orig), max(x_orig), numel(x_orig)*density);
    %z_interp = interp1(x_orig, z_orig, x_interp, 'spline');
        % 构建垂线坐标矩阵（向量化操作）
    %line_matrix = [x_interp; x_interp; 
     %              y_val*ones(size(x_interp)); y_val*ones(size(x_interp));
      %             z_interp; base_z*ones(size(x_interp))];
        % 批量绘制垂线（颜色同步）
    %line(line_matrix(1:2,:,:),...
    %                    line_matrix(3:4,:,:),...
     %                   line_matrix(5:6,:,:),...
      %                  'Color', [cmap(k,:) line_alpha],... % RGBA四通道
       %                 'LineWidth', 1.2);
    
    % 绘制主折线（增强对比度）
    plot3(x_orig, y_val*ones(size(x_orig)), z_orig,...
          'Color', cmap(k,:),...
          'LineWidth', 3,...
          'Marker','o',...
          'MarkerSize',1,...
          'MarkerFaceColor',cmap(k,:));

    % ====== 最近点检测算法 ======
    [~, idx] = min(abs(z_orig - 1));  % 找到最接近1的索引
    closest_points(k,:) = [x_orig(idx), y_val(1), z_orig(idx)]; % 存储坐标
end
% 按降雨强度排序坐标点
[~, sort_idx] = sort(closest_points(:,2)); % 按y值排序
sorted_points = closest_points(sort_idx,:);
% 专业级标记绘制
scatter3(sorted_points(:,1), sorted_points(:,2), sorted_points(:,3),...
    10,...                         % 标记尺寸
    'k',...                         % 黑色轮廓
    'filled',...                    % 实心填充
    'MarkerEdgeColor',[0.2 0.2 0.2],... % 边缘颜色
    'MarkerFaceAlpha',0.8,...       % 填充透明度
    'MarkerEdgeAlpha',0.9);         % 边缘透明度

% 工业级连接线绘制
plot3(sorted_points(:,1), sorted_points(:,2), sorted_points(:,3),...
    'Color','k',...
    'LineWidth',2.5,...
    ['LineSt' ...
    'yle'],'-.',...            % 虚线样式
    'Marker','none',...
    'LineJoin','round');            % 连接处圆角处理

% 图形优化
view(60,30);
light('Position',[-1 0 1],'Color',[0.8 0.8 1]);
lighting gouraud;
material dull;
grid on;
xlabel('漫流宽度参数 (m)');
ylabel('降雨强度等级');
zlabel('T/G 峰值流量比');

% 添加图例说明
legend('原始数据折线','最优临界点',...
    'Location','northeastoutside');

% 三维场景优化
view(60,30);
light('Position',[-1 0 1],'Color',[0.8 0.8 1]);
lighting gouraud;
material dull;
zlim([base_z max(zlim)*1.1]);
grid on;