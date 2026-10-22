// Extracts text from a PDF as pages > lines > cells, using PDF.js.
// Each cell is {x, t}: its left position and its text. Cells that sit close
// together are merged, so a "column" of a table ends up as one cell.
//
// Works in the browser (global pdfjsLib) and in Node (pass the library in).

async function extractPdfPages(data, lib) {
  lib = lib || pdfjsLib;
  const doc = await lib.getDocument({ data: data }).promise;
  const pages = [];
  for (let p = 1; p <= doc.numPages; p++) {
    const page = await doc.getPage(p);
    const content = await page.getTextContent();
    const items = content.items
      .filter((i) => i.str.trim() !== "")
      .map((i) => ({ x: i.transform[4], y: i.transform[5], w: i.width, t: i.str }));
    // Top of the page first, then left to right.
    items.sort((a, b) => b.y - a.y || a.x - b.x);
    const rows = [];
    for (const item of items) {
      const row = rows[rows.length - 1];
      if (row && Math.abs(row.y - item.y) <= 2.5) row.items.push(item);
      else rows.push({ y: item.y, items: [item] });
    }
    pages.push(
      rows.map((row) => {
        row.items.sort((a, b) => a.x - b.x);
        const cells = [];
        let last = null;
        for (const item of row.items) {
          const gap = last ? item.x - (last.x + last.w) : Infinity;
          if (last && gap < 1) {
            cells[cells.length - 1].t += item.t;
          } else if (last && gap < 6) {
            cells[cells.length - 1].t += " " + item.t;
          } else {
            cells.push({ x: Math.round(item.x), t: item.t });
          }
          last = item;
        }
        return cells.map((c) => ({ x: c.x, t: c.t.trim() }));
      })
    );
  }
  return pages;
}

// Called from Dart. Returns the pages as a JSON string.
async function extractPdfLines(bytes) {
  return JSON.stringify(await extractPdfPages(bytes));
}

if (typeof module !== "undefined") module.exports = { extractPdfPages };
