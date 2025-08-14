
class MagicMazeEnv:
    def __init__(self, maze, agents, tile_deck=None):
        self.maze = maze
        self.agents = agents
        self.tile_deck = tile_deck[1:] if tile_deck else []  # 把 tile 0 留在外面
        self.explored_sites = set()

    def explore(self, agent):
        cell = self.maze.get_cell(agent.col, agent.row)
        if isinstance(cell, str):
            cell = [cell]
        elif not isinstance(cell, list):
            return False

        target = next((c for c in cell if c.startswith("explore:")), None)
        if not target:
            return False

        try:
            parts = target.split(":")
            if len(parts) == 2:
                _, agent_name = parts
                direction = None  # auto detect
            elif len(parts) == 3:
                _, direction, agent_name = parts
            else:
                return False
        except:
            return False

        if agent_name != agent.name and agent_name != "all":
            return False

        # 🔍 自动判断 explore 所在边缘方向
        direction_vectors = {'up': (0, -1), 'down': (0, 1), 'left': (-1, 0), 'right': (1, 0)}
        if direction is None:
            for dir_name, (dx, dy) in direction_vectors.items():
                nx, ny = agent.col + dx, agent.row + dy
                if self.maze.get_cell(nx, ny) == []:
                    direction = dir_name
                    break
            if direction is None:
                print(">>> Could not auto-detect direction from explore edge")
                return False

        dx, dy = direction_vectors[direction]
        ex, ey = agent.col, agent.row
        ax, ay = ex + dx, ey + dy

        if not self.tile_deck:
            print(">>> Tile deck empty.")
            return False

        tile = self.tile_deck[0]

        # 尝试最多旋转 4 次新 tile，寻找 arrow 格与 explore 格拼接方式
        for _ in range(4):
            tile.rotate_right()

            for ty, row in enumerate(tile.layout):
                for tx, cell in enumerate(row):
                    types = cell.get("type", [])
                    if isinstance(types, str):
                        types = [types]

                    arrow_type = next((t for t in types if t.startswith("arrow:")), None)
                    if not arrow_type:
                        continue

                    # 🔍 判断 arrow 格是否在边缘
                    edge = None
                    if ty == 0:
                        edge = "up"
                    elif ty == tile.rows - 1:
                        edge = "down"
                    elif tx == 0:
                        edge = "left"
                    elif tx == tile.cols - 1:
                        edge = "right"
                    else:
                        continue  # 不是边缘

                    # ✅ 只有当 arrow 所在边与 explore 所在边方向相对时才允许拼接
                    opposite = {'up': 'down', 'down': 'up', 'left': 'right', 'right': 'left'}
                    if edge != opposite[direction]:
                        continue

                    # 计算新 tile 的 origin，使 arrow 格贴在 (ax, ay)
                    ox = ax - tx
                    oy = ay - ty
                    tile.origin = (ox, oy)

                    if self.maze.can_place_tile(tile):
                        self.maze.place_tile(tile)
                        self.tile_deck.pop(0)
                        self.explored_sites.add((ex, ey))
                        print(f">>> Tile placed at {tile.origin}")
                        return True

        print(">>> No suitable tile found")
        return False

    def use_escalator(self, agent):
        cell_type = self.maze.get_cell(agent.col, agent.row)
        if isinstance(cell_type, str):
            cell_type = [cell_type]

        # 当前 agent 所在格是否是 escalator:X
        current_label = next((t for t in cell_type if t.startswith("escalator:")), None)
        if not current_label:
            print(f">>> {agent.name} is not on an escalator.")
            return False

        parts = current_label.split(":")
        if len(parts) != 2:
            print(">>> Invalid escalator format.")
            return False

        # 计算配对的另一端
        pair_id = str(int(parts[1]) ^ 1)  # XOR 0↔1, 2↔3, 4↔5, ...

        target_label = f"escalator:{pair_id}"

        # 找配对 escalator 的位置
        for tile in self.maze.tiles:
            for i, row in enumerate(tile.layout):
                for j, cell in enumerate(row):
                    types = cell.get("type", [])
                    if isinstance(types, str):
                        types = [types]
                    if target_label in types:
                        gx = tile.origin[0] + j
                        gy = tile.origin[1] + i

                        # ✅ 检查目标格是否被其他 agent 占用
                        if any(a.col == gx and a.row == gy for a in self.agents):
                            print(f">>> Target escalator occupied.")
                            return False

                        # ✅ 自己传送过去（不能传送别人）
                        agent.col = gx
                        agent.row = gy
                        print(f">>> {agent.name} took escalator to ({gx},{gy})")
                        return True

        print(">>> Escalator destination not found.")
        return False

    def update_agent_status(self):
        for agent in self.agents:
            cell_type = self.maze.get_cell(agent.col, agent.row)
            if isinstance(cell_type, str):
                cell_type = [cell_type]
            for t in cell_type:
                if t.startswith("item:") and (t.endswith(agent.name) or t.endswith("all")):
                    agent.has_stolen = True
                if t.startswith("exit:") and agent.has_stolen and (t.endswith(agent.name) or t.endswith("all")):
                    if not agent.has_exited:
                        agent.has_exited = True
                        print(f">>> {agent.name} has exited — removing from map")
                        agent.col = -999
                        agent.row = -999

    def check_all_exited(self):
        return all(agent.has_exited for agent in self.agents)

    def trigger_theft(self):
        if not hasattr(self, "theft_done"):
            self.theft_done = False

        if not self.theft_done and self.check_theft_ready():
            self.theft_done = True
            print(">>> Theft triggered!")

    def check_theft_ready(self):
        return all(agent.has_stolen for agent in self.agents)

