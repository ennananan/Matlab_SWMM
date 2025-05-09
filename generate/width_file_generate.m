function width_file_generate(inpFile,tempFile, sectionLine, newValue)
 % 功能：仅用于在INP文件中 漫流宽度 写入
 % 
 % tempFile - temp.inp文件名称
 % sectionName - 寻找的模型对象名称
 % newValue - 所要替换的值

 % 2. 定位目标行（段落起始行 + 3）
 targetLine = sectionLine + 3;
 lines = readlines(tempFile);  % 读取所有行
 if targetLine > length(lines)
    error('目标行 %d 超出文件范围', targetLine);
 end

originalLine=lines{targetLine};
if length(originalLine) >= 69
   prefix = originalLine(1:69);  % 直接截取前69列
else
   prefix = [originalLine repmat(' ', 1, 69-length(originalLine))];  % repmat补足n个空格
end

% 3 动态定位参数1结束位置（从第70列开始，到第一个空格结束）
    param1Start = 70;
    param1End = param1Start - 1; % 初始化结束位置
    for i = param1Start:length(originalLine)
        if originalLine(i) == ' '
            param1End = i - 1;
            break;
        end
    end

    % 3.3 提取参数1和参数2
    param1Original = extractBetween(originalLine, param1Start, param1End);
    param2Original = '';
    if length(originalLine) >= 79
        param2Original = strtrim(originalLine(79:end)); % +3跳过两个空格,提取指定行后续所有内容
    end
    
    newParam1Str = sprintf('%.3f', newValue);  % 强制3位小数格式
    param1Start = 70;  % 参数1起始列
    newParam1Length = length(newParam1Str);
    %newParam1End = param1Start + newParam1Length - 1;

    % 计算需要填充的空格数
    spaceCount = 79 - (param1Start + newParam1Length);
    if spaceCount < 0
        error('参数1长度超出限制，最大允许%d字符（当前值：%s）', ...
            79-param1Start, newParam1Str);
    end

    %更换内容
    newLine = [...
        prefix, ...                     % 前69列
        newParam1Str, ...                % 新参数1
        '  ', ...                       % 强制两个空格间隔
        param2Original ...              % 原参数2内容（位置可能调整）
    ];

    lines{targetLine} = newLine;

    % 通过临时文件安全写入
    %tempFile = [tempname '.inp'];
    fid = fopen(tempFile, 'w');
    fprintf(fid, '%s\n', lines{:});
    fclose(fid);
end
