
import pygame

class MazeMap:
    def __init__(self):
        self.tiles = []

    def add_tile(self, tile):
        self.tiles.append(tile)

    def place_tile(self, tile):
        self.add_tile(tile)

    def can_place_tile(self, tile):
        for i, row in enumerate(tile.layout):
            for j, _ in enumerate(row):
                gx = tile.origin[0] + j
                gy = tile.origin[1] + i
                if self.get_cell(gx, gy):  # 已有 tile 占用
                    return False
        return True

    def get_cell(self, x, y):
        for tile in self.tiles:
            val = tile.get_cell(x, y)
            if val:
                return val
        return []

    def get_walls(self, x, y):
        for tile in self.tiles:
            walls = tile.get_walls(x, y)
            if walls:
                return walls
        return {}

    # def is_walkable(self, x, y):
    #     return "wall" not in self.get_cell(x, y)

    def is_walkable(self, x, y):
        cell = self.get_cell(x, y)
        # 越界（没有任何tile覆盖）直接不可走
        if not cell:
            return False
        # 统一成列表
        if isinstance(cell, str):
            cell = [cell]
        # 可选：如果你以后定义了 "void" 一类的禁走格，这里也一并拦住
        return ("void" not in cell) and ("wall" not in cell)

    def draw(self, screen, cell_size, offset_x=0, offset_y=0):
        font = pygame.font.SysFont("arial", 12)
        for tile in self.tiles:
            for i, row in enumerate(tile.layout):
                for j, cell in enumerate(row):
                    gx = tile.origin[0] + j
                    gy = tile.origin[1] + i
                    x = gx * cell_size + offset_x
                    y = gy * cell_size + offset_y


                    cell_type = cell.get("type", [])
                    if isinstance(cell_type, str):
                        cell_type = [cell_type]
                    walls = cell.get("walls", {})

                    base_color = (220, 220, 220)
                    if any("explore" in t for t in cell_type):
                        base_color = (200, 255, 200)
                    elif any("escalator" in t for t in cell_type):
                        base_color = (180, 220, 255)
                    elif any("arrow" in t for t in cell_type):
                        base_color = (240, 240, 240)

                    pygame.draw.rect(screen, base_color, (x, y, cell_size, cell_size))
                    pygame.draw.rect(screen, (180, 180, 180), (x, y, cell_size, cell_size), 1)

                    if walls.get("up"): pygame.draw.line(screen, (0, 0, 0), (x, y), (x+cell_size, y), 4)
                    if walls.get("down"): pygame.draw.line(screen, (0, 0, 0), (x, y+cell_size), (x+cell_size, y+cell_size), 4)
                    if walls.get("left"): pygame.draw.line(screen, (0, 0, 0), (x, y), (x, y+cell_size), 4)
                    if walls.get("right"): pygame.draw.line(screen, (0, 0, 0), (x+cell_size, y), (x+cell_size, y+cell_size), 4)

                    if any("explore" in t for t in cell_type):
                        screen.blit(font.render("E", True, (0, 128, 0)), (x+6, y+6))
                    for t in cell_type:
                        if t.startswith("escalator:"):
                            try:
                                _, num = t.split(":")
                                group = int(num) // 2
                                label = f"S{group}"
                                text = font.render(label, True, (0, 0, 255))
                                text_rect = text.get_rect(topright=(x + cell_size - 4, y + 2))
                                screen.blit(text, text_rect)
                            except:
                                pass

                    if any("arrow" in t for t in cell_type):
                        screen.blit(font.render("^", True, (0, 0, 0)), (x+6, y+6))
                    # ✅ item 渲染
                    for t in cell_type:
                        if t.startswith("item:"):
                            _, target = t.split(":")
                            if target == "all":
                                label = "IA"
                            else:
                                label = "I" + target[-1]  # 显示 I1–I4
                            item_text = font.render(label, True, (200, 0, 0))
                            screen.blit(item_text, (x + 6, y + 20))  # 调整位置

                    for t in cell_type:
                        if t.startswith("exit:"):
                            _, who = t.split(":")
                            label = "X" + (who[-1] if who != "all" else "A")  # X4 or XA
                            text = font.render(label, True, (255, 0, 0))  # 红色表示出口
                            screen.blit(text, (x + 6, y + 22))

