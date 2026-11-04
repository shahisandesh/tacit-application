.pragma library

// Syntax colour for fenced code. Markdown.js gives the fence's language; this module colours the
// words so a fence in a known language reads as code. Qt's styled text ignores the style
// attribute, so every colour is a <font color> tag, every space is kept with &nbsp;, and every
// line with <br/>. Colours come from the page's theme, never from here.

const ALIASES = {
    "js": "js", "javascript": "js", "mjs": "js", "cjs": "js", "jsx": "js",
    "ts": "ts", "typescript": "ts", "tsx": "ts",
    "bash": "bash", "sh": "bash", "shell": "bash", "zsh": "bash", "fish": "bash", "console": "bash", "shell-session": "bash",
    "py": "py", "python": "py", "python3": "py",
    "json": "json", "jsonc": "json",
    "css": "css", "scss": "css", "sass": "css", "less": "css",
    "html": "html", "xml": "html", "svg": "html", "htm": "html", "vue": "html", "xhtml": "html",
    "c": "c", "h": "c",
    "cpp": "cpp", "c++": "cpp", "cc": "cpp", "cxx": "cpp", "hpp": "cpp",
    "java": "java", "kt": "java", "kotlin": "java", "scala": "java",
    "rs": "rust", "rust": "rust",
    "go": "go", "golang": "go",
    "md": "markdown", "markdown": "markdown", "mdown": "markdown",
    "yml": "yaml", "yaml": "yaml",
    "toml": "toml", "ini": "toml", "conf": "toml",
    "sql": "sql", "postgres": "sql", "postgresql": "sql", "mysql": "sql", "sqlite": "sql",
    "diff": "diff", "patch": "diff",
    "text": "", "plaintext": "", "plain": "", "txt": "", "": ""
};

function wordSet(words) {
    const out = {};
    const parts = String(words).trim().split(/\s+/);
    for (const word of parts) if (word) out[word] = true;
    return out;
}

function extend(base, extra) {
    const out = {};
    for (const key in base) out[key] = true;
    const parts = String(extra).trim().split(/\s+/);
    for (const word of parts) if (word) out[word] = true;
    return out;
}

const JS = wordSet("break case catch class const continue debugger default delete do else export extends finally for function if import in instanceof let new return super switch this throw try typeof var void while with yield async await of static get set from as");
const TS = extend(JS, "interface type enum implements public private protected readonly namespace declare abstract keyof infer is asserts satisfies override");
const PY = wordSet("def class return if elif else for while in not and or is None True False import from as with try except finally raise lambda yield async await global nonlocal pass break continue del assert print self match case");
const BASH = wordSet("if then else elif fi for while until do done case esac function in select time coproc return exit local export readonly declare typeset unset shift source alias unalias echo printf read cd pwd test true false set trap wait kill exec eval");
const C = wordSet("auto break case char const continue default do double else enum extern float for goto if inline int long register restrict return short signed sizeof static struct switch typedef union unsigned void volatile while");
const CPP = extend(C, "alignas alignof and and_eq asm bitand bitor bool catch char8_t char16_t char32_t class compl concept consteval constexpr constinit const_cast co_await co_return co_yield decltype delete dynamic_cast explicit export false friend mutable namespace new noexcept not not_eq nullptr operator or or_eq private protected public reinterpret_cast requires static_assert static_cast template this thread_local throw true try typeid typename using virtual wchar_t xor xor_eq nullptr_t");
const JAVA = wordSet("abstract assert boolean break byte case catch char class const continue default do double else enum extends final finally float for goto if implements import instanceof int interface long native new package private protected public return short static strictfp super switch synchronized this throw throws transient true false try void volatile while var record sealed permits yield");
const RUST = wordSet("as async await break const continue crate dyn else enum extern false fn for if impl in let loop match mod move mut pub ref return self Self static struct super trait true type unsafe use where while");
const GO = wordSet("break case chan const continue default defer else fallthrough for func go goto if import interface map package range return select struct switch type var true false nil iota");
const SQL = wordSet("SELECT FROM WHERE JOIN LEFT RIGHT INNER OUTER ON INSERT INTO VALUES UPDATE SET DELETE CREATE TABLE DROP ALTER ADD COLUMN GROUP BY ORDER HAVING LIMIT OFFSET AS AND OR NOT NULL IS IN LIKE DISTINCT COUNT SUM AVG MIN MAX CASE WHEN THEN ELSE END UNION ALL PRIMARY KEY FOREIGN REFERENCES INDEX VIEW DATABASE SCHEMA EXISTS BETWEEN ASC DESC");
const JSONW = wordSet("true false null");
const YAMLW = wordSet("true false null yes no on off");
const TOMLW = wordSet("true false");
const CSSW = wordSet("@media @import @supports @font-face @keyframes @charset @namespace @page");
const MDW = {};

