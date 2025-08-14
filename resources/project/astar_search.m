function [path, path_info] = astar_search(start_pos, goal_pos, maze_grid, wall_map, elevator_map)
    open = containers.Map();
    closed = containers.Map();
    parent = containers.Map();
    elevator_used = containers.Map();

    key = @(pos) sprintf('%d_%d', pos(1), pos(2));
    h = @(pos) sum(abs(pos - goal_pos));

    g_cost = containers.Map();
    f_cost = containers.Map();

    start_k = key(start_pos);
    g_cost(start_k) = 0;
    f_cost(start_k) = h(start_pos);
    open(start_k) = start_pos;
    elevator_used(start_k) = false;

    while ~isempty(open)
        keys_open = keys(open);
        f_vals = cellfun(@(k) f_cost(k), keys_open);
        [~, idx] = min(f_vals);
        current = open(keys_open{idx});
        curr_k = key(current);

        if isequal(current, goal_pos)
            [path, path_info] = reconstruct_path_with_info(parent, elevator_used, current, key);
            return;
        end

        remove(open, curr_k);
        closed(curr_k) = true;

        neighbors = get_neighbors(current, maze_grid, wall_map, elevator_map);

        key_curr = sprintf("(%d,%d)", current(1), current(2));
        is_elevator_jump = false(size(neighbors,1), 1);
        if isKey(elevator_map, key_curr)
            elevator_list = elevator_map(key_curr);
            for j = 1:size(neighbors,1)
                if any(ismember(elevator_list, neighbors(j,:), 'rows'))
                    is_elevator_jump(j) = true;
                end
            end
        end

        for i = 1:size(neighbors,1)
            n = neighbors(i,:);
            nk = key(n);
            if isKey(closed, nk), continue; end

            if is_elevator_jump(i)
                tentative_g = g_cost(curr_k) + 0.5;  % 你定义一个常量，比如 1 或 0.5
            else
                tentative_g = g_cost(curr_k) + 1;
            end

            if ~isKey(open, nk) || tentative_g < g_cost(nk)
                parent(nk) = current;
                elevator_used(nk) = is_elevator_jump(i);
                g_cost(nk) = tentative_g;
                f_cost(nk) = tentative_g + h(n);
                open(nk) = n;
            end
        end
    end

    path = [];
    path_info = struct('elevator_steps', []);
end

function [path, info] = reconstruct_path_with_info(parent, elevator_used, current, key)
    path = current;
    elevator_flags = [false];

    while isKey(parent, key(current))
        prev = parent(key(current));
        path = [prev; path];
        elevator_flags = [elevator_used(key(current)); elevator_flags];
        current = prev;
    end

    info = struct('elevator_steps', elevator_flags);
end
