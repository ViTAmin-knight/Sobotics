function elevator_map = load_elevator_map()
    str = fileread('elevator_map.json');
    raw = jsondecode(str);

    temp_map = containers.Map();  % 暂存原始 x0, x1, ... -> coords

    % Step 1: 读取原始电梯组
    for i = 1:length(raw)
        eid = raw(i).id;
        positions = raw(i).positions;
        coords = zeros(length(positions), 2);
        for j = 1:length(positions)
            coords(j,:) = [positions(j).row, positions(j).col];
        end
        temp_map(eid) = coords;
    end

    % Step 2: 合并每两组（x0,x1）, (x2,x3)...
    all_coords = {};
    i = 1;
    while i <= length(keys(temp_map))
        klist = keys(temp_map);
        if i+1 <= length(klist)
            merged = [temp_map(klist{i}); temp_map(klist{i+1})];
        else
            merged = temp_map(klist{i});
        end
        all_coords{end+1} = merged;
        i = i + 2;
    end

    % Step 3: 构建 pos_key → list 跳跃表
    elevator_map = containers.Map();
    for i = 1:length(all_coords)
        coords = all_coords{i};
        for j = 1:size(coords,1)
            key = sprintf("(%d,%d)", coords(j,1), coords(j,2));
            others = coords(setdiff(1:end, j), :);
            elevator_map(key) = others;
        end
    end
end
