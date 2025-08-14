function wall_map = load_wall_map()
    max_attempts = 5;
    retry_delay = 0.1;

    for attempt = 1:max_attempts
        try
            str = fileread('wall_map.json');
            if isempty(str)
                error("wall_map.json 是空的。");
            end
            data = jsondecode(str);
            break;
        catch e
            fprintf("⚠️ 第 %d 次尝试读取 wall_map.json 失败：%s\n", attempt, e.message);
            if attempt == max_attempts
                error("❌ 多次尝试读取 wall_map.json 失败，终止加载。");
            end
            pause(retry_delay);
        end
    end

    % ✅ 从 grid_offset.json 动态获取偏移
    row_offset = 0;
    col_offset = 0;
    if exist('grid_offset.json', 'file') == 2
        try
            fid_offset = fopen('grid_offset.json', 'r');
            offset_str = char(fread(fid_offset, inf))';
            fclose(fid_offset);
            offset_data = jsondecode(offset_str);
            row_offset = offset_data.row_offset;
            col_offset = offset_data.col_offset;
        catch
            warning("⚠️ 无法读取 grid_offset.json，将使用默认偏移。");
        end
    end

    wall_map = containers.Map();

    for i = 1:length(data)
        row = data(i).row + row_offset;
        col = data(i).col + col_offset;
        directions = data(i).walls;

        for j = 1:length(directions)
            dir = strtrim(directions{j});
            key = sprintf('%d_%d_%s', row, col, dir);
            wall_map(key) = true;
        end
    end

    if isKey(wall_map, '4_6_up')
        %fprintf("✅ 关键墙体 '4_6_up' 已成功加载\n");
    else
        %fprintf("❌ 关键墙体 '4_6_up' 未在 wall_map 中！\n");
    end
end
