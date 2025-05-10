function node_flow_regionwide_peak_ridge
% 漫流宽度扫描，峰值流量脊线
% mex -setup;loadlibrary('swmm5');%每次重新打开软件都要创建一次
% node = (3); 
% G-Model-B
nodes = (128); % T-Model-A

rain=[1,2,3,4,5,6,7,8,9,10,11];%1a-rainfall

%指定模拟时间(min)，图像横坐标
time = 40;
gagetime = ones(length(rain));

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

steps=60*time; 
rain_count=length(rain);


%设定参数跨度
G_width = 2334.2;
paramgap = 40;
lowmultiple = 0.1;
upmultiple = 2;
multipliers = linspace(lowmultiple, upmultiple, paramgap);
G_width_Param = G_width * multipliers;
G_width_Param = round(G_width_Param * 1000) / 1000;


%G-Model
C = ones(steps, paramgap, rain_count);
B_G = ones(steps, paramgap, rain_count);
A_T = ones(steps, paramgap, rain_count);
%小节位置寻找

sectionLine = findInpSectionLine(locG_temp, 'SUBCATCHMENTS');
%gagetime(gages)=4+rain(gages);%时间标签

for k=1:rain_count
    %降雨序列更改
    %timeseries_file_generate(locG_temp, rain, 59, k);
    parameter_modify_TS(locG,locG_temp,'TS1',char('TS'+string(rain(k))));

    for j=1:paramgap 

        %广域漫流宽度参数更改
         replaceInpValue_write_in(locG_temp, locG_temp, sectionLine, 1, 70, G_width_Param(j))
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

 % B_G
%图形脊线导出即三维图左视图
maxValues_B_G=max(B_G, [], 1 );
maxValues_A_T=max(A_T, [], 1 );

%% 最大流量曲线绘制
% 添加控制变量，设为false以跳过绘图,true执行绘图
do_plot = false; 
if do_plot %设置开关，不执行绘图代码

figure('Name','参数-最大流量关系','NumberTitle','off');

% 生成横坐标（漫流宽度参数）
x = G_width_Param;
% 绘制曲线
plot(x, maxValues_B_G, 'b-o',...
    'LineWidth', 1.5,...
    'MarkerFaceColor', 'w');
%plot(x, maxValues_B_G, 'b-o',...
    %'MarkerSize', 6,...

% 图形美化
grid on;
xlabel('漫流宽度参数 (m)', 'FontWeight','bold', 'FontSize',12);
ylabel('最大节点流量 (LPS)', 'FontWeight','bold', 'FontSize',12);
%title('漫流宽度参数敏感性分析', 'FontSize',14);

% 设置坐标轴刻度
xticks(linspace(min(x), max(x), 5));  % 显示5个主要刻度
yticks(linspace(min(maxValues_B_G), max(maxValues_B_G), 5));
end

%% 绘图部分 峰值流量导出

maxValues_B_G = squeeze(maxValues_B_G)  % 维度变为 paramgap×rain_count
maxValues_A_T = squeeze(maxValues_A_T)
% 生成颜色映射（与雨量情景数量一致）
colors = hsv(length(rain));

figure;
hold on;

% 遍历每个雨量情景
for k = 1:rain_count
    % 绘制 B_G 的峰值曲线
    plot(G_width_Param, maxValues_B_G(:,k), 'Color', colors(k,:), 'LineWidth', 1.5, ...
        'DisplayName', ['G-Model (Rain ' num2str(rain(k)) ')']);
    
    % 绘制 A_T 的水平线（取第一个paramgap的值，因所有值相同）
    y_value = maxValues_A_T(1,k);
    line([min(G_width_Param), max(G_width_Param)], [y_value, y_value], ...
        'Color', colors(k,:), 'LineStyle', '--', 'LineWidth', 1.5, ...
        'HandleVisibility', 'off'); % 避免图例重复
end

hold off;

% 添加标签和图例
xlabel('漫流宽度参数 (m)');
ylabel('节点峰值流量 (m³/s)');
title('G-Model 与 T-Model 峰值对比');
legend('show', 'Location', 'bestoutside');
grid on;


end



