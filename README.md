# elm-minesweeper

Set up.

```shell
$ npm install
$ npm start
```

At this point, you could open static files and manually build after changing files.

```shell
$ open dist/index.html
$ npm run build
```

You could also use `elm reactor` to automatically run your build. Just refresh the page after making changes.

```shell
$ npm run reactor
$ open http://localhost:8000/src/Main.elm
```

`elm-format` is used to format the code here.

```shell
$ npm run format
```

### Trouble shooting?

**The images are not showing up?**

```shell
npm run static
```
That should copy the images etc. over.

**Debugger not showing?**

To get the elm debugger showing, try this:

```shell
$ npm run build -- --debug
```
It will build a JS file that includes dev tools. then, open dist/index.html.
