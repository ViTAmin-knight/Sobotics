function response = send_action(arm_id, action, agent_name)
    % 构造请求数据
    request.arm_id = arm_id;
    request.action = action;
    request.target = agent_name;

    % 写入 request.json（覆盖旧请求）
    jsonStr = jsonencode(request);
    fid = fopen('request.json', 'w');
    fprintf(fid, '%s', jsonStr);
    fclose(fid);

    % 等待 Python 响应（轮询 response.json）
    timeout = 5;  % 最多等待 5 秒
    tStart = tic;
    response = struct('status', 'fail', 'reason', 'timeout');

    while toc(tStart) < timeout
        pause(0.2);
        if exist('response.json', 'file')
            fid = fopen('response.json', 'r');
            raw = fread(fid, inf);
            fclose(fid);
            delete('response.json');  % 读取后立即删除
            str = char(raw');
            response = jsondecode(str);
            return;
        end
    end
end
