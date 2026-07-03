# Goal 

Implement nvim plugin "super-tab"

## Commands
### SuperTab
Default keymap if (opts enabled = true):
  <M->>

  Action: 
  normal mode: 
    tab whole line (similar as shift >>)
    additionally: 
      - if line above is tabbed to the same depth of line above. 
      - if line is in a comment respect the comment spacing. 

### SuperTabBack
Same as SuperTab but removes a tab

Default keymap if (opts enabled = true):
  <M-<>

## Config opts
respect_comments = true (default) | false
  if true: use current lsp to determine what the comment string is. 
    if comment string and respect_comments = true than tabs should be being one space after comment and comment should stay in the same spot it is. 

example: 

```js

console.log(...)
:SuperTab on line
becomes: 
  console.log(...)

//console.log(...)
:SuperTab on line
becomes: 
//  console.log(...)

//  console.log(...)
:SuperTabBack on line
becomes: 
//  console.log(...)

```