const KEYWORDS = {
    js: JS, ts: TS, py: PY, bash: BASH, c: C, cpp: CPP, java: JAVA,
    rust: RUST, go: GO, sql: SQL, json: JSONW, yaml: YAMLW, toml: TOMLW,
    css: CSSW, html: {}, markdown: MDW, diff: {}, generic: {}
};

const TYPE_LANGS = { js: true, ts: true, c: true, cpp: true, java: true, rust: true, go: true, py: true };
const LINE_COMMENTS = {
    js: ["//"], ts: ["//"], c: ["//"], cpp: ["//"], java: ["//"], rust: ["//"], go: ["//"],
    bash: ["#"], py: ["#"], yaml: ["#"], toml: ["#"], sql: ["--"],
    generic: ["//", "#"]
};
const BLOCK_COMMENTS = {
    js: ["/*", "*/"], ts: ["/*", "*/"], c: ["/*", "*/"], cpp: ["/*", "*/"], java: ["/*", "*/"],
    rust: ["/*", "*/"], go: ["/*", "*/"], css: ["/*", "*/"],
    generic: ["/*", "*/"]
};

function normalise(language) {
    const key = String(language ?? "").trim().toLowerCase();
    if (key === "") return "";
    // An unknown fence still gets strings, numbers and the common comment marks.
    return ALIASES[key] ?? "generic";
}

function escapeHtml(text) {
    return String(text ?? "")
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;");
}

// A run of code keeps its shape: spaces, tabs and line breaks.
function space(text) {
    return escapeHtml(text)
        .replace(/\t/g, "    ")
        .replace(/ /g, "&nbsp;")
        .replace(/\n/g, "<br/>");
}

function color(text, css) {
    if (!text) return "";
    const body = space(text);
    return css ? `<font color="${css}">${body}</font>` : body;
}

function atLineStart(code, i) {
    let k = i - 1;
    while (k >= 0 && code[k] !== "\n") {
        if (!/\s/.test(code[k])) return false;
        k--;
    }
    return true;
}

function hashComment(code, i) {
    if (i === 0) return true;
    const before = code[i - 1];
    return /\s/.test(before) || before === ";" || before === "&" || before === "|" || before === "(";
}

