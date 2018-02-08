// lite version of discourse/lib/utilities

export function determinePostReplaceSelection({ selection, needle, replacement }) {
  const diff = (replacement.end - replacement.start) - (needle.end - needle.start);

  if (selection.end <= needle.start) {
    // Selection ends (and starts) before needle.
    return { start: selection.start, end: selection.end };
  } else if (selection.start <= needle.start) {
    // Selection starts before needle...
    if (selection.end < needle.end) {
      // ... and ends inside needle.
      return { start: selection.start, end: needle.start };
    } else {
      // ... and spans needle completely.
      return { start: selection.start, end: selection.end + diff };
    }
  } else if (selection.start < needle.end) {
    // Selection starts inside needle...
    if (selection.end <= needle.end) {
      // ... and ends inside needle.
      return { start: replacement.end, end: replacement.end };
    } else {
      // ... and spans end of needle.
      return { start: replacement.end, end: selection.end + diff };
    }
  } else {
    // Selection starts (and ends) behind needle.
    return { start: selection.start + diff, end: selection.end + diff };
  }
}

const toArray = items => {
  items = items || [];

  if (!Array.isArray(items)) {
    return Array.from(items);
  }

  return items;
};

export function clipboardData(e, canUpload) {
  const clipboard = e.clipboardData ||
                      e.originalEvent.clipboardData ||
                      e.delegatedEvent.originalEvent.clipboardData;

  const types = toArray(clipboard.types);
  let files = toArray(clipboard.files);

  if (types.includes("Files") && files.length === 0) { // for IE
    files = toArray(clipboard.items).filter(i => i.kind === "file");
  }

  canUpload = files && canUpload && !types.includes("text/plain");
  const canUploadImage = canUpload && files.filter(f => f.type.match('^image/'))[0];
  const canPasteHtml = Discourse.SiteSettings.enable_rich_text_paste && types.includes("text/html") && !canUploadImage;

  return { clipboard, types, canUpload, canPasteHtml };
}
