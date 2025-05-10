function replaceInpValue_write_in(inpFile, tempFile, sectionLine, n, l, newValue)
    % 功能：***重要函数***安全替换INP文件参数并保持列对齐
    % 输入：
    %   inpFile     - 原始文件路径
    %   tempFile    - 临时文件路径
    %   sectionLine - 目标段起始行号
    %   n           - 需修改的行数
    %   l           - 参数起始列位置（从1开始）
    %   newValue    - 新数值数组（长度=n）
    
    % 读取文件并保留所有空白
    fid = fopen(inpFile, 'r');
    lines = {};
    while true
        thisLine = fgetl(fid);
        if ~ischar(thisLine)
            break;
        end
        lines{end+1} = [thisLine newline]; % 添加统一换行符
    end
    fclose(fid);
    lines = lines';

    % 计算目标行号
    for i = 1:n
        targetLine = sectionLine + i + 2;
        if targetLine > numel(lines)
        error('目标行 %d 超出文件范围', targetLine);
        end
        
        % 获取当前行并扩展长度
        currentLine = lines{targetLine};
        minCol = l; % 需要的最小列数
        
        % 扩展行长度至最少包含参数起始列
        if length(currentLine) < minCol
            currentLine = [currentLine repmat(' ', 1, minCol - length(currentLine))];
        end
        
        % 定位参数区域
        paramStart = l;
        paramEnd = paramStart - 1;
        while paramEnd + 1 <= length(currentLine) && currentLine(paramEnd + 1) ~= ' '
            paramEnd = paramEnd + 1;
        end
        
        % 计算后续空格区域
        spaceStart = paramEnd + 1;
        spaceEnd = spaceStart - 1;
        while spaceEnd + 1 <= length(currentLine) && currentLine(spaceEnd + 1) == ' '
            spaceEnd = spaceEnd + 1;
        end
        
        % 生成新参数（保持原占位长度）
        originalLength = (paramEnd - paramStart + 1) + (spaceEnd - spaceStart + 1);
        newParamStr = pad(num2str(newValue(i)), originalLength, 'right');
        
        % 构建新行内容
        prefix = currentLine(1:paramStart-1); % 关键修正点：paramStart-1
        suffix = currentLine(spaceEnd+1:end);
        newLine = [prefix newParamStr suffix];
        
        % 强制行长度一致
        if length(newLine) ~= length(currentLine)
            newLine = [newLine repmat(' ', 1, length(currentLine)-length(newLine))];
        end
        
        lines{targetLine} = newLine;
    end
     % 写入文件
    fid = fopen(tempFile, 'w');
    fprintf(fid, '%s', lines{:});
    fclose(fid);
end