function scan(code, lang, colors) {
    const keywords = KEYWORDS[lang] ?? {};
    const lineMarks = LINE_COMMENTS[lang] ?? [];
    const block = BLOCK_COMMENTS[lang];
    const typeLang = TYPE_LANGS[lang] === true;
    const n = code.length;
    let i = 0;
    let out = "";

    while (i < n) {
        const ch = code[i];

        // C and C++ read a # line as a preprocessor directive.
        if ((lang === "c" || lang === "cpp") && ch === "#" && atLineStart(code, i)) {
            let end = code.indexOf("\n", i);
            if (end < 0) end = n;
            out += color(code.slice(i, end), colors.meta);
            i = end;
            continue;
        }

        if (block && code.startsWith(block[0], i)) {
            let end = code.indexOf(block[1], i + block[0].length);
            end = end < 0 ? n : end + block[1].length;
            out += color(code.slice(i, end), colors.comment);
            i = end;
            continue;
        }

        let lineMark = "";
        for (const mark of lineMarks) {
            if (code.startsWith(mark, i) && (mark !== "#" || hashComment(code, i))) {
                lineMark = mark;
                break;
            }
        }
        if (lineMark !== "") {
            let end = code.indexOf("\n", i);
            if (end < 0) end = n;
            out += color(code.slice(i, end), colors.comment);
            i = end;
            continue;
        }

        // Python's triple-quoted strings.
        if (lang === "py" && (code.startsWith('"""', i) || code.startsWith("'''", i))) {
            const mark = code.substr(i, 3);
            let end = code.indexOf(mark, i + 3);
            end = end < 0 ? n : end + 3;
            out += color(code.slice(i, end), colors.string);
            i = end;
            continue;
        }

        if (ch === '"' || ch === "'" || (ch === "`" && (lang === "js" || lang === "ts" || lang === "bash"))) {
            let j = i + 1;
            while (j < n) {
                if (code[j] === "\\") { j += 2; continue; }
                if (code[j] === ch) { j++; break; }
                if (code[j] === "\n" && ch !== "`") break;
                j++;
            }
            let css = colors.string;
            if (lang === "json") {
                let k = j;
                while (k < n && /\s/.test(code[k])) k++;
                if (code[k] === ":") css = colors.key;
            }
            out += color(code.slice(i, j), css);
            i = j;
            continue;
        }

        if (lang === "css" && ch === "#") {
            const hex = /^#[0-9a-fA-F]{3,8}\b/.exec(code.slice(i));
            if (hex) {
                out += color(hex[0], colors.number);
                i += hex[0].length;
                continue;
            }
        }

        if (lang === "css" && ch === "@") {
            let j = i + 1;
            while (j < n && /[A-Za-z-]/.test(code[j])) j++;
            out += color(code.slice(i, j), colors.keyword);
            i = j;
            continue;
        }

        if (/[0-9]/.test(ch) || (ch === "." && /[0-9]/.test(code[i + 1] ?? ""))) {
            const number = /^(?:0[xX][0-9a-fA-F]+|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)/.exec(code.slice(i));
            if (number) {
                out += color(number[0], colors.number);
                i += number[0].length;
                continue;
            }
        }

        if (/[A-Za-z_$]/.test(ch)) {
            let j = i + 1;
            while (j < n && /[A-Za-z0-9_$-]/.test(code[j])) j++;
            const word = code.slice(i, j);
            const lookup = lang === "sql" ? word.toUpperCase() : word;
            let css = "";
            if (keywords[lookup]) css = colors.keyword;
            else if (code[j] === "(") css = colors.function;
            else if (typeLang && /^[A-Z]/.test(word)) css = colors.type;
            out += color(word, css);
            i = j;
            continue;
        }

        if (/[+\-*/%=<>!&|^~?:]/.test(ch)) { out += color(ch, colors.operator); i++; continue; }
        if (/[{}()[\],.;]/.test(ch)) { out += color(ch, colors.punctuation); i++; continue; }

        out += space(ch);
        i++;
    }
    return out;
}

