const fs = require('fs');
const { marked } = require('marked');

const md = fs.readFileSync('slides/07-conclusion.md', 'utf8');
const slides = md.split('\n---\n');
console.log(marked.parse(slides[2]));
