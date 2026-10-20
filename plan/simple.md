# Goal 

Create nvim plugin "super-tab"

- remove "hello world" template logic and commands

## Commands
### SuperTab
Default keymap if (opts enabled = true):
  <M->>

Action: 
normal mode and insert mode: 
    tab whole line (similar as shift >>)

        
### SuperTabBack
Default keymap if (opts enabled = true):
  <M-<>

Action: 
normal mode and insert mode: 
    tab whole line (similar as shift <<)


for both SuperTab and SuperTabBack

respect line context.  

line above or bellow

```
some line
    another line
third line
```
after super-tabbing third line
```
some line
    another line
    third line
```

respect comment blocks (for any given language calling super-tab in):
```lua
-- some comment
-- second line
-- third line
```
after super-tabbing second line:
```lua
-- some comment
--  second line
-- third line
```

