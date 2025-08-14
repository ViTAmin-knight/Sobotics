function [path, path_info] = astar_search_avoid(start_pos, goal_pos, maze_grid, wall_map, elevator_map, avoid_pos)
    [path, path_info] = astar_search(start_pos, goal_pos, maze_grid, wall_map, elevator_map);
    if ~isempty(path) && any(all(path == avoid_pos, 2))
        path = [];  % 含阻塞点，作废
        path_info = struct('elevator_steps', []);
    end
end
