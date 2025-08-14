import pygame
import json
import os
import time
from maptile import MapTile
from maze import MazeMap
from agent import Agent
from environment import MagicMazeEnv
from tile_deck import get_tile_deck
from game_mediator import handle_external_request

_last_tile_count = -1  # 初始化为全局变量

def color_name(rgb):
    color_map = {
        (128, 0, 128): "Purple",
        (0, 255, 0): "Green",
        (255, 165, 0): "Orange",
        (0, 0, 255): "Blue"
    }
    return color_map.get(rgb, str(rgb))

def safe_write_json(data, path, retries=5, delay=0.1):
    tmp_path = path + ".tmp"
    for _ in range(retries):
        try:
            with open(tmp_path, "w") as f:
                json.dump(data, f, indent=2)
            os.replace(tmp_path, path)
            return
        except PermissionError:
            time.sleep(delay)
    print(f"⚠️ 无法写入 {path}，请检查文件是否被占用。")

def create_game():
    tile_deck = get_tile_deck()
    maze = MazeMap()
    tile = tile_deck[0]
    maze.add_tile(tile)

    ox, oy = tile.origin
    agents = [
        Agent("p1", oy + 1, ox + 1, (128, 0, 128)),
        Agent("p2", oy + 1, ox + 2, (0, 255, 0)),
        Agent("p3", oy + 2, ox + 1, (255, 165, 0)),
        Agent("p4", oy + 2, ox + 2, (0, 0, 255)),
    ]

    env = MagicMazeEnv(maze, agents, tile_deck)
    return maze, env, agents

def export_explore_cells(env, filename="explore_cells.json"):
    explores = []
    for tile in env.maze.tiles:
        ox, oy = tile.origin
        for y, row in enumerate(tile.layout):
            for x, cell in enumerate(row):
                types = cell.get("type", [])
                if isinstance(types, str):
                    types = [types]
                if any("explore" in t for t in types):
                    explores.append({"row": oy + y, "col": ox + x})
    safe_write_json(explores, filename)

def export_maze_structure(env, grid_file="maze_grid.json", wall_file="wall_map.json", offset_file="grid_offset.json"):
    global _last_tile_count
    tile_count = len(env.maze.tiles)
    if _last_tile_count != tile_count:
        print(f"📎 maze_grid.json exported with {tile_count} tiles.")
        _last_tile_count = tile_count

    tile_cells = {}
    min_row, min_col = float("inf"), float("inf")
    max_row, max_col = float("-inf"), float("-inf")

    for tile in env.maze.tiles:
        ox, oy = tile.origin
        for y, row in enumerate(tile.layout):
            for x, cell in enumerate(row):
                gx = ox + x
                gy = oy + y
                tile_cells[(gy, gx)] = cell
                min_row = min(min_row, gy)
                min_col = min(min_col, gx)
                max_row = max(max_row, gy)
                max_col = max(max_col, gx)

    offset_row = min_row
    offset_col = min_col
    rows = max_row - min_row + 1
    cols = max_col - min_col + 1

    maze_grid = []
    wall_map = []

    for row in range(rows):
        maze_row = []
        for col in range(cols):
            gy = row + min_row
            gx = col + min_col
            if (gy, gx) in tile_cells:
                cell = tile_cells[(gy, gx)]
                cell_type = cell.get("type", [])
                if isinstance(cell_type, str):
                    cell_type = [cell_type]
                maze_cell = {"type": cell_type or []}

                walls = cell.get("walls", {})
                wall_dirs = [d for d, is_wall in walls.items() if is_wall]
                if wall_dirs:
                    wall_map.append({"row": row, "col": col, "walls": wall_dirs})
            else:
                maze_cell = {"type": []}  # void
            maze_row.append(maze_cell)
        maze_grid.append(maze_row)

    safe_write_json(maze_grid, grid_file)
    safe_write_json(wall_map, wall_file)
    safe_write_json({"row_offset": offset_row, "col_offset": offset_col}, offset_file)

def export_agent_positions(agents, filename="agent_state.json"):
    data = [{
        "name": a.name,
        "row": a.row,
        "col": a.col,
        "has_stolen": a.has_stolen,
        "has_exited": a.has_exited
    } for a in agents]
    safe_write_json(data, filename)


def export_elevator_map(env, filename="elevator_map.json"):
    elevator_dict = {}
    for tile in env.maze.tiles:
        ox, oy = tile.origin
        for y, row in enumerate(tile.layout):
            for x, cell in enumerate(row):
                types = cell.get("type", [])
                if isinstance(types, str):
                    types = [types]
                for t in types:
                    if t.startswith("escalator:"):
                        eid = "x" + t.split(":")[1]
                        if eid not in elevator_dict:
                            elevator_dict[eid] = []
                        elevator_dict[eid].append({"row": oy + y, "col": ox + x})
    data = [{"id": eid, "positions": poslist} for eid, poslist in elevator_dict.items()]
    safe_write_json(data, filename)

