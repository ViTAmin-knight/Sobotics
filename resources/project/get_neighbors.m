function neighbors = get_neighbors(pos, maze_grid, wall_map, elevator_map)
    % 4-连通方向
    dirs = [-1 0; 1 0; 0 -1; 0 1];           % up, down, left, right
    dir_names = {'up','down','left','right'};
    opp = containers.Map({'up','down','left','right'}, ...
                         {'down','up','right','left'});
    neighbors = [];

    [rows, cols] = size(maze_grid);

    % ✅ 读取 offset（maze_grid 内部索引用 1-based，本函数用世界坐标）
    row_offset = 0; col_offset = 0;
    if exist('grid_offset.json', 'file') == 2
        try
            fid = fopen('grid_offset.json', 'r'); str = char(fread(fid, inf))';
            fclose(fid);
            offset_data = jsondecode(str);
            % 注意：maze_grid 索引是 1-based，所以要 -1
            row_offset = offset_data.row_offset - 1;
            col_offset = offset_data.col_offset - 1;
        catch
            warning("⚠️ 读取 offset 失败，使用默认值。");
        end
    end

    % 🧩 当前所在格若本就 void，则不产生普通四邻（可选，稳妥）
    cur_r = pos(1) - row_offset;
    cur_c = pos(2) - col_offset;
    if cur_r < 1 || cur_r > rows || cur_c < 1 || cur_c > cols || isempty(maze_grid{cur_r, cur_c})
        % 不 return——仍允许下面加入电梯邻居（站在 void 不太可能，但防御式写法）
    else
        % ① 普通 4 向邻居：边界内 + 目标非 void + 双向不被墙阻挡
        for i = 1:4
            d  = dirs(i,:);
            np = pos + d;

            % maze_grid 内部索引
            local_r = np(1) - row_offset;
            local_c = np(2) - col_offset;

            % 边界
            if local_r < 1 || local_r > rows || local_c < 1 || local_c > cols
                continue;
            end

            % ✅ 目标格是否 void（空类型列表表示 void）
            if isempty(maze_grid{local_r, local_c})
                continue;
            end

            % ✅ 墙体双向检查：pos→np 的方向，以及 np→pos 的反方向
            dir_fwd = dir_names{i};
            dir_bak = opp(dir_fwd);
            if is_blocked_by_wall(pos, np, wall_map, dir_fwd) || ...
               is_blocked_by_wall(np, pos, wall_map, dir_bak)
                continue;
            end

            neighbors(end+1,:) = np; %#ok<AGROW>
        end
    end

    % ② 电梯跳跃邻居（独立于墙判定）
    key = sprintf("(%d,%d)", pos(1), pos(2));   % ⚠️ 这里的 pos 必须是“减过 offset 的世界坐标”一致
    if isKey(elevator_map, key)
        jumps = elevator_map(key);              % N×2 （与 A* 同一坐标系）
        for j = 1:size(jumps,1)
            target = jumps(j,:);
            if ~isequal(target, pos)            % 不加自身
                neighbors(end+1,:) = target; %#ok<AGROW>
            end
        end
    end
end
