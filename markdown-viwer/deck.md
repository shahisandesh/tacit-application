# Markdown

Write on the left. The page beside it follows as you type.

---

## Three views

- **Write** shows the source and the page side by side.
- **Read** gives the page the whole window.
- **Present** puts one slide on the stage; press F5 or the Present tab.

---

## Slides

A line of three dashes starts the next slide.

```markdown
# A title

A line of words.

---

## The next slide
```

The dashes inside a fence stay put.

---

## Code

A fence with a language is coloured.

```js
const slides = source.split("---");
slides.forEach((slide, i) => {
  // the page follows the source
  console.log(`Slide ${i + 1}: ${slide.trim()}`);
});
```

```bash
for file in ~/Documents/*.md; do
  echo "Reading $file"
  wc -l "$file"
done
```

---

## Marks

You can write **strong**, *italic*, `code`, ~~struck~~ and [links](https://example.com).

> A quote sits on a quiet rule, in the second ink.

---

## Lists and tables

- A point
- Another point
  - A point under it
- A last point

| Part | What it is for |
|---|---|
| Write | The source |
| Read | The page |
| Present | The stage |

---

# Set the type

The Type panel beside the page sets the reading face and size, the line height, the writing face and size, and the stage's size.

Press Esc to come back to the page.

---

## A long slide

- Line 01: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 02: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 03: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 04: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 05: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 06: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 07: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 08: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 09: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 10: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 11: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 12: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 13: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 14: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 15: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 16: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 17: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 18: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 19: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 20: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 21: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 22: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 23: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 24: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 25: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 26: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 27: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 28: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 29: the stage keeps the long slide readable, and the page scrolls when it does not fit.
- Line 30: the stage keeps the long slide readable, and the page scrolls when it does not fit.
