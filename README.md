# A script leveraging mpv for preview of images and more for **lf** on Windows platform
## 1. Install lf
## 2. Install mpv
## 3. download scripts to one directory or clone the repo
## 4. Set up lfrc
add lines into lfrc

```
# Custom file previewer
set previewer "PATH\TO\THE\LfMpvPreviewer_loader.cmd"
```

any extra script is added the similar way, for example 
```
# Copy file to clipboard
map <c-c> ${{"PATH\TO\THE\real_copy.cmd" %f%}}
```
