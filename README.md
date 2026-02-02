# scripts
useful bash, command line scripts
## Second Brain logseq/obsidian page
This constructs a logseg/obsidian page with minimal friction aafter capture. Select the page url, give the Obsidian a title, filename and a brief description. 
The description is typically the intro or abstract from a paper.  find_pdf_summary is intended to en-masse create entries from existing pdf files. No magic, just pdftotext and grep.
- create_note.sh This uses no AI, instead a list of tags in json to create a logseq/onsidian page. 
- select_tags.sh The two layer menus to select tags.
- all_tags.json  My go to list, your will be different.
- find_pdf_summary.sh WIP to extract the description for create_note
- pdf_summary.sh simple pdftotext extraction helper function
## Example
```bash
./create_note.sh -t 'ASR-TTS Paper Daily' -f tts_DAily_Papers -d 'This repository provides a daily-updated collection of the latest research papers from arXiv in the following domains:
Automatic Speech Recognition (ASR) Text-to-Speech (TTS) Machine Translation Small Language Models Data Augmentation Synthetic Generation' -u  https://nickdee96.github.io/ASR-TTS-paper-daily/
```
results in the markdown file with embedded yaml. The tags are selected from the json list.

```markdown
---
id: 202602021511
created_date: 2026-02-02
updated_date: 2026-02-02
---
Status: read
Tags: [[AI]] [[LLM]]
---
## How does in-context learning work?
In this post, we provide a Bayesian inference framework for in-context learning in large language models like GPT-3 and show empirical evidence for our framework, highlighting the differences from traditional supervised learning. This blog post primarily draws from the theoretical framework for in-context learning from An Explanation of In-context Learning as Implicit Bayesian Inference and experiments from Rethinking the Role of Demonstrations: What Makes In-Context Learning Work?

[text](https://ai.stanford.edu/blog/understanding-incontext/)
_______

References

```yaml
data:
  title: "How does in-context learning work?"
  type: note
  tags: [AI, LLM]
  status: read
  notes: |
    # How does in-context learning work?
    
    In this post, we provide a Bayesian inference framework for in-context learning in large language models like GPT-3 and show empirical evidence for our framework, highlighting the differences from traditional supervised learning. This blog post primarily draws from the theoretical framework for in-context learning from An Explanation of In-context Learning as Implicit Bayesian Inference and experiments from Rethinking the Role of Demonstrations: What Makes In-Context Learning Work?
```
