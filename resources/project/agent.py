
import pygame

class Agent:
    def __init__(self, name, row, col, color):
        self.name = name
        self.row = row
        self.col = col
        self.color = color
        self.has_stolen = False
        self.has_exited = False

    def move(self, drow, dcol, maze, agents):
        new_row = self.row + drow
        new_col = self.col + dcol

        dir_name = None
        if drow == -1:
            dir_name = "up"
        elif drow == 1:
            dir_name = "down"
        elif dcol == -1:
            dir_name = "left"
        elif dcol == 1:
            dir_name = "right"
        if not dir_name:
            return

        current_walls = maze.get_walls(self.col, self.row)
        if current_walls.get(dir_name):
            return

        if not maze.is_walkable(new_col, new_row):
            return

        # ✅ 检查目标格是否已有其他棋子
        for other in agents:
            if other is not self and other.col == new_col and other.row == new_row:
                return  # 被占用，不能移动

        # ✅ 可以移动
        self.row = new_row
        self.col = new_col

    def draw(self, screen, cell_size, offset_x=0, offset_y=0):
        if self.has_exited:
            return  # ✅ 不绘制已逃脱的 agent

        font = pygame.font.SysFont("arial", 16)
        small_font = pygame.font.SysFont("arial", 12)

        x = self.col * cell_size + cell_size // 2 + offset_x
        y = self.row * cell_size + cell_size // 2 + offset_y

        # 绘制 agent 本体
        pygame.draw.circle(screen, self.color, (x, y), cell_size // 3)

        # 显示 agent 状态（WAITING / STOLEN）
        label = "STOLEN" if self.has_stolen else "WAITING"
        text = font.render(label, True,
                           (255, 165, 0) if self.has_stolen else (100, 100, 100))
        screen.blit(text, (x - cell_size // 2, y + cell_size // 3 + 2))

        # ✅ 显示控制该 agent 的 ARM 名称（arm1 或 arm2）
        if hasattr(self, "last_arm"):
            arm_text = small_font.render(self.last_arm.upper(), True, (0, 0, 0))
            screen.blit(arm_text, (x - 15, y - 30))  # 上方显示控制器



