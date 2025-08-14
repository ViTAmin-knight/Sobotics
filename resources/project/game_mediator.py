# game_mediator.py

import json
import os

ACTION_TO_DELTA = {
    "move_up":    (-1, 0),
    "move_down":  (1, 0),
    "move_left":  (0, -1),
    "move_right": (0, 1),
}

# 处理 request.json → 控制 agent → 写入 response.json
def handle_external_request(env, agents):
    if not os.path.exists("request.json"):
        return

    try:
        with open("request.json", "r") as f:
            req = json.load(f)
        os.remove("request.json")

        arm_id = req.get("arm_id")
        action = req.get("action")
        target_name = req.get("target")  # 目标 agent 名称

        if not arm_id or not action or not target_name:
            raise ValueError("Missing arm_id, action, or target")

        # ✅ 更新：允许 use_elevator（改名）
        ALLOWED = {
            "arm1": ["move_up", "move_right", "explore"],
            "arm2": ["move_down", "move_left", "use_elevator"]
        }

        if action not in ALLOWED.get(arm_id, []):
            response = {"status": "fail", "reason": f"{arm_id} not allowed to do {action}"}
        else:
            agent = next((a for a in agents if a.name == target_name), None)

            if not agent:
                response = {"status": "fail", "reason": f"Agent {target_name} not found"}
            elif agent.has_exited:
                response = {"status": "fail", "reason": f"Agent {target_name} has already exited"}
            else:
                if action in ACTION_TO_DELTA:
                    drow, dcol = ACTION_TO_DELTA[action]
                    prev = (agent.row, agent.col)
                    agent.move(drow, dcol, env.maze, agents)
                    now = (agent.row, agent.col)
                    response = {"status": "success"} if now != prev else {"status": "fail", "reason": "invalid move"}

                elif action == "explore":
                    success = env.explore(agent)
                    response = {"status": "success"} if success else {"status": "fail", "reason": "explore failed"}

                elif action == "use_elevator":  # ✅ 修复：接收 use_elevator 动作
                    success = env.use_escalator(agent)
                    response = {"status": "success"} if success else {"status": "fail", "reason": "elevator failed"}

                else:
                    response = {"status": "fail", "reason": "unknown action"}

    except Exception as e:
        response = {"status": "fail", "reason": str(e)}

    with open("response.json", "w") as f:
        json.dump(response, f)
