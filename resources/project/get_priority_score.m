function score = get_priority_score(agent)
% 分数越低优先级越高
% stolen = 0（优先），not_stolen = 100（惩罚）
% 名字顺序 p1 > p2 > p3 > p4（1–4）

    name_order = ["p1", "p2", "p3", "p4"];
    idx = find(name_order == agent.name, 1);
    if isempty(idx)
        idx = 999;  % 未知名次最低优先
    end

    if agent.has_stolen
        stolen_penalty = 0;
    else
        stolen_penalty = 100;
    end

    score = stolen_penalty + idx;
end
