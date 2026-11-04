.pragma library

// A small Markdown reader for Tacit's document page and its stage. It reads what a slide deck needs:
// headings, paragraphs, lists, quotes, fences, rules, tables and the usual inline marks. A line of
// three dashes alone separates slides (the same line a rule uses on the page); a fence keeps its
// dashes. It returns plain data, so the QML parts draw every block from Kit.tokens and never from a
// colour of their own.

function normalise(text) {
    return String(text ?? "").replace(/\r\n?/g, "\n");
}

function escapeHtml(text) {
    return String(text ?? "")
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;");
}

function plain(text) {
    return String(text ?? "")
        .replace(/!\[([^\]]*)\]\([^)]*\)/g, "$1")
        .replace(/\[([^\]]*)\]\([^)]*\)/g, "$1")
        .replace(/`([^`]*)`/g, "$1")
        .replace(/[*_~]/g, "")
        .replace(/\s+/g, " ")
        .trim();
}

function inline(text, theme) {
    const code = [];
    let s = String(text ?? "");

    // Code spans first: their words are never read as marks.
    s = s.replace(/`([^`\n]+)`/g, (m, words) => {
        const i = code.push(words) - 1;
        return "\u0000C" + i + "\u0000";
    });

    s = escapeHtml(s);

    // Qt's styled text ignores the style attribute; it honours these tags. Images stay words on
    // the page: the alt text in the quieter ink.
    s = s.replace(/!\[([^\]]*)\]\(([^)\s]+)(?:\s+&quot;[^&]*&quot;)?\)/g,
        (m, alt) => `<font color="${theme.metaCss}">${alt}</font>`);

    s = s.replace(/\[([^\]]+)\]\(([^)\s]+)(?:\s+&quot;[^&]*&quot;)?\)/g,
        (m, words, url) => `<a href="${url}">${words}</a>`);

    s = s.replace(/\*\*([^*\n]+)\*\*/g, "<b>$1</b>");
    s = s.replace(/__([^_\n]+)__/g, "<b>$1</b>");
    s = s.replace(/(^|[^*])\*([^*\n]+)\*/g, "$1<i>$2</i>");
    s = s.replace(/(^|[^_])_([^_\n]+)_/g, "$1<i>$2</i>");
    s = s.replace(/~~([^~\n]+)~~/g, "<s>$1</s>");

    for (let i = 0; i < code.length; i++) {
        const span = `<font face="${theme.codeFamily}" color="${theme.codeInkCss}">${escapeHtml(code[i])}</font>`;
        s = s.replace("\u0000C" + i + "\u0000", span);
    }

    return s.replace(/\n/g, "<br/>");
}

function isBlank(line) {
    return /^\s*$/.test(line);
}

function isRule(line) {
    const s = String(line ?? "").trim();
    return s.length >= 3 && /^([-*_])(\s*\1){2,}$/.test(s);
}

function fenceAt(line) {
    const m = /^\s{0,3}(`{3,}|~{3,})\s*([^\s`]*)\s*$/.exec(line);
    return m ? { marker: m[1][0], length: m[1].length, language: m[2] || "" } : null;
}

function cells(line) {
    let s = String(line ?? "").trim();
    if (s.startsWith("|")) s = s.slice(1);
    if (s.endsWith("|")) s = s.slice(0, -1);
    return s.split("|").map(c => c.trim());
}

function isDelimiterRow(line) {
    if (!line || line.indexOf("-") < 0) return false;
    const parts = cells(line);
    return parts.length > 0 && parts.every(p => /^:?-{3,}:?$/.test(p));
}

function isTableStart(lines, i) {
    return i + 1 < lines.length && String(lines[i]).indexOf("|") >= 0 && isDelimiterRow(lines[i + 1]);
}

function startsBlock(lines, i) {
    const line = lines[i];
    if (isBlank(line)) return true;
    if (/^\s{0,3}#{1,6}\s+/.test(line)) return true;
    if (fenceAt(line)) return true;
    if (/^\s{0,3}>/.test(line)) return true;
    if (/^\s{0,3}([-*+]|\d+[.)])\s+/.test(line)) return true;
    if (isRule(line)) return true;
    if (isTableStart(lines, i)) return true;
    return false;
}

