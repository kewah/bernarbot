# slack-bernarbot

Bernarbot uses:
- [hubot-old](https://github.com/kewah/hubot-old)
- [hubot-curate-links](https://github.com/kewah/hubot-curate-links)

### Scripting

Local scripts must be included at `scripts/*.coffee`.  
[Scripting Guide](https://github.com/github/hubot/blob/master/docs/scripting.md)

### hubot-scripts

To enable scripts from the hubot-scripts package, add the script name with
extension as a double quoted string to the `hubot-scripts.json` file in this
repo.

### external-scripts

Hubot is able to load scripts from third-party `npm` package. Check the package's documentation, but in general it is:

1. Add the packages as dependencies into your `package.json`
2. `npm install` to make sure those packages are installed
3. Add the package name to `external-scripts.json` as a double quoted string

You can review `external-scripts.json` to see what is included by default.

## Guides

- [Hubot docs](https://github.com/github/hubot/tree/master/docs)
- [Hubot slack](https://github.com/slackhq/hubot-slack)
