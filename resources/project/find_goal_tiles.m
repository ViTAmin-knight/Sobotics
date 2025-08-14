function [item_targets, exit_targets] = find_goal_tiles(maze_grid, row_offset, col_offset)
    item_targets = containers.Map();
    exit_targets = containers.Map();

    for r = 1:size(maze_grid,1)
        for c = 1:size(maze_grid,2)
            if iscell(maze_grid)
                cell = maze_grid{r, c};
            else
                cell = maze_grid(r, c).type;
            end

            if ischar(cell)
                types = {cell};  % 单个字符串也转为 cell
            else
                types = cell;
            end

            for i = 1:length(types)
                txt = types{i};
                if startsWith(txt, 'item:')
                    key = strtrim(lower(extractAfter(txt, 'item:')));
                    real_r = r + row_offset;
                    real_c = c + col_offset;
                    item_targets(key) = [real_r, real_c];
                    fprintf("🧲 ITEM FOUND: %s at (%d,%d)\n", key, real_r, real_c);
                elseif startsWith(txt, 'exit:')
                    key = strtrim(lower(extractAfter(txt, 'exit:')));
                    real_r = r + row_offset;
                    real_c = c + col_offset;
                    exit_targets(key) = [real_r, real_c];
                    fprintf("🚪 EXIT FOUND: %s at (%d,%d)\n", key, real_r, real_c);
                end
            end
        end
    end
end
