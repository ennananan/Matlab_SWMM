function pal = absorption_palette()
% ABSORPTION_PALETTE 根据SCI论文光谱图定制的专业配色方案
%   包含11种优化色盲区分度的颜色，适用于时间序列光谱可视化
%   调用方式：
%      pal = absorption_palette(); % 获取全部颜色结构体
%      pal.colors % 获取N×3颜色矩阵
%      pal.get('color3') % 按名称获取单个颜色
%      pal.get([3,5,7]) % 按索引获取多个颜色
    
    % 核心颜色数据 (Hex转MATLAB RGB格式)
    colorData = {
        '#8f5362', 'dark_purple';    % 深紫色
        '#b96570', 'reddish_brown';  % 红褐色
        '#d37b6d', 'orange_brown';   % 橙褐色 
        '#e0a981', 'light_orange';   % 浅橙色
        '#ecd09c', 'pale_yellow';    % 浅黄色
        '#d4daa1', 'light_green';    % 浅绿色
        '#a3c8a4', 'medium_green';   % 绿色
        '#79b4a0', 'dark_green';     % 深绿色
        '#6888a5', 'sky_blue';       % 蓝色
        '#706d94', 'deep_blue';     % 深蓝色
         '#9bbf8a', 'color1';   % 叶绿素绿
        '#82afda', 'color2';   % 天空蓝
        '#f79059', 'color3';   % 橙红
        '#e7dbd3', 'color4';   % 珍珠白
        '#c2bdde', 'color5';   % 薰衣草紫
        '#8dcec8', 'color6';   % 浅水蓝
        '#add3e2', 'color7';   % 冰河蓝 
        '#3480b8', 'color8';   % 深海蓝
        '#ffbe7a', 'color9';   % 琥珀黄
        '#fa8878', 'color10';  % 珊瑚粉
        '#c82423', 'color11';  % 胭脂红
        '#104682', 'dark_blue';        % 深蓝
        '#317cb7', 'medium_blue';      % 中蓝
        '#6dadd1', 'soft_azure';       % 柔天蓝
        '#b6d7e8', 'powder_blue';      % 粉蓝
        '#e9f1f4', 'ice_white';        % 冰白
        '#fbe3d5', 'peach_glow';       % 桃粉
        '#f6b293', 'coral';            % 珊瑚
        '#dc6d57', 'terracotta';       % 陶红
        '#b72230', 'crimson';          % 绯红
        '#6d011f', 'burgundy';         % 酒红
        '#6E8FB2', 'light_blue';        % 浅蓝色（RGB:110,143,178）
        '#7DA494', 'sage_green';        % 灰绿色（RGB:125,164,148）
        '#EAB67A', 'sand_beige';        % 浅橙色（RGB:234,182,122）
        '#E5A79A', 'blush_pink';        % 浅粉色（RGB:229,167,154）
        '#C16E71', 'dusty_rose';        % 深粉红（RGB:193,110,113）
        '#ABC8E5', 'sky_blue';          % 浅蓝色（RGB:171,200,229）
        '#D8A0C1', 'orchid_pink';       % 浅紫色（RGB:216,160,193）
        '#9F8DB8', 'heather_purple';    % 淡紫色（RGB:159,141,184）
        '#D0D08A', 'pale_olive'};        % 淡黄绿（RGB:208,208,138）  ; };


    
    % 转换为0-1范围的RGB矩阵
    rgb = cellfun(@(x) hex2rgb(x), colorData(:,1), 'UniformOutput', false);
    pal.colors = vertcat(rgb{:});
    
    % 创建颜色名称查询结构体
    colorNames = colorData(:,2);
    for i = 1:length(colorNames)
        pal.(colorNames{i}) = pal.colors(i,:);
    end
    
    % 附加获取方法
    pal.get = @(in) getColors(in, pal.colors, colorNames);
end

function out = getColors(in, colors, names)
    if ischar(in) || isstring(in)
        idx = find(strcmpi(in, names));
    else
        idx = in;
    end
    out = colors(idx,:);
end

function rgb = hex2rgb(hexStr)
% HEX2RGB 将十六进制颜色代码转换为MATLAB RGB向量
    hexStr = erase(hexStr,'#'); % 移除#号
    if length(hexStr)~=6
        error('非法HEX代码: %s', hexStr);
    end
    rgb = sscanf(hexStr, '%2x')'/255; % 转为0-1范围
end