function parse(source) {
    const lines = normalise(source).split("\n");
    const blocks = [];
    let i = 0;

    while (i < lines.length) {
        const line = lines[i];
        if (isBlank(line)) { i++; continue; }

        // A fenced block keeps every line, including rules and hashes.
        let fence = fenceAt(line);
        if (fence) {
            const fenceLine = line;
            i++;
            const body = [];
            while (i < lines.length) {
                const next = lines[i];
                const close = /^\s{0,3}(`{3,}|~{3,})\s*$/.exec(next);
                if (close && close[1][0] === fence.marker && close[1].length >= fence.length) { i++; break; }
                body.push(next);
                i++;
            }
            blocks.push({ type: "code", language: fence.language, text: body.join("\n") });
            continue;
        }

        let m = /^\s{0,3}(#{1,6})\s+(.*?)\s*#*\s*$/.exec(line);
        if (m) {
            blocks.push({ type: "heading", level: m[1].length, text: m[2] });
            i++;
            continue;
        }

        if (isRule(line)) {
            blocks.push({ type: "rule" });
            i++;
            continue;
        }

        if (/^\s{0,3}>/.test(line)) {
            const body = [];
            while (i < lines.length && /^\s{0,3}>/.test(lines[i])) {
                body.push(lines[i].replace(/^\s{0,3}>\s?/, ""));
                i++;
            }
            blocks.push({ type: "quote", text: body.join("\n") });
            continue;
        }

        if (/^\s{0,3}([-*+]|\d+[.)])\s+/.test(line)) {
            const list = readList(lines, i);
            if (list.items.length > 0) blocks.push({ type: "list", items: list.items });
            i = list.next;
            continue;
        }

        if (isTableStart(lines, i)) {
            const header = cells(lines[i]);
            const aligns = cells(lines[i + 1]).map(c => {
                const left = c.startsWith(":");
                const right = c.endsWith(":");
                return left && right ? "center" : right ? "right" : left ? "left" : "";
            });
            i += 2;
            const rows = [];
            while (i < lines.length && !isBlank(lines[i]) && String(lines[i]).indexOf("|") >= 0 && !isRule(lines[i])) {
                rows.push(cells(lines[i]));
                i++;
            }
            blocks.push({ type: "table", header, aligns, rows });
            continue;
        }

        // A paragraph: soft line breaks become one line, two trailing spaces keep a hard one.
        const body = [];
        while (i < lines.length && !isBlank(lines[i]) && !startsBlock(lines, i)) {
            const hard = / {2,}$/.test(lines[i]);
            body.push(lines[i].replace(/\s+$/, "") + (hard ? "\u0000BR\u0000" : ""));
            i++;
        }
        if (body.length === 0) {
            blocks.push({ type: "paragraph", text: line });
            i++;
        } else {
            blocks.push({ type: "paragraph", text: body.join(" ").replace(/\u0000BR\u0000/g, "\n") });
        }
    }

    return blocks;
}

function readList(lines, start) {
    const items = [];
    let i = start;
    let baseIndent = -1;
    const itemAt = /^(\s*)([-*+]|\d+[.)])\s+(.*)$/;

    while (i < lines.length) {
        if (isBlank(lines[i])) {
            let j = i + 1;
            while (j < lines.length && isBlank(lines[j])) j++;
            if (j < lines.length && itemAt.test(lines[j])) { i = j; continue; }
            break;
        }
        const m = itemAt.exec(lines[i]);
        if (!m) break;

        const indent = m[1].replace(/\t/g, "    ").length;
        if (baseIndent < 0) baseIndent = indent;
        const depth = Math.max(0, Math.round((indent - baseIndent) / 2));
        const ordered = /^\d/.test(m[2]);
        const number = ordered ? parseInt(m[2], 10) : 0;
        let text = m[3];

        let j = i + 1;
        while (j < lines.length) {
            if (isBlank(lines[j])) break;
            if (itemAt.test(lines[j])) break;
            const more = /^(\s+)(.*)$/.exec(lines[j]);
            if (!more) break;
            text += " " + more[2].trim();
            j++;
        }

        items.push({ depth, ordered, number, text });
        i = j;
    }

    return { items, next: i };
}

// Slides: a line of exactly three dashes between them, outside a fence. A fence that starts or ends
// inside a slide is kept with it, so a deck can show a rule of its own.
function splitSlides(source) {
    const lines = normalise(source).split("\n");
    const chunks = [];
    let current = [];
    let fence = null;

    for (const line of lines) {
        const f = fenceAt(line);
        if (f) {
            if (fence === null) fence = f.marker;
            else if (fence === f.marker) fence = null;
            current.push(line);
            continue;
        }
        if (fence === null && /^\s{0,3}---\s*$/.test(line)) {
            if (current.join("\n").trim() !== "") chunks.push(current.join("\n"));
            current = [];
            continue;
        }
        current.push(line);
    }
    if (current.join("\n").trim() !== "") chunks.push(current.join("\n"));
    return chunks;
}

function slides(source) {
    return splitSlides(source).map(chunk => {
        const blocks = parse(chunk);
        let title = "";
        let body = blocks;
        if (blocks.length > 0 && blocks[0].type === "heading") {
            title = plain(blocks[0].text);
            body = blocks.slice(1);
        } else if (blocks.length > 0 && blocks[0].type === "paragraph") {
            title = plain(blocks[0].text);
            body = blocks.slice(1);
        }
        return { title, body, source: chunk };
    });
}

function wordCount(source) {
    const words = normalise(source)
        .replace(/```[\s\S]*?```/g, " ")
        .replace(/[#>*_`~\[\]\(\)!|]/g, " ")
        .trim();
    return words === "" ? 0 : words.split(/\s+/).length;
}

function slideCount(source) {
    return splitSlides(source).length;
}
