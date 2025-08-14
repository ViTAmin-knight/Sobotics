function [maze_grid, row_offset, col_offset] = load_maze_grid()
    max_attempts = 5;
    retry_delay = 0.1;

    for attempt = 1:max_attempts
        try
            fid = fopen('maze_grid.json', 'r');
            if fid == -1
                error('无法打开 maze_grid.json，请确认文件是否存在于当前目录：%s', pwd);
            end
            str = char(fread(fid, inf))';
            fclose(fid);
            if isempty(str)
                error('maze_grid.json 内容为空。');
            end
            data = jsondecode(str);
            break;
        catch ME
            fprintf("⚠️ 第 %d 次尝试读取 maze_grid.json 失败：%s\n", attempt, ME.message);
            if attempt == max_attempts
                rethrow(ME);
            else
                pause(retry_delay);
            end
        end
    end

    % === 读取 grid_offset.json ===
    row_offset = 0;
    col_offset = 0;
    if exist('grid_offset.json', 'file') == 2
        try
            fid_offset = fopen('grid_offset.json', 'r');
            offset_str = char(fread(fid_offset, inf))';
            fclose(fid_offset);
            offset_data = jsondecode(offset_str);
            row_offset = offset_data.row_offset - 1;
            col_offset = offset_data.col_offset - 1;
            %fprintf("✅ 使用偏移：row_offset = %d，col_offset = %d\n", row_offset, col_offset);
        catch
            warning('⚠️ 读取 grid_offset.json 失败，使用默认偏移。');
        end
    end

    % === 使用 struct array 的访问方式 ===
    [rows, cols] = size(data);
    maze_grid = cell(rows, cols);

    for i = 1:rows
        for j = 1:cols
            cell_struct = data(i,j);
            t = cell_struct.type;

            if isempty(t)
                maze_grid{i,j} = {'void'};
                continue;
            end

            if ischar(t)
                maze_grid{i,j} = {t};
            elseif isstring(t)
                maze_grid{i,j} = cellstr(t);
            elseif iscell(t)
                if all(cellfun(@ischar, t))
                    maze_grid{i,j} = t;
                elseif all(cellfun(@(x) isstring(x) || ischar(x), t))
                    maze_grid{i,j} = cellfun(@char, t, 'UniformOutput', false);
                else
                    maze_grid{i,j} = {'unknown'};
                end
            else
                maze_grid{i,j} = {'unknown'};
            end

            % ✅ 调试信息
            if ~any(strcmp(maze_grid{i,j}, 'void'))
                %fprintf("(%d,%d): %s\n", i + row_offset, j + col_offset, strjoin(maze_grid{i,j}, ", "));
            end
        end
    end

    % === 文本地图输出 ===
    %fprintf("\n=== Maze Grid 文本地图 ===\n    ");
    for j = 1:cols
        %fprintf("%2d ", j + col_offset);
    end
    %fprintf("\n");
    for i = 1:rows
        %fprintf("%2d: ", i + row_offset);
        for j = 1:cols
            types = maze_grid{i,j};
            if any(strcmp(types, 'void'))
                %fprintf(" . ");
            elseif any(contains(types, "start"))
                %fprintf(" S ");
            elseif any(contains(types, "explore"))
                %fprintf(" E ");
            elseif any(contains(types, "escalator"))
                %fprintf(" T ");
            elseif any(contains(types, "item"))
                %fprintf(" I ");
            elseif any(contains(types, "exit"))
                %fprintf(" X ");
            else
                %fprintf(" o ");
            end
        end
        %fprintf("\n");
    end
end
