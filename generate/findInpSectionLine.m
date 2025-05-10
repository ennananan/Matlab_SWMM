function sectionLine=findInpSectionLine(inpFile, sectionName)
    % 功能：***找到指定的模型对象名称所处的行号
    % inpFile - 原始INP文件路径
    % sectionName - 模型对象名称
        
    %确认寻找对象
    if ~startsWith(sectionName, '[') || ~endsWith(sectionName, ']')
        sectionName = ['[', strtrim(sectionName), ']'];  % 确保格式为 [SECTION]
    end

    % 读取文件所有行到单元格数组
    fid = fopen(inpFile, 'r');
    lines = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', '');
    lines = lines{1};
    fclose(fid);
    
    sectionLine=-1;

    %遍历文件所有行
    for i=1:length(lines)
        currentLine=strtrim(lines{i});
        if ~isempty(currentLine)
            lineParts=strsplit(currentLine,';');
            lineContent=strtrim(lineParts);

            if strcmpi(lineContent,sectionName)
                sectionLine=i;
                break;
            end
        end
    end
    sectionLine;
end
