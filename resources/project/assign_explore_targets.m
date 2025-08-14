function assignments = assign_explore_targets(agents, maze_grid, explored_sites, assigned_explore_sites)
    wall_map = load_wall_map();
    elevator_map = load_elevator_map();
    [~, row_offset, col_offset] = load_maze_grid();

    % Step 1: 获取所有 explore 格子（跳过已探索和已分配的）
    explore_cells = [];
    for r = 1:size(maze_grid,1)
        for c = 1:size(maze_grid,2)
            if any(contains(maze_grid{r,c}, "explore"))
                global_pos = [r + row_offset, c + col_offset];

                % ✅ 跳过已 explore 或已被本轮或历史分配的格子
                if any(ismember(explored_sites, global_pos, 'rows')) || ...
                   any(ismember(assigned_explore_sites, global_pos, 'rows'))
                    continue;
                end

                explore_cells(end+1,:) = global_pos;
            end
        end
    end

    assignments = containers.Map();
    if isempty(explore_cells)
        return;
    end

    % Step 2: 所有 agent 和 explore 的路径组合
    pairs = [];  % 每行: [agent_idx, explore_idx, path_len]
    path_table = containers.Map();  % key: "i_j", value: path

    %fprintf("=== 最近 explore 分配候选 (按 agent 分组) ===\n");
    for i = 1:length(agents)
        a = agents(i);
        if a.phase == "done"
            continue;
        end
        min_len = Inf;
        best_j = -1;
        for j = 1:size(explore_cells,1)
            pos = explore_cells(j,:);
            path = astar_search(a.pos, pos, maze_grid, wall_map, elevator_map);
            if ~isempty(path)
                len = size(path,1);
                pairs(end+1,:) = [i, j, len];
                path_table(sprintf('%d_%d', i, j)) = path;
                if len < min_len
                    min_len = len;
                    best_j = j;
                end
            end
        end
        if min_len < Inf
            goal = explore_cells(best_j,:);
            %fprintf("🔍 %s 最近的 explore: [%d,%d]，路径长度 = %d\n", a.name, goal(1), goal(2), min_len);
        else
            %fprintf("⚠️ %s 无法到达任何 explore 格\n", a.name);
        end
    end

    % Step 3: 贪心分配，按路径长度升序，避免重复使用 explore 格
    if isempty(pairs)
        return;
    end
    pairs = sortrows(pairs, 3);  % 按路径长度升序
    used_agents = [];
    used_explores = [];
    for k = 1:size(pairs,1)
        i = pairs(k,1); j = pairs(k,2);
        if ismember(i, used_agents) || ismember(j, used_explores)
            continue;
        end
        assignments(agents(i).name) = explore_cells(j,:);
        used_agents(end+1) = i;
        used_explores(end+1) = j;
    end
end
