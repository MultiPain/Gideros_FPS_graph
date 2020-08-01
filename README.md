# Preview

<p align="center">
  <img src="Gideros_examples/img/graph.png">
</p>

# API
```lua
(object) = FPSgraph.new(width, height, [options])
```

* width (number) - width of the container
* height (number) - height of the container
* options (table) - extra parameters [optional]
	* step (number, default - 20)- step between peeks
	* antialiasing (number, default - 2)- smooth graph edge on top
	* color (number, default - 0xffffff) - background color of the container
	* alpha (number, defalut - 0.5) - background alpha of the container
	* font (FontBase, default - nil) - textfiled font
	* textColor (number, defalut - 0) - textfiled color
	* textAlign (number, defalut -  FontBase.TLF_REF_LINETOP | FontBase.TLF_CENTER | FontBase.TLF_VCENTER) - text flags to :setLayout()
	* minColor (number, defalut - 0xff0000) - color of minimum FPS on a graph
	* maxColor (number, defalut - 0x00ff00) - color of maximum FPS on a graph
	* updateTime (number, defalut - 0.2) - graph is updated once per this amount of seconds
	* minTextColor (string, defalut - "#000") - color of minimum FPS in textfiled (works only with bitmap font)
	* currTextColor (string, defalut - "#000") - color of current FPS in textfiled (works only with bitmap font)
	* maxTextColor (string, defalut - "#000") - color of maximum FPS in textfiled (works only with bitmap font)