function html(code, colors) {
    const n = code.length;
    let i = 0;
    let out = "";

    while (i < n) {
        if (code.startsWith("<!--", i)) {
            let end = code.indexOf("-->", i + 4);
            end = end < 0 ? n : end + 3;
            out += color(code.slice(i, end), colors.comment);
            i = end;
            continue;
        }

        if (code[i] === "<") {
            let j = i + 1;
            if (code[j] === "/") j++;

            if (code[j] === "!" || code[j] === "?") {
                let end = code.indexOf(">", i);
                end = end < 0 ? n : end + 1;
                out += color(code.slice(i, end), colors.meta);
                i = end;
                continue;
            }

            let k = j;
            while (k < n && /[A-Za-z0-9:_-]/.test(code[k])) k++;
            if (k > j) {
                out += color(code.slice(i, j), colors.punctuation);
                out += color(code.slice(j, k), colors.tag);
                i = k;
                while (i < n && code[i] !== ">") {
                    const c = code[i];
                    if (c === '"' || c === "'") {
                        let e = i + 1;
                        while (e < n && code[e] !== c) {
                            if (code[e] === "\\") e++;
                            e++;
                        }
                        if (e < n) e++;
                        out += color(code.slice(i, e), colors.string);
                        i = e;
                    } else if (/[A-Za-z0-9:_-]/.test(c)) {
                        let e = i + 1;
                        while (e < n && /[A-Za-z0-9:_-]/.test(code[e])) e++;
                        out += color(code.slice(i, e), colors.attr);
                        i = e;
                    } else if (c === "=") {
                        out += color("=", colors.operator);
                        i++;
                    } else {
                        out += space(c);
                        i++;
                    }
                }
                if (i < n) {
                    out += color(">", colors.punctuation);
                    i++;
                }
                continue;
            }
        }

        if (code[i] === "&") {
            const entity = /^&[A-Za-z0-9#]+;/.exec(code.slice(i));
            if (entity) {
                out += color(entity[0], colors.meta);
                i += entity[0].length;
                continue;
            }
        }

        out += space(code[i]);
        i++;
    }
    return out;
}

function inlineMarkdown(text, colors) {
    const code = [];
    let s = String(text ?? "");
    s = s.replace(/`([^`]+)`/g, (m, words) => {
        const index = code.push(words) - 1;
        return "\u0000C" + index + "\u0000";
    });
    s = escapeHtml(s);
    s = s.replace(/ /g, "\u0000S\u0000");
    s = s.replace(/\*\*([^*]+)\*\*/g, "<b>$1</b>");
    s = s.replace(/\*([^*]+)\*/g, "<i>$1</i>");
    s = s.replace(/\[([^\]]+)\]\(([^)]+)\)/g, (m, label) => `<font color="${colors.attr}">${label}</font>`);
    for (let i = 0; i < code.length; i++) {
        const span = `<font color="${colors.string}">${escapeHtml(code[i]).replace(/ /g, "\u0000S\u0000")}</font>`;
        s = s.replace("\u0000C" + i + "\u0000", span);
    }
    return s.replace(/\u0000S\u0000/g, "&nbsp;");
}

function markdown(code, colors) {
    const lines = code.split("\n");
    return lines.map(line => {
        if (/^\s*```/.test(line)) return color(line, colors.meta);
        if (/^\s{0,3}(?:---+|\*\*\*+|___+)\s*$/.test(line)) return color(line, colors.meta);
        if (/^\s{0,3}#{1,6}\s/.test(line)) return "<b>" + color(line, colors.keyword) + "</b>";
        if (/^\s{0,3}>/.test(line)) return color(line, colors.comment);
        const item = /^(\s*)([-*+]|\d+[.)])(\s+)(.*)$/.exec(line);
        if (item)
            return space(item[1]) + color(item[2], colors.keyword) + space(item[3]) + inlineMarkdown(item[4], colors);
        return inlineMarkdown(line, colors);
    }).join("<br/>");
}

function diff(code, colors) {
    return code.split("\n").map(line => {
        if (/^(\+\+\+|---|diff |index |@@)/.test(line)) return color(line, colors.meta);
        if (line.startsWith("+")) return color(line, colors.added);
        if (line.startsWith("-")) return color(line, colors.removed);
        return color(line, "");
    }).join("<br/>");
}

function highlight(code, language, colors) {
    const lang = normalise(language);
    if (lang === "") return space(code);
    if (lang === "html") return html(code, colors);
    if (lang === "markdown") return markdown(code, colors);
    if (lang === "diff") return diff(code, colors);
    return scan(code, lang, colors);
}
