function exists(selector) {
  return document.querySelector(selector) !== null;
}

export { exists };
