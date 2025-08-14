function magic_maze_controller()
    fprintf("🧐 magic_maze_controller 启动（含死锁规避+让路等待）\n");

    % 可调参数：让出后等待的回合数
    YIELD_WAIT_ROUNDS = 4;

    raw_agents = jsondecode(fileread('agent_state.json'));
    agents = struct();
    for i = 1:length(raw_agents)
        agents(i).name = strtrim(lower(char(raw_agents(i).name)));
        agents(i).pos = [raw_agents(i).row, raw_agents(i).col];
        agents(i).phase = "to_item";
        agents(i).path = [];
        agents(i).path_info = [];
        agents(i).step = 2;
        agents(i).has_stolen = false;
        agents(i).has_exited = false;
        agents(i).stuck_count = 0;
        agents(i).deadlock_count = 0;
        agents(i).yield_lock = 0;    % ✨ 新增：让路后的等待计数器
        fprintf("📌 %s 起始位置: (%d,%d)\n", agents(i).name, agents(i).pos(1), agents(i).pos(2));
    end

    explored_sites = zeros(0, 2);
    assigned_explore_sites = zeros(0, 2);
    max_rounds = 200;
    no_progress_counter = 0;

    for round = 1:max_rounds
        fprintf("\n🔁 回合 %d...\n", round);
        [maze_grid, row_offset, col_offset] = load_maze_grid();
        wall_map = load_wall_map();
        elevator_map = load_elevator_map();
        [item_targets, exit_targets] = find_goal_tiles(maze_grid, row_offset, col_offset);

        % 同步外部状态
        raw_agents = jsondecode(fileread('agent_state.json'));
        for i = 1:length(agents)
            idx = find(strcmp({raw_agents.name}, agents(i).name));
            if ~isempty(idx)
                agents(i).has_stolen = raw_agents(idx).has_stolen;
                agents(i).has_exited = raw_agents(idx).has_exited;
            end
        end

        % 分配探索目标
        explore_assignments = assign_explore_targets(agents, maze_grid, explored_sites, assigned_explore_sites);
        any_progress = false;

        for i = 1:length(agents)
            a = agents(i); name = a.name;

            % 已完成则跳过
            if a.phase == "done", continue; end

            % ✨ 让路后的等待：在冷却期内，本回合不做任何动作
            if a.yield_lock > 0
                a.yield_lock = a.yield_lock - 1;
                agents(i) = a;
                fprintf("⏳ [%s] 让路等待中（剩余 %d 回合）\n", name, a.yield_lock);
                continue;
            end

            % 阶段切换
            if a.phase == "to_item" && a.has_stolen
                a.phase = "to_exit"; a.path = []; a.step = 2;
            elseif a.phase == "to_exit" && a.has_exited
                a.phase = "done"; agents(i) = a; continue;
            end

            % 选择目标
            key = name; goal = [];
            if a.phase == "to_item" && isKey(item_targets, key) && ~a.has_stolen
                goal = item_targets(key);
            elseif a.phase == "to_exit" && isKey(exit_targets, key) && ~a.has_exited
                goal = exit_targets(key);
            elseif isKey(explore_assignments, name)
                goal = explore_assignments(name);
            else
                agents(i) = a;  % 无目标
                continue;
            end

            % 规划路径
            if isempty(a.path) || a.step > size(a.path,1)
                [a.path, a.path_info] = astar_search(a.pos, goal, maze_grid, wall_map, elevator_map);
                a.step = 2;
                if isempty(a.path)
                    fprintf("❌ %s 无法到达目标 [%d,%d]\n", name, goal(1), goal(2));
                    agents(i) = a; continue;
                end
            end

            % 当前位置即为动作格（仅 explore）
            if size(a.path,1) == 1
                [maze_r, maze_c] = deal(a.pos(1)-row_offset, a.pos(2)-col_offset);
                if maze_r >= 1 && maze_c >= 1 && maze_r <= size(maze_grid,1) && maze_c <= size(maze_grid,2)
                    if contains(maze_grid{maze_r,maze_c}, "explore")
                        res = send_action("arm1", "explore", name);
                        if strcmp(res.status, "success")
                            explored_sites(end+1,:) = a.pos;
                            % 地图变化：清空其它 agent 的路径
                            for j2 = 1:length(agents)
                                if j2 ~= i && agents(j2).phase ~= "done"
                                    agents(j2).path = []; agents(j2).step = 2;
                                end
                            end
                        end
                    end
                end
                a.path = []; a.step = 2; agents(i) = a; continue;
            end

            % 下一步动作
            from = a.path(a.step-1,:); to = a.path(a.step,:);
            delta = to - from;
            % elevator_map 需已加载
            is_elevator_here = isKey(elevator_map, sprintf("(%d,%d)", a.pos(1), a.pos(2)));
            
            if isfield(a.path_info, 'elevator_steps') && ...
               a.step <= length(a.path_info.elevator_steps) && ...
               a.path_info.elevator_steps(a.step) && ...
               is_elevator_here
                action = "use_elevator"; arm = "arm2";
            else
                if isequal(delta, [-1 0]), action = "move_up"; arm = "arm1";
                elseif isequal(delta, [1 0]), action = "move_down"; arm = "arm2";
                elseif isequal(delta, [0 -1]), action = "move_left"; arm = "arm2";
                elseif isequal(delta, [0 1]), action = "move_right"; arm = "arm1";
                else, action = "use_elevator"; arm = "arm2"; end
            end


            % 🧱 对位互卡检测（两级跳出 + 让路等待）
            yielded = false;   % ✨ 本回合是否“已让路/等待”，若是则不再执行后续动作
            for j = 1:length(agents)
                if j == i, continue; end
                b = agents(j);
                if b.step > 1 && b.step <= size(b.path,1)
                    from_b = b.path(b.step-1,:);
                    to_b = b.path(b.step,:);
                    if isequal(from_b, to) && isequal(to_b, from)
                        fprintf("♻️ [%s] 与 [%s] 对位互卡检测\n", name, b.name);

                        let_me_yield = false;
                        if ~a.has_stolen && b.has_stolen
                            let_me_yield = true;
                        elseif a.has_stolen == b.has_stolen
                            if string(name) > string(b.name)
                                let_me_yield = true;
                            end
                        end

                        if let_me_yield
                            dirs = [-1 0; 1 0; 0 -1; 0 1];
                            for d = 1:4
                                try_to = a.pos + dirs(d,:);
                                if all(arrayfun(@(x) ~isequal(x.pos, try_to), agents)) && ...
                                   ~is_blocked_by_wall(a.pos, try_to, wall_map, "")
                                    dd = try_to - a.pos;
                                    if isequal(dd, [-1 0]), act="move_up"; a_arm="arm1";
                                    elseif isequal(dd, [1 0]), act="move_down"; a_arm="arm2";
                                    elseif isequal(dd, [0 -1]), act="move_left"; a_arm="arm2";
                                    elseif isequal(dd, [0 1]), act="move_right"; a_arm="arm1";
                                    else, continue;
                                    end
                                    moved_res = send_action(a_arm, act, name);
                                    if strcmp(moved_res.status, "success")
                                        fprintf("↩️ [%s] 成功让出 (%d,%d)\n", name, try_to(1), try_to(2));
                                        a.pos = try_to;
                                        a.path = []; a.step = 2;
                                        a.deadlock_count = 0;
                                        a.yield_lock = YIELD_WAIT_ROUNDS;   % ✨ 进入等待期
                                        agents(i) = a;
                                        yielded = true;   % 成功让路，本回合结束
                                        break;            % 跳出方向循环
                                    end
                                end
                            end

                            if ~yielded
                                fprintf("⛔ [%s] 无法让路，等待...\n", name);
                                a.deadlock_count = a.deadlock_count + 1;
                                if a.deadlock_count >= 3
                                    fprintf("🔁 [%s] 死锁等待重规划路径\n", name);
                                    avoid = to;
                                    [a.path, a.path_info] = astar_search_avoid(a.pos, goal, maze_grid, wall_map, elevator_map, avoid);
                                    a.step = 2; a.deadlock_count = 0;
                                end
                                agents(i) = a;
                                yielded = true;  % 本回合也不再动作
                            end
                        else
                            fprintf("🛑 [%s] 拥有优先权，等待对方让路\n", name);
                            a.deadlock_count = a.deadlock_count + 1;
                            if a.deadlock_count >= 3
                                fprintf("🔁 [%s] 死锁等待重规划路径\n", name);
                                avoid = to;
                                [a.path, a.path_info] = astar_search_avoid(a.pos, goal, maze_grid, wall_map, elevator_map, avoid);
                                a.step = 2; a.deadlock_count = 0;
                            end
                            agents(i) = a;
                            yielded = true;  % 优先者也本回合不再动作（等对方）
                        end

                        break;   % ✨ 跳出 j 循环
                    end
                end
            end

            if yielded
                % ✨ 本回合已处理（让路/等待），不要继续尝试“▶️ 动作”
                continue;
            end
            
            % 常规动作执行
            fprintf("▶️ %s 尝试 %s 到 (%d,%d)\n", name, action, to(1), to(2));
            res = send_action(arm, action, name);

            % —— 发送前预检：用“从当前格出边”做墙检查；若被墙，绕开这一步重规划 ——
            if is_blocked_by_wall(a.pos, to, wall_map, "from_cell")  % 第4参只是标注，可忽略
                fprintf("🚧 [%s] 预检命中墙：(%d,%d)->(%d,%d)，改为绕开重规划\n", ...
                        name, a.pos(1), a.pos(2), to(1), to(2));
                avoid = to;  % 把这一步加入避让集合
                [a.path, a.path_info] = astar_search_avoid(a.pos, goal, maze_grid, wall_map, elevator_map, avoid);
                a.step = 2;
                agents(i) = a;
                continue;   % 本回合不再执行旧动作
            end



            if strcmp(res.status, "success")
                a.pos = to; a.step = a.step + 1; a.stuck_count = 0; any_progress = true;
            else
                fprintf("🧲 %s 执行失败: %s\n", name, res.reason);
                %a.path = [];
                %a.step = 2;
                %a.stuck_count = a.stuck_count + 1;
                % ✅ 若是普通移动失败，立刻绕开这一步的目标格重规划，避免一直尝试同一格
                if startsWith(string(action), "move")
                    avoid = to;   % 这一步要去但失败的格子
                    [a.path, a.path_info] = astar_search_avoid(a.pos, goal, maze_grid, wall_map, elevator_map, avoid);
                    a.step = 2;
                    a.stuck_count = 0;
                    agents(i) = a;
                    continue;     % 本回合结束，等待下回合按新路径走
                end


                if action == "use_elevator"
                    if a.stuck_count >= 2
                        dirs = [-1 0; 1 0; 0 -1; 0 1];
                        for j3 = 1:4
                            try_to = a.pos + dirs(j3,:);
                            if all(arrayfun(@(bb) ~isequal(bb.pos, try_to), agents)) && ...
                               ~is_blocked_by_wall(a.pos, try_to, wall_map, "")
                                dd = try_to - a.pos;
                                if isequal(dd, [-1 0]), act="move_up"; a_arm="arm1";
                                elseif isequal(dd, [1 0]), act="move_down"; a_arm="arm2";
                                elseif isequal(dd, [0 -1]), act="move_left"; a_arm="arm2";
                                elseif isequal(dd, [0 1]), act="move_right"; a_arm="arm1";
                                else, continue;
                                end
                                moved = send_action(a_arm, act, name);
                                if strcmp(moved.status, "success")
                                    a.pos = try_to; a.path = []; a.step = 2;
                                    break;
                                end
                            end
                        end
                    end
                    if a.stuck_count >= 3
                        fprintf("⛔ [%s] 尝试绕开电梯目标重新规划\n", name);
                        avoid = to;
                        [a.path, a.path_info] = astar_search_avoid(a.pos, goal, maze_grid, wall_map, elevator_map, avoid);
                        a.step = 2;
                    end
                else
                    if a.stuck_count >= 2
                        a.path = []; a.step = 2;
                    end
                end
            end
            agents(i) = a;
        end

        % 胜利判定
        if all(arrayfun(@(aa) strcmp(aa.phase, "done"), agents))
            fprintf("🎉 所有 agent 成功逃脱！\n"); return;
        end

        % 进展判定
        if any_progress
            no_progress_counter = 0;
        else
            no_progress_counter = no_progress_counter + 1;
            if no_progress_counter >= 5
                fprintf("❌ 连续 5 回合无进展，终止程序\n"); return;
            else
                fprintf("⏸️ 无进展，等待...\n");
            end
        end
        pause(0.4);
    end
    fprintf("❌ 超出最大回合，失败\n");
end
