from maptile import MapTile


def get_tile_deck():
    tile_list = []

    layout = [
        [  # Row 0
            {"type": "empty", "walls": {"up": True, "down": False, "left": True, "right": False}},
            {"type": "empty", "walls": {"up": True, "down": False, "left": False, "right": False}},
            {"type": "explore:all", "walls": {"up": False, "down": True, "left": False, "right": False}},
            {"type": "escalator:0", "walls": {"up": True, "down": True, "left": False, "right": True}},
        ],
        [  # Row 1
            {"type": "explore:all", "walls": {"up": False, "down": False, "left": False, "right": False}},
            {"type": "start:arm1", "walls": {"up": False, "down": False, "left": False, "right": False}},
            {"type": ["start:arm2", "escalator:1"],
             "walls": {"up": True, "down": False, "left": False, "right": False}},
            {"type": "empty", "walls": {"up": True, "down": False, "left": False, "right": True}},
        ],
        [  # Row 2
            {"type": "empty", "walls": {"up": False, "down": True, "left": True, "right": False}},
            {"type": ["start:arm3", "escalator:2"],
             "walls": {"up": False, "down": True, "left": False, "right": False}},
            {"type": "start:arm4", "walls": {"up": False, "down": False, "left": False, "right": False}},
            {"type": "explore:all", "walls": {"up": False, "down": False, "left": False, "right": False}},
        ],
        [  # Row 3
            {"type": "escalator:3", "walls": {"up": True, "down": True, "left": True, "right": False}},
            {"type": "explore:all", "walls": {"up": True, "down": False, "left": False, "right": False}},
            {"type": "empty", "walls": {"up": False, "down": True, "left": False, "right": False}},
            {"type": "empty", "walls": {"up": False, "down": True, "left": False, "right": True}},
        ]
    ]

    layout2 = [
        [  # Row 0
            {"type": ["empty"], "walls": {"up": True, "left": True, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": True, "down": False}},
            {"type": ["explore:all", "escalator:4"],
             "walls": {"up": False, "left": True, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": True, "down": False}},
        ],
        [  # Row 1
            {"type": ["explore:all"], "walls": {"left": False, "right": False}},
            {"type": ["escalator:5"], "walls": {"left": False, "right": True}},
            {"type": ["empty"], "walls": {"left": True, "right": False}},
            {"type": ["empty"], "walls": {"left": False, "right": True}},
        ],
        [  # Row 2
            {"type": ["empty"], "walls": {"left": True, "right": False}},
            {"type": ["empty"], "walls": {"left": False, "right": True}},
            {"type": ["escalator:6"], "walls": {"left": True, "right": False}},
            {"type": ["explore:all"], "walls": {"left": False, "right": False}},
        ],
        [  # Row 3
            {"type": ["empty"], "walls": {"left": True, "down": True, "right": False}},
            {"type": ["arrow:up", "escalator:7"], "walls": {"left": False, "down": False, "right": True}},
            {"type": ["empty"], "walls": {"left": True, "down": True, "right": False}},
            {"type": ["empty"], "walls": {"left": False, "down": True, "right": True}},
        ],
    ]

    layout3 = [
        [  # Row 0
            {"type": ["empty"], "walls": {"up": True, "left": True, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": False, "down": True}},
            {"type": ["explore:all"], "walls": {"up": False, "left": False, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": True, "down": False}},
        ],
        [  # Row 1
            {"type": ["explore:all"], "walls": {"left": False, "right": True}},
            {"type": ["empty"], "walls": {"up": True, "left": True, "right": False}},
            {"type": ["item:p4"], "walls": {"left": False, "right": True}},
            {"type": ["empty"], "walls": {"left": True, "right": True}},
        ],
        [  # Row 2
            {"type": ["empty"], "walls": {"left": True, "right": True}},
            {"type": ["empty"], "walls": {"left": True, "right": False}},
            {"type": ["empty"], "walls": {"left": False, "right": True, "down": True}},
            {"type": ["explore:all"], "walls": {"left": True, "right": False}},
        ],
        [  # Row 3
            {"type": ["empty"], "walls": {"left": True, "right": False, "down": True}},
            {"type": ["arrow:up"], "walls": {"left": False, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": False, "down": True}},
            {"type": ["empty"], "walls": {"left": False, "right": True, "down": True}},
        ],
    ]

    layout4 = [
        [  # Row 0
            {"type": ["escalator:8"], "walls": {"up": True, "left": True, "right": False, "down": True}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": False, "down": False}},
            {"type": ["explore:all", "escalator:10"], "walls": {"up": False, "left": False, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": True, "down": False}},
        ],
        [  # Row 1
            {"type": ["explore:all", "escalator:11", "exit:p3"], "walls": {"up": True, "left": False, "right": True, "down": False}},
            {"type": ["escalator:9"], "walls": {"up": False, "left": True, "right": False, "down": False}},
            {"type": ["escalator:12"], "walls": {"up": False, "left": False, "right": False, "down": True}},
            {"type": ["empty"], "walls": {"up": False, "left": False, "right": True, "down": True}},
        ],
        [  # Row 2
            {"type": ["exit:p1", "escalator:14"], "walls": {"up": False, "left": True, "right": True, "down": True}},
            {"type": ["escalator:16"], "walls": {"up": False, "left": True, "right": False, "down": False}},
            {"type": ["escalator:13"], "walls": {"up": True, "left": False, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": True, "down": False}},
        ],
        [  # Row 3
            {"type": ["escalator:17"], "walls": {"up": True, "left": True, "right": False, "down": True}},
            {"type": ["arrow:up"], "walls": {"up": False, "left": False, "right": False, "down": False}},
            {"type": ["escalator:15", "item:p1"], "walls": {"up": False, "left": False, "right": False, "down": True}},
            {"type": ["empty"], "walls": {"up": False, "left": False, "right": True, "down": True}},
        ],
    ]

    layout5 = [
        [  # Row 0
            {"type": ["empty"], "walls": {"up": True, "left": True, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": False, "down": False}},
            {"type": ["explore:all", "escalator:18"], "walls": {"up": False, "left": False, "right": False, "down": True}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": True, "down": False}},
        ],
        [  # Row 1
            {"type": ["explore:all", "escalator:20"], "walls": {"up": False, "left": False, "right": True, "down": True}},
            {"type": ["escalator:19"], "walls": {"up": False, "left": True, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": False, "down": False}},
            {"type": ["escalator:22"], "walls": {"up": False, "left": False, "right": True, "down": True}},
        ],
        [  # Row 2
            {"type": ["escalator:21"], "walls": {"up": True, "left": True, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": False, "left": False, "right": False, "down": True}},
            {"type": ["escalator:24", "item:p3"], "walls": {"up": False, "left": False, "right": True, "down": False}},
            {"type": ["explore:all", "escalator:23"], "walls": {"up": True, "left": True, "right": False, "down": False}},
        ],
        [  # Row 3
            {"type": ["empty"], "walls": {"up": False, "left": True, "right": False, "down": True}},
            {"type": ["arrow:up", "escalator:25"], "walls": {"up": True, "left": False, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": False, "left": False, "right": False, "down": True}},
            {"type": ["empty"], "walls": {"up": False, "left": False, "right": True, "down": True}},
        ],
    ]

    layout6 = [
        [  # Row 0
            {"type": ["empty"], "walls": {"up": True, "left": True, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": True, "down": False}},
        ],
        [  # Row 1
            {"type": ["explore:all", "escalator:26"], "walls": {"up": False, "left": False, "right": True, "down": True}},
            {"type": ["empty"], "walls": {"up": False, "left": True, "right": True, "down": False}},
            {"type": ["empty"], "walls": {"up": False, "left": True, "right": True, "down": False}},
            {"type": ["escalator:28"], "walls": {"up": False, "left": True, "right": True, "down": True}},
        ],
        [  # Row 2
            {"type": ["escalator:27"], "walls": {"up": True, "left": True, "right": True, "down": False}},
            {"type": ["item:p2"], "walls": {"up": False, "left": True, "right": True, "down": False}},
            {"type": ["empty"], "walls": {"up": False, "left": True, "right": True, "down": False}},
            {"type": ["explore:all", "escalator:29"], "walls": {"up": True, "left": True, "right": False, "down": False}},
        ],
        [  # Row 3
            {"type": ["empty"], "walls": {"up": False, "left": True, "right": False, "down": True}},
            {"type": ["arrow:up"], "walls": {"up": False, "left": False, "right": False, "down": False}},
            {"type": ["exit:p2"], "walls": {"up": False, "left": False, "right": False, "down": True}},
            {"type": ["empty"], "walls": {"up": False, "left": False, "right": True, "down": True}},
        ],
    ]

    layout7 = [
        [  # Row 0
            {"type": ["empty"], "walls": {"up": True, "left": True, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": False, "down": False}},
            {"type": ["explore:all"], "walls": {"up": False, "left": False, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": True, "down": False}},
        ],
        [  # Row 1
            {"type": ["explore:all"], "walls": {"up": False, "left": False, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": False, "left": False, "right": True, "down": False}},
            {"type": ["exit:p4"], "walls": {"up": False, "left": True, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": False, "left": False, "right": True, "down": False}},
        ],
        [  # Row 2
            {"type": ["empty"], "walls": {"up": False, "left": True, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": False, "left": False, "right": True, "down": False}},
            {"type": ["empty"], "walls": {"up": False, "left": True, "right": False, "down": False}},
            {"type": ["explore:all"], "walls": {"up": False, "left": False, "right": False, "down": False}},
        ],
        [  # Row 3
            {"type": ["empty"], "walls": {"up": False, "left": True, "right": False, "down": True}},
            {"type": ["arrow:up"], "walls": {"up": False, "left": False, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": False, "left": False, "right": False, "down": True}},
            {"type": ["empty"], "walls": {"up": False, "left": False, "right": True, "down": True}},
        ],
    ]

    layout8 = [
        [  # Row 0
            {"type": ["escalator:30"], "walls": {"up": True, "left": True, "right": False, "down": True}},
            {"type": ["escalator:32"], "walls": {"up": True, "left": False, "right": False, "down": True}},
            {"type": ["explore:all"], "walls": {"up": False, "left": False, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": True, "down": False}},
        ],
        [  # Row 1
            {"type": ["escalator:31", "escalator:34"], "walls": {"up": True, "left": True, "right": True, "down": False}},
            {"type": ["escalator:33", "escalator:35"], "walls": {"up": True, "left": True, "right": True, "down": False}},
            {"type": ["empty"], "walls": {"up": False, "left": True, "right": False, "down": True}},
            {"type": ["empty"], "walls": {"up": False, "left": False, "right": True, "down": False}},
        ],
        [  # Row 2
            {"type": ["empty"], "walls": {"up": False, "left": True, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": False, "left": False, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": True, "right": True, "down": True}},
            {"type": ["empty"], "walls": {"up": False, "left": True, "right": True, "down": False}},
        ],
        [  # Row 3
            {"type": ["empty"], "walls": {"up": False, "left": True, "right": False, "down": True}},
            {"type": ["arrow:up"], "walls": {"up": False, "left": False, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": False, "down": True}},
            {"type": ["empty"], "walls": {"up": False, "left": False, "right": True, "down": True}},
        ],
    ]

    layout9 = [
        [  # Row 0
            {"type": ["empty"], "walls": {"up": True, "left": True, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": False, "down": False}},
            {"type": ["explore:all"], "walls": {"up": False, "left": False, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": True, "down": False}},
        ],
        [  # Row 1
            {"type": ["empty"], "walls": {"up": False, "left": True, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": False, "left": False, "right": False, "down": True}},
            {"type": ["empty"], "walls": {"up": False, "left": False, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": False, "left": False, "right": True, "down": False}},
        ],
        [  # Row 2
            {"type": ["empty"], "walls": {"up": False, "left": True, "right": True, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": True, "right": True, "down": False}},
            {"type": ["empty"], "walls": {"up": False, "left": True, "right": True, "down": False}},
            {"type": ["empty"], "walls": {"up": False, "left": True, "right": True, "down": False}},
        ],
        [  # Row 3
            {"type": ["empty"], "walls": {"up": False, "left": True, "right": False, "down": True}},
            {"type": ["arrow:up"], "walls": {"up": False, "left": False, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": False, "left": False, "right": False, "down": True}},
            {"type": ["empty"], "walls": {"up": False, "left": False, "right": True, "down": True}},
        ],
    ]

    layout10 = [
        [  # Row 0
            {"type": ["empty"], "walls": {"up": True, "left": True, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": False, "down": True}},
            {"type": ["explore:all"], "walls": {"up": False, "left": False, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": True, "down": False}},
        ],
        [  # Row 1
            {"type": ["empty"], "walls": {"up": False, "left": True, "right": True, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": True, "right": True, "down": True}},
            {"type": ["empty"], "walls": {"up": False, "left": True, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": False, "left": False, "right": True, "down": False}},
        ],
        [  # Row 2
            {"type": ["empty"], "walls": {"up": False, "left": True, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": True, "down": False}},
            {"type": ["empty"], "walls": {"up": False, "left": True, "right": False, "down": True}},
            {"type": ["empty"], "walls": {"up": False, "left": False, "right": True, "down": True}},
        ],
        [  # Row 3
            {"type": ["empty"], "walls": {"up": False, "left": True, "right": False, "down": True}},
            {"type": ["arrow:up"], "walls": {"up": False, "left": False, "right": False, "down": False}},
            {"type": ["empty"], "walls": {"up": True, "left": False, "right": True, "down": True}},
            {"type": ["empty"], "walls": {"up": True, "left": True, "right": True, "down": True}},
        ],
    ]
    tile_list.append(MapTile(layout=layout, origin=(4, 3)))  # tile1
    tile_list.append(MapTile(layout=layout2, origin=(0, 0)))  # tile2
    tile_list.append(MapTile(layout=layout3, origin=(0, 0)))  # tile3
    tile_list.append(MapTile(layout=layout4, origin=(0, 0)))    # tile4
    tile_list.append(MapTile(layout=layout5, origin=(0, 0)))    # tile5
    tile_list.append(MapTile(layout=layout6, origin=(0, 0)))    # tile6
    tile_list.append(MapTile(layout=layout7, origin=(0, 0)))    # tile7
    # tile_list.append(MapTile(layout=layout8, origin=(0, 0)))    # tile8
    # tile_list.append(MapTile(layout=layout9, origin=(0, 0)))    # tile9
    # tile_list.append(MapTile(layout=layout10, origin=(0, 0)))  # tile10
    return tile_list
