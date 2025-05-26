function output = absorption_palette_n(input)
% ABSORPTION_PALETTE 自定义光谱可视化配色方案
% 调用方式：
%   pal = absorption_palette();              % 获取完整结构体
%   colors = absorption_palette(N);          % 获取前N个颜色
%   colors = absorption_palette([3,5,7]);    % 按索引获取多个颜色
%   color = absorption_palette('color3');    % 按名称获取单个颜色

    % 核心颜色数据（Hex + 名称）
    colorData = {
        '#8f5362', 'dark_purple';
        '#b96570', 'reddish_brown';
        '#d37b6d', 'orange_brown';
        '#e0a981', 'light_orange';
        '#ecd09c', 'pale_yellow';
        '#d4daa1', 'light_green';
        '#a3c8a4', 'medium_green';
        '#79b4a0', 'dark_green';
        '#6888a5', 'sky_blue';
        '#706d94', 'deep_blue';
        '#9bbf8a', 'color1';
        '#82afda', 'color2';
        '#f79059', 'color3';
        '#e7dbd3', 'color4';
        '#c2bdde', 'color5';
        '#8dcec8', 'color6';
        '#add3e2', 'color7';
        '#3480b8', 'color8';
        '#ffbe7a', 'color9';
        '#fa8878', 'color10';
        '#c82423', 'color11';
        '#104682', 'dark_blue';
        '#317cb7', 'medium_blue';
        '#6dadd1', 'soft_azure';
        '#b6d7e8', 'powder_blue';
        '#e9f1f4', 'ice_white';
        '#fbe3d5', 'peach_glow';
        '#f6b293', 'coral';
        '#dc6d57', 'terracotta';
        '#b72230', 'crimson';
        '#6d011f', 'burgundy';
        '#6E8FB2', 'light_blue';
        '#7DA494', 'sage_green';
        '#EAB67A', 'sand_beige';
        '#E5A79A', 'blush_pink';
        '#C16E71', 'dusty_rose';
        '#ABC8E5', 'sky_blue';
        '#D8A0C1', 'orchid_pink';
        '#9F8DB8', 'heather_purple';
        '#D0D08A', 'pale_olive';
    };

    % 转换为RGB矩阵
    rgb = cellfun(@(x) hex2rgb(x), colorData(:,1), 'UniformOutput', false);
    colors = vertcat(rgb{:});
    names = colorData(:,2);

    % 构造结构体
    pal.colors = colors;
    for i = 1:length(names)
        pal.(names{i}) = colors(i,:);
    end
    pal.get = @(in) getColors(in, colors, names);

    % 判断调用方式
    if nargin == 0
        output = pal; % 返回完整结构体
    elseif ischar(input) || isstring(input)
        output = getColors(input, colors, names); % 名称调用
    elseif isnumeric(input)
        output = getColors(input, colors, names); % 索引调用
    else
        error('不支持的输入参数类型。');
    end
end

function out = getColors(in, colors, names)
    if ischar(in) || isstring(in)
        idx = find(strcmpi(in, names));
        if isempty(idx)
            error('未找到颜色名称 "%s"', in);
        end
    else
        idx = in;
    end
    out = colors(idx, :);
end

function rgb = hex2rgb(hexStr)
    hexStr = erase(hexStr, '#');
    if length(hexStr) ~= 6
        error('非法HEX颜色代码: %s', hexStr);
    end
    rgb = sscanf(hexStr, '%2x')'/255;
end
