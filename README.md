# SpriteKit-WindowManager

*You see, here I was, minding my own business listening to [Stacktrace](https://twitter.com/stacktracepod) when suddenly a certain couple of podcasters started talking about a SpriteKit Window Manager, which was an idea of mine also, and suddenly I found myself elbow deep in Metal Shader code trying to build my own texture atlas.  Don’t get me wrong, this was fun and all, and I may end up using some of this code in a current project, but I've moved on to SwiftUI now.  I knew when I started this,  that Apple had a good possibility of beating me at building a cross platform UI framework, and boy did they🤯*

After fixing my apps to support iOS 13, and starting 3 new apps, I don't feel the motivation to finish this anymore, so I thought It would be fun to just share what I have now, might be useful in a game or something

Basically I have set up a responder chain, and gesture recognizers, and created a SKNodeController that works kind of like a UIViewController. Then when I moved the code into a framework, I couldn’t load the SKTextureAtlas from the bundle anymore.  I had to resort to manually loading the atlas, which throws away all of the image rotation info so SKTextures started randomly loading at 90 degree angles.  If it stays as a separate framework this will need to be worked around by manually creating a new texture atlas implementation, and the code (mostly done in a playground) to fit sprites to the sheet is what finally bogged me down.  If you rip the code out and include it in an app by itself, the texture loading should work with the default SKTextureAtlas loading method again.  

Touches are just received by gesture recognizers and passed up the chain to parent nodes.  I really have no idea what I’m doing ☺️ (it was just an experiment) and you can all thank [@stroughtonsmith's thread](https://twitter.com/stroughtonsmith/status/1235348764858159104) for encouraging me to release this abomination upon humanity🤣

`SKWindowManagerKit` is the base framework for creating any type of window manager.  I started building a version of the classic Mac window manager.  It comes with a few B&W OS 7 style controls (window, title bar, button, and close box) in the `ClassicWMKit` framework.

iOS 13 broke something in the SKShader code I was using to tile images in the SKSpriteNode+RepeatTexture.swift file (for rendering the classic desktop background).

I realize that what seems like self-documenting code to me, may not read so well to others, and for that I apologize, If I had the time to properly finish and release this, I would have included many more comments🙃
