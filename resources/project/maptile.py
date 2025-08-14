
class MapTile:
    def __init__(self, layout, origin, interface=None):
        self.layout = layout
        self.origin = origin
        self.rows = len(layout)
        self.cols = len(layout[0])
        self.interface = interface or {}

    def get_cell(self, gx, gy):
        lx = gx - self.origin[0]
        ly = gy - self.origin[1]
        if 0 <= ly < self.rows and 0 <= lx < self.cols:
            return self.layout[ly][lx].get("type", [])
        return []

    def get_walls(self, gx, gy):
        lx = gx - self.origin[0]
        ly = gy - self.origin[1]
        if 0 <= ly < self.rows and 0 <= lx < self.cols:
            return self.layout[ly][lx].get("walls", {})
        return {}

    def is_walkable(self, gx, gy):
        types = self.get_cell(gx, gy)
        return "void" not in types

    def rotate_right(self):
        new_layout = []
        for x in range(self.cols):
            new_row = []
            for y in range(self.rows - 1, -1, -1):
                original = self.layout[y][x]
                old_walls = original.get("walls", {})
                new_walls = {
                    "up": old_walls.get("left", False),
                    "right": old_walls.get("up", False),
                    "down": old_walls.get("right", False),
                    "left": old_walls.get("down", False),
                }
                new_row.append({
                    "type": original.get("type", []),
                    "walls": new_walls
                })
            new_layout.append(new_row)
        self.layout = new_layout
        self.rows = len(self.layout)
        self.cols = len(self.layout[0])

