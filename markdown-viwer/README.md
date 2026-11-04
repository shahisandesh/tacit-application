# Markdown

A markdown reader, writer and presentation deck for Quickshell, built from
[Tacit.Kit](https://design.tacitos.co). The document sits on the same dark glass
sheet as the Type panel, over the window ground, so it takes the wallpaper's
colour and glow. Headings take the palette's green, and the accent marks the
rules, bullets, quotes, links and code edges.

## Run

On Tacit:

```sh
qs -p app.qml
```

Elsewhere, put the kit's `qml/` folder on the import path:

```sh
QML_IMPORT_PATH=/path/to/tacit-kit/qml qs -p app.qml
```

Quickshell 0.3 or later and Qt 6.7 or later are required.

## Views

- **Write** — the Markdown source on the left, the page following it on the right.
- **Read** — the page alone, centred on the window.
- **Present** — one slide at a time on the stage, with arrow keys, Space and the
  progress bar. F5 starts a presentation and Esc leaves it.

Save with Ctrl+S. The Type action opens the docked panel for the reading face,
size and line height, the writing face and size, and the slide size.

## Slides

A line of three dashes starts the next slide:

```markdown
# A title

A line of words.

---

## The next slide
```

A fence keeps its dashes: `---` inside a code block does not split a slide.

## Code

Name the language on the fence and the code is coloured: keywords, strings,
numbers, comments, functions and types all take their colour from the page's
palette.

```js
const slides = source.split("---");
console.log(slides.length);
```

JavaScript and TypeScript, Bash, Python, JSON, CSS, HTML/XML, C/C++, Java and
Kotlin, Rust, Go, SQL, YAML, TOML, Markdown and diffs are read. A fence with an
unknown language still gets strings, numbers and comments; a fence with no
language stays plain.
