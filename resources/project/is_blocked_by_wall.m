function blocked = is_blocked_by_wall(pos, next_pos, wall_map, direction)
    row = pos(1);
    col = pos(2);
    key = sprintf('%d_%d_%s', row, col, strtrim(direction));  % ✅ 严格去空格
    blocked = isKey(wall_map, key);
end