def run_game():
    CELL_SIZE = 60
    pygame.init()
    screen = pygame.display.set_mode((1000, 900))
    pygame.font.init()
    clock = pygame.time.Clock()

    maze, env, agents = create_game()
    export_maze_structure(env)
    for agent in agents:
        print(f"[AGENT INIT] {agent.name} starts at row={agent.row}, col={agent.col}")

    env.explore(agents[0])
    export_explore_cells(env)
    export_agent_positions(agents)
    export_maze_structure(env)

    selected_idx = 0
    win = False
    running = True
    offset_x, offset_y = 0, 0
    dragging = False
    last_mouse_pos = (0, 0)

    while running:
        screen.fill((255, 255, 255))
        maze.draw(screen, CELL_SIZE, offset_x, offset_y)

        # 🔁 每帧读取控制信息，注入 agent 的 .last_arm 字段供渲染使用
        try:
            with open("agent_state.json", "r") as f:
                agent_state = json.load(f)
            for agent in agents:
                match = next((a for a in agent_state if a["name"] == agent.name), None)
                if match and "last_arm" in match:
                    agent.last_arm = match["last_arm"]
        except Exception as e:
            print(f"[WARN] 读取 last_arm 失败: {e}")

        info_font = pygame.font.SysFont("arial", 18)
        ui_y = 10

        controlled_agent = agents[selected_idx]
        control_text = f"Controlling: {controlled_agent.name.upper()} ({color_name(controlled_agent.color)})"
        text_surface = info_font.render(control_text, True, (0, 0, 0))
        screen.blit(text_surface, (10, ui_y))

        for i, agent in enumerate(agents):
            label = f"{agent.name.upper()}: {color_name(agent.color)}"
            color_preview = pygame.Surface((20, 20))
            color_preview.fill(agent.color)
            screen.blit(color_preview, (10, ui_y + 30 + i * 25))
            screen.blit(info_font.render(label, True, (0, 0, 0)), (40, ui_y + 30 + i * 25))

        for agent in agents:
            agent.draw(screen, CELL_SIZE, offset_x, offset_y)

        env.update_agent_status()
        env.trigger_theft()
        export_explore_cells(env)
        export_agent_positions(agents)
        export_maze_structure(env)
        export_elevator_map(env)
        handle_external_request(env, agents)

        if env.check_all_exited():
            if not win:
                print(">>> All agents escaped. You win!")
            win = True

        if win:
            win_font = pygame.font.SysFont("arial", 48)
            win_text = win_font.render("YOU WIN! Press R to restart", True, (0, 128, 0))
            screen.blit(win_text, (100, 350))

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.MOUSEBUTTONDOWN:
                if event.button == 1:
                    dragging = True
                    last_mouse_pos = pygame.mouse.get_pos()
            elif event.type == pygame.MOUSEBUTTONUP:
                if event.button == 1:
                    dragging = False
            elif event.type == pygame.MOUSEMOTION:
                if dragging:
                    current_mouse_pos = pygame.mouse.get_pos()
                    dx = current_mouse_pos[0] - last_mouse_pos[0]
                    dy = current_mouse_pos[1] - last_mouse_pos[1]
                    offset_x += dx
                    offset_y += dy
                    last_mouse_pos = current_mouse_pos
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_r:
                    maze, env, agents = create_game()
                    selected_idx = 0
                    win = False
                    offset_x, offset_y = 0, 0
                elif not win:
                    agent = agents[selected_idx]
                    if event.key == pygame.K_TAB:
                        selected_idx = (selected_idx + 1) % len(agents)
                    elif event.key == pygame.K_w:
                        agent.move(-1, 0, maze, agents)
                    elif event.key == pygame.K_s:
                        agent.move(1, 0, maze, agents)
                    elif event.key == pygame.K_a:
                        agent.move(0, -1, maze, agents)
                    elif event.key == pygame.K_d:
                        agent.move(0, 1, maze, agents)
                    elif event.key == pygame.K_e:
                        env.explore(agent)
                    elif event.key == pygame.K_q:
                        env.use_vortex(agent)
                    elif event.key == pygame.K_z:
                        env.use_escalator(agent)

        pygame.display.flip()
        clock.tick(30)

    pygame.quit()

if __name__ == "__main__":
    run_game()
