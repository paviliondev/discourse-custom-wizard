function generateSelectKitContent(content) {
  return content.map(i => ({id: i, name: i}))
}

export { generateSelectKitContent };