# Content Marketing Pipeline

End-to-end blog post creation with research, write, edit, publish agents.

## Agents

1. Research - Gathers sources, creates brief and outline
2. Write - Drafts the blog post
3. Edit - Polishes for grammar, flow, SEO
4. Publish - Formats and prepares for publication

## Features Demonstrated

- **SEO Integration**: Keyword research贯穿整个流程
- **Quality Control**: Editor can send back to writer for revisions
- **Multi-format Output**: Article + social posts + metadata
- **Platform-aware**: Formatting adapts to target platform

## Running

```bash
# Set your content parameters
export TASK="Write about the benefits of async/await in JavaScript"
export TARGET_AUDIENCE="intermediate developers"
export TONE="professional but approachable"
export WORD_COUNT=1500
export SEO_KEYWORDS="javascript async await, promises, asynchronous programming"
export PLATFORM=wordpress

# Run the pipeline
chain-runner examples/content-marketing/chain.json
```

## Workspace Structure

```
workspace/
  research/
    brief.md          - content brief with outline
    sources.md        - source links and citations
    keywords.md       - SEO keyword research
    outline.md        - detailed article structure
  write/
    article.md        - the blog post draft
    meta.md           - title, description, tags
    word-count.md     - article statistics
  edit/
    edited-article.md - polished version
    edit-notes.md     - changes and suggestions
    seo-checklist.md  - SEO optimization review
  publish/
    ready-to-publish.md   - final formatted content
    excerpt.md            - short summary
    social-posts.md       - social media teasers
    image-prompts.md      - featured image ideas
```

## Customization

Override environment variables to adapt the workflow:

- `TARGET_AUDIENCE` - Who you're writing for
- `TONE` - professional, casual, technical
- `WORD_COUNT` - Target length
- `PLATFORM` - wordpress, medium, ghost, custom
