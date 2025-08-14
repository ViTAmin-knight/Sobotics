% =============================
% Magic Maze 测试动作序列脚本
% =============================

% 设置项目路径（请确认已修改）
cd('C:\Users\my030\Desktop\个人信息\IC AML\Sobotics\resources\project');

% 可选控制方（'arm1' or 'arm2'）
arm_id = 'arm1';  % 改为 'arm2' 可切换控制方

% 各自允许的动作
if strcmp(arm_id, 'arm1')
    actions = {'move_up', 'move_right', 'explore'};
else
    actions = {'move_down', 'move_left', 'elevator'};
end

% 所有棋子（紫p1，绿p2，橙p3，蓝p4）
agent_list = {'p1', 'p2', 'p3', 'p4'};

% 循环测试每个 agent 执行所有动作
for j = 1:length(agent_list)
    for i = 1:length(actions)
        action = actions{i};
        target_agent = agent_list{j};

        fprintf("ARM = %s | AGENT = %s | ACTION = %s -> ", arm_id, target_agent, action);
        res = send_action(arm_id, action, target_agent);

        if isfield(res, "status") && strcmp(res.status, "success")
            fprintf("✅ Success\n");
        else
            fprintf("❌ Failed (%s)\n", res.reason);
        end

        pause(1);  % 等待 1 秒观察效果
    end
end
