// SPDX-License-Identifier: LGPL-3.0-or-later
// Emoji for the launcher's `:` mode: one word per face or thing, the way people already
// write them. A typing list: the rows are the shortnames whose start matches what was typed.
.pragma library

var MAP = {
    // faces
    "grinning": "😀", "smiley": "😃", "smile": "😄", "grin": "😁", "laughing": "😆",
    "sweat_smile": "😅", "joy": "😂", "rofl": "🤣", "relaxed": "☺️", "blush": "😊",
    "heart_eyes": "😍", "kiss": "😘", "wink": "😉", "cool": "😎", "thinking": "🤔",
    "zipper_mouth": "🤐", "neutral": "😐", "expressionless": "😑", "unamused": "😒",
    "roll_eyes": "🙄", "grimacing": "😬", "lying": "🤥", "sneezing": "🤧", "dizzy": "😵",
    "sunflower_face": "🌻", "melting": "🫠", "partying": "🥳", "smirk": "😏",
    "tongue": "😛", "tongue_wink": "😜", "tongue_closed": "😝", "hushed": "😯",
    "sleepy": "😪", "sleeping": "😴", "mask": "😷", "hot": "🥵", "cold": "🥶",
    "woozy": "🥴", "cry": "😢", "sob": "😭", "angry": "😠", "rage": "😡",
    "confounded": "😖", "persevere": "😣", "worried": "😟", "weary": "😩",
    "open_mouth": "😮", "astonished": "😲", "flushed": "😳", "pleading": "🥺",
    "frown": "☹️", "scream": "😱", "confused": "😕", "cowboy": "🤠",
    // hands and people
    "wave": "👋", "raised_hand": "✋", "ok_hand": "👌", "thumbs_up": "👍",
    "thumbs_down": "👎", "clap": "👏", "pray": "🙏", "muscle": "💪", "point_right": "👉",
    "point_left": "👈", "point_up": "☝️", "point_down": "👇", "v": "✌️", "crossed_fingers": "🤞",
    "love_you": "🫰", "pinch": "🤏", "fist": "✊", "punch": "👊", "handshake": "🤝",
    "eyes": "👀", "brain": "🧠", "skull": "💀", "ghost": "👻", "alien": "👽", "robot": "🤖",
    "poop": "💩", "baby": "👶", "artist": "🧑‍🎨", "detective": "🕵️", "santa": "🎅",
    // hearts and marks
    "heart": "❤️", "orange_heart": "🧡", "yellow_heart": "💛", "green_heart": "💚",
    "blue_heart": "💙", "purple_heart": "💜", "black_heart": "🖤", "broken_heart": "💔",
    "sparkling_heart": "💖", "growing_heart": "💗", "beating_heart": "💓",
    "star": "⭐", "sparkles": "✨", "zap": "⚡", "fire": "🔥", "boom": "💥",
    "check": "✅", "correct": "✅", "cross": "❌", "wrong": "❌", "wrong_mark": "❌",
    "warning": "⚠️", "question": "❓", "exclamation": "❗",
    "100": "💯", "recycle": "♻️", "infinity": "♾️", "sos": "🆘",
    // objects and tools
    "rocket": "🚀", "bulb": "💡", "computer": "💻", "keyboard": "⌨️", "phone": "📱",
    "email": "📧", "envelope": "✉️", "package": "📦", "lock": "🔒", "unlock": "🔓",
    "key": "🔑", "hammer": "🔨", "wrench": "🔧", "gear": "⚙️", "magnify": "🔍",
    "bell": "🔔", "book": "📖", "memo": "📝", "calendar": "📅", "clock": "🕐",
    "pin": "📌", "scissors": "✂️", "link": "🔗", "trophy": "🏆", "medal": "🏅",
    "balloon": "🎈", "tada": "🎉", "congrats": "🎉", "congratulations": "🎉",
    "well_done": "👏", "gift": "🎁", "crystal_ball": "🔮", "magic_wand": "🪄",
    // nature and sky
    "sun": "☀️", "moon": "🌙", "earth": "🌍", "cloud": "☁️", "rainbow": "🌈",
    "snowflake": "❄️", "ocean": "🌊", "star_crescent": "🌟", "glowing_star": "🌟",
    "rose": "🌹", "flower": "🌸", "sunflower": "🌻", "leaf": "🍃", "tree": "🌳",
    "cactus": "🌵", "mushroom": "🍄", "herb": "🌿", "cherry_blossom": "🌸",
    // animals
    "dog": "🐶", "cat": "🐱", "mouse": "🐭", "hamster": "🐹", "rabbit": "🐰",
    "fox": "🦊", "bear": "🐻", "panda": "🐼", "koala": "🐨", "tiger": "🐯",
    "lion": "🦁", "cow": "🐮", "pig": "🐷", "frog": "🐸", "monkey": "🐵",
    "chicken": "🐔", "penguin": "🐧", "bird": "🐦", "owl": "🦉", "bat": "🦇",
    "unicorn": "🦄", "dragon": "🐉", "snake": "🐍", "turtle": "🐢", "whale": "🐋",
    "dolphin": "🐬", "fish": "🐟", "octopus": "🐙", "butterfly": "🦋", "bee": "🐝",
    "ant": "🐜", "spider": "🕷️", "bug": "🐛", "t-rex": "🦖",
    // food
    "apple": "🍎", "banana": "🍌", "orange": "🍊", "lemon": "🍋", "watermelon": "🍉",
    "grapes": "🍇", "strawberry": "🍓", "cherry": "🍒", "peach": "🍑", "avocado": "🥑",
    "broccoli": "🥦", "pizza": "🍕", "burger": "🍔", "fries": "🍟", "hotdog": "🌭",
    "taco": "🌮", "burrito": "🌯", "sushi": "🍣", "ramen": "🍜", "spaghetti": "🍝",
    "bread": "🍞", "egg": "🥚", "cheese": "🧀", "popcorn": "🍿", "ice_cream": "🍦",
    "donut": "🍩", "cookie": "🍪", "cake": "🍰", "chocolate": "🍫", "candy": "🍬",
    "coffee": "☕", "tea": "🍵", "beer": "🍺", "cocktail": "🍸", "wine": "🍷",
    "tumbler": "🥃", "cup": "🧋", "chopsticks": "🥢",
    // play and travel
    "soccer": "⚽", "basketball": "🏀", "football": "🏈", "baseball": "⚾", "tennis": "🎾",
    "volleyball": "🏐", "rugby": "🏉", "ping_pong": "🏓", "badminton": "🏸", "bowling": "🎳",
    "dart": "🎯", "game_die": "🎲", "puzzle": "🧩", "chess": "♟️",
    "joystick": "🕹️", "video_game": "🎮", "target": "🎯",
    "music": "🎵", "notes": "🎶", "mic": "🎤", "headphones": "🎧", "guitar": "🎸",
    "drum": "🥁", "violin": "🎻", "trumpet": "🎺", "piano": "🎹",
    "art": "🎨", "camera": "📷", "movie": "🎥", "cinema": "🎬", "theater": "🎭",
    "car": "🚗", "bus": "🚌", "truck": "🚚", "train": "🚆", "bike": "🚲",
    "plane": "✈️", "boat": "⛵", "ship": "🚢", "helicopter": "🚁", "scooter": "🛴",
    "house": "🏠", "office": "🏢", "hospital": "🏥", "school": "🏫", "church": "⛪",
    "castle": "🏰", "tent": "⛺", "mountain": "⛰️", "desert": "🏜️", "island": "🏝️",
    // arrows and misc
    "arrow_right": "➡️", "arrow_left": "⬅️", "arrow_up": "⬆️", "arrow_down": "⬇️",
    "cycle": "🔄", "back": "🔙", "soon": "🔜", "up": "🔝", "new": "🔖",
    "flag": "🚩", "white_flag": "🏳️", "checkered_flag": "🏁", "anchor": "⚓",
    "compass": "🧭", "hourglass": "⏳", "scale": "⚖️", "toolbox": "🧰",
    "bandage": "🩹", "pill": "💊", "syringe": "💉", "dna": "🧬", "microscope": "🔬",
    "telescope": "🔭", "satellite": "🛰️", "ufo": "🛸", "ring": "💍", "gem": "💎",
    "money": "💰", "coin": "🪙", "credit_card": "💳", "receipt": "🧾"
}

// the rows for what has been typed after the colon, nearest first: a name that starts
// with the words beats a name that merely holds them
function matches(typed) {
    const needle = typed.toLowerCase()
    const starts = []
    const holds = []
    for (const name of Object.keys(MAP)) {
        if (needle === "") continue
        if (name.startsWith(needle)) starts.push(name)
        else if (name.includes(needle)) holds.push(name)
    }
    starts.sort((a, b) => a.length - b.length)
    holds.sort()
    return (needle === "" ? Object.keys(MAP).sort() : starts.concat(holds)).slice(0, 8)
}
