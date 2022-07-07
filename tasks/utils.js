exports.parseCommaSeparatedValues = (string) => {
  return string.split(',').map(v => v.trim())
};
