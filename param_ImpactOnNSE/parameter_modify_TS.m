function parameter_modify_TS(filename_ini,filename_new,value,new_value)
fileID=fopen(filename_ini,'r+');%r+是以读写方式打开文件
i=0;
done=0;
while ~feof(fileID) %当文件没有结束时，即遍历文件
    tline=fgetl(fileID);%逐行读取
    i=i+1;
    newline{i}=tline;%逐行记录
    location=strfind(tline,value);%返回记录tline中value的位置，即找到所输入的value
    if ~isempty(location)&&done ==  0%如果location不为空，对应上方的位置记录，且done==0
        a = i;
        b = location(1);
        done = 1;%只要找到第一个就立即结束，添加开关的方式tip
        newline{a}=strrep(newline{a},newline{a}(b:b+3),new_value);%此处的{}表示一个单元格数组，从第a的单元格中的b到b+12更换为new_value
    end
end
fclose(fileID);

if length(new_value)<4
    new_value=pad(new_value,4,'right');
end

%newline{a}=strrep(newline{a},newline{a}(b:b+3),new_value);
%将这行省略之后的程序运行成功，所以在于这一行的更改问题理解，基于行为理解对文件序列进行了更改；

fileID=fopen(filename_new,'w+');
for k=1:i
    fprintf(fileID,'%s\t\n',newline{k});
end
fclose(fileID);
end